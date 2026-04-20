import React, { useState, useEffect } from "react";
import { ScreenId } from "./Sidebar";
import { open } from "@tauri-apps/plugin-dialog";
import { invoke } from "@tauri-apps/api/core";
import { homeDir, join } from "@tauri-apps/api/path";

export function ImageToPdfScreen({ setScreen }: { setScreen: (s: ScreenId) => void }) {
  const [imageFiles, setImageFiles] = useState<string[]>([]);
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
      filters: [{ name: 'Images', extensions: ['jpg', 'jpeg', 'png', 'webp', 'bmp', 'tiff'] }]
    });
    if (Array.isArray(selected)) {
      setImageFiles(selected);
    } else if (selected && typeof selected === 'string') {
      setImageFiles([selected]);
    }
  };

  const handleBrowseSavePath = async () => {
    const selected = await open({ directory: true });
    if (selected && typeof selected === 'string') {
      setSavePath(selected);
    }
  };

  const handleConvert = async () => {
    if (imageFiles.length === 0) {
      setStatus("error");
      setErrorMessage("Please select at least one image.");
      return;
    }

    setStatus("processing");
    try {
      const finalName = `combined_${Date.now()}.pdf`;
      const fullOutputPath = await join(savePath, finalName);

      const result: any = await invoke("images_to_pdf", {
        imagePaths: imageFiles,
        outputPath: fullOutputPath,
        layout: "portrait"
      });

      if (result.success) {
        setStatus("success");
        setOutputPath(result.output_path || fullOutputPath);
      } else {
        setStatus("error");
        setErrorMessage(result.error_message || "Conversion failed.");
      }
    } catch (e) {
      setStatus("error");
      setErrorMessage(String(e));
    }
  };

  const handleFixDependencies = async () => {
    setStatus("processing");
    try {
      const result: any = await invoke("check_python_deps");
      if (result.success) {
        setStatus("idle");
        setErrorMessage("");
      } else {
        setStatus("error");
        setErrorMessage(result.error_message || "Failed to install dependencies.");
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
            <div className="th-icon-c">🖼️</div>
            <div>
              <div className="th-title">Images to PDF</div>
              <div className="th-sub"><span style={{fontSize:"14px"}}>🛡️</span> Locally processed — no cloud upload</div>
            </div>
          </div>
          <div className="on-device-badge">ON-DEVICE</div>
        </div>

        <div className="input-panel glass-panel" style={{borderRadius: "24px"}}>
          
          <div className="drop-zone" onClick={handleBrowseInput}>
            <div className="dz-icon">🖼️</div>
            <div className="dz-text">Drop images here or <span style={{color: "var(--teal)", cursor:"pointer"}}>Browse</span></div>
            <div className="dz-sub">
              {["JPG", "PNG", "WEBP", "BMP", "TIFF"].map(f => (
                <span key={f} style={{background:"rgba(255,255,255,0.06)", padding:"2px 8px", borderRadius:"6px", margin:"0 4px", fontSize:"10px", fontWeight:700}}>{f}</span>
              ))}
            </div>
            {imageFiles.length > 0 ? (
              <div style={{marginTop:"8px", fontSize:"12px", color:"var(--teal)"}}>{imageFiles.length} images selected</div>
            ) : (
              <div className="dz-sub" style={{marginTop:"8px"}}>Select up to 50 files</div>
            )}
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
            {status === "processing" ? "COMBINING..." : "COMBINE TO PDF"}
          </button>
        </div>
      </div>

      <div className="right-column">
        <div className="side-card">
          <div className="side-card-title">STATUS</div>
          
          {status === "idle" && (
            <div className="status-state-idle">
              <div style={{fontSize:"32px", marginBottom:"12px", opacity:0.5}}>⏳</div>
              <div>Ready to combine</div>
              <div style={{fontSize:"12px", marginTop:"4px", color:"var(--text-muted)"}}>{imageFiles.length} images selected</div>
            </div>
          )}

          {status === "processing" && (
            <div className="status-state-processing">
              <div className="spinner" style={{marginBottom: "12px"}} />
              <div style={{fontWeight: 700}}>Processing...</div>
              <div style={{fontSize: "12px", marginTop: "4px", color: "var(--text-muted)"}}>Merging image sequence</div>
            </div>
          )}

          {status === "success" && (
            <div className="status-state-success">
              <div style={{fontSize:"32px", marginBottom:"12px"}}>✅</div>
              <div style={{fontWeight: 700, color: "#10b981"}}>PDF Created!</div>
              <button className="status-action-btn" onClick={openFile} style={{marginTop:"16px"}}>Open PDF</button>
            </div>
          )}

          {status === "error" && (
            <div className="status-state-error">
              <div style={{fontSize:"32px", marginBottom:"12px"}}>❌</div>
              <div style={{fontWeight: 700, color: "#ef4444"}}>Failed</div>
              <div style={{fontSize: "12px", marginTop: "8px", color: "rgba(239,68,68,0.8)", wordBreak:"break-word"}}>{errorMessage}</div>
              
              {errorMessage.toLowerCase().includes("module") && (
                <button className="status-action-btn" onClick={handleFixDependencies} style={{marginTop:"16px", background: "var(--teal)"}}>Fix Python Libraries</button>
              )}
              
              <button className="status-action-btn" onClick={() => setStatus("idle")} style={{marginTop: (errorMessage.toLowerCase().includes("module") ? "8px" : "16px")}}>Try Again</button>
            </div>
          )}
        </div>

        <div className="side-card">
          <div className="side-card-title">ABOUT THIS TOOL</div>
          <div className="side-card-desc">
            Combine multiple image files into a single continuous PDF document for easy sharing.
          </div>
          <div style={{marginTop: "8px", display:"flex", gap:"8px"}}>
            <span className="engine-badge">Powered by Formatica PDF Engine</span>
          </div>
        </div>
      </div>
    </div>
  );
}
