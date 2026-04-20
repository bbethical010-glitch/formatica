import React, { useState, useEffect } from "react";
import { ScreenId } from "./Sidebar";
import { open } from "@tauri-apps/plugin-dialog";
import { invoke } from "@tauri-apps/api/core";
import { homeDir, join } from "@tauri-apps/api/path";

export function DocumentScreen({ setScreen }: { setScreen: (s: ScreenId) => void }) {
  const [format, setFormat] = useState("PDF");
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
      filters: [{ name: 'Documents', extensions: ['doc', 'docx', 'pdf', 'odt', 'pages', 'txt'] }]
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
      setErrorMessage("Please select a document first.");
      return;
    }

    setStatus("processing");
    try {
      const fileName = inputPath.split(/[/\\]/).pop() || "converted_doc";
      const nameWithoutExt = fileName.substring(0, fileName.lastIndexOf('.')) || fileName;
      
      const result: any = await invoke("convert_document", {
        inputPath,
        outputFormat: format.toLowerCase(),
        outputDir: savePath,
        outputName: `${nameWithoutExt}_converted`
      });

      if (result.success) {
        setStatus("success");
        setOutputPath(result.output_path);
      } else {
        setStatus("error");
        setErrorMessage(result.error_message || "Conversion failed. Ensure LibreOffice is installed.");
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
    <div className="tool-view-wrapper" style={{"--tint-col": "var(--indigo)", "--tint-rgb": "99,102,241"} as any}>
      <div className="center-column">
        <div className="tool-header">
          <div className="th-left">
            <button className="back-btn" onClick={() => setScreen("home")}>←</button>
            <div className="th-icon-c">📄</div>
            <div>
              <div className="th-title">Convert Document</div>
              <div className="th-sub"><span style={{fontSize:"14px"}}>🛡️</span> Locally processed — no cloud upload</div>
            </div>
          </div>
          <div className="on-device-badge">ON-DEVICE</div>
        </div>

        <div className="input-panel glass-panel" style={{borderRadius: "24px"}}>
          
          <div className="drop-zone" onClick={handleBrowseInput}>
            <div className="dz-icon">⬇</div>
            <div className="dz-text">Drop file here or <span style={{color: "var(--indigo)", cursor:"pointer"}}>Browse</span></div>
            {inputPath && <div style={{fontSize: "12px", color: "white", marginTop:"8px", background:"rgba(255,255,255,0.1)", padding:"4px 8px", borderRadius:"6px", overflow:"hidden", textOverflow:"ellipsis", maxWidth:"100%"}}>{inputPath}</div>}
          </div>

          <div>
            <div className="form-section-label">OUTPUT FORMAT</div>
            <div className="pill-row">
              {["PDF", "DOCX", "ODT", "TXT", "JPG", "PNG"].map(f => (
                <button 
                  key={f} 
                  className={`format-pill ${format === f ? "active" : ""}`}
                  onClick={() => setFormat(f)}
                >
                  {f}
                </button>
              ))}
            </div>
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
            {status === "processing" ? "CONVERTING..." : "CONVERT DOCUMENT"}
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
              <div style={{fontSize: "12px", marginTop: "4px", color: "var(--text-muted)"}}>Converting document format</div>
            </div>
          )}

          {status === "success" && (
            <div className="status-state-success">
              <div style={{fontSize:"32px", marginBottom:"12px"}}>✅</div>
              <div style={{fontWeight: 700, color: "#10b981"}}>Conversion Complete!</div>
              <button className="status-action-btn" onClick={openFile} style={{marginTop:"16px"}}>Open File</button>
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
            Convert documents between Word, PDF, and other office formats. High-fidelity conversion preserves layout and formatting.
          </div>
          <div style={{marginTop: "8px", display:"flex", gap:"8px"}}>
            <span className="engine-badge">Powered by LibreOffice Engine</span>
          </div>
        </div>
      </div>
    </div>
  );
}
