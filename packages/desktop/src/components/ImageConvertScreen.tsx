import React, { useState, useEffect } from "react";
import { ScreenId } from "./Sidebar";
import { open } from "@tauri-apps/plugin-dialog";
import { invoke } from "@tauri-apps/api/core";
import { homeDir, join } from "@tauri-apps/api/path";

export function ImageConvertScreen({ setScreen }: { setScreen: (s: ScreenId) => void }) {
  const [format, setFormat] = useState("WEBP");
  const [imageFiles, setImageFiles] = useState<string[]>([]);
  const [savePath, setSavePath] = useState<string>("");
  const [status, setStatus] = useState<"idle" | "processing" | "success" | "error">("idle");
  const [errorMessage, setErrorMessage] = useState("");
  const [progress, setProgress] = useState(0);

  useEffect(() => {
    async function init() {
      const home = await homeDir();
      const defaultPath = await join(home, "Pictures", "Formatica");
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
    setProgress(0);
    
    let successCount = 0;
    try {
      for (let i = 0; i < imageFiles.length; i++) {
        const inputPath = imageFiles[i];
        const fileName = inputPath.split(/[/\\]/).pop() || `image_${i}`;
        const nameWithoutExt = fileName.substring(0, fileName.lastIndexOf('.')) || fileName;

        const result: any = await invoke("convert_image_format", {
          inputPath,
          outputFormat: format.toLowerCase(),
          outputDir: savePath,
          outputName: `${nameWithoutExt}_converted`
        });

        if (result.success) {
          successCount++;
        }
        setProgress(Math.round(((i + 1) / imageFiles.length) * 100));
      }

      if (successCount > 0) {
        setStatus("success");
        setErrorMessage(successCount < imageFiles.length ? `Converted ${successCount}/${imageFiles.length} images.` : "");
      } else {
        setStatus("error");
        setErrorMessage("None of the images could be converted.");
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
    <div className="tool-view-wrapper" style={{"--tint-col": "var(--purple)", "--tint-rgb": "168,85,247"} as any}>
      <div className="center-column">
        <div className="tool-header">
          <div className="th-left">
            <button className="back-btn" onClick={() => setScreen("home")}>←</button>
            <div className="th-icon-c">📸</div>
            <div>
              <div className="th-title">Image Converter</div>
              <div className="th-sub"><span style={{fontSize:"14px"}}>🛡️</span> Locally processed — no cloud upload</div>
            </div>
          </div>
          <div className="on-device-badge">ON-DEVICE</div>
        </div>

        <div className="input-panel glass-panel" style={{borderRadius: "24px"}}>
          
          <div className="drop-zone" onClick={handleBrowseInput}>
            <div className="dz-icon">📸</div>
            <div className="dz-text">Drop Images here or <span style={{color: "var(--purple)", cursor:"pointer"}}>Browse</span></div>
            {imageFiles.length > 0 && <div style={{marginTop:"8px", fontSize:"12px", color:"var(--purple)"}}>{imageFiles.length} images selected</div>}
          </div>

          <div>
            <div className="form-section-label">OUTPUT FORMAT</div>
            <div className="pill-row">
              {["WEBP", "PNG", "JPG", "BMP"].map(f => (
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

          {format === "WEBP" && (
            <div>
              <div className="form-section-label">QUALITY OPTIMIZATION</div>
              <label style={{display: "flex", alignItems: "center", gap: "12px", cursor: "pointer"}}>
                <div style={{width: "44px", height: "24px", background: "var(--purple)", borderRadius: "12px", position: "relative"}}>
                  <div style={{width: "20px", height: "20px", background: "white", borderRadius: "50%", position: "absolute", right: "2px", top: "2px"}} />
                </div>
                <div>
                  <div style={{fontSize: "13px", fontWeight: 700}}>Lossless Compression</div>
                </div>
              </label>
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
            onClick={handleConvert}
            disabled={status === "processing"}
          >
            {status === "processing" ? `CONVERTING (${progress}%)...` : "CONVERT IMAGES"}
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
              <div style={{fontSize:"12px", marginTop:"4px", color:"var(--text-muted)"}}>Waiting for files...</div>
            </div>
          )}

          {status === "processing" && (
            <div className="status-state-processing">
              <div className="spinner" style={{marginBottom: "12px"}} />
              <div style={{fontWeight: 700}}>Processing...</div>
              <div style={{fontSize: "12px", marginTop: "4px", color: "var(--text-muted)"}}>Converting image collection</div>
            </div>
          )}

          {status === "success" && (
            <div className="status-state-success">
              <div style={{fontSize:"32px", marginBottom:"12px"}}>✅</div>
              <div style={{fontWeight: 700, color: "#10b981"}}>Conversion Complete!</div>
              {errorMessage && <div style={{fontSize: "12px", marginTop: "4px", color: "var(--text-muted)"}}>{errorMessage}</div>}
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
            Batch convert images quickly without quality loss. Supports modern next-gen formats like WebP for high efficiency.
          </div>
          <div style={{marginTop: "8px", display:"flex", gap:"8px"}}>
            <span className="engine-badge">Powered by Formatica Engine</span>
          </div>
        </div>
      </div>
    </div>
  );
}
