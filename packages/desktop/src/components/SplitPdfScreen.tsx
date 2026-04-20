import React, { useState, useEffect } from "react";
import { ScreenId } from "./Sidebar";
import { open } from "@tauri-apps/plugin-dialog";
import { invoke } from "@tauri-apps/api/core";
import { homeDir, join } from "@tauri-apps/api/path";

export function SplitPdfScreen({ setScreen }: { setScreen: (s: ScreenId) => void }) {
  const [splitMode, setSplitMode] = useState("range");
  const [fromPage, setFromPage] = useState("1");
  const [toPage, setToPage] = useState("");
  const [everyN, setEveryN] = useState("1");
  const [inputPath, setInputPath] = useState<string | null>(null);
  const [savePath, setSavePath] = useState<string>("");
  const [status, setStatus] = useState<"idle" | "processing" | "success" | "error">("idle");
  const [errorMessage, setErrorMessage] = useState("");
  const [outputPath, setOutputPath] = useState("");

  useEffect(() => {
    async function init() {
      const home = await homeDir();
      const defaultPath = await join(home, "Documents", "Formatica");
      setSavePath(defaultPath);
    }
    init();
  }, []);

  const handleBrowseInput = async () => {
    const selected = await open({
      multiple: false,
      filters: [{ name: 'PDF', extensions: ['pdf'] }]
    });
    if (selected && typeof selected === 'string') {
      setInputPath(selected);
    }
  };

  const handleBrowseSavePath = async () => {
    const selected = await open({ directory: true });
    if (selected && typeof selected === 'string') {
      setSavePath(selected);
    }
  };

  const handleSplit = async () => {
    if (!inputPath) {
      setStatus("error");
      setErrorMessage("Please select a PDF file first.");
      return;
    }

    setStatus("processing");
    try {
      // Corrected logic to match backend:
      // mode: "range" or "every"
      // value: the actual parameter
      const mode = splitMode === "range" ? "range" : "every";
      const value = mode === "range" 
        ? `${fromPage}-${toPage || 'end'}`
        : everyN;

      const result: any = await invoke("split_pdf", {
        inputPath,
        mode,
        value,
        outputDir: savePath,
        outputPrefix: `split_${Date.now()}`
      });

      if (result.success) {
        setStatus("success");
        setOutputPath(result.output_path || savePath);
      } else {
        setStatus("error");
        setErrorMessage(result.error_message || "Split failed.");
      }
    } catch (e) {
      setStatus("error");
      setErrorMessage(String(e));
    }
  };

  const openFolder = async () => {
    await invoke("open_in_folder", { path: savePath });
  };

  return (
    <div className="tool-view-wrapper" style={{"--tint-col": "var(--amber)", "--tint-rgb": "245,158,11"} as any}>
      <div className="center-column">
        <div className="tool-header">
          <div className="th-left">
            <button className="back-btn" onClick={() => setScreen("home")}>←</button>
            <div className="th-icon-c">✂️</div>
            <div>
              <div className="th-title">Split PDF</div>
              <div className="th-sub"><span style={{fontSize:"14px"}}>🛡️</span> Locally processed — no cloud upload</div>
            </div>
          </div>
          <div className="on-device-badge">ON-DEVICE</div>
        </div>

        <div className="input-panel glass-panel" style={{borderRadius: "24px"}}>
          
          <div className="drop-zone" style={{height: "120px"}} onClick={handleBrowseInput}>
            <div className="dz-icon" style={{fontSize: "24px", marginBottom: "8px"}}>📄</div>
            <div className="dz-text">Drop PDF to split or <span style={{color: "var(--amber)", cursor:"pointer"}}>Browse</span></div>
            {inputPath && <div style={{fontSize: "12px", color: "white", marginTop:"8px", background:"rgba(255,255,255,0.1)", padding:"4px 8px", borderRadius:"6px", overflow:"hidden", textOverflow:"ellipsis", maxWidth:"100%"}}>{inputPath}</div>}
          </div>

          <div>
            <div className="form-section-label">SPLIT MODE</div>
            <div className="pill-row">
              <button 
                className={`format-pill ${splitMode === "range" ? "active" : ""}`}
                onClick={() => setSplitMode("range")}
              >
                By Page Range
              </button>
              <button 
                className={`format-pill ${splitMode === "every" ? "active" : ""}`}
                onClick={() => setSplitMode("every")}
              >
                Every N Pages
              </button>
            </div>
          </div>

          {splitMode === "range" ? (
            <div>
              <div className="form-section-label">PAGE RANGE</div>
              <div style={{display: "flex", gap: "12px", alignItems: "center"}}>
                <input 
                  type="number" 
                  className="sinput" 
                  placeholder="From (e.g. 1)" 
                  style={{width: "120px"}} 
                  value={fromPage}
                  onChange={(e) => setFromPage(e.target.value)}
                />
                <span style={{color: "var(--text-muted)"}}>to</span>
                <input 
                  type="number" 
                  className="sinput" 
                  placeholder="To (e.g. 5)" 
                  style={{width: "120px"}} 
                  value={toPage}
                  onChange={(e) => setToPage(e.target.value)}
                />
              </div>
            </div>
          ) : (
            <div>
              <div className="form-section-label">SPLIT FREQUENCY</div>
              <div style={{display: "flex", gap: "12px", alignItems: "center"}}>
                <span style={{color: "var(--text-muted)"}}>Split into files of</span>
                <input 
                  type="number" 
                  className="sinput" 
                  style={{width: "80px"}} 
                  value={everyN}
                  onChange={(e) => setEveryN(e.target.value)}
                />
                <span style={{color: "var(--text-muted)"}}>pages</span>
              </div>
            </div>
          )}

          <div>
            <div className="form-section-label">SAVE TO FOLDER</div>
            <div className="path-input-row" onClick={handleBrowseSavePath}>
              <span style={{color:"var(--text-secondary)", marginRight:"8px"}}>📁</span>
              <span className="path-text">{savePath || "Loading..."}</span>
              <button className="browse-btn">Browse</button>
            </div>
          </div>

          <button 
            className={`cta-btn ${status === "processing" ? "loading" : ""}`}
            onClick={handleSplit}
            disabled={status === "processing"}
          >
            {status === "processing" ? "SPLITTING..." : "SPLIT PDF"}
          </button>
        </div>
      </div>

      <div className="right-column">
        <div className="side-card">
          <div className="side-card-title">STATUS</div>
          
          {status === "idle" && (
            <div className="status-state-idle">
              <div style={{fontSize:"32px", marginBottom:"12px", opacity:0.5}}>⏳</div>
              <div>Ready to split</div>
              <div style={{fontSize:"12px", marginTop:"4px", color:"var(--text-muted)"}}>Waiting for file...</div>
            </div>
          )}

          {status === "processing" && (
            <div className="status-state-processing">
              <div className="spinner" style={{marginBottom: "12px"}} />
              <div style={{fontWeight: 700}}>Processing...</div>
              <div style={{fontSize: "12px", marginTop: "4px", color: "var(--text-muted)"}}>Extracting PDF pages</div>
            </div>
          )}

          {status === "success" && (
            <div className="status-state-success">
              <div style={{fontSize:"32px", marginBottom:"12px"}}>✅</div>
              <div style={{fontWeight: 700, color: "#f59e0b"}}>Split Complete!</div>
              <button className="status-action-btn" onClick={openFolder} style={{marginTop:"16px"}}>View in Folder</button>
            </div>
          )}

          {status === "error" && (
            <div className="status-state-error">
              <div style={{fontSize:"32px", marginBottom:"12px"}}>❌</div>
              <div style={{fontWeight: 700, color: "#ef4444"}}>Failed</div>
              <div style={{fontSize: "12px", marginTop: "8px", color: "rgba(239,68,68,0.8)", wordBreak:"break-word"}}>{errorMessage}</div>
              <button className="status-action-btn" onClick={() => setStatus("idle")} style={{marginTop:"16px"}}>Try Again</button>
            </div>
          )}
        </div>

        <div className="side-card">
          <div className="side-card-title">ABOUT THIS TOOL</div>
          <div className="side-card-desc">
            Extract specific pages or break down a large PDF into smaller files.
          </div>
          <div style={{marginTop: "8px", display:"flex", gap:"8px"}}>
            <span className="engine-badge">Powered by Formatica PDF Engine</span>
          </div>
        </div>
      </div>
    </div>
  );
}
