import React, { useState, useEffect } from "react";
import { ScreenId } from "./Sidebar";
import { open } from "@tauri-apps/plugin-dialog";
import { invoke } from "@tauri-apps/api/core";
import { homeDir, join } from "@tauri-apps/api/path";

export function CompressVideoScreen({ setScreen }: { setScreen: (s: ScreenId) => void }) {
  const [crf, setCrf] = useState("28");
  const [resolution, setResolution] = useState("none");
  const [inputPath, setInputPath] = useState<string | null>(null);
  const [savePath, setSavePath] = useState<string>("");
  const [status, setStatus] = useState<"idle" | "processing" | "success" | "error">("idle");
  const [errorMessage, setErrorMessage] = useState("");
  const [outputPath, setOutputPath] = useState("");

  useEffect(() => {
    async function init() {
      const home = await homeDir();
      const defaultPath = await join(home, "Movies", "Formatica");
      setSavePath(defaultPath);
    }
    init();
  }, []);

  const handleBrowseInput = async () => {
    const selected = await open({
      multiple: false,
      filters: [{ name: 'Videos', extensions: ['mp4', 'mkv', 'mov', 'avi', 'flv', 'webm'] }]
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
      setErrorMessage("Please select a video file first.");
      return;
    }

    setStatus("processing");
    try {
      const fileName = inputPath.split(/[/\\]/).pop() || "compressed_video";
      const nameWithoutExt = fileName.substring(0, fileName.lastIndexOf('.')) || fileName;
      
      const result: any = await invoke("compress_video", {
        inputPath,
        outputFormat: "mp4",
        outputDir: savePath,
        resolution,
        crf,
        preset: "medium",
        outputName: `${nameWithoutExt}_compressed`
      });

      if (result.success) {
        setStatus("success");
        setOutputPath(result.output_path);
      } else {
        setStatus("error");
        setErrorMessage(result.error_message || "Compression failed. Ensure FFmpeg is installed.");
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
    <div className="tool-view-wrapper" style={{"--tint-col": "var(--orange)", "--tint-rgb": "249,115,22"} as any}>
      <div className="center-column">
        <div className="tool-header">
          <div className="th-left">
            <button className="back-btn" onClick={() => setScreen("home")}>←</button>
            <div className="th-icon-c">🗜️</div>
            <div>
              <div className="th-title">Compress Video</div>
              <div className="th-sub"><span style={{fontSize:"14px"}}>🛡️</span> Locally processed — no cloud upload</div>
            </div>
          </div>
          <div className="on-device-badge">ON-DEVICE</div>
        </div>

        <div className="input-panel glass-panel" style={{borderRadius: "24px"}}>
          
          <div className="drop-zone" onClick={handleBrowseInput}>
            <div className="dz-icon">🗜️</div>
            <div className="dz-text">Drop large Video File here or <span style={{color: "var(--orange)", cursor:"pointer"}}>Browse</span></div>
            {inputPath && <div style={{fontSize: "12px", color: "white", marginTop:"8px", background:"rgba(255,255,255,0.1)", padding:"4px 8px", borderRadius:"6px", overflow:"hidden", textOverflow:"ellipsis", maxWidth:"100%"}}>{inputPath}</div>}
          </div>

          <div>
            <div className="form-section-label">COMPRESSION QUALITY (CRF) · {crf}</div>
            <div style={{marginTop: "8px"}}>
              <input 
                type="range" 
                min="0" max="51" step="1" 
                value={crf} 
                onChange={(e) => setCrf(e.target.value)} 
              />
              <div style={{display: "flex", justifyContent: "space-between", marginTop: "4px", fontSize: "10px", color: "var(--text-muted)", fontWeight: 700}}>
                <span>← Lossless (Gigantic)</span>
                <span>Visually Transparent</span>
                <span>Default (Medium)</span>
                <span>Small Size</span>
                <span>Worst (Tiny) →</span>
              </div>
            </div>
          </div>

          <div>
            <div className="form-section-label">RESCALE RESOLUTION</div>
            <select 
              className="sinput" 
              style={{width: "100%", background: "rgba(255,255,255,0.02)", color: "white"}}
              value={resolution}
              onChange={(e) => setResolution(e.target.value)}
            >
              <option value="none">Keep Original</option>
              <option value="1080">1080p Full HD</option>
              <option value="720">720p HD</option>
              <option value="480">480p SD</option>
            </select>
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
            {status === "processing" ? "COMPRESSING..." : "COMPRESS VIDEO"}
          </button>
        </div>
      </div>

      <div className="right-column">
        <div className="side-card">
          <div className="side-card-title">STATUS</div>
          
          {status === "idle" && (
            <div className="status-state-idle">
              <div style={{fontSize:"32px", marginBottom:"12px", opacity:0.5}}>⏳</div>
              <div>Ready to compress</div>
              <div style={{fontSize:"12px", marginTop:"4px", color:"var(--text-muted)"}}>Waiting for file...</div>
            </div>
          )}

          {status === "processing" && (
            <div className="status-state-processing">
              <div className="spinner" style={{marginBottom: "12px"}} />
              <div style={{fontWeight: 700}}>Processing...</div>
              <div style={{fontSize: "12px", marginTop: "4px", color: "var(--text-muted)"}}>Compressing video file</div>
            </div>
          )}

          {status === "success" && (
            <div className="status-state-success">
              <div style={{fontSize:"32px", marginBottom:"12px"}}>✅</div>
              <div style={{fontWeight: 700, color: "#f97316"}}>Compression Complete!</div>
              <button className="status-action-btn" onClick={openFile} style={{marginTop:"16px"}}>Open Video</button>
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
            Significantly reduce video file sizes using Advanced Video Coding (H.264/H.265) compression. Higher CRF means smaller file size but visually worse quality. 28 is recommended for typical viewing.
          </div>
          <div style={{marginTop: "8px", display:"flex", gap:"8px"}}>
            <span className="engine-badge">Powered by Formatica Engine</span>
          </div>
        </div>
      </div>
    </div>
  );
}
