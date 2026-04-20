import React, { useState, useEffect } from "react";
import { invoke } from "@tauri-apps/api/core";

export type ScreenId = "home" | "document" | "image" | "merge" | "split" | "greyscale" | "audio" | "download" | "video" | "compress" | "imgconv";

export function Sidebar({ currentScreen, setScreen }: { currentScreen: ScreenId; setScreen: (s: ScreenId) => void }) {
  const [deps, setDeps] = useState([
    { name: "LibreOffice", ok: false, version: "Checking..." },
    { name: "ffmpeg", ok: false, version: "Checking..." },
    { name: "yt-dlp", ok: false, version: "Checking..." },
    { name: "Tesseract", ok: false, version: "Checking..." },
    { name: "Python", ok: false, version: "Checking..." },
  ]);

  useEffect(() => {
    async function check() {
      try {
        const status: any[] = await invoke("check_dependencies");
        setDeps(status.map(s => ({
          name: s.name,
          ok: s.installed,
          version: s.installed ? (s.name === "Python" ? "Installed" : "Ready") : "Missing"
        })));
      } catch (e) {
        console.error("Failed to check deps", e);
      }
    }
    check();
    const interval = setInterval(check, 5000); // Check every 5s
    return () => clearInterval(interval);
  }, []);

  const allOk = deps.every(d => d.ok);

  const docTools = [
    { id: "document", icon: "📄", label: "Convert Document", color: "var(--indigo)" },
    { id: "image", icon: "🖼", label: "Images to PDF", color: "var(--teal)" },
    { id: "merge", icon: "🔗", label: "Merge PDF", color: "var(--teal)" },
    { id: "split", icon: "✂️", label: "Split PDF", color: "var(--amber)" },
    { id: "greyscale", icon: "🌓", label: "Greyscale PDF", color: "var(--slate)" },
  ];

  const mediaTools = [
    { id: "audio", icon: "🎵", label: "Extract Audio", color: "var(--rose)" },
    { id: "download", icon: "⬇️", label: "Download Media", color: "var(--blue)" },
    { id: "video", icon: "🎬", label: "Convert Video", color: "var(--purple)" },
    { id: "compress", icon: "🗜", label: "Compress Video", color: "var(--orange)" },
    { id: "imgconv", icon: "🔄", label: "Convert Image", color: "var(--purple)" },
  ];

  return (
    <div className="sidebar">
      <div className="sidebar-top">
        <div className="app-identity" onClick={() => setScreen("home")} style={{cursor: "pointer"}}>
          <div className="app-logo">F</div>
          <div>
            <div className="app-name">Formatica</div>
            <div className="app-version">v2.1.0</div>
          </div>
        </div>
      </div>

      <div className="glass-panel system-status-card">
        <div className="status-header">
          <div className={`status-dot ${!allOk ? "error" : ""}`} />
          {allOk ? "All Systems Ready" : "System Error"}
        </div>
        <div style={{ display: "flex", flexDirection: "column", gap: "8px" }}>
          {deps.map(d => (
            <div className="status-row" key={d.name}>
              <div className="status-row-left">
                <div className={`mini-dot ${!d.ok ? "error" : ""}`} />
                {d.name}
              </div>
              <div>{d.version}</div>
            </div>
          ))}
        </div>
      </div>

      <div className="nav-section">
        <div className="section-label">TOOLS</div>
        {docTools.map(t => (
          <button 
            key={t.id} 
            className={`nav-item ${currentScreen === t.id ? "active" : ""}`}
            style={{ "--nav-accent": t.color, "--accent-rgb": t.color === "var(--indigo)" ? "99,102,241" : t.color === "var(--teal)" ? "16,185,129" : t.color === "var(--amber)" ? "245,158,11" : t.color === "var(--slate)" ? "100,116,139" : t.color === "var(--rose)" ? "232,80,124" : t.color === "var(--blue)" ? "59,130,246" : t.color === "var(--orange)" ? "249,115,22" : "139,92,246" } as React.CSSProperties}
            onClick={() => setScreen(t.id as ScreenId)}
          >
            <div className="nav-icon" style={{color: t.color}}>{t.icon}</div>
            {t.label}
          </button>
        ))}

        <div className="nav-divider" />
        <div className="section-label" style={{marginTop: "12px"}}>MEDIA</div>
        
        {mediaTools.map(t => (
          <button 
            key={t.id} 
            className={`nav-item ${currentScreen === t.id ? "active" : ""}`}
            style={{ "--nav-accent": t.color, "--accent-rgb": t.color === "var(--indigo)" ? "99,102,241" : t.color === "var(--teal)" ? "16,185,129" : t.color === "var(--amber)" ? "245,158,11" : t.color === "var(--slate)" ? "100,116,139" : t.color === "var(--rose)" ? "232,80,124" : t.color === "var(--blue)" ? "59,130,246" : t.color === "var(--orange)" ? "249,115,22" : "139,92,246" } as React.CSSProperties}
            onClick={() => setScreen(t.id as ScreenId)}
          >
            <div className="nav-icon" style={{color: t.color}}>{t.icon}</div>
            {t.label}
          </button>
        ))}
      </div>

      <div className="sidebar-bottom">
        <div className="storage-ind">
          <div className="storage-bar-wrap">
            <div className="storage-bar-fill" />
          </div>
          <div className="storage-text">124 MB · /Documents/Formatica</div>
        </div>
        <button className="preferences-link">
          <span style={{fontSize: "14px", color: "var(--text-muted)"}}>⚙️</span> Preferences
        </button>
      </div>
    </div>
  );
}
