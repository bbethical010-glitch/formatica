import React, { useState, useEffect } from "react";
import { ScreenId } from "./Sidebar";
import { open } from "@tauri-apps/plugin-dialog";
import { invoke } from "@tauri-apps/api/core";
import { homeDir, join } from "@tauri-apps/api/path";

export function DownloadScreen({ setScreen }: { setScreen: (s: ScreenId) => void }) {
  const [url, setUrl] = useState("");
  const [quality, setQuality] = useState("Best");
  const [savePath, setSavePath] = useState<string>("");
  const [status, setStatus] = useState<"idle" | "processing" | "success" | "error">("idle");
  const [errorMessage, setErrorMessage] = useState("");
  const [outputPath, setOutputPath] = useState("");

  useEffect(() => {
    async function init() {
      const home = await homeDir();
      const defaultPath = await join(home, "Downloads", "Formatica");
      setSavePath(defaultPath);
    }
    init();
  }, []);

  const handleBrowseSavePath = async () => {
    const selected = await open({ directory: true });
    if (selected && typeof selected === 'string') {
      setSavePath(selected);
    }
  };

  const handleDownload = async () => {
    if (!url) {
      setStatus("error");
      setErrorMessage("Please enter a URL first.");
      return;
    }

    setStatus("processing");
    try {
      const result: any = await invoke("download_media", {
        url,
        outputDir: savePath,
        outputName: `download_${Date.now()}`,
        format: quality === "Audio Only" ? "audio" : quality.toLowerCase(),
        cookiesPath: null
      });

      if (result.success) {
        setStatus("success");
        setOutputPath(result.output_path);
      } else {
        setStatus("error");
        setErrorMessage(result.error_message || "Download failed. Ensure Python and yt-dlp are installed.");
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
    <div className="tool-view-wrapper" style={{"--tint-col": "var(--blue)", "--tint-rgb": "59,130,246"} as any}>
      <div className="center-column">
        <div className="tool-header">
          <div className="th-left">
            <button className="back-btn" onClick={() => setScreen("home")}>←</button>
            <div className="th-icon-c">🔽</div>
            <div>
              <div className="th-title">Download Media</div>
              <div className="th-sub"><span style={{fontSize:"14px"}}>🛡️</span> Direct download — no tracking</div>
            </div>
          </div>
          <div className="on-device-badge">ON-DEVICE</div>
        </div>

        <div className="input-panel glass-panel" style={{borderRadius: "24px"}}>
          
          <div>
            <div className="form-section-label">MEDIA URL</div>
            <input 
              type="text" 
              className="sinput" 
              placeholder="https://youtube.com/watch?v=..." 
              style={{width: "100%"}} 
              value={url}
              onChange={(e) => setUrl(e.target.value)}
            />
          </div>

          <div>
            <div className="form-section-label">QUALITY PREFERENCE</div>
            <div className="pill-row">
              {["Best", "1080p", "720p", "Audio Only"].map(q => (
                <button 
                  key={q} 
                  className={`format-pill ${quality === q ? "active" : ""}`}
                  onClick={() => setQuality(q)}
                >
                  {q}
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
            onClick={handleDownload}
            disabled={status === "processing"}
          >
            {status === "processing" ? "DOWNLOADING..." : "FETCH MEDIA"}
          </button>
        </div>
      </div>

      <div className="right-column">
        <div className="side-card">
          <div className="side-card-title">STATUS</div>
          
          {status === "idle" && (
            <div className="status-state-idle">
              <div style={{fontSize:"32px", marginBottom:"12px", opacity:0.5}}>⏳</div>
              <div>Ready to download</div>
              <div style={{fontSize:"12px", marginTop:"4px", color:"var(--text-muted)"}}>Enter a URL to begin...</div>
            </div>
          )}

          {status === "processing" && (
            <div className="status-state-processing">
              <div className="spinner" style={{marginBottom: "12px"}} />
              <div style={{fontWeight: 700}}>Processing...</div>
              <div style={{fontSize: "12px", marginTop: "4px", color: "var(--text-muted)"}}>Downloading media content</div>
            </div>
          )}

          {status === "success" && (
            <div className="status-state-success">
              <div style={{fontSize:"32px", marginBottom:"12px"}}>✅</div>
              <div style={{fontWeight: 700, color: "#3b82f6"}}>Download Complete!</div>
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
            Download high quality videos or extract audio from thousands of supported websites.
          </div>
          <div style={{marginTop: "8px", display:"flex", gap:"8px"}}>
            <span className="engine-badge">Powered by yt-dlp</span>
          </div>
        </div>
      </div>
    </div>
  );
}
