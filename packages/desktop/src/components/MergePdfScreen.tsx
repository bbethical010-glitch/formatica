import React, { useState, useEffect } from "react";
import { ScreenId } from "./Sidebar";
import { open } from "@tauri-apps/plugin-dialog";
import { invoke } from "@tauri-apps/api/core";
import { homeDir, join } from "@tauri-apps/api/path";

export function MergePdfScreen({ setScreen }: { setScreen: (s: ScreenId) => void }) {
  const [files, setFiles] = useState<string[]>([]);
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
      multiple: true,
      filters: [{ name: 'PDFs', extensions: ['pdf'] }]
    });
    if (Array.isArray(selected)) {
      setFiles((prev) => [...prev, ...selected]);
    } else if (selected && typeof selected === 'string') {
      setFiles((prev) => [...prev, selected]);
    }
  };

  const handleBrowseSavePath = async () => {
    const selected = await open({ directory: true });
    if (selected && typeof selected === 'string') {
      setSavePath(selected);
    }
  };

  const removeFile = (idx: number) => {
    const fresh = [...files];
    fresh.splice(idx, 1);
    setFiles(fresh);
  };

  const handleMerge = async () => {
    if (files.length < 2) {
      setStatus("error");
      setErrorMessage("Please select at least two PDF files to merge.");
      return;
    }

    setStatus("processing");
    try {
      // Consolidate target path
      const finalName = `merged_${Date.now()}.pdf`;
      const fullOutputPath = await join(savePath, finalName);

      const result: any = await invoke("merge_pdfs", {
        inputPaths: files,
        outputPath: fullOutputPath
      });

      if (result.success) {
        setStatus("success");
        setOutputPath(result.output_path || fullOutputPath);
      } else {
        setStatus("error");
        setErrorMessage(result.error_message || "Merge failed. Ensure PDF engine is ready.");
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
    <div className="tool-view-wrapper" style={{"--tint-col": "var(--teal)", "--tint-rgb": "16,185,129"} as any}>
      <div className="center-column">
        <div className="tool-header">
          <div className="th-left">
            <button className="back-btn" onClick={() => setScreen("home")}>←</button>
            <div className="th-icon-c">🔗</div>
            <div>
              <div className="th-title">Merge PDF</div>
              <div className="th-sub"><span style={{fontSize:"14px"}}>🛡️</span> Locally processed — no cloud upload</div>
            </div>
          </div>
          <div className="on-device-badge">ON-DEVICE</div>
        </div>

        <div className="input-panel glass-panel" style={{borderRadius: "24px"}}>
          
          <div className="drop-zone" style={{height: "120px"}} onClick={handleBrowseInput}>
            <div className="dz-icon" style={{fontSize: "24px", marginBottom: "8px"}}>➕</div>
            <div className="dz-text">Drop PDFs to merge or <span style={{color: "var(--teal)", cursor:"pointer"}}>Browse</span></div>
          </div>

          <div>
            <div className="form-section-label">FILES TO MERGE</div>
            <div style={{display: "flex", flexDirection: "column", gap: "8px"}}>
              {files.length === 0 && <div style={{fontSize: "12px", color:"var(--text-muted)", fontStyle:"italic"}}>No files selected.</div>}
              {files.map((file, idx) => (
                <div key={idx} style={{display: "flex", alignItems: "center", background: "rgba(255,255,255,0.04)", padding: "12px", borderRadius: "12px", border: "1px solid rgba(255,255,255,0.1)"}}>
                  <div style={{fontSize: "20px", marginRight: "12px", color: "var(--rose)"}}>📄</div>
                  <div style={{flex: 1, fontSize: "12px", fontWeight: 700, overflow:"hidden", textOverflow:"ellipsis"}}>{file.split(/[/\\]/).pop()}</div>
                  <button onClick={() => removeFile(idx)} style={{background: "none", border: "none", color: "var(--text-muted)", cursor: "pointer"}}>✕</button>
                </div>
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
            onClick={handleMerge}
            disabled={status === "processing"}
          >
            {status === "processing" ? "MERGING..." : "MERGE PDFs"}
          </button>
        </div>
      </div>

      <div className="right-column">
        <div className="side-card">
          <div className="side-card-title">STATUS</div>
          
          {status === "idle" && (
            <div className="status-state-idle">
              <div style={{fontSize:"32px", marginBottom:"12px", opacity:0.5}}>⏳</div>
              <div>Ready to merge</div>
              <div style={{fontSize:"12px", marginTop:"4px", color:"var(--text-muted)"}}>{files.length} files selected</div>
            </div>
          )}

          {status === "processing" && (
            <div className="status-state-processing">
              <div className="spinner" style={{marginBottom: "12px"}} />
              <div style={{fontWeight: 700}}>Processing...</div>
              <div style={{fontSize: "12px", marginTop: "4px", color: "var(--text-muted)"}}>Merging PDF collection</div>
            </div>
          )}

          {status === "success" && (
            <div className="status-state-success">
              <div style={{fontSize:"32px", marginBottom:"12px"}}>✅</div>
              <div style={{fontWeight: 700, color: "#10b981"}}>Merge Complete!</div>
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
            Combine multiple PDF files into one. Preserves bookmarks.
          </div>
          <div style={{marginTop: "8px", display:"flex", gap:"8px"}}>
            <span className="engine-badge">Powered by Formatica PDF Engine</span>
          </div>
        </div>
      </div>
    </div>
  );
}
