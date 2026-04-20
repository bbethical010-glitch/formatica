import React, { useState, useEffect } from "react";
import "./App.css";
import { Sidebar, ScreenId } from "./components/Sidebar";
import { HomeScreen } from "./components/HomeScreen";
import { DocumentScreen } from "./components/DocumentScreen";
import { ImageToPdfScreen } from "./components/ImageToPdfScreen";
import { MergePdfScreen } from "./components/MergePdfScreen";
import { SplitPdfScreen } from "./components/SplitPdfScreen";
import { GreyscalePdfScreen } from "./components/GreyscalePdfScreen";
import { AudioScreen } from "./components/AudioScreen";
import { DownloadScreen } from "./components/DownloadScreen";
import { VideoScreen } from "./components/VideoScreen";
import { CompressVideoScreen } from "./components/CompressVideoScreen";
import { ImageConvertScreen } from "./components/ImageConvertScreen";

export default function App() {
  const [screen, setScreen] = useState<ScreenId>("home");
  const [theme, setTheme] = useState<"dark"|"light">("dark");

  useEffect(() => {
    if (theme === "light") {
      document.body.classList.add("theme-light");
    } else {
      document.body.classList.remove("theme-light");
    }
  }, [theme]);

  const renderScreen = () => {
    switch (screen) {
      case "home": return <HomeScreen setScreen={setScreen} />;
      case "document": return <DocumentScreen setScreen={setScreen} />;
      case "image": return <ImageToPdfScreen setScreen={setScreen} />;
      case "merge": return <MergePdfScreen setScreen={setScreen} />;
      case "split": return <SplitPdfScreen setScreen={setScreen} />;
      case "greyscale": return <GreyscalePdfScreen setScreen={setScreen} />;
      case "audio": return <AudioScreen setScreen={setScreen} />;
      case "download": return <DownloadScreen setScreen={setScreen} />;
      case "video": return <VideoScreen setScreen={setScreen} />;
      case "compress": return <CompressVideoScreen setScreen={setScreen} />;
      case "imgconv": return <ImageConvertScreen setScreen={setScreen} />;
      default:
        return (
          <div className="main-column" style={{alignItems:"center", justifyContent:"center", color:"var(--text-muted)"}}>
            <div style={{fontSize:"48px", marginBottom:"16px", opacity:0.5}}>🚧</div>
            <div>{screen} screen UI is under construction.</div>
            <button className="cta-btn" style={{width:"200px", marginTop:"24px"}} onClick={() => setScreen("home")}>Go Back</button>
          </div>
        );
    }
  };

  return (
    <div className={`app ${theme === "light" ? "theme-light" : ""}`}>
      <div className="mesh-atmosphere" />
      
      <div className="app-container">
        {/* Title Bar (macOS standard window drag region) */}
        <div className="title-bar">
          <div className="title-bar-left">
            {/* Native OS traffic lights sit here automatically on Mac depending on Tauri config.
                We leave this area empty. */}
          </div>
          <div className="title-bar-center" />
          <div className="title-bar-right">
            <button 
              className="window-control-icon" 
              onClick={() => setTheme(theme === "dark" ? "light" : "dark")}
              title="Toggle Light/Dark Mode"
            >
              {theme === "dark" ? "☀️" : "🌙"}
            </button>
            <button className="window-control-icon" title="Settings">⚙️</button>
          </div>
        </div>

        {/* 1. LEFT SIDEBAR */}
        <Sidebar currentScreen={screen} setScreen={setScreen} />

        {/* 2 & 3. MAIN CONTENT AND DETAIL PANEL */}
        {renderScreen()}
      </div>
    </div>
  );
}
