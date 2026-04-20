import React, { useState, useEffect } from "react";
import { ScreenId } from "./Sidebar";
import { open } from "@tauri-apps/plugin-dialog";
import { invoke } from "@tauri-apps/api/core";
import { homeDir, join } from "@tauri-apps/api/path";

export function VideoScreen({ setScreen }: { setScreen: (s: ScreenId) => void }) {
  const [format, setFormat] = useState("MP4");
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
      filters: [{ name: 'Videos', extensions: ['mp4', 'mkv', 'mov', 'webm', 'gif', 'avi', 'flv'] }]
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
      const fileName = inputPath.split(/[/\\]/).pop() || "converted_video";
      const nameWithoutExt = fileName.substring(0, fileName.lastIndexOf('.')) || fileName;
      
      const result: any = await invoke("convert_video", {
        inputPath,
        outputFormat: format.toLowerCase(),
        outputDir: savePath,
        quality: "medium",
        preset: "medium",
        outputName: `${nameWithoutExt}_converted`
      });

      if (result.success) {
        setStatus("success");
        setOutputPath(result.output_path);
      } else {
        setStatus("error");
        setErrorMessage(result.error_message || "Unknown error occurred.");
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

  const openFolder = async () => {
    await invoke("open_in_folder", { path: savePath });
  };

  return (
    <div className="tool-view-wrapper" style={{"--tint-col": "var(--purple)", "--tint-rgb": "168,85,247"} as any}>
      <div className="center-column">
        <div className="tool-header">
          <div className="th-left">
            <button className="back-btn" onClick={() => setScreen("home")}>←</button>
            <div className="th-icon-c">🎞️</div>
            <div>
              <div className="th-title">Video Converter</div>
              <div className="th-sub"><span style={{fontSize:"14px"}}>🛡️</span> Locally processed — no cloud upload</div>
            </div>
          </div>
          <div className="on-device-badge">ON-DEVICE</div>
        </div>

        <div className="input-panel glass-panel" style={{borderRadius: "24px"}}>
          
          <div className="drop-zone" onClick={handleBrowseInput}>
            <div className="dz-icon">🎞️</div>
            <div className="dz-text">Drop Video File here or <span style={{color: "var(--purple)", cursor:"pointer"}}>Browse</span></div>
            {inputPath && <div style={{fontSize: "12px", color: "white", marginTop:"8px", background:"rgba(255,255,255,0.1)", padding:"4px 8px", borderRadius:"6px", overflow:"hidden", textOverflow:"ellipsis", maxWidth:"100%"}}>{inputPath}</div>}
          </div>

          <div>
            <div className="form-section-label">OUTPUT FORMAT</div>
            <div className="pill-row">
              {["MP4", "MKV", "MOV", "WEBM", "GIF"].map(f => (
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
            <div className="form-section-label">HARDWARE ACCELERATION</div>
            <label style={{display: "flex", alignItems: "center", gap: "12px", cursor: "pointer"}}>
              <div style={{width: "44px", height: "24px", background: "var(--purple)", borderRadius: "12px", position: "relative"}}>
                <div style={{width: "20px", height: "20px", background: "white", borderRadius: "50%", position: "absolute", right: "2px", top: "2px"}} />
              </div>
              <div>
                <div style={{fontSize: "13px", fontWeight: 700}}>Use Apple VideoToolbox (Fast)</div>
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
            {status === "processing" ? "CONVERTING..." : "CONVERT VIDEO"}
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
              <div style={{fontSize: "12px", marginTop: "4px", color: "var(--text-muted)"}}>Converting video format</div>
            </div>
          )}

          {status === "success" && (
            <div className="status-state-success">
              <div style={{fontSize:"32px", marginBottom:"12px"}}>✅</div>
              <div style={{fontWeight: 700, color: "#10b981"}}>Conversion Complete!</div>
              <button className="status-action-btn" onClick={openFile} style={{marginTop:"16px"}}>Open File</button>
              <button className="status-action-btn" onClick={openFolder} style={{marginTop:"8px", background:"transparent", border:"1px solid rgba(255,255,255,0.1)"}}>View in Folder</button>
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
            Convert videos between different container formats. Fast hardware-accelerated transcoding available on Mac.
          </div>
          <div style={{marginTop: "8px", display:"flex", gap:"8px"}}>
            <span className="engine-badge">Powered by FFmpeg</span>
          </div>
        </div>
      </div>
    </div>
  );
}
