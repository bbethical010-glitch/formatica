import React, { useState, useEffect } from "react";
import { ScreenId } from "./Sidebar";
import { open } from "@tauri-apps/plugin-dialog";
import { invoke } from "@tauri-apps/api/core";
import { homeDir, join } from "@tauri-apps/api/path";

export function AudioScreen({ setScreen }: { setScreen: (s: ScreenId) => void }) {
  const [format, setFormat] = useState("MP3");
  const [bitrate, setBitrate] = useState("192");
  const [inputPath, setInputPath] = useState<string | null>(null);
  const [savePath, setSavePath] = useState<string>("");
  const [status, setStatus] = useState<"idle" | "processing" | "success" | "error">("idle");
  const [errorMessage, setErrorMessage] = useState("");
  const [outputPath, setOutputPath] = useState("");
  
  const formats = ["MP3", "AAC", "WAV"];

  useEffect(() => {
    async function init() {
      const home = await homeDir();
      const defaultPath = await join(home, "Music", "Formatica");
      setSavePath(defaultPath);
    }
    init();
  }, []);

  const handleBrowseInput = async () => {
    const selected = await open({
      multiple: false,
      filters: [{ name: 'Media', extensions: ['mp4', 'mkv', 'mov', 'avi', 'webm', 'm4a', 'mp3', 'flv', 'wav', 'aac'] }]
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
      setErrorMessage("Please select a media file first.");
      return;
    }

    setStatus("processing");
    try {
      const fileName = inputPath.split(/[/\\]/).pop() || "extracted_audio";
      const nameWithoutExt = fileName.substring(0, fileName.lastIndexOf('.')) || fileName;
      
      const result: any = await invoke("convert_audio", {
        inputPath,
        outputFormat: format.toLowerCase(),
        bitrate: `${bitrate}k`,
        outputDir: savePath,
        outputName: `${nameWithoutExt}_audio`
      });

      if (result.success) {
        setStatus("success");
        setOutputPath(result.output_path);
      } else {
        setStatus("error");
        setErrorMessage(result.error_message || "Extraction failed. Ensure FFmpeg is installed.");
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
    <div className="tool-view-wrapper" style={{"--tint-col": "var(--rose)", "--tint-rgb": "232,80,124"} as any}>
      <div className="center-column">
        <div className="tool-header">
          <div className="th-left">
            <button className="back-btn" onClick={() => setScreen("home")}>←</button>
            <div className="th-icon-c">🎵</div>
            <div>
              <div className="th-title">Extract Audio</div>
              <div className="th-sub"><span style={{fontSize:"14px"}}>🛡️</span> Locally processed — no cloud upload</div>
            </div>
          </div>
          <div className="on-device-badge">ON-DEVICE</div>
        </div>

        <div className="input-panel glass-panel" style={{borderRadius: "24px"}}>
          
          <div className="drop-zone" onClick={handleBrowseInput}>
            <div className="dz-icon">🎵</div>
            <div className="dz-text">Drop Media File here or <span style={{color: "var(--rose)", cursor:"pointer"}}>Browse</span></div>
            <div className="dz-sub">
              {["MP4", "MKV", "MOV", "AVI", "WEBM", "M4A"].map(f => (
                <span key={f} style={{background:"rgba(255,255,255,0.06)", padding:"2px 8px", borderRadius:"6px", margin:"0 4px", fontSize:"10px", fontWeight:700}}>{f}</span>
              ))}
            </div>
            {inputPath && <div style={{fontSize: "12px", color: "white", marginTop:"8px", background:"rgba(255,255,255,0.1)", padding:"4px 8px", borderRadius:"6px", overflow:"hidden", textOverflow:"ellipsis", maxWidth:"100%"}}>{inputPath}</div>}
          </div>

          <div>
            <div className="form-section-label">OUTPUT FORMAT</div>
            <div className="pill-row">
              {formats.map(f => (
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

          {format !== "WAV" && (
            <div>
              <div className="form-section-label">BITRATE · {bitrate} kbps</div>
              <div style={{marginTop: "8px"}}>
                <input 
                  type="range" 
                  min="64" max="320" step="32" 
                  value={bitrate} 
                  onChange={(e) => setBitrate(e.target.value)} 
                />
                <div style={{display: "flex", justifyContent: "space-between", marginTop: "4px", fontSize: "10px", color: "var(--text-muted)", fontWeight: 700}}>
                  <span>← Smaller File</span>
                  <span>128k</span>
                  <span>192k</span>
                  <span>256k</span>
                  <span>320k Best Quality →</span>
                </div>
              </div>
            </div>
          )}

          <div>
            <div className="form-section-label">STRIP VIDEO METADATA</div>
            <label style={{display: "flex", alignItems: "center", gap: "12px", cursor: "pointer"}}>
              <div style={{width: "44px", height: "24px", background: "var(--rose)", borderRadius: "12px", position: "relative"}}>
                <div style={{width: "20px", height: "20px", background: "white", borderRadius: "50%", position: "absolute", right: "2px", top: "2px"}} />
              </div>
              <div>
                <div style={{fontSize: "13px", fontWeight: 700}}>Remove original metadata tags</div>
              </div>
            </label>
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
            {status === "processing" ? "EXTRACTING..." : "EXTRACT AUDIO"}
          </button>
        </div>
      </div>

      <div className="right-column">
        <div className="side-card">
          <div className="side-card-title">STATUS</div>
          
          {status === "idle" && (
            <div className="status-state-idle">
              <div style={{fontSize:"32px", marginBottom:"12px", opacity:0.5}}>⏳</div>
              <div>Ready to extract</div>
              <div style={{fontSize:"12px", marginTop:"4px", color:"var(--text-muted)"}}>Waiting for file...</div>
            </div>
          )}

          {status === "processing" && (
            <div className="status-state-processing">
              <div className="spinner" style={{marginBottom: "12px"}} />
              <div style={{fontWeight: 700}}>Processing...</div>
              <div style={{fontSize: "12px", marginTop: "4px", color: "var(--text-muted)"}}>Extracting audio track</div>
            </div>
          )}

          {status === "success" && (
            <div className="status-state-success">
              <div style={{fontSize:"32px", marginBottom:"12px"}}>✅</div>
              <div style={{fontWeight: 700, color: "#e8507c"}}>Extraction Complete!</div>
              <button className="status-action-btn" onClick={openFile} style={{marginTop:"16px"}}>Open Audio</button>
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
            Extract high-quality audio tracks directly from video files without re-encoding video.
          </div>
          <div style={{marginTop: "8px", display:"flex", gap:"8px"}}>
            <span className="engine-badge">Powered by FFmpeg</span>
          </div>
        </div>
      </div>
    </div>
  );
}
