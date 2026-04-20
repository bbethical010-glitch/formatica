import React, { useState, useEffect } from "react";
import { ScreenId } from "./Sidebar";

export function HomeScreen({ setScreen }: { setScreen: (s: ScreenId) => void }) {
  const [time, setTime] = useState("");
  const [dateStr, setDateStr] = useState("");

  useEffect(() => {
    const updateTime = () => {
      const now = new Date();
      setTime(now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }));
      setDateStr(now.toLocaleDateString([], { weekday: 'long', month: 'long', day: 'numeric' }));
    };
    updateTime();
    const timer = setInterval(updateTime, 10000);
    return () => clearInterval(timer);
  }, []);

  const tools = [
    { id: "document", color: "var(--indigo)", icon: "📄", name: "Convert Document", desc: "DOCX, PDF, XLSX, ODT, PPTX", chips: ["DOCX", "PDF", "XLSX"] },
    { id: "image", color: "var(--teal)", icon: "🖼", name: "Images to PDF", desc: "JPG, PNG, WEBP, up to 50 files", chips: ["JPG", "PNG", "WEBP"] },
    { id: "audio", color: "var(--rose)", icon: "🎵", name: "Extract Audio", desc: "MP3, AAC, WAV from MP4/MKV/MOV", chips: ["MP3", "AAC", "WAV"] },
    { id: "download", color: "var(--blue)", icon: "⬇️", name: "Download Media", desc: "YouTube, Vimeo, save locally", chips: ["MP4", "MP3", "MKV"] },
    { id: "video", color: "var(--purple)", icon: "🎬", name: "Convert Video", desc: "MP4, MKV, MOV, AVI, WEBM, GIF", chips: ["MP4", "MKV", "MOV"] },
    { id: "compress", color: "var(--orange)", icon: "🗜", name: "Compress Video", desc: "CRF-based, reduce without quality loss", chips: ["CRF", "H264", "HEVC"] },
    { id: "imgconv", color: "var(--purple)", icon: "🔄", name: "Convert Image", desc: "JPG, PNG, WEBP, GIF, BMP", chips: ["JPG", "PNG", "WEBP"] },
    { id: "merge", color: "var(--teal)", icon: "🔗", name: "Merge PDF", desc: "Combine multiple PDFs into one", chips: ["PDF"] },
    { id: "split", color: "var(--amber)", icon: "✂️", name: "Split PDF", desc: "Extract pages or split by range", chips: ["PDF"] },
    { id: "greyscale", color: "var(--slate)", icon: "🌓", name: "Greyscale PDF", desc: "Eco-friendly print preparation", chips: ["PDF"] },
  ];

  return (
    <div className="main-column">
      <div className="main-view-inner">
        <div className="hero-header">
          <div>
            <div className="hero-greeting">Good morning,</div>
            <div className="hero-title">What are you converting today?</div>
            <div className="hero-sub">All processing happens locally on this Mac. Zero cloud.</div>
          </div>
          <div className="hero-clock">
            <div className="clock-time">{time}</div>
            <div className="clock-date">{dateStr}</div>
          </div>
        </div>

        <div className="search-bar-wrap">
          <input type="text" className="search-pill" placeholder="Search tools or drop a file anywhere..." />
          <span className="search-icon">🔍</span>
          <span className="search-shortcut">⌘K</span>
          <div className="search-tip">Tip: You can drag any file directly onto a tool card.</div>
        </div>

        <div className="tool-grid-dash">
          {tools.map((t, idx) => (
            <div 
              key={t.id} 
              className="tool-card-d" 
              onClick={() => setScreen(t.id as ScreenId)}
              style={{"--hover-col": t.color, "--hover-glow": t.color === "var(--indigo)" ? "rgba(99,102,241,0.2)" : t.color === "var(--purple)" ? "rgba(139,92,246,0.2)" : "rgba(255,255,255,0.05)"} as any}
            >
              <div className="tc-icon">{t.icon}</div>
              <div className="tc-name">{t.name}</div>
              <div className="tc-desc">{t.desc}</div>
              <div className="tc-chips">
                {t.chips.map(c => <span key={c} className="tc-chip">{c}</span>)}
              </div>
            </div>
          ))}
        </div>

        <div className="recent-header">
          <div className="r-title">RECENT ACTIVITY</div>
          <a href="#" className="r-link">View All</a>
        </div>
        <div className="recent-rail">
          <div className="recent-ghost">
            <div style={{fontSize: "24px", marginBottom: "8px", opacity: 0.5}}>📄</div>
            No recent activity yet. Process your first file to see it here.
          </div>
        </div>
      </div>
    </div>
  );
}
