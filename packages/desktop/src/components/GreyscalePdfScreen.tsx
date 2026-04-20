import React, { useState, useEffect } from "react";
import { ScreenId } from "./Sidebar";
import { open } from "@tauri-apps/plugin-dialog";
import { invoke } from "@tauri-apps/api/core";
import { homeDir, join } from "@tauri-apps/api/path";

export function GreyscalePdfScreen({ setScreen }: { setScreen: (s: ScreenId) => void }) {
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

  const handleConvert = async () => {
    if (!inputPath) {
      setStatus("error");
      setErrorMessage("Please select a PDF file first.");
      return;
    }

    setStatus("processing");
    try {
      const fileName = inputPath.split(/[/\\]/).pop() || "greyscale_pdf";
      const nameWithoutExt = fileName.substring(0, fileName.lastIndexOf('.')) || fileName;
      const finalName = `${nameWithoutExt}_greyscale.pdf`;
      const fullOutputPath = await join(savePath, finalName);
      
      const result: any = await invoke("greyscale_pdf", {
        inputPath,
        outputPath: fullOutputPath
      });

      if (result.success) {
        setStatus("success");
        setOutputPath(result.output_path || fullOutputPath);
      } else {
        setStatus("error");
        setErrorMessage(result.error_message || "Greyscale conversion failed.");
      }
    } catch (e) {
      setStatus("error");
      setErrorMessage(String(e));
    }
  };

  const openFile = async () => {
    if (outputPath) {
      await invoke("open_url", { url: outputPath });
    }
  };

  return (
    <div className="tool-view-wrapper" style={{"--tint-col": "var(--slate)", "--tint-rgb": "100,116,139"} as any}>
      <div className="center-column">
        <div className="tool-header">
          <div className="th-left">
            <button className="back-btn" onClick={() => setScreen("home")}>←</button>
            <div className="th-icon-c">🌓</div>
            <div>
              <div className="th-title">Greyscale PDF</div>
              <div className="th-sub"><span style={{fontSize:"14px"}}>🛡️</span> Locally processed — no cloud upload</div>
            </div>
          </div>
          <div className="on-device-badge">ON-DEVICE</div>
        </div>

        <div className="input-panel glass-panel" style={{borderRadius: "24px"}}>
          <div className="drop-zone" onClick={handleBrowseInput}>
            <div className="dz-icon">📄</div>
            <div className="dz-text">Drop PDF here or <span style={{color: "var(--slate)", cursor:"pointer"}}>Browse</span></div>
            <div className="dz-sub">Convert colors to black, white, and greys</div>
            {inputPath && <div style={{fontSize: "12px", color: "white", marginTop:"8px", background:"rgba(255,255,255,0.1)", padding:"4px 8px", borderRadius:"6px", overflow:"hidden", textOverflow:"ellipsis", maxWidth:"100%"}}>{inputPath}</div>}
          </div>

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
            onClick={handleConvert}
            disabled={status === "processing"}
          >
            {status === "processing" ? "CONVERTING..." : "CONVERT TO GREYSCALE"}
          </button>
        </div>
      </div>

      <div className="right-column">
        <div className="side-card">
          <div className="side-card-title">STATUS</div>
          
          {status === "idle" && (
            <div className="status-state-idle">
              <div style={{fontSize:"32px", marginBottom:"12px", opacity:0.5}}>⏳</div>
              <div>Ready to convert</div>
              <div style={{fontSize:"12px", marginTop:"4px", color:"var(--text-muted)"}}>Waiting for file...</div>
            </div>
          )}

          {status === "processing" && (
            <div className="status-state-processing">
              <div className="spinner" style={{marginBottom: "12px"}} />
              <div style={{fontWeight: 700}}>Processing...</div>
              <div style={{fontSize: "12px", marginTop: "4px", color: "var(--text-muted)"}}>Applying greyscale filter</div>
            </div>
          )}

          {status === "success" && (
            <div className="status-state-success">
              <div style={{fontSize:"32px", marginBottom:"12px"}}>✅</div>
              <div style={{fontWeight: 700, color: "#64748b"}}>Conversion Complete!</div>
              <button className="status-action-btn" onClick={openFile} style={{marginTop:"16px"}}>Open PDF</button>
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
            Perfect for preparing documents for Black & White printing. Saves ink and makes file sizes smaller.
          </div>
          <div style={{marginTop: "8px", display:"flex", gap:"8px"}}>
            <span className="engine-badge">Powered by Ghostscript / Formatica PDF Engine</span>
          </div>
        </div>
      </div>
    </div>
  );
}
