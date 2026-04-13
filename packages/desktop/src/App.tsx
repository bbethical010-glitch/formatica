import { useState, useEffect } from "react";
import { invoke, convertFileSrc } from "@tauri-apps/api/core";
import { listen } from "@tauri-apps/api/event";
import { open } from "@tauri-apps/plugin-dialog";
import "./App.css";
import { Layout } from "./components/Layout";

type Theme = "dark" | "light";
type Screen = 
  | "home" | "document" | "image" | "download" | "audio" | "video" | "imageconvert" 
  | "compress" | "mergepdf" | "splitpdf" | "greyscalepdf" | "onboarding"
  | "ocr" | "watermark" | "batchfolder" | "queue" | "shortcuts" | "settings" | "monitor"
  | "media_download";

const STAGES = ["Input", "Configuration", "Processing"];

interface TaskResult {
  success: boolean;
  outputPath: string;
  errorMessage: string;
}

interface DepStatus {
  name: string;
  command: string;
  installed: boolean;
}

interface Activity {
  name: string;
  meta: string;
  time: string;
}

interface ProcessTask {
  id: string;
  name: string;
  tool: string;
  status: "queued" | "processing" | "completed" | "failed";
  progress: number;
  timeRemaining?: string;
  startTime: number;
  inputPath: string;
  outputPath?: string;
  error?: string;
}

interface ToolScreenProps {
  onBack: () => void;
  addTask: (task: Omit<ProcessTask, "id" | "startTime" | "progress" | "status">) => string;
  updateTask: (id: string, patch: Partial<ProcessTask>) => void;
  tasks: ProcessTask[];
  state: any;
  updateState: (patch: any) => void;
  deps: DepStatus[];
  onFixDeps: () => void;
}

// ── Persist output paths per feature ─────────────────────────────
function useSavedPath(key: string) {
  const storageKey = `mds_output_${key}`;
  const [path, setPath] = useState<string>(() => localStorage.getItem(storageKey) || "");
  const savePath = (p: string) => { setPath(p); localStorage.setItem(storageKey, p); };
  return [path, savePath] as const;
}

// ── Activity log ──────────────────────────────────────────────────
const activityKey = "mds_activity";
function loadActivity(): Activity[] {
  try { return JSON.parse(localStorage.getItem(activityKey) || "[]"); } catch { return []; }
}
function addActivity(item: Activity) {
  const list = [item, ...loadActivity()].slice(0, 10);
  localStorage.setItem(activityKey, JSON.stringify(list));
  // Dispatch custom event to notify HistoryPanel
  window.dispatchEvent(new Event('mds_activity_updated'));
}

// ── App ───────────────────────────────────────────────────────────
export default function App() {
  const [theme, setTheme] = useState<Theme>(() => (localStorage.getItem("mds_theme") as Theme) || "dark");
  const [screen, setScreen] = useState<Screen>("home");
  const [deps, setDeps] = useState<DepStatus[]>([]);
  const [showOnboarding, setShowOnboarding] = useState(false);
  const [showSetup, setShowSetup] = useState(false);
  const [toast, setToast] = useState<{ key: string; action: string } | null>(null);
  const [tasks, setTasks] = useState<ProcessTask[]>([]);
  const [screenStates, setScreenStates] = useState<Record<string, any>>({});

  const getScreenState = (id: string, defaults: any) => screenStates[id] || defaults;
  const updateScreenState = (id: string, patch: any) => {
    setScreenStates((prev: Record<string, any>) => ({
      ...prev,
      [id]: { ...(prev[id] || {}), ...patch }
    }));
  };

  const addTask = (task: Omit<ProcessTask, "id" | "startTime" | "progress" | "status">) => {
    const newTask: ProcessTask = {
      ...task,
      id: Math.random().toString(36).substring(7),
      startTime: Date.now(),
      progress: 0,
      status: "processing"
    };
    setTasks((prev: ProcessTask[]) => [newTask, ...prev]);
    return newTask.id;
  };

  const updateTask = (id: string, patch: Partial<ProcessTask>) => {
    setTasks((prev: ProcessTask[]) => prev.map((t: ProcessTask) => t.id === id ? { ...t, ...patch } : t));
  };

  const removeTask = (id: string) => {
    setTasks((prev: ProcessTask[]) => prev.filter((t: ProcessTask) => t.id !== id));
  };

  const showKbdToast = (key: string, action: string) => {
    setToast({ key, action });
    setTimeout(() => setToast(null), 1800);
  };

  useEffect(() => {
    invoke<boolean>("is_first_run").then((first: boolean) => {
      if (first) setShowOnboarding(true);
    });
    invoke("get_setup_status").then((status: any) => {
      if (status.needs_setup && !showOnboarding) {
        setShowSetup(true);
      }
    });
  }, [showOnboarding]);

  useEffect(() => {
    invoke<DepStatus[]>("check_dependencies").then(setDeps).catch(console.error);
  }, []);

  async function completeOnboarding() {
    await invoke("mark_initialized");
    setShowOnboarding(false);
    const status: any = await invoke("get_setup_status");
    if (status.needs_setup) setShowSetup(true);
  }

  function completeSetup() {
    setShowSetup(false);
    invoke<DepStatus[]>("check_dependencies").then(setDeps);
  }

  useEffect(() => {
    localStorage.setItem("mds_theme", theme);
  }, [theme]);

  useEffect(() => {
    invoke<DepStatus[]>("check_dependencies").then(setDeps).catch(() => {});
  }, [screen]); // Refetch on screen change to stay synced

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.target instanceof HTMLInputElement || e.target instanceof HTMLTextAreaElement) return;
      const key = (e.ctrlKey || e.metaKey ? "ctrl+" : "") + e.key.toLowerCase();
      
      const map: Record<string, { action: string; screen: Screen }> = {
        "ctrl+1": { action: "Convert document", screen: "document" },
        "ctrl+2": { action: "Images to PDF", screen: "image" },
        "ctrl+3": { action: "Merge PDF", screen: "mergepdf" },
        "ctrl+4": { action: "Split PDF", screen: "splitpdf" },
        "ctrl+5": { action: "OCR PDF", screen: "ocr" },
        "ctrl+6": { action: "Compress video", screen: "compress" },
        "ctrl+7": { action: "Convert image", screen: "imageconvert" },
        "ctrl+8": { action: "Watermark", screen: "watermark" },
        "ctrl+q": { action: "Queue", screen: "queue" },
        "ctrl+,": { action: "Settings", screen: "settings" },
        "ctrl+m": { action: "Resource monitor", screen: "monitor" },
        "ctrl+/": { action: "Shortcuts", screen: "shortcuts" },
      };

      if (map[key]) {
        e.preventDefault();
        showKbdToast(map[key].action, key.toUpperCase().replace("CTRL+", "Ctrl + "));
        setScreen(map[key].screen);
      }

      if (key === "ctrl+d") {
        e.preventDefault();
        toggleTheme();
        showKbdToast("Toggle Theme", "Ctrl + D");
      }
    };

    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [theme]);

  const toggleTheme = () => setTheme(t => t === "dark" ? "light" : "dark");
  const handleFixDeps = async () => {
    setShowSetup(true);
  };

  if (showOnboarding) return <OnboardingScreen onComplete={completeOnboarding} />;
  if (showSetup && !showOnboarding) return <SetupScreen onComplete={completeSetup} />;

  const handleNavigate = (screenId: string) => {
    setScreen(screenId as Screen);
  };

  return (
    <Layout
      theme={theme}
      onThemeToggle={toggleTheme}
      currentScreen={screen}
      onNavigate={handleNavigate}
      deps={deps}
      onFixDeps={handleFixDeps}
    >
      {screen === "home" && <HomeScreen setScreen={setScreen} />}
      {screen === "document" && (
        <DocumentScreen 
          onBack={() => setScreen("home")} 
          addTask={addTask} 
          updateTask={updateTask} 
          tasks={tasks}
          state={getScreenState("document", { stage: 1, file: null, outputName: "" })}
          updateState={(p: any) => updateScreenState("document", p)}
          deps={deps}
          onFixDeps={handleFixDeps}
        />
      )}
      {screen === "image" && (
        <ImageScreen 
          onBack={() => setScreen("home")} 
          addTask={addTask} 
          updateTask={updateTask} 
          tasks={tasks}
          state={getScreenState("image", { stage: 1, files: [], outputName: "combined_images" })}
          updateState={(p: any) => updateScreenState("image", p)}
          deps={deps}
          onFixDeps={handleFixDeps}
        />
      )}
      {screen === "ocr" && (
        <OCRScreen 
          onBack={() => setScreen("home")} 
          addTask={addTask} 
          updateTask={updateTask} 
          tasks={tasks}
          state={getScreenState("ocr", { stage: 1, file: null, outputName: "", activeTaskId: null })}
          updateState={(p: any) => updateScreenState("ocr", p)}
          deps={deps}
          onFixDeps={handleFixDeps}
        />
      )}
      {screen === "watermark" && (
        <WatermarkScreen 
          onBack={() => setScreen("home")} 
          addTask={addTask} 
          updateTask={updateTask} 
          tasks={tasks}
          state={getScreenState("watermark", { stage: 1, file: null, outputName: "", activeTaskId: null })}
          updateState={(p: any) => updateScreenState("watermark", p)}
          deps={deps}
          onFixDeps={handleFixDeps}
        />
      )}
      {screen === "compress" && (
        <CompressVideoScreen 
          onBack={() => setScreen("home")} 
          addTask={addTask} 
          updateTask={updateTask} 
          tasks={tasks} 
          state={getScreenState("compress", { stage: 1, files: [], activeTaskIds: [] })}
          updateState={(p: any) => updateScreenState("compress", p)}
          deps={deps}
          onFixDeps={handleFixDeps}
        />
      )}
      {screen === "mergepdf" && (
        <MergePDFScreen 
          onBack={() => setScreen("home")} 
          addTask={addTask} 
          updateTask={updateTask} 
          tasks={tasks} 
          state={getScreenState("mergepdf", { stage: 1, files: [], outputName: "merged_document" })}
          updateState={(p: any) => updateScreenState("mergepdf", p)}
          deps={deps}
          onFixDeps={handleFixDeps}
        />
      )}
      {screen === "splitpdf" && (
        <SplitPDFScreen 
          onBack={() => setScreen("home")} 
          addTask={addTask} 
          updateTask={updateTask} 
          tasks={tasks} 
          state={getScreenState("splitpdf", { stage: 1, file: null, mode: "count", value: "5" })}
          updateState={(p: any) => updateScreenState("splitpdf", p)}
          deps={deps}
          onFixDeps={handleFixDeps}
        />
      )}
      {screen === "greyscalepdf" && (
        <GreyscalePDFScreen 
          onBack={() => setScreen("home")} 
          addTask={addTask} 
          updateTask={updateTask} 
          tasks={tasks} 
          state={getScreenState("greyscalepdf", { stage: 1, file: null, outputName: "" })}
          updateState={(p: any) => updateScreenState("greyscalepdf", p)}
          deps={deps}
          onFixDeps={handleFixDeps}
        />
      )}
      {screen === "audio" && (
        <AudioScreen 
          onBack={() => setScreen("home")} 
          addTask={addTask} 
          updateTask={updateTask} 
          tasks={tasks} 
          state={getScreenState("audio", { stage: 1, file: null, outputName: "" })}
          updateState={(p: any) => updateScreenState("audio", p)}
          deps={deps}
          onFixDeps={handleFixDeps}
        />
      )}
      {screen === "video" && (
        <VideoScreen 
          onBack={() => setScreen("home")} 
          addTask={addTask} 
          updateTask={updateTask} 
          tasks={tasks} 
          state={getScreenState("video", { stage: 1, file: null, outputName: "" })}
          updateState={(p: any) => updateScreenState("video", p)}
          deps={deps}
          onFixDeps={handleFixDeps}
        />
      )}
      {screen === "imageconvert" && (
        <ImageConvertScreen 
          onBack={() => setScreen("home")} 
          addTask={addTask} 
          updateTask={updateTask} 
          tasks={tasks} 
          state={getScreenState("imageconvert", { stage: 1, file: null, outputName: "" })}
          updateState={(p: any) => updateScreenState("imageconvert", p)}
          deps={deps}
          onFixDeps={handleFixDeps}
        />
      )}
      {screen === "media_download" && (
        <DownloadScreen 
          onBack={() => setScreen("home")} 
          addTask={addTask} 
          updateTask={updateTask} 
          tasks={tasks} 
          state={getScreenState("media_download", { stage: 1, url: "", outputName: "", format: "mp4" })}
          updateState={(p: any) => updateScreenState("media_download", p)}
          deps={deps}
          onFixDeps={handleFixDeps}
        />
      )}
      {screen === "batchfolder" && (
        <BatchFolderScreen 
          onBack={() => setScreen("home")} 
          addTask={addTask} 
          updateTask={updateTask} 
          tasks={tasks} 
          state={getScreenState("batchfolder", { stage: 1, path: "", action: "pdf_to_docx" })}
          updateState={(p: any) => updateScreenState("batchfolder", p)}
          deps={deps}
          onFixDeps={handleFixDeps}
        />
      )}
      {screen === "queue" && <QueueScreen onBack={() => setScreen("home")} tasks={tasks} removeTask={removeTask} />}
      {screen === "shortcuts" && <ShortcutsScreen onBack={() => setScreen("home")} />}
      {screen === "settings" && <SettingsScreen onBack={() => setScreen("home")} />}
      {screen === "monitor" && <MonitorScreen onBack={() => setScreen("home")} />}

      {toast && (
        <div className={`kbd-toast ${toast ? "show" : ""}`}>
          <span className="kt-key">{toast.key}</span>
          <span>{toast.action}</span>
        </div>
      )}
    </Layout>
  );
}

// ── Home Screen ───────────────────────────────────────────────────
function HomeScreen({ setScreen }: { setScreen: (s: Screen) => void }) {
  const [query, setQuery] = useState("");

  const toolGroups = [
    {
      name: "Documents",
      icon: "article",
      tools: [
        { id: "document", title: "Convert Doc", desc: "DOCX, PDF, XLSX", symbol: "description" },
        { id: "image", title: "Images to PDF", desc: "Scan to Document", symbol: "picture_as_pdf" },
        { id: "ocr", title: "OCR Engine", desc: "Extract Text", symbol: "find_in_page" },
        { id: "mergepdf", title: "Merge PDF", desc: "Join multiple files", symbol: "picture_in_picture" },
        { id: "splitpdf", title: "Split PDF", desc: "Split pages", symbol: "content_cut" },
      ]
    },
    {
      name: "Multimedia",
      icon: "movie",
      tools: [
        { id: "media_download", title: "Downloader", desc: "Save from URL", symbol: "download" },
        { id: "compress", title: "Compress", desc: "Reduce file size", symbol: "compress" },
        { id: "video", title: "Video Conv", desc: "MP4, MKV, AVI", symbol: "sync" },
        { id: "audio", title: "Extract Audio", desc: "MP3, AAC, WAV", symbol: "audiotrack" },
      ]
    },
    {
      name: "Image & Batch",
      icon: "apps",
      tools: [
        { id: "imageconvert", title: "Image Conv", desc: "JPG, PNG, WEBP", symbol: "image" },
        { id: "watermark", title: "Watermark", desc: "Protect media", symbol: "opacity" },
        { id: "batchfolder", title: "Batch Pro", desc: "Entire folders", symbol: "folder_zip" },
      ]
    }
  ];

  const filteredGroups = toolGroups.map(g => ({
    ...g,
    tools: g.tools.filter(t => t.title.toLowerCase().includes(query.toLowerCase()) || t.desc.toLowerCase().includes(query.toLowerCase()))
  })).filter(g => g.tools.length > 0);

  return (
    <div className="screen">
      <div className="pt">Studio <span className="bl">Tools</span></div>
      <div className="ps">High-performance local media processing</div>

      <div className="search-container">
        <div style={{ position: 'relative' }}>
          <span className="material-symbols-outlined" style={{ position: 'absolute', left: '20px', top: '50%', transform: 'translateY(-50%)', opacity: 0.5 }}>search</span>
          <input 
            className="search-bar" 
            placeholder="Search for a tool or format (e.g. PDF, MP4)..." 
            value={query}
            onChange={e => setQuery(e.target.value)}
          />
        </div>
      </div>

      {filteredGroups.map(group => (
        <div key={group.name} style={{ marginBottom: '40px' }}>
          <div className="section-header">
            <div className="section-title">{group.name}</div>
            <div className="count-badge">{group.tools.length} Tools</div>
          </div>
          <div className="tool-grid">
            {group.tools.map(tool => (
              <div key={tool.id} className="tool-card glass-card" onClick={() => setScreen(tool.id as Screen)}>
                <span className="material-symbols-outlined" style={{ color: 'var(--accent)' }}>{tool.symbol}</span>
                <div>
                  <div className="tool-label">{tool.title}</div>
                  <div style={{ fontSize: '10px', color: 'var(--on-surface-variant)', marginTop: '4px' }}>{tool.desc}</div>
                </div>
              </div>
            ))}
          </div>
        </div>
      ))}
    </div>
  );
}

// ── Watermark Screen ──────────────────────────────────────────────
function WatermarkScreen({ onBack, addTask, updateTask, tasks, state, updateState, deps, onFixDeps }: ToolScreenProps) {
  const { stage, file, outputName, text = "CONFIDENTIAL", opacity = 30, pos = "C", activeTaskId, logoPath = null, logoScale = 0.2 } = state;
  const [outputDir, saveOutputDir] = useSavedPath("watermark");
  const [isDragOver, setIsDragOver] = useState(false);

  const setStage = (s: number) => updateState({ stage: s });
  const setFile = (f: any) => updateState({ file: f });
  const setOutputName = (n: string) => updateState({ outputName: n });
  const setText = (t: string) => updateState({ text: t });
  const setOpacity = (o: number) => updateState({ opacity: o });
  const setPos = (p: string) => updateState({ pos: p });
  const setActiveTaskId = (id: string | null) => updateState({ activeTaskId: id });

  const activeTask = tasks.find((t: ProcessTask) => t.id === activeTaskId);
  const isEngineReady = deps.find((d: DepStatus) => d.name === "imagemagick")?.installed ?? true;

  useEffect(() => {
    if (file && !outputName) {
      setOutputName(file.name.split('.').slice(0, -1).join('.') + "_watermark");
    }
  }, [file]);

  const pickFile = async () => {
    const selected = await open({ multiple: false });
    if (selected && !Array.isArray(selected)) {
      setFile({ name: selected.split(/[\\/]/).pop(), path: selected });
      setStage(2);
    }
  };

  const pickDir = async () => {
    const s = await open({ directory: true, multiple: false });
    if (s && !Array.isArray(s)) saveOutputDir(s);
  };

  const handleStartWatermark = async () => {
    if (!file || !outputDir) return;
    setStage(3);
    
    const tid = addTask({
      name: `${outputName}.${file.name.split('.').pop()}`,
      tool: "Watermark Engine",
      inputPath: file.path,
    });
    setActiveTaskId(tid);

    try {
      const res: any = await invoke("apply_watermark", {
        inputPath: file.path,
        outputPath: `${outputDir}\\${outputName}.${file.name.split('.').pop()}`,
        text: text,
        opacity: opacity / 100,
        position: pos
      });
      
      if (res.success) {
        updateTask(tid, { status: "completed", progress: 100, outputPath: res.outputPath });
        addActivity({ 
          name: outputName + "." + file.name.split('.').pop(), 
          meta: "Watermark Protection", 
          time: "Just now" 
        });
      } else {
        updateTask(tid, { status: "failed", error: res.errorMessage });
      }
    } catch(e) {
      updateTask(tid, { status: "failed", error: String(e) });
    }
  };

  return (
    <div className="screen active">
      <div className="tool-header">
        <div className="tool-header-info">
          <button className="back-btn" onClick={onBack}>
            <span className="material-symbols-outlined">arrow_back</span>
          </button>
          <div className="tool-title-group">
            <div className="pt">Watermark <span className="bl">Studio</span></div>
            <div className="ps">Protect your documents with professional text or logo overlays</div>
          </div>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '20px' }}>
          {!isEngineReady && (
            <div className="status-badge error animate-in">
              <span className="material-symbols-outlined" style={{ fontSize: '16px' }}>warning</span>
              <span>Backend Missing</span>
              <button className="sbtn red" onClick={onFixDeps}>Install</button>
            </div>
          )}
          <StageIndicator current={stage} stages={STAGES} />
        </div>
      </div>

      {stage === 1 && (
        <div className={`panel animate-in ${isDragOver ? "drag-over" : ""}`} style={{ padding: '80px 40px', textAlign: 'center' }}>
          <div className="plabel">Stage 1: Source Document</div>
          <div className="dz" onClick={pickFile}>
            <div className="dz-icon">
              <span className="material-symbols-outlined">branding_watermark</span>
            </div>
            <div className="dz-main">{file ? file.name : "Drop File or Browse"}</div>
            <div className="dz-sub">PDF • JPG • PNG High-Performance Overlays</div>
          </div>
          {file && (
            <button className="abtn primary" style={{ marginTop: '32px' }} onClick={() => setStage(2)}>
              <span>Configure Protection</span>
              <span className="material-symbols-outlined">arrow_forward</span>
            </button>
          )}
        </div>
      )}

      {stage === 2 && (
        <div className="panel animate-in">
          <div className="plabel">Stage 2: Watermark Setup</div>
          
          <div className="srow">
            <div className="slabel">Watermark Text</div>
            <div className="sfield">
              <span className="material-symbols-outlined sfield-icon">text_fields</span>
              <input className="sinput" value={text} onChange={e => setText(e.target.value)} placeholder="CONFIDENTIAL" />
            </div>
          </div>

          <div className="two-col" style={{ marginTop: '24px' }}>
             <div>
                <div className="slabel" style={{ marginBottom: '8px' }}>Opacity (%)</div>
                <div className="sfield">
                  <span className="material-symbols-outlined sfield-icon">opacity</span>
                  <input type="number" className="sinput" value={opacity} onChange={e => setOpacity(parseInt(e.target.value))} min="1" max="100" />
                </div>
             </div>
             <div>
                <div className="slabel" style={{ marginBottom: '8px' }}>Placement</div>
                <div className="grid-picker">
                   {['TL', 'C', 'BR'].map(p => (
                     <div key={p} className={`grid-item ${pos === p ? "active" : ""}`} onClick={() => setPos(p)}>
                       {p}
                     </div>
                   ))}
                </div>
             </div>
          </div>

          <div className="srow" style={{ marginTop: '24px' }}>
            <div className="slabel">Export Filename</div>
            <div className="sfield">
              <span className="material-symbols-outlined sfield-icon">edit_note</span>
              <input className="sinput" value={outputName} onChange={e => setOutputName(e.target.value)} />
            </div>
          </div>

          <div className="srow" style={{ marginTop: '24px' }}>
            <div className="slabel">Target Folder</div>
            <div className="sfield">
              <span className="material-symbols-outlined sfield-icon">folder_open</span>
              <input className="sinput" value={outputDir || "No folder selected"} readOnly />
              <button className="sbtn" onClick={pickDir}>Browse</button>
            </div>
          </div>

          <div style={{ display: 'flex', gap: '12px', marginTop: '32px' }}>
            <button className="abtn primary" onClick={handleStartWatermark} disabled={!outputDir || !outputName || !isEngineReady} style={{ flex: 1 }}>
              <span>Initialize Overlay</span>
              <span className="material-symbols-outlined">verified_user</span>
            </button>
            <button className="abtn secondary" onClick={() => setStage(1)}>Back</button>
          </div>
        </div>
      )}

      {stage === 3 && (
        <div className="panel animate-in">
           <div className="plabel">Stage 3: {activeTask ? "Applying Watermark" : "Ready"}</div>
           {!activeTask ? (
             <div style={{ padding: '20px', textAlign: 'center' }}>
                <div className="status-icon-large">
                   <span className="material-symbols-outlined">hourglass_empty</span>
                </div>
                <div className="pt">Initializing Engine...</div>
             </div>
           ) : (
             <div style={{ textAlign: 'center', padding: '40px 20px' }}>
                <div className={`status-icon-large ${activeTask.status}`}>
                   <span className="material-symbols-outlined">
                     {activeTask.status === "processing" ? "sync" : activeTask.status === "completed" ? "check_circle" : "error"}
                   </span>
                </div>
                <div className="pt">{activeTask.status === "processing" ? "Processing..." : activeTask.status === "completed" ? "Complete" : "Error"}</div>
                <div className="ps" style={{ marginBottom: '32px' }}>{activeTask.name}</div>

                {activeTask.status === "completed" && (
                  <div style={{ display: 'flex', gap: '12px', justifyContent: 'center' }}>
                    <button className="abtn primary" onClick={() => invoke("open_url", { url: activeTask.outputPath })}>
                      <span className="material-symbols-outlined">file_open</span>
                      <span>Review</span>
                    </button>
                    <button className="abtn secondary" onClick={() => setStage(1)}>
                      <span className="material-symbols-outlined">refresh</span>
                      <span>Protect Another</span>
                    </button>
                  </div>
                )}
                {activeTask.status === "failed" && (
                  <div className="info-card error" style={{ marginBottom: '24px' }}>
                     <span className="material-symbols-outlined">error</span>
                     <div className="ps">{activeTask.error}</div>
                  </div>
                )}
                {activeTask.status === "failed" && <button className="abtn secondary" onClick={() => setActiveTaskId(null)}>Retry</button>}
             </div>
           )}
        </div>
      )}
    </div>
  );
}

// ── Document Screen ───────────────────────────────────────────────
function DocumentScreen({ onBack, addTask, updateTask, tasks, state, updateState }: ToolScreenProps) {
  const { stage, file, outputFormat = "pdf", outputName, activeTaskId } = state;
  const [outputDir, saveOutputDir] = useSavedPath("document");
  const [isDragOver, setIsDragOver] = useState(false);

  const setStage = (s: number) => updateState({ stage: s });
  const setFile = (f: any) => updateState({ file: f });
  const setOutputFormat = (f: string) => updateState({ outputFormat: f });
  const setOutputName = (n: string) => updateState({ outputName: n });
  const setActiveTaskId = (id: string | null) => updateState({ activeTaskId: id });

  const activeTask = tasks.find((t: ProcessTask) => t.id === activeTaskId);
  const formats = ["pdf","docx","odt","txt","html","rtf","xlsx","csv"];

  useEffect(() => {
    if (file && !outputName) {
      setOutputName(file.name.split('.').slice(0, -1).join('.') + "_converted");
    }
  }, [file]);

  const pickFile = async () => {
    const selected = await open({ multiple: false, filters: [{ name: "Documents", extensions: ["docx","pdf","xlsx","csv","txt","odt","rtf","pptx"] }] });
    if (selected && !Array.isArray(selected)) {
      setFile({ name: selected.split(/[\\/]/).pop(), path: selected });
      setStage(2);
    }
  };

  const pickDir = async () => {
    const s = await open({ directory: true, multiple: false });
    if (s && !Array.isArray(s)) saveOutputDir(s);
  };

  const run = async () => {
    if (!file || !outputDir) return;
    setStage(3);
    
    const tid = addTask({
      name: outputName + "." + outputFormat,
      tool: "DOC Convert",
      inputPath: file.path,
    });
    setActiveTaskId(tid);

    try {
      const res = await invoke<TaskResult>("convert_document", { 
        inputPath: file.path, 
        outputFormat: outputFormat, 
        outputDir: outputDir,
        outputName: outputName
      });
      
      if (res.success) {
        updateTask(tid, { status: "completed", progress: 100, outputPath: res.outputPath });
        addActivity({ 
          name: file.name, 
          meta: `→ ${outputFormat.toUpperCase()}`, 
          time: "Just now" 
        });
      } else {
        updateTask(tid, { status: "failed", error: res.errorMessage });
      }
    } catch(e) {
      updateTask(tid, { status: "failed", error: String(e) });
    }
  };

  useEffect(() => {
    let unDrop: any, unEnter: any, unLeave: any;
    listen("tauri://drag-drop", (e: any) => {
      setIsDragOver(false);
      const paths = e.payload.paths;
      if (paths && paths.length > 0) {
        setFile({ name: paths[0].split(/[\\/]/).pop(), path: paths[0] });
        setStage(2);
      }
    }).then(u => unDrop = u);
    listen("tauri://drag-enter", () => setIsDragOver(true)).then(u => unEnter = u);
    listen("tauri://drag-leave", () => setIsDragOver(false)).then(u => unLeave = u);
    return () => {
      if (unDrop) unDrop();
      if (unEnter) unEnter();
      if (unLeave) unLeave();
    };
  }, []);

  return (
    <div className="screen active">
      <div className="tool-header">
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          <button className="back-btn" onClick={onBack} style={{ position: 'relative', top: 0 }}>
            <span className="material-symbols-outlined">arrow_back</span>
          </button>
          <div>
            <div className="pt">Document <span className="bl">Converter</span></div>
            <div className="ps" style={{ marginBottom: 0 }}>Professional local document transformation</div>
          </div>
        </div>
        <StageIndicator current={stage} stages={STAGES} />
      </div>
      
      {stage === 1 && (
        <div className={`panel animate-in ${isDragOver ? "drag-over" : ""}`} style={{ padding: '80px', textAlign: 'center' }}>
          <div className="plabel" style={{ marginBottom: '24px' }}>Stage 1: Select Document</div>
          <div className="dz" onClick={pickFile}>
            <span className="material-symbols-outlined" style={{ fontSize: '48px', color: 'var(--accent)', marginBottom: '16px' }}>description</span>
            <div className="dz-main">Drop file or <span className="bl">Browse</span></div>
            <div className="dz-sub">DOCX · PDF · XLSX · ODT · RTF · PPTX</div>
          </div>
        </div>
      )}

      {stage === 2 && (
        <div className="panel animate-in">
          <div className="plabel">Stage 2: Configuration</div>
          
          <div className="srow">
            <div className="slabel">Export Filename</div>
            <div className="sfield">
              <span className="material-symbols-outlined sfield-icon">title</span>
              <input className="sinput" value={outputName} onChange={e => setOutputName(e.target.value)} style={{ flex: 1 }} />
              <div className="sbtn-static">.{outputFormat}</div>
            </div>
          </div>

          <div className="fmt-gl" style={{ marginTop: '24px' }}>Target Format</div>
          <div className="fmtb" style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '8px' }}>
            {formats.map(f => (
              <div key={f} className={`fb ${outputFormat === f ? "active" : ""}`} onClick={() => setOutputFormat(f)}>
                {f.toUpperCase()}
              </div>
            ))}
          </div>

          <div className="srow" style={{ marginTop: '32px' }}>
            <div className="slabel">Save To Folder</div>
            <div className="sfield">
              <span className="material-symbols-outlined sfield-icon">folder</span>
              <input className="sinput" value={outputDir || "No folder selected"} readOnly style={{ flex: 1 }} />
              <button className="sbtn" onClick={pickDir}>Browse</button>
            </div>
          </div>

          <div className="info-card" style={{ marginTop: '32px', padding: '16px', background: 'rgba(91, 79, 232, 0.05)', borderRadius: '16px', border: '1px solid rgba(91, 79, 232, 0.1)' }}>
             <div className="ps" style={{ margin: 0, display: 'flex', alignItems: 'center', gap: '8px' }}>
               <span className="material-symbols-outlined" style={{ fontSize: '18px', color: 'var(--accent)' }}>info</span>
               Documents are processed locally using the LibreOffice engine.
             </div>
          </div>

          <div style={{ display: 'flex', gap: '12px', marginTop: '32px' }}>
            <button className="abtn primary" style={{ flex: 1 }} onClick={() => setStage(3)} disabled={!outputDir}>
              Review Conversion Plan →
            </button>
            <button className="abtn secondary" onClick={() => { setFile(null); setStage(1); }}>Change File</button>
          </div>
        </div>
      )}

      {stage === 3 && (
        <div className="panel animate-in">
           <div className="plabel">Stage 3: {activeTask ? "Processing" : "Ready"}</div>
           {!activeTask ? (
             <div style={{ padding: '20px' }}>
                <div className="info-card" style={{ marginBottom: '24px' }}>
                  <div style={{ fontSize: '13px', color: 'var(--text-secondary)' }}>Summary:</div>
                  <div style={{ fontSize: '15px', fontWeight: '700', margin: '8px 0' }}>{file.name} ➜ {outputName}.{outputFormat}</div>
                  <div style={{ fontSize: '12px', color: 'var(--text-muted)' }}>Destination: {outputDir}</div>
                </div>
                <div style={{ display: 'flex', gap: '12px' }}>
                  <button className="abtn primary" style={{ flex: 1 }} onClick={run}>⚡ Start Conversion</button>
                  <button className="abtn secondary" onClick={() => setStage(2)}>Back to Config</button>
                </div>
             </div>
           ) : (
             <div style={{ textAlign: 'center', padding: '40px 20px' }}>
                <div style={{ fontSize: '48px', marginBottom: '20px' }}>
                  {activeTask.status === "processing" ? "⚙️" : activeTask.status === "completed" ? "✅" : "❌"}
                </div>
                <div className="pt">{activeTask.status === "processing" ? "Converting..." : activeTask.status === "completed" ? "Success" : "Failed"}</div>
                <div className="ps" style={{ marginBottom: '24px' }}>{activeTask.name}</div>
                
                <div className="rm-bar-bg" style={{ height: '8px', marginBottom: '32px' }}>
                  <div className="rm-bar-fill rm-cpu-fill" style={{ 
                    width: `${activeTask.progress || 100}%`,
                    animation: activeTask.status === "processing" ? 'pulse 1.5s infinite' : 'none'
                  }} />
                </div>

                {activeTask.status === "completed" && (
                  <div style={{ display: 'flex', gap: '12px', justifyContent: 'center' }}>
                    <button className="abtn primary" onClick={() => invoke("open_url", { url: activeTask.outputPath }).catch(alert)}>📂 Open File</button>
                    <button className="abtn secondary" onClick={() => invoke("open_in_folder", { path: activeTask.outputPath }).catch(alert)}>📁 Open Folder</button>
                    <button className="abtn primary bl" onClick={() => updateState({ stage: 1, file: null, outputName: "", activeTaskId: null })}>🔄 New Task</button>
                  </div>
                )}

                {activeTask.status === "failed" && (
                  <div className="info-card error" style={{ marginBottom: '16px' }}>{activeTask.error}</div>
                )}
                {activeTask.status === "failed" && <button className="abtn secondary" onClick={() => setActiveTaskId(null)}>Retry</button>}

                {activeTask.status === "processing" && (
                  <button className="abtn secondary" onClick={onBack}>Run in Background</button>
                )}
             </div>
           )}
        </div>
      )}
    </div>
  );
}

// ── Audio Screen ──────────────────────────────────────────────────
function AudioScreen({ onBack, addTask, updateTask, tasks, state, updateState }: ToolScreenProps) {
  const { stage, file, outputFormat = "mp3", outputName, bitrate = "192", activeTaskId } = state;
  const [outputDir, saveOutputDir] = useSavedPath("audio");
  const [isDragOver, setIsDragOver] = useState(false);

  const setStage = (s: number) => updateState({ stage: s });
  const setFile = (f: any) => updateState({ file: f });
  const setOutputFormat = (f: string) => updateState({ outputFormat: f });
  const setOutputName = (n: string) => updateState({ outputName: n });
  const setBitrate = (b: string) => updateState({ bitrate: b });
  const setActiveTaskId = (id: string | null) => updateState({ activeTaskId: id });

  const activeTask = tasks.find((t: ProcessTask) => t.id === activeTaskId);
  const formats = ["mp3","aac","wav","flac","ogg","m4a","opus"];

  useEffect(() => {
    if (file && !outputName) {
      setOutputName(file.name.split('.').slice(0, -1).join('.') + "_audio");
    }
  }, [file]);

  const pickFile = async () => {
    const s = await open({ multiple:false, filters:[{name:"Media",extensions:["mp4","mkv","avi","mov","webm","flv","mp3","wav","flac","ogg","m4a"]}] });
    if (s && !Array.isArray(s)) {
      setFile({ name: s.split(/[\\/]/).pop(), path: s });
      setStage(2);
    }
  };

  const pickDir = async () => {
    const s = await open({ directory:true, multiple:false });
    if (s && !Array.isArray(s)) saveOutputDir(s);
  };

  const run = async () => {
    if (!file || !outputDir) return;
    
    const tid = addTask({
      name: outputName + "." + outputFormat,
      tool: "Audio Extract",
      inputPath: file.path,
    });
    setActiveTaskId(tid);

    try {
      const res = await invoke<TaskResult>("convert_audio", { 
        inputPath: file.path, 
        outputFormat: outputFormat, 
        bitrate: bitrate + "k", 
        outputDir: outputDir,
        outputName: outputName
      });
      
      if (res.success) {
        updateTask(tid, { status: "completed", progress: 100, outputPath: res.outputPath });
        addActivity({ 
          name: file.name, 
          meta: `→ ${outputFormat.toUpperCase()} (${bitrate}k)`, 
          time: "Just now" 
        });
      } else {
        updateTask(tid, { status: "failed", error: res.errorMessage });
      }
    } catch(e) {
      updateTask(tid, { status: "failed", error: String(e) });
    }
  };

  useEffect(() => {
    let unDrop: any, unEnter: any, unLeave: any;
    listen("tauri://drag-drop", (e: any) => {
      setIsDragOver(false);
      const paths = e.payload.paths;
      if (paths && paths.length > 0) {
        setFile({ name: paths[0].split(/[\\/]/).pop(), path: paths[0] });
        setStage(2);
      }
    }).then(u => unDrop = u);
    listen("tauri://drag-enter", () => setIsDragOver(true)).then(u => unEnter = u);
    listen("tauri://drag-leave", () => setIsDragOver(false)).then(u => unLeave = u);
    return () => {
      if (unDrop) unDrop();
      if (unEnter) unEnter();
      if (unLeave) unLeave();
    };
  }, []);

  return (
    <div className="screen active">
      <div className="tool-header">
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          <button className="back-btn" onClick={onBack} style={{ position: 'relative', top: 0 }}>
             <span className="material-symbols-outlined">arrow_back</span>
          </button>
          <div>
            <div className="pt">Audio <span className="bl">Extractor</span></div>
            <div className="ps" style={{ marginBottom: 0 }}>Extract or convert high-quality audio tracks</div>
          </div>
        </div>
        <StageIndicator current={stage} stages={STAGES} />
      </div>
      
      {stage === 1 && (
        <div className={`panel animate-in ${isDragOver ? "drag-over" : ""}`} style={{ padding: '80px', textAlign: 'center' }}>
          <div className="plabel" style={{ marginBottom: '24px' }}>Stage 1: Select Media Source</div>
          <div className="dz" onClick={pickFile}>
            <span className="material-symbols-outlined" style={{ fontSize: '48px', color: 'var(--accent)', marginBottom: '16px' }}>audiotrack</span>
            <div className="dz-main">Drop audio/video or <span className="bl">Browse</span></div>
            <div className="dz-sub">High-fidelity extraction (MP3, FLAC, WAV...)</div>
          </div>
        </div>
      )}

      {stage === 2 && (
        <div className="panel animate-in">
          <div className="plabel">Stage 2: Configuration & Settings</div>
          
          <div className="srow">
            <div className="slabel">Export Filename</div>
            <div className="sfield">
              <span className="material-symbols-outlined sfield-icon">title</span>
              <input className="sinput" value={outputName} onChange={e => setOutputName(e.target.value)} style={{ flex: 1 }} />
              <div className="sbtn-static">.{outputFormat}</div>
            </div>
          </div>

          <div className="fmt-gl" style={{ marginTop: '24px' }}>Target Format</div>
          <div className="fmtb" style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '8px' }}>
            {formats.map(f => (
              <div key={f} className={`fb ${outputFormat === f ? "active" : ""}`} onClick={() => setOutputFormat(f)}>
                {f.toUpperCase()}
              </div>
            ))}
          </div>

          <div className="srow" style={{ marginTop: '32px' }}>
            <div className="slabel" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span>Audio Quality (Bitrate)</span>
              <span className="status-badge info">{bitrate} kbps</span>
            </div>
            <div className="slider-wrap" style={{ marginTop: '16px' }}>
              <input type="range" min="64" max="320" step="32" value={bitrate} onChange={e => setBitrate(e.target.value)} className="modern-slider" />
              <div className="slider-labels"><span>Smaller (64k)</span><span>Studio (320k)</span></div>
            </div>
          </div>

          <div className="srow" style={{ marginTop: '32px' }}>
            <div className="slabel">Save Location</div>
            <div className="sfield">
              <span className="material-symbols-outlined sfield-icon">folder</span>
              <input className="sinput" value={outputDir || "No folder selected"} readOnly style={{ flex: 1 }} />
              <button className="sbtn" onClick={pickDir}>Browse</button>
            </div>
          </div>

          <div style={{ display: 'flex', gap: '12px', marginTop: '40px' }}>
            <button className="abtn primary" style={{ flex: 1 }} onClick={() => setStage(3)} disabled={!outputDir}>
              Review Extraction Plan →
            </button>
            <button className="abtn secondary" onClick={() => { setFile(null); setStage(1); }}>Change File</button>
          </div>
        </div>
      )}

      {stage === 3 && (
        <div className="panel animate-in">
           <div className="plabel">Stage 3: {activeTask ? "Processing" : "Ready"}</div>
           {!activeTask ? (
             <div style={{ padding: '20px' }}>
                <div className="info-card" style={{ marginBottom: '32px' }}>
                  <div style={{ fontSize: '13px', color: 'var(--text-secondary)' }}>Audio Plan:</div>
                  <div style={{ fontSize: '16px', fontWeight: '700', margin: '8px 0' }}>{file.name} ➜ {outputName}.{outputFormat}</div>
                  <div style={{ fontSize: '12px', color: 'var(--text-muted)' }}>Quality: {bitrate}kbps • Target: {outputDir}</div>
                </div>
                <div style={{ display: 'flex', gap: '12px' }}>
                   <button className="abtn primary" style={{ flex: 1 }} onClick={run}>⚡ Start Extraction</button>
                   <button className="abtn secondary" onClick={() => setStage(2)}>Modify Settings</button>
                </div>
             </div>
           ) : (
             <div style={{ textAlign: 'center', padding: '40px 20px' }}>
                <div style={{ fontSize: '48px', marginBottom: '20px' }}>
                  {activeTask.status === "processing" ? "🎹" : activeTask.status === "completed" ? "✅" : "❌"}
                </div>
                <div className="pt">{activeTask.status === "processing" ? "Extracting Audio..." : activeTask.status === "completed" ? "Success" : "Failed"}</div>
                <div className="ps" style={{ marginBottom: '32px' }}>{activeTask.name}</div>
                
                <div className="rm-bar-bg" style={{ height: '8px', borderRadius: '10px', marginBottom: '40px' }}>
                  <div className="rm-bar-fill rm-cpu-fill" style={{ 
                    width: `${activeTask.progress || 100}%`,
                    height: '100%',
                    borderRadius: '10px',
                    animation: activeTask.status === "processing" ? 'pulse 1.5s infinite' : 'none'
                  }} />
                </div>

                {activeTask.status === "completed" && (
                  <div style={{ display: 'flex', gap: '12px', justifyContent: 'center' }}>
                    <button className="abtn primary" onClick={() => invoke("open_url", { url: activeTask.outputPath }).catch(alert)}>
                       <span className="material-symbols-outlined" style={{ fontSize: '18px', marginRight: '8px' }}>music_note</span>
                       Play File
                    </button>
                    <button className="abtn secondary" onClick={() => invoke("open_in_folder", { path: activeTask.outputPath }).catch(alert)}>
                       <span className="material-symbols-outlined" style={{ fontSize: '18px', marginRight: '8px' }}>folder_open</span>
                       Open Folder
                    </button>
                    <button className="abtn primary bl" onClick={() => updateState({ stage: 1, file: null, outputName: "", activeTaskId: null })}>
                       <span className="material-symbols-outlined" style={{ fontSize: '18px', marginRight: '8px' }}>refresh</span>
                       New Task
                    </button>
                  </div>
                )}

                {activeTask.status === "failed" && (
                  <div className="info-card error" style={{ marginBottom: '24px' }}>
                     <span className="material-symbols-outlined">error</span>
                     <div className="ps">{activeTask.error}</div>
                  </div>
                )}
                {activeTask.status === "failed" && <button className="abtn secondary" onClick={() => setActiveTaskId(null)}>Retry</button>}

                {activeTask.status === "processing" && (
                  <button className="abtn secondary" onClick={() => onBack()}>Run in Background</button>
                )}
             </div>
           )}
        </div>
      )}
    </div>
  );
}




// ── Image to PDF Screen ───────────────────────────────────────────
function ImageScreen({ onBack, addTask, updateTask, tasks, state, updateState }: ToolScreenProps) {
  const { stage, files = [], outputName = "combined_images", layout = "A4", activeTaskId } = state;
  const [outputDir, saveOutputDir] = useSavedPath("imagepdf");
  const [isDragOver, setIsDragOver] = useState(false);

  const setStage = (s: number) => updateState({ stage: s });
  const setFiles = (f: any[]) => updateState({ files: f });
  const setOutputName = (n: string) => updateState({ outputName: n });
  const setLayout = (l: string) => updateState({ layout: l });
  const setActiveTaskId = (id: string | null) => updateState({ activeTaskId: id });

  const activeTask = tasks.find((t: ProcessTask) => t.id === activeTaskId);

  useEffect(() => {
    if (files.length > 0 && outputName === "combined_images") {
      const base = files[0].name.split('.').slice(0, -1).join('.');
      setOutputName(`${base}_bundle`);
    }
  }, [files]);

  useEffect(() => {
    let unDrop: any, unEnter: any, unLeave: any;
    listen("tauri://drag-drop", (e: any) => {
      setIsDragOver(false);
      const paths = e.payload.paths;
      if (paths && paths.length > 0) {
        const newImgFiles = paths.map((p: string) => ({ name: p.split(/[\\/]/).pop(), path: p }));
        setFiles([...files, ...newImgFiles]);
        setStage(2);
      }
    }).then(u => unDrop = u);
    listen("tauri://drag-enter", () => setIsDragOver(true)).then(u => unEnter = u);
    listen("tauri://drag-leave", () => setIsDragOver(false)).then(u => unLeave = u);
    return () => {
      if (unDrop) unDrop();
      if (unEnter) unEnter();
      if (unLeave) unLeave();
    };
  }, []);

  const pickFiles = async () => {
    const selected = await open({ multiple: true, filters: [{ name: 'Images', extensions: ['jpg', 'jpeg', 'png', 'webp', 'bmp'] }] });
    if (selected && Array.isArray(selected)) {
      const newImgFiles = selected.map((p: string) => ({ name: p.split(/[\\/]/).pop(), path: p }));
      setFiles([...files, ...newImgFiles]);
      setStage(2);
    }
  };

  const pickDir = async () => {
    const s = await open({ directory: true, multiple: false });
    if (s && !Array.isArray(s)) saveOutputDir(s);
  };

  const run = async () => {
    if (files.length === 0 || !outputDir || !outputName) return;
    
    const tid = addTask({
      name: `${outputName}.pdf`,
      tool: "Images to PDF",
      inputPath: `${files.length} images`,
    });
    setActiveTaskId(tid);

    try {
      const res = await invoke<TaskResult>("images_to_pdf", { 
        imagePaths: files.map((f: any) => f.path), 
        outputPath: outputDir + "\\" + outputName + ".pdf",
        layout: layout
      });
      
      if (res.success) {
        updateTask(tid, { status: "completed", progress: 100, outputPath: res.outputPath });
        addActivity({ name: outputName + ".pdf", meta: "Images → PDF", time: "Just now" });
      } else {
        updateTask(tid, { status: "failed", error: res.errorMessage });
      }
    } catch(e) {
      updateTask(tid, { status: "failed", error: String(e) });
    }
  };

  return (
    <div className="screen active">
      <div className="tool-header">
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          <button className="back-btn" onClick={onBack} style={{ position: 'relative', top: 0 }}>
            <span className="material-symbols-outlined">arrow_back</span>
          </button>
          <div>
            <div className="pt">Images <span className="bl">to PDF</span></div>
            <div className="ps" style={{ marginBottom: 0 }}>Combine multiple photos into a single PDF document</div>
          </div>
        </div>
        <StageIndicator current={stage} stages={STAGES} />
      </div>

      {stage === 1 && (
        <div className="animate-in">
          <div className={`panel ${isDragOver ? "drag-over" : ""}`} style={{ padding: '80px', textAlign: 'center' }}>
            <div className="plabel" style={{ marginBottom: '24px' }}>Stage 1: Select Assets</div>
            <div className="dz" onClick={pickFiles}>
              <span className="material-symbols-outlined" style={{ fontSize: '48px', color: 'var(--accent)', marginBottom: '16px' }}>collections</span>
              <div className="dz-main">Drop Images or <span className="bl">Browse</span></div>
              <div className="dz-sub">Combine JPG, PNG, WEBP into one document</div>
            </div>
          </div>

          {files.length > 0 && (
            <div className="panel" style={{ marginTop: '24px' }}>
              <div className="plabel" style={{ marginBottom: '20px' }}>Selected Batch ({files.length})</div>
              <div className="scrollable-list" style={{ maxHeight: '240px', overflowY: 'auto', paddingRight: '8px' }}>
                {files.map((f: { name: string; path: string }, i: number) => (
                  <div key={i} className="list-item" style={{ marginBottom: '8px' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                      <span className="material-symbols-outlined" style={{ color: 'var(--accent)', fontSize: '20px' }}>image</span>
                      <span style={{ fontSize: '13px', fontWeight: '500' }}>{f.name}</span>
                    </div>
                    <button className="icon-btn red" onClick={() => setFiles(files.filter((_: any, idx: number) => idx !== i))}>
                      <span className="material-symbols-outlined" style={{ fontSize: '18px' }}>delete</span>
                    </button>
                  </div>
                ))}
              </div>
              <button className="abtn primary" style={{ width: '100%', marginTop: '24px' }} onClick={() => setStage(2)}>
                Continue to Compilation →
              </button>
            </div>
          )}
        </div>
      )}

      {stage === 2 && (
        <div className="panel animate-in">
          <div className="plabel">Stage 2: Document Compilation</div>
          
          <div className="srow">
            <div className="slabel">Deployment Name</div>
            <div className="sfield">
              <span className="material-symbols-outlined sfield-icon">description</span>
              <input className="sinput" value={outputName} onChange={e => setOutputName(e.target.value)} style={{ flex: 1 }} />
              <div className="sbtn-static">.pdf</div>
            </div>
          </div>

          <div className="fmt-gl" style={{ marginTop: '24px' }}>Page Scaling & Layout</div>
          <div className="fmtb" style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
            <div className={`fb ${layout === "A4" ? "active" : ""}`} onClick={() => setLayout("A4")}>
              <span className="material-symbols-outlined">description</span> Standard A4
            </div>
            <div className={`fb ${layout === "Fit" ? "active" : ""}`} onClick={() => setLayout("Fit")}>
              <span className="material-symbols-outlined">aspect_ratio</span> Original Ratio
            </div>
          </div>

          <div className="srow" style={{ marginTop: '32px' }}>
             <div className="slabel">Target Repository</div>
             <div className="sfield">
               <span className="material-symbols-outlined sfield-icon">folder_zip</span>
               <input className="sinput" value={outputDir || "Select destination..."} readOnly style={{ flex: 1 }} />
               <button className="sbtn" onClick={pickDir}>Browse</button>
             </div>
          </div>

          <div style={{ display: 'flex', gap: '12px', marginTop: '40px' }}>
            <button className="abtn primary" style={{ flex: 1 }} onClick={() => setStage(3)} disabled={!outputDir || !outputName}>
              Finalize & Compile PDF →
            </button>
            <button className="abtn secondary" onClick={() => setStage(1)}>Modify Assets</button>
          </div>
        </div>
      )}

      {stage === 3 && (
        <div className="panel animate-in">
           <div className="plabel">Stage 3: {activeTask ? "Processing Engine" : "Compilation Ready"}</div>
           {!activeTask ? (
             <div style={{ padding: '20px' }}>
                <div className="info-card" style={{ marginBottom: '32px' }}>
                  <div style={{ fontSize: '13px', color: 'var(--text-secondary)', marginBottom: '12px' }}>Compilation Plan:</div>
                  <div className="list-item" style={{ background: 'none', border: 'none', padding: 0, marginBottom: '8px' }}>
                    <span className="material-symbols-outlined" style={{ color: 'var(--accent)' }}>layers</span>
                    <span style={{ fontWeight: 600 }}>{files.length} Source Images</span>
                  </div>
                  <div className="list-item" style={{ background: 'none', border: 'none', padding: 0 }}>
                    <span className="material-symbols-outlined" style={{ color: 'var(--accent)' }}>picture_as_pdf</span>
                    <span style={{ fontWeight: 600 }}>{outputName}.pdf ({layout})</span>
                  </div>
                </div>
                <div style={{ display: 'flex', gap: '12px' }}>
                  <button className="abtn primary" style={{ flex: 1 }} onClick={run}>⚡ Start Engine</button>
                  <button className="abtn secondary" onClick={() => setStage(2)}>Back to Config</button>
                </div>
             </div>
           ) : (
             <div style={{ textAlign: 'center', padding: '40px 20px' }}>
                <div style={{ fontSize: '48px', marginBottom: '24px' }}>
                  {activeTask.status === "processing" ? "🏗️" : activeTask.status === "completed" ? "✅" : "❌"}
                </div>
                <div className="pt">{activeTask.status === "processing" ? "Compiling Document..." : activeTask.status === "completed" ? "Success" : "Failed"}</div>
                <div className="ps" style={{ marginBottom: '32px' }}>{activeTask.name}</div>
                
                <div className="rm-bar-bg" style={{ height: '8px', borderRadius: '10px', marginBottom: '40px' }}>
                   <div className="rm-bar-fill rm-cpu-fill" style={{ 
                     width: `${activeTask.progress || 100}%`,
                     height: '100%',
                     borderRadius: '10px',
                     animation: activeTask.status === "processing" ? 'pulse 1.5s infinite' : 'none'
                   }} />
                </div>

                {activeTask.status === "completed" && (
                  <div style={{ display: 'flex', gap: '12px', justifyContent: 'center' }}>
                    <button className="abtn primary" onClick={() => invoke("open_url", { url: activeTask.outputPath }).catch(alert)}>
                      <span className="material-symbols-outlined" style={{ fontSize: '18px', marginRight: '8px' }}>visibility</span>
                      View PDF
                    </button>
                    <button className="abtn secondary" onClick={() => invoke("open_in_folder", { path: activeTask.outputPath }).catch(alert)}>
                      <span className="material-symbols-outlined" style={{ fontSize: '18px', marginRight: '8px' }}>folder_open</span>
                      Open Folder
                    </button>
                    <button className="abtn primary bl" onClick={() => updateState({ stage: 1, files: [], outputName: "", activeTaskId: null })}>
                      <span className="material-symbols-outlined" style={{ fontSize: '18px', marginRight: '8px' }}>add</span>
                      New Bundle
                    </button>
                  </div>
                )}

                {activeTask.status === "failed" && (
                  <div className="info-card error" style={{ marginBottom: '24px' }}>
                    <span className="material-symbols-outlined">error</span>
                    <div className="ps">{activeTask.error}</div>
                  </div>
                )}
                {activeTask.status === "failed" && <button className="abtn secondary" onClick={() => setActiveTaskId(null)}>Retry Setup</button>}

                {activeTask.status === "processing" && (
                  <button className="abtn secondary" onClick={() => onBack()}>Run in Background</button>
                )}
             </div>
           )}
        </div>
      )}
    </div>
  );
}

// ── Video Convert Screen ──────────────────────────────────────────
function VideoScreen({ onBack, addTask, updateTask, tasks, state, updateState }: ToolScreenProps) {
  const { stage, file, outputFormat = "mp4", outputName, quality = "medium", activeTaskId } = state;
  const [outputDir, saveOutputDir] = useSavedPath("video");
  const [isDragOver, setIsDragOver] = useState(false);

  const setStage = (s: number) => updateState({ stage: s });
  const setFile = (f: any) => updateState({ file: f });
  const setOutputFormat = (f: string) => updateState({ outputFormat: f });
  const setOutputName = (n: string) => updateState({ outputName: n });
  const setQuality = (q: string) => updateState({ quality: q });
  const setActiveTaskId = (id: string | null) => updateState({ activeTaskId: id });

  const activeTask = tasks.find((t: ProcessTask) => t.id === activeTaskId);
  const formats = ["mp4","mkv","mov","avi","webm","gif"];

  useEffect(() => {
    if (file) {
      setOutputName(file.name.split('.').slice(0, -1).join('.') + "_converted");
    }
  }, [file]);

  const pickFile = async () => {
    const s = await open({ multiple:false, filters:[{name:"Video",extensions:["mp4","mkv","avi","mov","webm","flv","wmv","m4v"]}] });
    if (s && !Array.isArray(s)) {
      setFile({ name: s.split(/[\\/]/).pop(), path: s });
      setStage(2);
    }
  };

  const pickDir = async () => {
    const s = await open({ directory:true, multiple:false });
    if (s && !Array.isArray(s)) saveOutputDir(s);
  };

  const run = async () => {
    if (!file || !outputDir) return;
    
    const tid = addTask({
      name: outputName + "." + outputFormat,
      tool: "Video Convert",
      inputPath: file.path,
    });
    setActiveTaskId(tid);

    try {
      const res = await invoke<TaskResult>("convert_video", { 
        inputPath: file.path, 
        outputFormat: outputFormat, 
        outputDir: outputDir,
        quality,
        preset: null,
        outputName: outputName
      });
      
      if (res.success) {
        updateTask(tid, { status: "completed", progress: 100, outputPath: res.outputPath });
        addActivity({ 
          name: file.name, 
          meta: `→ ${outputFormat.toUpperCase()} (${quality})`, 
          time: "Just now" 
        });
      } else {
        updateTask(tid, { status: "failed", error: res.errorMessage });
      }
    } catch(e) {
      updateTask(tid, { status: "failed", error: String(e) });
    }
  };

  useEffect(() => {
    let unDrop: any, unEnter: any, unLeave: any;
    listen("tauri://drag-drop", (e: any) => {
      setIsDragOver(false);
      const paths = e.payload.paths;
      if (paths && paths.length > 0) {
        setFile({ name: paths[0].split(/[\\/]/).pop(), path: paths[0] });
        setStage(2);
      }
    }).then(u => unDrop = u);
    listen("tauri://drag-enter", () => setIsDragOver(true)).then(u => unEnter = u);
    listen("tauri://drag-leave", () => setIsDragOver(false)).then(u => unLeave = u);
    return () => {
      if (unDrop) unDrop();
      if (unEnter) unEnter();
      if (unLeave) unLeave();
    };
  }, []);

  return (
    <div className="screen active">
      <div className="tool-header">
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          <button className="back-btn" onClick={onBack} style={{ position: 'relative', top: 0 }}>
            <span className="material-symbols-outlined">arrow_back</span>
          </button>
          <div>
            <div className="pt">Video <span className="bl">Converter</span></div>
            <div className="ps" style={{ marginBottom: 0 }}>High-fidelity local media transcoding</div>
          </div>
        </div>
        <StageIndicator current={stage} stages={STAGES} />
      </div>
      
      {stage === 1 && (
        <div className={`panel animate-in ${isDragOver ? "drag-over" : ""}`} style={{ padding: '80px', textAlign: 'center' }}>
          <div className="plabel" style={{ marginBottom: '24px' }}>Stage 1: Select Video Source</div>
          <div className="dz" onClick={pickFile}>
            <span className="material-symbols-outlined" style={{ fontSize: '48px', color: 'var(--accent)', marginBottom: '16px' }}>movie</span>
            <div className="dz-main">Drop video or <span className="bl">Browse</span></div>
            <div className="dz-sub">Pro-grade conversion (MP4, MKV, AVI, WebM)</div>
          </div>
        </div>
      )}

      {stage === 2 && (
        <div className="panel animate-in">
          <div className="plabel">Stage 2: Transcoding Settings</div>
          
          <div className="srow">
            <div className="slabel">Export Filename</div>
            <div className="sfield">
              <span className="material-symbols-outlined sfield-icon">title</span>
              <input className="sinput" value={outputName} onChange={e => setOutputName(e.target.value)} style={{ flex: 1 }} />
              <div className="sbtn-static">.{outputFormat}</div>
            </div>
          </div>

          <div className="fmt-gl" style={{ marginTop: '24px' }}>Target Container</div>
          <div className="fmtb" style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '8px' }}>
            {formats.map(f => (
              <div key={f} className={`fb ${outputFormat === f ? "active" : ""}`} onClick={() => setOutputFormat(f)}>
                {f.toUpperCase()}
              </div>
            ))}
          </div>

          <div className="fmt-gl" style={{ marginTop: '24px' }}>Optimized Quality profile</div>
          <div className="fmtb" style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '12px' }}>
            {["high", "medium", "low"].map(q => (
              <div key={q} className={`fb ${quality === q ? "active" : ""}`} onClick={() => setQuality(q)}>
                <span className="material-symbols-outlined" style={{ fontSize: '18px', marginRight: '6px' }}>
                  {q === 'high' ? 'speed' : q === 'medium' ? 'balance' : 'eco'}
                </span>
                {q.charAt(0).toUpperCase() + q.slice(1)}
              </div>
            ))}
          </div>

          <div className="srow" style={{ marginTop: '32px' }}>
            <div className="slabel">Target Export Folder</div>
            <div className="sfield">
              <span className="material-symbols-outlined sfield-icon">folder</span>
              <input className="sinput" value={outputDir || "Select directory..."} readOnly style={{ flex: 1 }} />
              <button className="sbtn" onClick={pickDir}>Browse</button>
            </div>
          </div>

          <div style={{ display: 'flex', gap: '12px', marginTop: '40px' }}>
            <button className="abtn primary" style={{ flex: 1 }} onClick={() => setStage(3)} disabled={!outputDir || !outputName}>
              Review Transcoding Plan →
            </button>
            <button className="abtn secondary" onClick={() => { setFile(null); setStage(1); }}>Change Source</button>
          </div>
        </div>
      )}

      {stage === 3 && (
        <div className="panel animate-in">
           <div className="plabel">Stage 3: {activeTask ? "Processing" : "Ready to Launch"}</div>
           {!activeTask ? (
             <div style={{ padding: '20px' }}>
                <div className="info-card" style={{ marginBottom: '32px' }}>
                  <div style={{ fontSize: '13px', color: 'var(--text-secondary)', marginBottom: '12px' }}>Transcoding Summary:</div>
                  <div style={{ fontSize: '15px', fontWeight: '700', margin: '4px 0' }}>{file.name} ➜ {outputName}.{outputFormat}</div>
                  <div style={{ fontSize: '12px', color: 'var(--text-muted)' }}>Profile: {quality.toUpperCase()} • Encapsulation: {outputFormat.toUpperCase()}</div>
                </div>
                <div style={{ display: 'flex', gap: '12px' }}>
                   <button className="abtn primary" style={{ flex: 1 }} onClick={run}>⚡ Start Transcoder</button>
                   <button className="abtn secondary" onClick={() => setStage(2)}>Back to Config</button>
                </div>
             </div>
           ) : (
             <div style={{ textAlign: 'center', padding: '40px 20px' }}>
                <div style={{ fontSize: '48px', marginBottom: '24px' }}>
                  {activeTask.status === "processing" ? "🎬" : activeTask.status === "completed" ? "✅" : "❌"}
                </div>
                <div className="pt">{activeTask.status === "processing" ? "Transcoding Media..." : activeTask.status === "completed" ? "Success" : "Failed"}</div>
                <div className="ps" style={{ marginBottom: '32px' }}>{activeTask.name}</div>
                
                <div className="rm-bar-bg" style={{ height: '8px', borderRadius: '10px', marginBottom: '40px' }}>
                  <div className="rm-bar-fill rm-cpu-fill" style={{ 
                    width: `${activeTask.progress || 100}%`,
                    height: '100%',
                    borderRadius: '10px',
                    animation: activeTask.status === "processing" ? 'pulse 1.5s infinite' : 'none'
                  }} />
                </div>

                {activeTask.status === "completed" && (
                  <div style={{ display: 'flex', gap: '12px', justifyContent: 'center' }}>
                    <button className="abtn primary" onClick={() => invoke("open_url", { url: activeTask.outputPath }).catch(alert)}>
                      <span className="material-symbols-outlined" style={{ fontSize: '18px', marginRight: '8px' }}>play_circle</span>
                      Preview
                    </button>
                    <button className="abtn secondary" onClick={() => invoke("open_in_folder", { path: activeTask.outputPath }).catch(alert)}>
                      <span className="material-symbols-outlined" style={{ fontSize: '18px', marginRight: '8px' }}>folder_open</span>
                      Open Folder
                    </button>
                    <button className="abtn primary bl" onClick={() => updateState({ stage: 1, file: null, outputName: "", activeTaskId: null })}>
                      <span className="material-symbols-outlined" style={{ fontSize: '18px', marginRight: '8px' }}>refresh</span>
                      New Task
                    </button>
                  </div>
                )}

                {activeTask.status === "failed" && (
                  <div className="info-card error" style={{ marginBottom: '24px' }}>
                    <span className="material-symbols-outlined">error</span>
                <div className="info-card error" style={{ marginBottom: '24px' }}>
                  <span className="material-symbols-outlined">error</span>
                  <div className="ps">{activeTask.error}</div>
                </div>
              )}
              {activeTask.status === "failed" && <button className="abtn secondary" onClick={() => setActiveTaskId(null)}>Retry</button>}
              {activeTask.status === "processing" && (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                  <button className="abtn primary" onClick={() => { setStage(1); setFile(null); setActiveTaskId(null); }}>
                    <span className="material-symbols-outlined">close</span>
                    <span>Abort Process</span>
                  </button>
                  <button className="abtn secondary" onClick={() => onBack()}>Run in Background</button>
                </div>
              )}
            </div>
          )}
        </div>
      )}
    </div>
  );
}

function CompressVideoScreen({ onBack, addTask, updateTask, tasks, state, updateState }: ToolScreenProps) {
  const { stage, files = [], outputFormat = "mp4", resolution = "1080p", crf = "23", preset = "fast", activeTaskIds = [], outputName = "" } = state;
  const [outputDir, saveOutputDir] = useSavedPath("compress");
  const [isDragOver, setIsDragOver] = useState(false);

  const setStage = (s: number) => updateState({ stage: s });
  const setFiles = (f: any[]) => updateState({ files: f });
  const setOutputFormat = (f: string) => updateState({ outputFormat: f });
  const setResolution = (r: string) => updateState({ resolution: r });
  const setCrf = (c: string) => updateState({ crf: c });
  const setPreset = (p: string) => updateState({ preset: p });
  const setActiveTaskIds = (ids: string[]) => updateState({ activeTaskIds: ids });
  const setOutputName = (n: string) => updateState({ outputName: n });

  useEffect(() => {
    let unDrop: any, unEnter: any, unLeave: any;
    listen("tauri://drag-drop", (e: any) => {
      setIsDragOver(false);
      const paths = e.payload.paths;
      if (paths && paths.length > 0) {
        setFiles(paths.map((p: any) => ({ name: p.split(/[\\/]/).pop(), path: p })));
        setStage(2);
      }
    }).then(u => unDrop = u);
    listen("tauri://drag-enter", () => setIsDragOver(true)).then(u => unEnter = u);
    listen("tauri://drag-leave", () => setIsDragOver(false)).then(u => unLeave = u);
    return () => {
      if (unDrop) unDrop();
      if (unEnter) unEnter();
      if (unLeave) unLeave();
    };
  }, []);

  const pickFiles = async () => {
    const selected = await open({ multiple:true, filters:[{name:"Video",extensions:["mp4","mkv","avi","mov","webm","flv"]}] });
    if (selected && Array.isArray(selected)) {
      setFiles(selected.map(s => ({ name: s.split(/[\\/]/).pop(), path: s })));
      setStage(2);
    }
  };

  const pickDir = async () => {
    const s = await open({ directory:true, multiple:false });
    if (s && !Array.isArray(s)) saveOutputDir(s);
  };

  const run = async () => {
    if (!files.length || !outputDir) return;
    
    const tids: string[] = [];
    for (let i = 0; i < files.length; i++) {
      const f = files[i];
      const finalName = files.length === 1 && outputName 
        ? outputName 
        : (outputName || f.name.split('.').slice(0, -1).join('.')) + (files.length > 1 ? `_${i+1}` : "_compressed");
      
      const tid = addTask({
        name: finalName + "." + outputFormat,
        tool: "Batch Compression",
        inputPath: f.path,
      });
      tids.push(tid);
    }
    setActiveTaskIds(tids);

    for (let i = 0; i < files.length; i++) {
        const f = files[i];
        const tid = tids[i];
        try {
            const finalName = files.length === 1 && outputName 
                ? outputName 
                : (outputName || f.name.split('.').slice(0, -1).join('.')) + (files.length > 1 ? `_${i+1}` : "_compressed");

            const res = await invoke<TaskResult>("compress_video", { 
                inputPath: f.path, 
                outputFormat: outputFormat, 
                outputDir: outputDir, 
                resolution, 
                crf, 
                preset,
                outputName: finalName
            });
            if (res.success) {
                updateTask(tid, { status: "completed", progress: 100, outputPath: res.outputPath });
                addActivity({ name: f.name, meta: `Compressed to ${resolution}`, time: "Just now" });
            } else {
                updateTask(tid, { status: "failed", error: res.errorMessage });
            }
        } catch(e) {
            updateTask(tid, { status: "failed", error: String(e) });
        }
    }
  };

  const currentActiveTasks = tasks.filter((t: ProcessTask) => activeTaskIds.includes(t.id));
  const completedCount = currentActiveTasks.filter((t: ProcessTask) => t.status !== 'processing').length;

  return (
    <div className="screen active">
      <div className="tool-header">
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          <button className="back-btn" onClick={onBack} style={{ position: 'relative', top: 0 }}>
            <span className="material-symbols-outlined">arrow_back</span>
          </button>
          <div>
            <div className="pt">Video <span className="bl">Compressor</span></div>
            <div className="ps" style={{ marginBottom: 0 }}>Advanced high-efficiency media buffer compression</div>
          </div>
        </div>
        <StageIndicator current={stage} stages={STAGES} />
      </div>
      
      {stage === 1 && (
        <div className="animate-in">
          <div className={`panel ${isDragOver ? "drag-over" : ""}`} style={{ padding: '80px', textAlign: 'center' }}>
            <div className="plabel" style={{ marginBottom: '24px' }}>Stage 1: Select Media Pool</div>
            <div className="dz" onClick={pickFiles}>
              <span className="material-symbols-outlined" style={{ fontSize: '48px', color: 'var(--accent)', marginBottom: '16px' }}>compress</span>
              <div className="dz-main">{files.length > 0 ? `${files.length} Assets Staged` : "Drop videos or Browse"}</div>
              <div className="dz-sub">Multi-threaded H.264 / H.265 compression engine</div>
            </div>
          </div>
          {files.length > 0 && (
            <div className="panel" style={{ marginTop: '24px' }}>
               <div className="plabel" style={{ marginBottom: '20px' }}>Staged for Compression ({files.length})</div>
               <div className="scrollable-list" style={{ maxHeight: '200px', overflowY: 'auto', paddingRight: '8px' }}>
                 {files.map((f: any, i: number) => (
                   <div key={i} className="list-item" style={{ marginBottom: '8px' }}>
                     <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                       <span className="material-symbols-outlined" style={{ color: 'var(--accent)', fontSize: '20px' }}>movie</span>
                       <span style={{ fontSize: '13px', fontWeight: '500' }}>{f.name}</span>
                     </div>
                     <button className="icon-btn red" onClick={() => setFiles(files.filter((_: any, idx: number) => idx !== i))}>
                       <span className="material-symbols-outlined" style={{ fontSize: '18px' }}>delete</span>
                     </button>
                   </div>
                 ))}
               </div>
               <button className="abtn primary" style={{ width: '100%', marginTop: '24px' }} onClick={() => setStage(2)}>
                 Proceed to Engine Config →
               </button>
            </div>
          )}
        </div>
      )}

      {stage === 2 && (
        <div className="panel animate-in">
          <div className="plabel">Stage 2: Engine Configuration</div>
          
          <div className="srow">
            <div className="slabel">{files.length > 1 ? "Shared Naming Prefix" : "Export Identifier"}</div>
            <div className="sfield">
              <span className="material-symbols-outlined sfield-icon">label</span>
              <input className="sinput" value={outputName} onChange={e => setOutputName(e.target.value)} style={{ flex: 1 }} />
              <div className="sbtn-static">.{outputFormat}</div>
            </div>
          </div>

          <div className="two-col" style={{ gap: '24px', marginTop: '24px' }}>
            <div>
              <div className="fmt-gl">Target Resolution</div>
              <div className="fmtb" style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '8px' }}>
                {["original", "1080p", "720p", "480p"].map(r => (
                  <div key={r} className={`fb ${resolution === r ? "active" : ""}`} onClick={() => setResolution(r)}>{r === 'original' ? 'Native' : r}</div>
                ))}
              </div>
            </div>
            <div>
              <div className="fmt-gl">Optimization Preset</div>
              <div className="fmtb" style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '8px' }}>
                {["ultrafast", "fast", "medium", "slow"].map(p => (
                  <div key={p} className={`fb ${preset === p ? "active" : ""}`} onClick={() => setPreset(p)}>{p}</div>
                ))}
              </div>
            </div>
          </div>

          <div className="srow" style={{ marginTop: '32px' }}>
            <div className="slabel" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span>Compression Density (CRF)</span>
              <span className="status-badge info">Value: {crf}</span>
            </div>
            <div className="slider-wrap" style={{ marginTop: '16px' }}>
              <input type="range" min="18" max="32" value={crf} onChange={e => setCrf(e.target.value)} className="modern-slider" />
              <div className="slider-labels"><span>Lossless (18)</span><span>High Comp (32)</span></div>
            </div>
          </div>

          <div className="fmt-gl" style={{ marginTop: '32px' }}>Target Encapsulation</div>
          <div className="fmtb" style={{ display: 'grid', gridTemplateColumns: 'repeat(5, 1fr)', gap: '8px' }}>
            {["mp4","mkv","mov","avi","webm"].map(f => (
              <div key={f} className={`fb ${outputFormat === f ? "active" : ""}`} onClick={() => setOutputFormat(f)}>
                {f.toUpperCase()}
              </div>
            ))}
          </div>

          <div className="srow" style={{ marginTop: '32px' }}>
            <div className="slabel">Archive Directory</div>
            <div className="sfield">
              <span className="material-symbols-outlined sfield-icon">folder_special</span>
              <input className="sinput" value={outputDir || "Select target..."} readOnly style={{ flex: 1 }} />
              <button className="sbtn" onClick={pickDir}>Browse</button>
            </div>
          </div>

          <div style={{ display: 'flex', gap: '12px', marginTop: '40px' }}>
            <button className="abtn primary" style={{ flex: 1 }} onClick={() => setStage(3)} disabled={!outputDir}>
              Confirm Deployment Plan →
            </button>
            <button className="abtn secondary" onClick={() => { setFiles([]); setStage(1); }}>Change Assets</button>
          </div>
        </div>
      )}

      {stage === 3 && (
        <div className="panel animate-in">
           <div className="plabel">Stage 3: {activeTaskIds.length > 0 ? "Batch Deployment" : "Ready to Commit"}</div>
           {activeTaskIds.length === 0 ? (
             <div style={{ padding: '20px' }}>
                <div className="info-card" style={{ marginBottom: '32px' }}>
                  <div style={{ fontSize: '13px', color: 'var(--text-secondary)', marginBottom: '12px' }}>Execution Plan:</div>
                  <div className="list-item" style={{ background: 'none', border: 'none', padding: 0, marginBottom: '8px' }}>
                    <span className="material-symbols-outlined" style={{ color: 'var(--accent)' }}>dynamic_feed</span>
                    <span style={{ fontWeight: 600 }}>{files.length} Videos queued</span>
                  </div>
                  <div className="list-item" style={{ background: 'none', border: 'none', padding: 0 }}>
                    <span className="material-symbols-outlined" style={{ color: 'var(--accent)' }}>precision_manufacturing</span>
                    <span style={{ fontWeight: 600 }}>{resolution} Plan • CRF {crf}</span>
                  </div>
                </div>
                <div style={{ display: 'flex', gap: '12px' }}>
                  <button className="abtn primary" style={{ flex: 1 }} onClick={run}>⚡ Launch Engine</button>
                  <button className="abtn secondary" onClick={() => setStage(2)}>Modify Strategy</button>
                </div>
             </div>
           ) : (
             <div style={{ padding: '20px' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
                  <div>
                    <div className="pt" style={{ fontSize: '20px' }}>{completedCount === files.length ? "Batch Success" : "Engine Working..."}</div>
                    <div className="ps" style={{ margin: 0 }}>Progress: {completedCount} of {files.length} finalized</div>
                  </div>
                </div>
                
                <div className="rm-bar-bg" style={{ height: '10px', borderRadius: '10px', marginBottom: '32px' }}>
                  <div className="rm-bar-fill rm-cpu-fill" style={{ 
                    width: `${(completedCount/files.length)*100}%`,
                    height: '100%',
                    borderRadius: '10px'
                  }} />
                </div>
                
                <div style={{ maxHeight: '300px', overflowY: 'auto', paddingRight: '8px' }}>
                  {currentActiveTasks.map((t: ProcessTask) => (
                    <div key={t.id} className="list-item" style={{ marginBottom: '10px', opacity: t.status === 'processing' ? 1 : 0.8 }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '12px', flex: 1, minWidth: 0 }}>
                        <span className="material-symbols-outlined" style={{ 
                          color: t.status === 'completed' ? 'var(--green)' : t.status === 'failed' ? 'var(--red)' : 'var(--accent)'
                        }}>
                          {t.status === 'completed' ? 'check_circle' : t.status === 'failed' ? 'error' : 'pending'}
                        </span>
                        <span style={{ fontSize: '13px', fontWeight: 600, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{t.name}</span>
                      </div>
                      <span className={`status-badge ${t.status === 'completed' ? 'success' : t.status === 'failed' ? 'error' : 'info'}`}>
                          {t.status === 'completed' ? 'Done' : t.status === 'failed' ? 'Fail' : 'Working'}
                      </span>
                    </div>
                  ))}
                </div>

                {completedCount === files.length && (
                  <div style={{ display: 'flex', gap: '12px', marginTop: '32px', justifyContent: 'center' }}>
                    <button className="abtn primary" onClick={() => invoke("open_in_folder", { path: outputDir }).catch(alert)}>
                      <span className="material-symbols-outlined" style={{ fontSize: '18px', marginRight: '8px' }}>folder_open</span>
                      Open Folder
                    </button>
                    <button className="abtn primary bl" onClick={() => { setStage(1); setFiles([]); setActiveTaskIds([]); setOutputName(""); }}>
                      <span className="material-symbols-outlined" style={{ fontSize: '18px', marginRight: '8px' }}>refresh</span>
                      New Batch
                    </button>
                  </div>
                )}
                
                {completedCount < files.length && (
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '12px', marginTop: '32px' }}>
                    <div className="gpu-badge" style={{ margin: '0 auto' }}>
                      <div className="gpu-badge-dot" />
                      Hardware Accel Active
                    </div>
                    <button className="abtn secondary" onClick={() => onBack()}>Run in Background</button>
                  </div>
                )}
             </div>
           )}
        </div>
      )}
    </div>
  );
}Working...'}
                          </span>
                      </div>
                    </div>
                  ))}
                </div>

                {completedCount === files.length && (
                  <div style={{ display: 'flex', gap: '8px', marginTop: '24px', justifyContent: 'center' }}>
                    <button className="abtn primary" onClick={() => invoke("open_in_folder", { path: outputDir }).catch(alert)}>📁 Open Folder</button>
                    <button className="abtn secondary bl" onClick={() => { setStage(1); setFiles([]); setActiveTaskIds([]); setOutputName(""); }}>⚡ New Batch</button>
                  </div>
                )}
                {completedCount < files.length && (
                  <button className="abtn secondary" style={{ marginTop: '24px' }} onClick={() => onBack()}>Run in Background</button>
                )}
             </div>
           )}
        </div>
      )}
    </div>
  );
}

// ── Image Convert Screen ──────────────────────────────────────────
function ImageConvertScreen({ onBack, addTask, updateTask, tasks, state, updateState }: ToolScreenProps) {
  const { stage, file, outputFormat = "webp", outputName, quality = "85", activeTaskId } = state;
  const [outputDir, saveOutputDir] = useSavedPath("imgconv");
  const [isDragOver, setIsDragOver] = useState(false);

  const setStage = (s: number) => updateState({ stage: s });
  const setFile = (f: any) => updateState({ file: f });
  const setOutputFormat = (f: string) => updateState({ outputFormat: f });
  const setOutputName = (n: string) => updateState({ outputName: n });
  const setQuality = (q: string) => updateState({ quality: q });
  const setActiveTaskId = (id: string | null) => updateState({ activeTaskId: id });

  const activeTask = tasks.find((t: ProcessTask) => t.id === activeTaskId);
  const formats = ["jpg","png","webp","gif","bmp","tiff"];

  useEffect(() => {
    if (file) {
      setOutputName(file.name.split('.').slice(0, -1).join('.') + "_converted");
    }
  }, [file]);

  const pickFile = async () => {
    const s = await open({ multiple:false, filters:[{name:"Images",extensions:["jpg","jpeg","png","webp","bmp","tiff","gif"]}] });
    if (s && !Array.isArray(s)) {
      setFile({ name: s.split(/[\\/]/).pop(), path: s });
      setStage(2);
    }
  };

  const pickDir = async () => {
    const s = await open({ directory:true, multiple:false });
    if (s && !Array.isArray(s)) saveOutputDir(s);
  };

  const run = async () => {
    if (!file || !outputDir) return;
    
    const tid = addTask({
      name: outputName + "." + outputFormat,
      tool: "Image Convert",
      inputPath: file.path,
    });
    setActiveTaskId(tid);

    try {
      const res = await invoke<TaskResult>("convert_image_format", { 
        inputPath: file.path, 
        outputFormat: outputFormat, 
        outputDir: outputDir,
        outputName: outputName
      });
      
      if (res.success) {
        updateTask(tid, { status: "completed", progress: 100, outputPath: res.outputPath });
        addActivity({ 
          name: file.name, 
          meta: `→ ${outputFormat.toUpperCase()}`, 
          time: "Just now" 
        });
      } else {
        updateTask(tid, { status: "failed", error: res.errorMessage });
      }
    } catch(e) {
      updateTask(tid, { status: "failed", error: String(e) });
    }
  };

  useEffect(() => {
    let unDrop: any, unEnter: any, unLeave: any;
    listen("tauri://drag-drop", (e: any) => {
      setIsDragOver(false);
      const paths = e.payload.paths;
      if (paths && paths.length > 0) {
        setFile({ name: paths[0].split(/[\\/]/).pop(), path: paths[0] });
        setStage(2);
      }
    }).then(u => unDrop = u);
    listen("tauri://drag-enter", () => setIsDragOver(true)).then(u => unEnter = u);
    listen("tauri://drag-leave", () => setIsDragOver(false)).then(u => unLeave = u);
    return () => {
      if (unDrop) unDrop();
      if (unEnter) unEnter();
      if (unLeave) unLeave();
    };
  }, []);

  return (
    <div className="screen active">
      <div className="tool-header">
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          <button className="back-btn" onClick={onBack} style={{ position: 'relative', top: 0 }}>
            <span className="material-symbols-outlined">arrow_back</span>
          </button>
          <div>
            <div className="pt">Image <span className="bl">Converter</span></div>
            <div className="ps" style={{ marginBottom: 0 }}>Transform images between professional formats</div>
          </div>
        </div>
        <StageIndicator current={stage} stages={STAGES} />
      </div>
      
      {stage === 1 && (
        <div className={`panel animate-in ${isDragOver ? "drag-over" : ""}`} style={{ padding: '80px', textAlign: 'center' }}>
          <div className="plabel" style={{ marginBottom: '24px' }}>Stage 1: Select Source Image</div>
          <div className="dz" onClick={pickFile}>
            <span className="material-symbols-outlined" style={{ fontSize: '48px', color: 'var(--accent)', marginBottom: '16px' }}>image</span>
            <div className="dz-main">Drop image or <span className="bl">Browse</span></div>
            <div className="dz-sub">PNG · JPG · WEBP · TIFF · BMP</div>
          </div>
        </div>
      )}

      {stage === 2 && (
        <div className="panel animate-in">
          <div className="plabel">Stage 2: Conversion Details</div>
          
          <div className="srow">
            <div className="slabel">Export Filename</div>
            <div className="sfield">
              <span className="material-symbols-outlined sfield-icon">edit_note</span>
              <input className="sinput" value={outputName} onChange={e => setOutputName(e.target.value)} style={{ flex: 1 }} />
              <div className="sbtn-static">.{outputFormat}</div>
            </div>
          </div>

          <div className="fmt-gl" style={{ marginTop: '32px' }}>Target Format</div>
          <div className="fmtb" style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '8px' }}>
            {formats.map(f => (
              <div key={f} className={`fb ${outputFormat === f ? "active" : ""}`} onClick={() => setOutputFormat(f)}>
                {f.toUpperCase()}
              </div>
            ))}
          </div>

          <div className="srow" style={{ marginTop: '32px' }}>
            <div className="slabel">Save To Folder</div>
            <div className="sfield">
              <span className="material-symbols-outlined sfield-icon">folder_open</span>
              <input className="sinput" value={outputDir || "No folder selected"} readOnly style={{ flex: 1 }} />
              <button className="sbtn" onClick={pickDir}>Browse</button>
            </div>
          </div>

          <div style={{ display: 'flex', gap: '12px', marginTop: '40px' }}>
            <button className="abtn primary" style={{ flex: 1 }} onClick={() => setStage(3)} disabled={!outputDir || !outputName}>
              Confirm Conversion →
            </button>
            <button className="abtn secondary" onClick={() => { setFile(null); setStage(1); }}>Change File</button>
          </div>
        </div>
      )}

      {stage === 3 && (
        <div className="panel animate-in">
           <div className="plabel">Stage 3: {activeTask ? "Engine Active" : "Final Review"}</div>
           {!activeTask ? (
             <div style={{ padding: '20px' }}>
                <div className="info-card" style={{ marginBottom: '32px' }}>
                  <div style={{ fontSize: '13px', color: 'var(--text-secondary)', marginBottom: '12px' }}>Workflow Summary:</div>
                  <div className="list-item" style={{ background: 'none', border: 'none', padding: 0, marginBottom: '8px' }}>
                    <span className="material-symbols-outlined" style={{ color: 'var(--accent)' }}>image</span>
                    <span style={{ fontWeight: 600 }}>{file.name} ➜ {outputName}.{outputFormat}</span>
                  </div>
                  <div className="list-item" style={{ background: 'none', border: 'none', padding: 0 }}>
                    <span className="material-symbols-outlined" style={{ color: 'var(--accent)' }}>category</span>
                    <span style={{ fontWeight: 600 }}>Type: {outputFormat.toUpperCase()} • Dest: {outputDir}</span>
                  </div>
                </div>
                <button className="abtn primary" style={{ width: '100%' }} onClick={run}>⚡ Start Conversion Engine</button>
                <button className="abtn secondary" style={{ width: '100%', marginTop: '12px' }} onClick={() => setStage(2)}>Back to Config</button>
             </div>
           ) : (
             <div style={{ textAlign: 'center', padding: '20px' }}>
                <div style={{ marginBottom: '32px' }}>
                  <div style={{ 
                    width: '80px', 
                    height: '80px', 
                    borderRadius: '50%', 
                    background: 'rgba(91, 79, 232, 0.1)', 
                    display: 'flex', 
                    alignItems: 'center', 
                    justifyContent: 'center',
                    margin: '0 auto 24px'
                  }}>
                    <span className="material-symbols-outlined" style={{ 
                      fontSize: '40px', 
                      color: activeTask.status === "completed" ? 'var(--green)' : activeTask.status === "failed" ? 'var(--red)' : 'var(--accent)',
                      animation: activeTask.status === "processing" ? 'spin 2s linear infinite' : 'none'
                    }}>
                      {activeTask.status === "completed" ? "check_circle" : activeTask.status === "failed" ? "error" : "settings"}
                    </span>
                  </div>
                  <div className="pt">{activeTask.status === "processing" ? "Converting Media..." : activeTask.status === "completed" ? "Success" : "Failed"}</div>
                  <div className="ps">{activeTask.name}</div>
                </div>
                
                <div className="rm-bar-bg" style={{ height: '8px', marginBottom: '32px' }}>
                  <div className="rm-bar-fill rm-cpu-fill" style={{ 
                    width: `${activeTask.progress || 100}%`,
                    animation: activeTask.status === "processing" ? 'pulse 1.5s infinite' : 'none'
                  }} />
                </div>

                {activeTask.status === "completed" && (
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                    <button className="abtn primary" onClick={() => invoke("open_url", { url: activeTask.outputPath }).catch(alert)}>
                      <span className="material-symbols-outlined" style={{ fontSize: '18px', marginRight: '8px' }}>visibility</span>
                      View File
                    </button>
                    <button className="abtn secondary" onClick={() => invoke("open_in_folder", { path: activeTask.outputPath }).catch(alert)}>
                      <span className="material-symbols-outlined" style={{ fontSize: '18px', marginRight: '8px' }}>folder_open</span>
                      Folder
                    </button>
                    <button className="abtn primary bl" style={{ gridColumn: 'span 2', marginTop: '8px' }} onClick={() => updateState({ stage: 1, file: null, outputName: "", activeTaskId: null })}>
                      <span className="material-symbols-outlined" style={{ fontSize: '18px', marginRight: '8px' }}>add_photo_alternate</span>
                      Convert Another
                    </button>
                  </div>
                )}

                {activeTask.status === "failed" && (
                  <>
                    <div className="info-card error" style={{ marginBottom: '24px' }}>
                      <span className="material-symbols-outlined">report</span>
                      <div className="ps">{activeTask.error}</div>
                    </div>
                    <button className="abtn secondary" onClick={() => setActiveTaskId(null)}>Retry Engine</button>
                  </>
                )}

                {activeTask.status === "processing" && (
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                    <button className="abtn primary" onClick={() => { setStage(1); setFile(null); setActiveTaskId(null); }}>Process Another</button>
                    <button className="abtn secondary" onClick={() => onBack()}>Run in Background</button>
                  </div>
                )}
             </div>
           )}
        </div>
      )}
    </div>
  );
}

function MergePDFScreen({ onBack, addTask, updateTask, tasks, state, updateState, deps, onFixDeps }: ToolScreenProps) {
  const { stage, files = [], outputName = "merged_documents", activeTaskId } = state;
  const [outputDir, saveOutputDir] = useSavedPath("mergepdf");
  const [isDragOver, setIsDragOver] = useState(false);

  const setStage = (s: number) => updateState({ stage: s });
  const setFiles = (f: any[]) => updateState({ files: f });
  const setOutputName = (n: string) => updateState({ outputName: n });
  const setActiveTaskId = (id: string | null) => updateState({ activeTaskId: id });

  const activeTask = tasks.find((t: ProcessTask) => t.id === activeTaskId);

  useEffect(() => {
    if (files.length > 0 && !state.outputName) {
      setOutputName(files[0].name.split('.').slice(0, -1).join('.') + "_merged");
    }
  }, [files]);

  const pickFiles = async () => {
    const selected = await open({ multiple: true, filters: [{ name: 'PDF', extensions: ['pdf'] }] });
    if (selected && Array.isArray(selected)) {
      setFiles(selected.map(s => ({ name: s.split(/[\\/]/).pop(), path: s })));
      setStage(2);
    }
  };

  const pickDir = async () => {
    const s = await open({ directory: true, multiple: false });
    if (s && !Array.isArray(s)) saveOutputDir(s);
  };

  const run = async () => {
    if (!files.length || !outputDir) return;
    setStage(3);
    
    const tid = addTask({
      name: outputName + ".pdf",
      tool: "PDF Merger",
      inputPath: files[0].path,
    });
    setActiveTaskId(tid);

    try {
      const outPath = `${outputDir}\\${outputName}.pdf`;
      const res = await invoke<TaskResult>("merge_pdfs", { 
        inputPaths: files.map((f: any) => f.path), 
        outputPath: outPath 
      });
      
      if (res.success) {
        updateTask(tid, { status: "completed", progress: 100, outputPath: res.outputPath });
        addActivity({ 
          name: outputName + ".pdf", 
          meta: `${files.length} PDFs merged`, 
          time: "Just now" 
        });
      } else {
        updateTask(tid, { status: "failed", error: res.errorMessage });
      }
    } catch(e) {
      updateTask(tid, { status: "failed", error: String(e) });
    }
  };

  useEffect(() => {
    let unDrop: any, unEnter: any, unLeave: any;
    listen("tauri://drag-drop", (e: any) => {
      setIsDragOver(false);
      const paths = e.payload.paths;
      if (paths && paths.length > 0) {
        setFiles(paths.map((p: any) => ({ name: p.split(/[\\/]/).pop(), path: p })));
        setStage(2);
      }
    }).then(u => unDrop = u);
    listen("tauri://drag-enter", () => setIsDragOver(true)).then(u => unEnter = u);
    listen("tauri://drag-leave", () => setIsDragOver(false)).then(u => unLeave = u);
    return () => {
      if (unDrop) unDrop();
      if (unEnter) unEnter();
      if (unLeave) unLeave();
    };
  }, []);

  return (
    <div className="screen active">
      <div className="tool-header">
        <div className="tool-header-info">
          <button className="back-btn" onClick={onBack}>
            <span className="material-symbols-outlined">arrow_back</span>
          </button>
          <div className="tool-title-group">
            <div className="pt">PDF <span className="bl">Merger</span></div>
            <div className="ps">Combine multiple PDF files into one high-quality document</div>
          </div>
        </div>
        <StageIndicator current={stage} stages={STAGES} />
      </div>

      {stage === 1 && (
        <div className={`panel animate-in ${isDragOver ? "drag-over" : ""}`} style={{ padding: '80px 40px', textAlign: 'center' }}>
          <div className="plabel">Stage 1: Select PDFs</div>
          <div className="dz" onClick={pickFiles}>
            <div className="dz-icon">
              <span className="material-symbols-outlined">merge_type</span>
            </div>
            <div className="dz-main">{files.length > 0 ? `${files.length} PDFs selected` : "Drop PDFs or Browse"}</div>
            <div className="dz-sub">Files will be combined in the order chosen</div>
          </div>
          {files.length > 0 && (
            <button className="abtn primary" style={{ marginTop: '32px' }} onClick={() => setStage(2)}>
              <span>Continue to Configuration</span>
              <span className="material-symbols-outlined">arrow_forward</span>
            </button>
          )}
        </div>
      )}

      {stage === 2 && (
        <div className="panel animate-in">
          <div className="plabel">Stage 2: Configuration & Destination</div>
          
          <div className="srow">
            <div className="slabel">Merged Filename</div>
            <div className="sfield">
              <span className="material-symbols-outlined sfield-icon">edit_document</span>
              <input className="sinput" value={outputName} onChange={e => setOutputName(e.target.value)} />
              <div className="sbtn">.pdf</div>
            </div>
          </div>

          <div className="srow" style={{ marginTop: '24px' }}>
            <div className="slabel">Save To Folder</div>
            <div className="sfield">
              <span className="material-symbols-outlined sfield-icon">folder_zip</span>
              <input className="sinput" value={outputDir || "No folder selected"} readOnly />
              <button className="sbtn" onClick={pickDir}>Browse</button>
            </div>
          </div>

          <div className="info-card" style={{ marginTop: '32px' }}>
            <span className="material-symbols-outlined">description</span>
            <div style={{ flex: 1 }}>
              <div className="ps" style={{ fontWeight: '600', color: 'var(--text-primary)' }}>Files to Merge ({files.length})</div>
              <div style={{ maxHeight: '120px', overflowY: 'auto', marginTop: '8px' }}>
                {files.map((f, i) => (
                  <div key={i} style={{ fontSize: '12px', color: 'var(--text-muted)', marginBottom: '4px', display: 'flex', gap: '8px' }}>
                    <span>{i + 1}.</span>
                    <span style={{ whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{f.name}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>

          <div style={{ display: 'flex', gap: '12px', marginTop: '32px' }}>
            <button className="abtn primary" onClick={() => setStage(3)} disabled={!outputDir || !outputName || files.length < 2} style={{ flex: 1 }}>
              <span>Review & Merge</span>
              <span className="material-symbols-outlined">shutter_speed</span>
            </button>
            <button className="abtn secondary" onClick={() => { setFiles([]); setStage(1); }}>Change Files</button>
          </div>
        </div>
      )}

      {stage === 3 && (
        <div className="panel scrollable animate-in">
           <div className="plabel">Stage 3: {activeTask ? "Processing" : "Ready"}</div>
           {!activeTask ? (
             <div style={{ padding: '20px' }}>
                <div className="info-card" style={{ marginBottom: '32px' }}>
                  <div className="info-card-header">
                    <span className="material-symbols-outlined">summary</span>
                    <div style={{ fontSize: '13px', fontWeight: '600' }}>Merge Summary</div>
                  </div>
                  <div style={{ padding: '12px 0 0 32px' }}>
                    <div style={{ fontSize: '14px', fontWeight: '700', marginBottom: '4px' }}>Combine {files.length} PDFs</div>
                    <div style={{ fontSize: '12px', color: 'var(--text-muted)' }}>Output: {outputName}.pdf</div>
                    <div style={{ fontSize: '12px', color: 'var(--text-muted)' }}>Location: {outputDir}</div>
                  </div>
                </div>
                <button className="abtn primary" onClick={run}>
                  <span className="material-symbols-outlined">bolt</span>
                  <span>Start PDF Merge Engine</span>
                </button>
                <button className="abtn secondary" style={{ marginTop: '12px' }} onClick={() => setStage(2)}>Back to Config</button>
             </div>
           ) : (
             <div style={{ textAlign: 'center', padding: '40px 20px' }}>
                <div className={`status-icon-large ${activeTask.status}`}>
                  <span className="material-symbols-outlined">
                    {activeTask.status === "processing" ? "settings" : activeTask.status === "completed" ? "check_circle" : "error"}
                {activeTask.status === "failed" && (
                  <div className="info-card error" style={{ marginBottom: '24px' }}>
                    <span className="material-symbols-outlined">error</span>
                    <div className="ps">{activeTask.error}</div>
                  </div>
                )}
                {activeTask.status === "failed" && <button className="abtn secondary" onClick={() => setActiveTaskId(null)}>Retry</button>}
                {activeTask.status === "processing" && (
                   <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                    <button className="abtn primary" onClick={() => { setStage(1); setFiles([]); setActiveTaskId(null); }}>
                      <span className="material-symbols-outlined">close</span>
                      <span>Abort Merge</span>
                    </button>
                    <button className="abtn secondary" onClick={() => onBack()}>Run in Background</button>
                  </div>
                )}
             </div>
           )}
        </div>
      )}
    </div>
  );
}

function SplitPDFScreen({ onBack, addTask, updateTask, tasks, state, updateState, deps, onFixDeps }: ToolScreenProps) {
  const { stage, file, mode = "count", value = "5", activeTaskId, outputName = "" } = state;
  const [outputDir, saveOutputDir] = useSavedPath("splitpdf");
  const [isDragOver, setIsDragOver] = useState(false);

  const setStage = (s: number) => updateState({ stage: s });
  const setFile = (f: any) => updateState({ file: f });
  const setMode = (m: "count" | "ranges") => updateState({ mode: m });
  const setValue = (v: string) => updateState({ value: v });
  const setActiveTaskId = (id: string | null) => updateState({ activeTaskId: id });
  const setOutputName = (n: string) => updateState({ outputName: n });

  const activeTask = tasks.find((t: ProcessTask) => t.id === activeTaskId);

  useEffect(() => {
    if (file && !state.outputName) {
      setOutputName(file.name.split('.').slice(0, -1).join('.') + "_split");
    }
  }, [file]);

  useEffect(() => {
    let unDrop: any, unEnter: any, unLeave: any;
    listen("tauri://drag-drop", (e: any) => {
      setIsDragOver(false);
      const paths = e.payload.paths;
      if (paths && paths.length > 0) {
        setFile({ name: paths[0].split(/[\\/]/).pop(), path: paths[0] });
        setStage(2);
      }
    }).then(u => unDrop = u);
    listen("tauri://drag-enter", () => setIsDragOver(true)).then(u => unEnter = u);
    listen("tauri://drag-leave", () => setIsDragOver(false)).then(u => unLeave = u);
    return () => {
      if (unDrop) unDrop();
      if (unEnter) unEnter();
      if (unLeave) unLeave();
    };
  }, []);

  const pickFile = async () => {
    const s = await open({ multiple: false, filters: [{ name: "PDF", extensions: ["pdf"] }] });
    if (s && !Array.isArray(s)) {
      setFile({ name: s.split(/[\\/]/).pop(), path: s });
      setStage(2);
    }
  };

  const pickDir = async () => {
    const s = await open({ directory: true, multiple: false });
    if (s && !Array.isArray(s)) saveOutputDir(s);
  };

  const run = async () => {
    if (!file || !outputDir) return;
    setStage(3);
    
    const tid = addTask({
      name: `Split: ${file.name}`,
      tool: "PDF Splitter",
      inputPath: file.path,
    });
    setActiveTaskId(tid);

    try {
      const res = await invoke<TaskResult>("split_pdf", { 
        inputPath: file.path, 
        outputDir: outputDir, 
        mode, 
        value,
        outputPrefix: outputName || file.name.split('.').slice(0, -1).join('.')
      });
      
      if (res.success) {
        updateTask(tid, { status: "completed", progress: 100, outputPath: res.outputPath });
        addActivity({ name: file.name, meta: `Split by ${mode}`, time: "Just now" });
      } else {
        updateTask(tid, { status: "failed", error: res.errorMessage });
      }
    } catch(e) {
      updateTask(tid, { status: "failed", error: String(e) });
    }
  };

  return (
    <div className="screen active">
      <div className="tool-header">
        <div className="tool-header-info">
          <button className="back-btn" onClick={onBack}>
            <span className="material-symbols-outlined">arrow_back</span>
          </button>
          <div className="tool-title-group">
            <div className="pt">PDF <span className="bl">Splitter</span></div>
            <div className="ps">Extract pages or break documents into segments</div>
          </div>
        </div>
        <StageIndicator current={stage} stages={STAGES} />
      </div>

      {stage === 1 && (
        <div className={`panel animate-in ${isDragOver ? "drag-over" : ""}`} style={{ padding: '80px 40px', textAlign: 'center' }}>
          <div className="plabel">Stage 1: Select PDF Source</div>
          <div className="dz" onClick={pickFile}>
            <div className="dz-icon">
              <span className="material-symbols-outlined">content_cut</span>
            </div>
            <div className="dz-main">{file ? file.name : "Drop PDF or Browse"}</div>
            <div className="dz-sub">Single PDF file transformation</div>
          </div>
          {file && (
            <button className="abtn primary" style={{ marginTop: '32px' }} onClick={() => setStage(2)}>
              <span>Continue to Split Rules</span>
              <span className="material-symbols-outlined">arrow_forward</span>
            </button>
          )}
        </div>
      )}

      {stage === 2 && (
        <div className="panel animate-in">
          <div className="plabel">Stage 2: Configuration & Rules</div>
          
          <div className="two-col" style={{ gap: '24px', marginBottom: '32px' }}>
            <div>
              <div className="slabel" style={{ marginBottom: '12px' }}>Split Strategy</div>
              <div className="fmtb" style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '8px' }}>
                <div className={`fb ${mode === "count" ? "active" : ""}`} onClick={() => setMode("count")}>
                  <span className="material-symbols-outlined">dynamic_feed</span>
                  <span>By Count</span>
                </div>
                <div className={`fb ${mode === "ranges" ? "active" : ""}`} onClick={() => setMode("ranges")}>
                  <span className="material-symbols-outlined">auto_stories</span>
                  <span>By Ranges</span>
                </div>
              </div>
            </div>
            <div>
              <div className="slabel" style={{ marginBottom: '12px' }}>{mode === "count" ? "Pages per file" : "Page ranges (e.g. 1-3,5)"}</div>
              <div className="sfield">
                <span className="material-symbols-outlined sfield-icon">settings_input_component</span>
                <input className="sinput" value={value} onChange={e => setValue(e.target.value)} />
              </div>
            </div>
          </div>

          <div className="srow">
            <div className="slabel">Output Prefix</div>
            <div className="sfield">
              <span className="material-symbols-outlined sfield-icon">edit_note</span>
              <input className="sinput" value={outputName} onChange={e => setOutputName(e.target.value)} />
              <div className="sbtn" style={{ fontSize: '11px', opacity: 0.7 }}>_split_X.pdf</div>
            </div>
          </div>

          <div className="srow" style={{ marginTop: '24px' }}>
            <div className="slabel">Save To Folder</div>
            <div className="sfield">
              <span className="material-symbols-outlined sfield-icon">folder_special</span>
              <input className="sinput" value={outputDir || "No folder selected"} readOnly />
              <button className="sbtn" onClick={pickDir}>Browse</button>
            </div>
          </div>

          <div style={{ display: 'flex', gap: '12px', marginTop: '40px' }}>
            <button className="abtn primary" onClick={() => setStage(3)} disabled={!outputDir || !outputName} style={{ flex: 1 }}>
              <span>Review & Split</span>
              <span className="material-symbols-outlined">shutter_speed</span>
            </button>
            <button className="abtn secondary" onClick={() => { setFile(null); setStage(1); }}>Change File</button>
          </div>
        </div>
      )}

      {stage === 3 && (
        <div className="panel scrollable animate-in">
           <div className="plabel">Stage 3: {activeTask ? "Processing" : "Ready"}</div>
           {!activeTask ? (
             <div style={{ padding: '20px' }}>
                <div className="info-card" style={{ marginBottom: '32px' }}>
                  <div className="info-card-header">
                    <span className="material-symbols-outlined">summarize</span>
                    <div style={{ fontSize: '13px', fontWeight: '600' }}>Workflow Summary</div>
                  </div>
                  <div style={{ padding: '12px 0 0 32px' }}>
                    <div style={{ fontSize: '14px', fontWeight: '700', marginBottom: '4px' }}>Splitting "{file.name}"</div>
                    <div style={{ fontSize: '12px', color: 'var(--text-muted)' }}>Strategy: {mode === 'count' ? `Every ${value} pages` : `Ranges: ${value}`}</div>
                    <div style={{ fontSize: '12px', color: 'var(--text-muted)' }}>Destination: {outputDir}</div>
                  </div>
                </div>
                <button className="abtn primary" onClick={run}>
                  <span className="material-symbols-outlined">bolt</span>
                  <span>Execute Split Order</span>
                </button>
                <button className="abtn secondary" style={{ marginTop: '12px' }} onClick={() => setStage(2)}>Back to Config</button>
             </div>
           ) : (
             <div style={{ textAlign: 'center', padding: '40px 20px' }}>
                <div className={`status-icon-large ${activeTask.status}`}>
                  <span className="material-symbols-outlined">
                    {activeTask.status === "processing" ? "settings" : activeTask.status === "completed" ? "check_circle" : "error"}
                  </span>
                </div>
                <div className="pt">{activeTask.status === "processing" ? "Splitting Document..." : activeTask.status === "completed" ? "Success" : "Failed"}</div>
                <div className="ps" style={{ marginBottom: '32px' }}>{activeTask.name}</div>
                
                <div className="rm-bar-bg" style={{ height: '8px', marginBottom: '32px' }}>
                  <div className="rm-bar-fill rm-cpu-fill" style={{ 
                    width: `${activeTask.progress || 100}%`,
                    animation: activeTask.status === "processing" ? 'pulse 1.5s infinite' : 'none'
                  }} />
                </div>

                {activeTask.status === "completed" && (
                  <div style={{ display: 'flex', gap: '12px', justifyContent: 'center' }}>
                    <button className="abtn primary" onClick={() => invoke("open_in_folder", { path: outputDir }).catch(alert)}>
                      <span className="material-symbols-outlined">folder_open</span>
                      <span>Open Folder</span>
                    </button>
                    <button className="abtn primary bl" onClick={() => updateState({ stage: 1, file: null, outputName: "", activeTaskId: null })}>
                      <span className="material-symbols-outlined">refresh</span>
                      <span>Split More</span>
                    </button>
                  </div>
                )}
                {activeTask.status === "failed" && (
                  <div className="info-card error" style={{ marginBottom: '24px' }}>
                    <span className="material-symbols-outlined">error</span>
                    <div className="ps">{activeTask.error}</div>
                  </div>
                )}
                {activeTask.status === "failed" && <button className="abtn secondary" onClick={() => setActiveTaskId(null)}>Retry</button>}
                {activeTask.status === "processing" && (
                   <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                    <button className="abtn primary" onClick={() => { setStage(1); setFile(null); setActiveTaskId(null); }}>
                      <span className="material-symbols-outlined">close</span>
                      <span>Abort Process</span>
                    </button>
                    <button className="abtn secondary" onClick={() => onBack()}>Run in Background</button>
                  </div>
                )}
             </div>
           )}
        </div>
      )}
    </div>
  );
}

function GreyscalePDFScreen({ onBack, addTask, updateTask, tasks, state, updateState, deps, onFixDeps }: ToolScreenProps) {
  const { stage, file, outputName, activeTaskId } = state;
  const [outputDir, saveOutputDir] = useSavedPath("greyscalepdf");
  const [isDragOver, setIsDragOver] = useState(false);

  const setStage = (s: number) => updateState({ stage: s });
  const setFile = (f: any) => updateState({ file: f });
  const setOutputName = (n: string) => updateState({ outputName: n });
  const setActiveTaskId = (id: string | null) => updateState({ activeTaskId: id });

  const activeTask = tasks.find((t: ProcessTask) => t.id === activeTaskId);

  useEffect(() => {
    if (file && !outputName) {
      setOutputName(file.name.replace(".pdf", "") + "_greyscale");
    }
  }, [file]);

  useEffect(() => {
    let unDrop: any, unEnter: any, unLeave: any;
    listen("tauri://drag-drop", (e: any) => {
      setIsDragOver(false);
      const paths = e.payload.paths;
      if (paths && paths.length > 0) {
        setFile({ name: paths[0].split(/[\\/]/).pop(), path: paths[0] });
        setStage(2);
      }
    }).then(u => unDrop = u);
    listen("tauri://drag-enter", () => setIsDragOver(true)).then(u => unEnter = u);
    listen("tauri://drag-leave", () => setIsDragOver(false)).then(u => unLeave = u);
    return () => {
      if (unDrop) unDrop();
      if (unEnter) unEnter();
      if (unLeave) unLeave();
    };
  }, []);

  const pickFile = async () => {
    const s = await open({ multiple: false, filters: [{ name: "PDF", extensions: ["pdf"] }] });
    if (s && !Array.isArray(s)) {
      setFile({ name: s.split(/[\\/]/).pop(), path: s });
      setStage(2);
    }
  };

  const pickDir = async () => {
    const s = await open({ directory: true, multiple: false });
    if (s && !Array.isArray(s)) saveOutputDir(s);
  };

  const handleStartProcess = async () => {
    if (!file || !outputDir) return;
    setStage(3);
    
    const tid = addTask({
      name: outputName + ".pdf",
      tool: "Greyscale PDF",
      inputPath: file.path,
    });
    setActiveTaskId(tid);

    const outPath = outputDir + "\\" + outputName + ".pdf";
     try {
       const res: any = await invoke("greyscale_pdf", { 
         inputPath: file.path, 
         outputPath: outPath 
       });
       
       if (res.success) {
         updateTask(tid, { status: "completed", progress: 100, outputPath: res.outputPath });
         addActivity({ 
           name: file.name, 
           meta: "Greyscale Conversion", 
           time: "Just now" 
         });
       } else {
         updateTask(tid, { status: "failed", error: res.errorMessage });
       }
    } catch(e) {
      updateTask(tid, { status: "failed", error: String(e) });
    }
  };

  return (
    <div className="screen active">
      <div className="tool-header">
        <div className="tool-header-info">
          <button className="back-btn" onClick={onBack}>
            <span className="material-symbols-outlined">arrow_back</span>
          </button>
          <div className="tool-title-group">
            <div className="pt">Greyscale <span className="bl">PDF</span></div>
            <div className="ps">Professional black & white conversion for documents</div>
          </div>
        </div>
        <StageIndicator current={stage} stages={STAGES} />
      </div>
      
      {stage === 1 && (
        <div className={`panel animate-in ${isDragOver ? "drag-over" : ""}`} style={{ padding: '80px 40px', textAlign: 'center' }}>
          <div className="plabel">Stage 1: Select PDF Source</div>
          <div className="dz" onClick={pickFile}>
            <div className="dz-icon">
              <span className="material-symbols-outlined">contrast</span>
            </div>
            <div className="dz-main">{file ? file.name : "Drop PDF or Browse"}</div>
            <div className="dz-sub">High-fidelity grayscale optimization</div>
          </div>
          {file && (
            <button className="abtn primary" style={{ marginTop: '32px' }} onClick={() => setStage(2)}>
              <span>Continue to Output Config</span>
              <span className="material-symbols-outlined">arrow_forward</span>
            </button>
          )}
        </div>
      )}

      {stage === 2 && (
        <div className="panel animate-in">
          <div className="plabel">Stage 2: Output Configuration</div>
          
          <div className="srow">
            <div className="slabel">Export Filename</div>
            <div className="sfield">
              <span className="material-symbols-outlined sfield-icon">edit</span>
              <input className="sinput" value={outputName} onChange={e => setOutputName(e.target.value)} />
              <div className="sbtn">.pdf</div>
            </div>
          </div>

          <div className="srow" style={{ marginTop: '24px' }}>
            <div className="slabel">Save To Folder</div>
            <div className="sfield">
              <span className="material-symbols-outlined sfield-icon">folder</span>
              <input className="sinput" value={outputDir || "No folder selected"} readOnly />
              <button className="sbtn" onClick={pickDir}>Browse</button>
            </div>
          </div>

          <div className="info-card" style={{ marginTop: '32px' }}>
            <span className="material-symbols-outlined">info</span>
            <div className="ps">Formatica will process "{file?.name}" and save the greyscale version. Professional conversion ensures text remains sharp while removing all color data.</div>
          </div>

          <div style={{ display: 'flex', gap: '12px', marginTop: '32px' }}>
            <button className="abtn primary" onClick={() => setStage(3)} disabled={!outputDir || !outputName} style={{ flex: 1 }}>
              <span>Review & Process</span>
              <span className="material-symbols-outlined">shutter_speed</span>
            </button>
            <button className="abtn secondary" onClick={() => setStage(1)}>Back</button>
          </div>
        </div>
      )}

      {stage === 3 && (
        <div className="panel scrollable animate-in">
           <div className="plabel">Stage 3: {activeTask ? "Processing" : "Ready"}</div>
           {!activeTask ? (
             <div style={{ padding: '20px' }}>
                <div className="info-card" style={{ marginBottom: '32px' }}>
                  <div className="info-card-header">
                    <span className="material-symbols-outlined">summary</span>
                    <div style={{ fontSize: '13px', fontWeight: '600' }}>Process Summary</div>
                  </div>
                  <div style={{ padding: '12px 0 0 32px' }}>
                    <div style={{ fontSize: '14px', fontWeight: '700', marginBottom: '4px' }}>Greyscale Conversion: {file?.name}</div>
                    <div style={{ fontSize: '12px', color: 'var(--text-muted)' }}>Target: {outputName}.pdf</div>
                    <div style={{ fontSize: '12px', color: 'var(--text-muted)' }}>Destination: {outputDir}</div>
                  </div>
                </div>
                <button className="abtn primary" onClick={handleStartProcess}>
                  <span className="material-symbols-outlined">bolt</span>
                  <span>Start Conversion</span>
                </button>
                <button className="abtn secondary" style={{ marginTop: '12px' }} onClick={() => setStage(2)}>Back to Config</button>
             </div>
           ) : (
             <div style={{ textAlign: 'center', padding: '40px 20px' }}>
                <div className={`status-icon-large ${activeTask.status}`}>
                  <span className="material-symbols-outlined">
                    {activeTask.status === "processing" ? "settings" : activeTask.status === "completed" ? "check_circle" : "error"}
                  </span>
                </div>
                <div className="pt">{activeTask.status === "processing" ? "Converting..." : activeTask.status === "completed" ? "Success" : "Failed"}</div>
                <div className="ps" style={{ marginBottom: '32px' }}>{activeTask.name}</div>
                
                <div className="rm-bar-bg" style={{ height: '8px', marginBottom: '32px' }}>
                  <div className="rm-bar-fill rm-cpu-fill" style={{ 
                    width: `${activeTask.progress || 100}%`,
                    animation: activeTask.status === "processing" ? 'pulse 1.5s infinite' : 'none'
                  }} />
                </div>

                {activeTask.status === "completed" && (
                  <div style={{ display: 'flex', gap: '12px', justifyContent: 'center' }}>
                    <button className="abtn primary" onClick={() => invoke("open_url", { url: activeTask.outputPath }).catch(alert)}>
                      <span className="material-symbols-outlined">file_open</span>
                      <span>Open File</span>
                    </button>
                    <button className="abtn secondary" onClick={() => invoke("open_in_folder", { path: activeTask.outputPath }).catch(alert)}>
                      <span className="material-symbols-outlined">folder</span>
                      <span>Container</span>
                    </button>
                    <button className="abtn primary bl" onClick={() => updateState({ stage: 1, file: null, outputName: "", activeTaskId: null })}>
                      <span className="material-symbols-outlined">refresh</span>
                      <span>Convert More</span>
                    </button>
                  </div>
                )}
                {activeTask.status === "failed" && (
                    <div className="info-card error" style={{ marginBottom: '24px' }}>
                      <span className="material-symbols-outlined">error</span>
                      <div className="ps">{activeTask.error}</div>
                    </div>
                )}
                {activeTask.status === "failed" && <button className="abtn secondary" onClick={() => { setActiveTaskId(null); setStage(2); }}>Retry Setup</button>}
                {activeTask.status === "processing" && (
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                    <button className="abtn primary" onClick={() => { setStage(1); setFile(null); setActiveTaskId(null); }}>
                      <span className="material-symbols-outlined">close</span>
                      <span>Abort Process</span>
                    </button>
                    <button className="abtn secondary" onClick={() => onBack()}>Run in Background</button>
                  </div>
                )}
             </div>
           )}
        </div>
      )}
    </div>
  );
}

function OnboardingScreen({ onComplete }: { onComplete: () => void }) {
  const [step, setStep] = useState(1);
  const steps = [
    {
      icon: "🛡️",
      title: "Privacy First",
      body: "All document conversions and media processing happen entirely on your device. Your files never leave your computer."
    },
    {
      icon: "⚡",
      title: "GPU Accelerated",
      body: "Video compression uses your GPU automatically for 5-10x faster processing. Falls back to CPU if needed."
    },
    {
      icon: "🚀",
      title: "You're All Set",
      body: "10 powerful tools in one app — welcome to Formatica."
    }
  ];
  const current = steps[step - 1];

  return (
    <div style={{
      position: "fixed", inset: 0, background: "var(--bg-base)",
      display: "flex", alignItems: "center", justifyContent: "center",
      zIndex: 1000, flexDirection: "column", gap: "24px", padding: "40px"
    }}>
      <div style={{textAlign:"center", maxWidth:"400px"}}>
        <div style={{fontSize:"64px", marginBottom:"20px"}}>{current.icon}</div>
        <div style={{fontFamily:"inherit", fontSize:"24px", fontWeight:"700",
          color:"var(--text-primary)", marginBottom:"12px"}}>{current.title}</div>
        <div style={{fontSize:"15px", color:"var(--text-secondary)",
          lineHeight:"1.6"}}>{current.body}</div>
      </div>
      <div style={{display:"flex", gap:"6px", margin:"8px 0"}}>
        {steps.map((_, i) => (
          <div key={i} style={{
            width: i+1===step ? "24px" : "8px", height:"8px",
            borderRadius:"4px", background: i+1===step ? "var(--accent)" : "var(--border)",
            transition:"all 0.3s ease"
          }} />
        ))}
      </div>
      <button className="btn-primary" style={{width:"200px", padding:"13px"}}
        onClick={() => step < 3 ? setStep(s => s+1) : onComplete()}>
        {step < 3 ? "Next →" : "Get Started"}
      </button>
      {step > 1 && (
        <button className="back-btn" onClick={() => setStep(s => s-1)}>← Back</button>
      )}
    </div>
  );
}

function SetupScreen({ onComplete }: { onComplete: () => void }) {
  const [steps, setSteps] = useState([
    { id: "python",      label: "Python Runtime",     subtitle: "Core Engine Host", status: "waiting" as "waiting"|"active"|"done"|"error", percent: 0 },
    { id: "ytdlp",       label: "Media Downloader",   subtitle: "yt-dlp",       status: "waiting" as "waiting"|"active"|"done"|"error", percent: 0 },
    { id: "ffmpeg",      label: "Media Engine",       subtitle: "FFmpeg",       status: "waiting" as "waiting"|"active"|"done"|"error", percent: 0 },
    { id: "tesseract",   label: "OCR Engine",        subtitle: "Tesseract",    status: "waiting" as "waiting"|"active"|"done"|"error", percent: 0 },
    { id: "libreoffice", label: "Document Engine",     subtitle: "LibreOffice",  status: "waiting" as "waiting"|"active"|"done"|"error", percent: 0 },
  ]);
  const [currentMsg, setCurrentMsg] = useState("Preparing Formatica...");
  const [allDone, setAllDone] = useState(false);
  const [hasError, setHasError] = useState(false);

  function updateStep(id: string, patch: any) {
    setSteps(prev => prev.map(s => s.id === id ? { ...s, ...patch } : s));
  }

  useEffect(() => {
    // Listen for progress events from Rust
    const unlisten = listen("setup_progress", (event: any) => {
      const { step, status, message, percent } = event.payload;
      if (message) setCurrentMsg(message);
      
      const statusMap = {
        "done": "done",
        "downloading": "active",
        "installing": "active",
        "extracting": "active",
        "error": "error"
      } as const;

      updateStep(step, {
        status: statusMap[status as keyof typeof statusMap] || "active",
        percent
      });
    });

    async function runSetup() {
      // Get current status to see what's already installed
      const status: any = await invoke("get_setup_status");
      
      const checkAndInstall = async (id: string, isInstalled: boolean, installCmd: string) => {
        if (isInstalled) {
          updateStep(id, { status: "done", percent: 100 });
          return true;
        }
        
        updateStep(id, { status: "active", percent: 0 });
        try {
          const r: any = await invoke(installCmd);
          if (r.success) {
            updateStep(id, { status: "done", percent: 100 });
            return true;
          } else {
            updateStep(id, { status: "error", percent: 0 });
            setHasError(true);
            return false;
          }
        } catch (e) {
          updateStep(id, { status: "error", percent: 0 });
          setHasError(true);
          return false;
        }
      };

      // Step 0: Python Runtime (Check only)
      if (status.python) {
        updateStep("python", { status: "done", percent: 100 });
      } else {
        updateStep("python", { status: "error", percent: 0 });
        setHasError(true);
        setCurrentMsg("Python not found. Please install Python to continue.");
      }

      // Step 1: yt-dlp
      await checkAndInstall("ytdlp", status.ytdlp, "install_ytdlp");

      // Step 2: FFmpeg
      await checkAndInstall("ffmpeg", status.ffmpeg, "install_ffmpeg");

      // Step 3: Tesseract
      await checkAndInstall("tesseract", status.tesseract, "install_tesseract");

      // Step 4: LibreOffice
      await checkAndInstall("libreoffice", status.libreoffice, "install_libreoffice");

      // Final Step: Install Python deps if python found
      if (status.python) {
        setCurrentMsg("Updating Python dependencies...");
        try {
          await invoke("check_python_deps");
        } catch (e) {
          console.error("Dependency check failed:", e);
          // Don't block the UI for dependency issues - handled as non-critical
        }
      }

      setAllDone(true);
      setCurrentMsg(hasError ? "Setup completed with some issues." : "Formatica is ready!");
    }

    runSetup();
    return () => { unlisten.then(f => f()); };
  }, []);

  return (
    <div style={{
      position: "fixed", inset: 0,
      background: "var(--bg-base)",
      display: "flex", alignItems: "center", justifyContent: "center",
      zIndex: 1000, flexDirection: "column", gap: "0", padding: "40px"
    }}>
      {/* Logo */}
      <div style={{
        width: "64px", height: "64px",
        background: "linear-gradient(135deg, #4F6BF4, #7c3aed)",
        borderRadius: "16px",
        display: "flex", alignItems: "center", justifyContent: "center",
        fontSize: "28px", fontWeight: "800", color: "white",
        marginBottom: "24px",
        boxShadow: "0 8px 32px rgba(79,107,244,0.3)"
      }}>F</div>

      <div style={{ fontSize: "22px", fontWeight: "700", color: "var(--text-primary)", marginBottom: "8px" }}>
        Setting up Formatica
      </div>
      <div style={{ fontSize: "13px", color: "var(--text-muted)", marginBottom: "40px", textAlign: "center" }}>
        This only happens once. Please keep the app open.
      </div>

      {/* Step cards */}
      <div style={{ width: "100%", maxWidth: "380px", display: "flex", flexDirection: "column", gap: "12px", marginBottom: "32px" }}>
        {steps.map(step => (
          <div key={step.id} style={{
            background: "var(--bg-card)",
            border: `1px solid ${step.status === "active" ? "rgba(79,107,244,0.4)" : step.status === "done" ? "rgba(16,185,129,0.3)" : step.status === "error" ? "rgba(239,68,68,0.3)" : "var(--border)"}`,
            borderRadius: "12px",
            padding: "14px 16px",
            transition: "all 0.3s ease"
          }}>
            <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: step.status === "active" ? "10px" : "0" }}>
              <div>
                <div style={{ fontSize: "13px", fontWeight: "600", color: "var(--text-primary)" }}>{step.label}</div>
                <div style={{ fontSize: "11px", color: "var(--text-muted)" }}>{step.subtitle}</div>
              </div>
              <div style={{ fontSize: "18px" }}>
                {step.status === "waiting" && "⏳"}
                {step.status === "active"  && "⚡"}
                {step.status === "done"    && "✅"}
                {step.status === "error"   && "⚠️"}
              </div>
            </div>
            {step.status === "active" && (
              <div style={{ height: "3px", background: "var(--border)", borderRadius: "2px", overflow: "hidden" }}>
                <div style={{
                  height: "100%",
                  background: "linear-gradient(90deg, #4F6BF4, #7c3aed)",
                  borderRadius: "2px",
                  boxShadow: "0 0 8px rgba(79,107,244,0.5)",
                  animation: "indeterminate 1.4s ease infinite",
                  width: "40%"
                }} />
              </div>
            )}
          </div>
        ))}
      </div>

      {/* Current message */}
      <div style={{ fontSize: "12px", color: "var(--text-muted)", marginBottom: "24px", textAlign: "center", minHeight: "20px" }}>
        {currentMsg}
      </div>

      {/* Done button */}
      {allDone && (
        <button className="btn-primary" style={{ width: "200px", padding: "13px", animation: "fadeUp 0.4s ease both" }}
          onClick={onComplete}>
          {hasError ? "Continue Anyway →" : "Launch Formatica →"}
        </button>
      )}

      {allDone && hasError && (
        <div style={{ marginTop: "12px", fontSize: "11px", color: "var(--text-muted)", textAlign: "center", maxWidth: "340px" }}>
          Some components couldn't install automatically. You can retry later using the ⚡ Fix Now button in the app.
        </div>
      )}
    </div>
  );
}

function OCRScreen({ onBack, addTask, updateTask, tasks, state, updateState, deps, onFixDeps }: ToolScreenProps) {
  const { stage, file, outputName, outputFormat = "pdf", language = "eng", ocrMode = "fast", activeTaskId } = state;
  const [outputDir, saveOutputDir] = useSavedPath("ocr");
  const [isDragOver, setIsDragOver] = useState(false);
  const isEngineReady = deps.find((d: DepStatus) => d.name === "tesseract")?.installed ?? true;

  const setStage = (s: number) => updateState({ stage: s });
  const setFile = (f: any) => updateState({ file: f });
  const setOutputName = (n: string) => updateState({ outputName: n });
  const setLang = (l: string) => updateState({ language: l });
  const setMode = (m: string) => updateState({ ocrMode: m });
  const setActiveTaskId = (id: string | null) => updateState({ activeTaskId: id });

  const activeTask = tasks.find((t: ProcessTask) => t.id === activeTaskId);

  useEffect(() => {
    if (file && !outputName) {
      const base = file.name.split('.').slice(0, -1).join('.');
      setOutputName(`${base}_ocr`);
    }
  }, [file]);

  const pickFile = async () => {
    const selected = await open({ filters: [{ name: 'PDF', extensions: ['pdf'] }] });
    if (selected && !Array.isArray(selected)) {
      setFile({ name: selected.split(/[\\/]/).pop(), path: selected });
      setStage(2);
    }
  };

  const pickDir = async () => {
    const s = await open({ directory: true, multiple: false });
    if (s && !Array.isArray(s)) saveOutputDir(s);
  };

  const handleStartOCR = async () => {
    if (!file || !outputDir) return;
    setStage(3);
    
    const tid = addTask({
      name: `${outputName}.${outputFormat}`,
      tool: "OCR Engine",
      inputPath: file.path,
    });
    setActiveTaskId(tid);

    try {
      const res: any = await invoke("perform_ocr", {
        inputPath: file.path,
        outputFormat: outputFormat,
        outputPath: `${outputDir}\\${outputName}.${outputFormat}`,
        language: language,
        ocrMode: ocrMode
      });
      
      if (res.success) {
        updateTask(tid, { status: "completed", progress: 100, outputPath: res.outputPath });
        addActivity({ 
          name: outputName + "." + outputFormat, 
          meta: "OCR Extraction", 
          time: "Just now" 
        });
      } else {
        updateTask(tid, { status: "failed", error: res.errorMessage });
      }
    } catch(e) {
      updateTask(tid, { status: "failed", error: String(e) });
    }
  };

  useEffect(() => {
    let unDrop: any;
    listen("tauri://drag-drop", (e: any) => {
      setIsDragOver(false);
      const paths = e.payload.paths;
      if (paths && paths.length > 0 && paths[0].toLowerCase().endsWith(".pdf")) {
        setFile({ name: paths[0].split(/[\\/]/).pop(), path: paths[0] });
        setStage(2);
      }
    }).then(u => unDrop = u);
    return () => { if (unDrop) unDrop(); };
  }, []);

  return (
    <div className="screen active">
      <div className="tool-header">
        <div className="tool-header-info">
          <button className="back-btn" onClick={onBack}>
            <span className="material-symbols-outlined">arrow_back</span>
          </button>
          <div className="tool-title-group">
            <div className="pt">OCR <span className="bl">Engine</span></div>
            <div className="ps">Extract searchable text from scanned PDF documents</div>
          </div>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '20px' }}>
          {!isEngineReady && (
            <div className="status-badge error animate-in">
              <span className="material-symbols-outlined" style={{ fontSize: '16px' }}>warning</span>
              <span>Engine Offline</span>
              <button className="sbtn red" onClick={onFixDeps}>Fix Now</button>
            </div>
          )}
          <StageIndicator current={stage} stages={STAGES} />
        </div>
      </div>

      {stage === 1 && (
        <div className={`panel animate-in ${isDragOver ? "drag-over" : ""}`} style={{ padding: '80px 40px', textAlign: 'center' }}>
          <div className="plabel">Stage 1: Select Scanned PDF</div>
          <div className="dz" onClick={pickFile}>
            <div className="dz-icon">
              <span className="material-symbols-outlined">find_in_page</span>
            </div>
            <div className="dz-main">{file ? file.name : "Drop PDF or Browse"}</div>
            <div className="dz-sub">Tesseract OCR Engine • Professional Extraction</div>
          </div>
          {file && (
            <button className="abtn primary" style={{ marginTop: '32px' }} onClick={() => setStage(2)}>
              <span>Continue to Extraction Settings</span>
              <span className="material-symbols-outlined">arrow_forward</span>
            </button>
          )}
        </div>
      )}

      {stage === 2 && (
        <div className="panel animate-in">
          <div className="plabel">Stage 2: Extraction Configuration</div>
          
          <div className="srow">
            <div className="slabel">Export Filename</div>
            <div className="sfield">
              <span className="material-symbols-outlined sfield-icon">edit_note</span>
              <input className="sinput" value={outputName} onChange={e => setOutputName(e.target.value)} />
              <div className="sbtn">.{outputFormat}</div>
            </div>
          </div>

          <div className="two-col" style={{ marginTop: '24px' }}>
            <div>
              <div className="slabel" style={{ marginBottom: '8px' }}>Document Language</div>
              <div className="sfield">
                <span className="material-symbols-outlined sfield-icon">language</span>
                <select className="sinput" value={language} onChange={e => setLang(e.target.value)} style={{ width: '100%', background: 'transparent' }}>
                  <option value="eng">English (Latin)</option>
                  <option value="spa">Spanish</option>
                  <option value="fra">French</option>
                  <option value="deu">German</option>
                  <option value="chi_sim">Chinese (Simple)</option>
                </select>
              </div>
            </div>
            <div>
              <div className="slabel" style={{ marginBottom: '8px' }}>Processing Accuracy</div>
              <div className="fmtb">
                <div className={`fb ${ocrMode === "fast" ? "active" : ""}`} onClick={() => setMode("fast")}>
                  <span className="material-symbols-outlined" style={{ fontSize: '16px' }}>bolt</span>
                  <span>Fast</span>
                </div>
                <div className={`fb ${ocrMode === "best" ? "active" : ""}`} onClick={() => setMode("best")}>
                  <span className="material-symbols-outlined" style={{ fontSize: '16px' }}>high_quality</span>
                  <span>Best</span>
                </div>
              </div>
            </div>
          </div>

          <div className="srow" style={{ marginTop: '24px' }}>
            <div className="slabel">Target Folder</div>
            <div className="sfield">
              <span className="material-symbols-outlined sfield-icon">folder_open</span>
              <input className="sinput" value={outputDir || "No folder selected"} readOnly />
              <button className="sbtn" onClick={pickDir}>Browse</button>
            </div>
          </div>

          <div className="info-card warning" style={{ marginTop: '32px' }}>
            <span className="material-symbols-outlined">info</span>
            <div className="ps">High-accuracy mode requires significantly more CPU and time, but provides better results for handwritten or low-quality scans.</div>
          </div>

          <div style={{ display: 'flex', gap: '12px', marginTop: '32px' }}>
            <button className="abtn primary" onClick={() => setStage(3)} disabled={!outputDir || !outputName || !isEngineReady} style={{ flex: 1 }}>
              <span>Confirm & Initialize</span>
              <span className="material-symbols-outlined">shutter_speed</span>
            </button>
            <button className="abtn secondary" onClick={() => setStage(1)}>Back</button>
          </div>
          {!isEngineReady && <div style={{ fontSize: '11px', color: 'var(--red)', marginTop: '12px', textAlign: 'center' }}>OCR Engine must be installed to process files.</div>}
        </div>
      )}

      {stage === 3 && (
        <div className="panel animate-in">
          <div className="plabel">Stage 3: {activeTask ? "Processing" : "Ready"}</div>
          {!activeTask ? (
            <div style={{ padding: '20px' }}>
              <div className="info-card" style={{ marginBottom: '32px' }}>
                <div className="info-card-header">
                  <span className="material-symbols-outlined">task</span>
                  <div style={{ fontSize: '13px', fontWeight: '600' }}>Extraction Summary</div>
                </div>
                <div style={{ padding: '12px 0 0 32px' }}>
                  <div style={{ fontSize: '14px', fontWeight: '700', marginBottom: '4px' }}>{file.name} ⮕ {outputName}.{outputFormat}</div>
                  <div style={{ fontSize: '12px', color: 'var(--text-muted)' }}>Engine: Tesseract 5.4 Best • Language: {language.toUpperCase()}</div>
                  <div style={{ fontSize: '12px', color: 'var(--text-muted)' }}>Target: {outputDir}</div>
                </div>
              </div>
              <button className="abtn primary" onClick={handleStartOCR}>
                <span className="material-symbols-outlined">bolt</span>
                <span>Run OCR Engine</span>
              </button>
              <button className="abtn secondary" style={{ marginTop: '12px' }} onClick={() => setStage(2)}>Adjust Configuration</button>
            </div>
          ) : (
            <div style={{ textAlign: 'center', padding: '40px 20px' }}>
              <div className={`status-icon-large ${activeTask.status}`}>
                 <span className="material-symbols-outlined">
                   {activeTask.status === "processing" ? "settings" : activeTask.status === "completed" ? "check_circle" : "error"}
                 </span>
              </div>
              <div className="pt">{activeTask.status === "processing" ? "Running OCR..." : activeTask.status === "completed" ? "Success" : "Failed"}</div>
              <div className="ps" style={{ marginBottom: '32px' }}>{activeTask.name}</div>
              
              <div className="rm-bar-bg" style={{ height: '8px', marginBottom: '32px' }}>
                <div className="rm-bar-fill rm-cpu-fill" style={{ 
                  width: `${activeTask.progress || 100}%`,
                  animation: activeTask.status === "processing" ? 'pulse 1.5s infinite' : 'none'
                }} />
              </div>
              {activeTask.status === "completed" && (
                <div style={{ display: 'flex', gap: '12px', justifyContent: 'center' }}>
                  <button className="abtn primary" onClick={() => invoke("open_url", { url: activeTask.outputPath }).catch(alert)}>
                    <span className="material-symbols-outlined">file_open</span>
                    <span>Open Hasil</span>
                  </button>
                  <button className="abtn secondary" onClick={() => invoke("open_in_folder", { path: activeTask.outputPath }).catch(alert)}>
                    <span className="material-symbols-outlined">folder</span>
                    <span>Container</span>
                  </button>
                  <button className="abtn primary bl" onClick={() => updateState({ stage: 1, file: null, outputName: "", activeTaskId: null })}>
                    <span className="material-symbols-outlined">refresh</span>
                    <span>New Extraction</span>
                  </button>
                </div>
              )}
              {activeTask.status === "failed" && (
                <div className="info-card error" style={{ marginBottom: '24px' }}>
                  <span className="material-symbols-outlined">error</span>
                  <div className="ps">{activeTask.error}</div>
                </div>
              )}
              {activeTask.status === "failed" && <button className="abtn secondary" onClick={() => setActiveTaskId(null)}>Retry</button>}
              {activeTask.status === "processing" && (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                  <button className="abtn primary" onClick={() => { setStage(1); setFile(null); setActiveTaskId(null); }}>
                    <span className="material-symbols-outlined">close</span>
                    <span>Abort Process</span>
                  </button>
                  <button className="abtn secondary" onClick={() => onBack()}>Run in Background</button>
                </div>
              )}
            </div>
          )}
        </div>
      )}
    </div>
  );
}
span>New Extraction</span>
                  </button>
                </div>
              )}
              {activeTask.status === "failed" && (
                <div className="info-card error" style={{ marginBottom: '24px' }}>
                  <span className="material-symbols-outlined">error</span>
                  <div className="ps">{activeTask.error}</div>
                </div>
              )}
              {activeTask.status === "failed" && <button className="abtn secondary" onClick={() => setActiveTaskId(null)}>Retry</button>}
              {activeTask.status === "processing" && (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                  <button className="abtn primary" onClick={() => { setStage(1); setFile(null); setActiveTaskId(null); }}>
                    <span className="material-symbols-outlined">close</span>
                    <span>Abort Process</span>
                  </button>
                  <button className="abtn secondary" onClick={() => onBack()}>Run in Background</button>
                </div>
              )}
            </div>
          )}
        </div>
      )}
    </div>
  );
}

function WatermarkScreen({ onBack, addTask, updateTask, tasks, state, updateState, deps, onFixDeps }: ToolScreenProps) {
  const { stage, file, outputName, text = "CONFIDENTIAL", opacity = 30, pos = "C", activeTaskId, logoPath = null, logoScale = 0.2 } = state;
  const [outputDir, saveOutputDir] = useSavedPath("watermark");
  const [isDragOver, setIsDragOver] = useState(false);

  const setStage = (s: number) => updateState({ stage: s });
  const setFile = (f: any) => updateState({ file: f });
  const setOutputName = (n: string) => updateState({ outputName: n });
  const setText = (t: string) => updateState({ text: t });
  const setOpacity = (o: number) => updateState({ opacity: o });
  const setPos = (p: string) => updateState({ pos: p });
  const setLogoPath = (lp: string | null) => updateState({ logoPath: lp });
  const setLogoScale = (ls: number) => updateState({ logoScale: ls });
  const setActiveTaskId = (id: string | null) => updateState({ activeTaskId: id });

  const activeTask = tasks.find((t: ProcessTask) => t.id === activeTaskId);

  useEffect(() => {
    if (file && !outputName) {
      const base = file.name.split('.').slice(0, -1).join('.');
      setOutputName(`${base}_watermark`);
    }
  }, [file]);

  const pickFile = async () => {
    const selected = await open({ filters: [{ name: 'Images', extensions: ['jpg','jpeg','png','webp','bmp'] }] });
    if (selected && !Array.isArray(selected)) {
      setFile({ name: selected.split(/[\\/]/).pop(), path: selected });
      setStage(2);
    }
  };

  const pickDir = async () => {
    const s = await open({ directory: true, multiple: false });
    if (s && !Array.isArray(s)) saveOutputDir(s);
  };

  const handleStartWatermark = async () => {
    if (!file || !outputDir) return;
    
    const tid = addTask({
      name: `${outputName}.png`,
      tool: "Watermark",
      inputPath: file.path,
    });
    setActiveTaskId(tid);

    try {
      const res: any = await invoke("apply_watermark", { 
        inputPath: file.path, 
        outputPath: outputDir + "\\" + outputName + ".png",
        watermarkText: text || null,
        logoPath: logoPath,
        fontSize: 32,
        opacity: opacity,
        color: "white",
        position: pos,
        logoScale: logoScale
      });
      
      if (res.success) {
        updateTask(tid, { status: "completed", progress: 100, outputPath: res.outputPath });
        addActivity({ name: file.name, meta: "Watermarked", time: "Just now" });
      } else {
        updateTask(tid, { status: "failed", error: res.errorMessage });
      }
    } catch(e) {
      updateTask(tid, { status: "failed", error: String(e) });
    }
  };

  useEffect(() => {
    let unDrop: any, unEnter: any, unLeave: any;
    listen("tauri://drag-drop", (e: any) => {
      setIsDragOver(false);
      const paths = e.payload.paths;
      if (paths && paths.length > 0) {
        setFile({ name: paths[0].split(/[\\/]/).pop(), path: paths[0] });
        setStage(2);
      }
    }).then(u => unDrop = u);
    listen("tauri://drag-enter", () => setIsDragOver(true)).then(u => unEnter = u);
    listen("tauri://drag-leave", () => setIsDragOver(false)).then(u => unLeave = u);
    return () => {
      if (unDrop) unDrop();
      if (unEnter) unEnter();
      if (unLeave) unLeave();
    };
  }, []);

  return (
    <div className="screen active">
      <div className="tool-header">
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          <button className="back-btn" onClick={onBack} style={{ position: 'relative', top: 0 }}>
             <span className="material-symbols-outlined">arrow_back</span>
          </button>
          <div>
            <div className="pt">Add <span className="bl">Watermark</span></div>
            <div className="ps" style={{ marginBottom: 0 }}>Protect your images with text overlays</div>
          </div>
        </div>
        <StageIndicator current={stage} stages={STAGES} />
      </div>
      
      {stage === 1 && (
        <div className={`panel animate-in ${isDragOver ? "drag-over" : ""}`} style={{ padding: '60px' }}>
          <div className="plabel" style={{ textAlign: 'center', marginBottom: '24px' }}>Stage 1: Input Selection</div>
          <div className="dz" onClick={pickFile}>
            <span className="material-symbols-outlined" style={{ fontSize: '48px', color: 'var(--accent)', marginBottom: '16px' }}>image</span>
            <div className="dz-main">{file ? file.name : "Drop Image or Browse"}</div>
            <div className="dz-sub">PNG · JPG · WEBP · BMP</div>
          </div>
          {file && (
            <button className="abtn primary" style={{ marginTop: '30px', width: '100%' }} onClick={() => setStage(2)}>Continue to Overlay Settings →</button>
          )}
        </div>
      )}

      {stage === 2 && (
        <div className="two-col animate-in">
          <div className="panel" style={{ flex: 1.5 }}>
            <div className="plabel">Live Visual Preview</div>
            <div className="dz" style={{ 
              height: '360px', 
              background: 'rgba(0,0,0,0.2)', 
              borderRadius: '16px', 
              position: 'relative', 
              overflow: 'hidden', 
              display: 'flex', 
              alignItems: 'center', 
              justifyContent: 'center',
              boxShadow: 'inset 0 0 20px rgba(0,0,0,0.3)',
              border: '1px solid var(--border)'
            }}>
               {file ? (
                 <img 
                   src={convertFileSrc(file.path)} 
                   alt="Preview" 
                   style={{ width: '100%', height: '100%', objectFit: 'contain' }}
                 />
               ) : (
                 <span className="material-symbols-outlined" style={{ fontSize: '64px', opacity: 0.1 }}>image</span>
               )}
               <div style={{ 
                 position: 'absolute', 
                 opacity: opacity / 100, 
                 fontSize: '32px', 
                 fontWeight: '900', 
                 color: 'white', 
                 textShadow: '0 2px 10px rgba(0,0,0,0.8)',
                 userSelect: 'none', 
                 pointerEvents: 'none',
                 textAlign: 'center',
                 zIndex: 10,
                 ...(pos === 'TL' && { top: '20px', left: '20px' }),
                 ...(pos === 'TC' && { top: '20px' }),
                 ...(pos === 'TR' && { top: '20px', right: '20px' }),
                 ...(pos === 'CL' && { left: '20px' }),
                 ...(pos === 'C' && {}),
                 ...(pos === 'CR' && { right: '20px' }),
                 ...(pos === 'BL' && { bottom: '20px', left: '20px' }),
                 ...(pos === 'BC' && { bottom: '20px' }),
                 ...(pos === 'BR' && { bottom: '20px', right: '20px' }),
               }}>
                 {text || "PREVIEW"}
               </div>
            </div>
            
            <div className="plabel" style={{ marginTop: '24px' }}>Watermark Anchor</div>
            <div className="fmt-gl" style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '4px' }}>
              {['TL', 'TC', 'TR', 'ML', 'C', 'MR', 'BL', 'BC', 'BR'].map(p => (
                <div key={p} className={`fb ${pos === p ? "active" : ""}`} onClick={() => setPos(p)} style={{ textAlign: 'center', padding: '10px', fontSize: '12px' }}>{p}</div>
              ))}
            </div>
          </div>

          <div className="panel" style={{ maxHeight: '600px', overflowY: 'auto' }}>
            <div className="plabel">Configuration</div>
            <div className="srow">
                <div className="slabel">Export Filename</div>
                <div className="sfield">
                  <input className="sinput" value={outputName} onChange={e => setOutputName(e.target.value)} />
                  <div className="sbtn">.png</div>
                </div>
            </div>
            <div className="srow" style={{ marginTop: '16px' }}>
              <div className="slabel">Watermark Text</div>
              <input type="text" className="sinput" value={text} onChange={e => setText(e.target.value)} placeholder="Type here..." style={{ width: '100%' }} />
              <button className="abtn secondary bl" style={{ marginTop: '4px', fontSize: '10px' }} onClick={() => setText("")}>Clear Text</button>
            </div>
            <div className="srow" style={{ marginTop: '16px' }}>
              <div className="slabel">Logo Overlay (Optional)</div>
              <div className="sfield">
                <input className="sinput" value={logoPath ? logoPath.split(/[\\/]/).pop() : "No logo selected"} readOnly />
                <button className="sbtn" onClick={async () => {
                  const s = await open({ filters: [{ name: 'Images', extensions: ['png','jpg','jpeg','webp'] }] });
                  if (s && !Array.isArray(s)) setLogoPath(s);
                }}>Pick</button>
                {logoPath && <button className="sbtn" onClick={() => setLogoPath(null)}>×</button>}
              </div>
            </div>
            {logoPath && (
              <div className="srow" style={{ marginTop: '16px' }}>
                <div className="slabel">Logo Scale ({Math.round(logoScale * 100)}%)</div>
                <input type="range" min="0.05" max="0.5" step="0.01" value={logoScale} onChange={e => setLogoScale(parseFloat(e.target.value))} style={{ width: '100%', accentColor: 'var(--accent)' }} />
              </div>
            )}
            <div className="srow" style={{ marginTop: '16px' }}>
              <div className="slabel">Overall Intensity ({opacity}%)</div>
              <input type="range" min="5" max="100" value={opacity} onChange={e => setOpacity(parseInt(e.target.value))} style={{ width: '100%', accentColor: 'var(--accent)' }} />
            </div>
            <div className="srow" style={{ marginTop: '20px' }}>
              <div className="slabel">Target Directory</div>
              <div className="sfield">
                <input className="sinput" value={outputDir || "No folder selected"} readOnly />
                <button className="sbtn" onClick={pickDir}>Browse</button>
              </div>
            </div>

            <button className="abtn primary" style={{ marginTop: '30px' }} onClick={() => setStage(3)} disabled={!outputDir || !outputName}>Apply & Export →</button>
            <button className="abtn secondary" style={{ marginTop: '10px' }} onClick={() => setStage(1)}>Back</button>
          </div>
        </div>
      )}

      {stage === 3 && (
        <div className="panel scrollable animate-in">
           <div className="plabel">Stage 3: {activeTask ? "Processing" : "Ready"}</div>
           {!activeTask ? (
             <div style={{ padding: '20px' }}>
                <div className="info-card" style={{ marginBottom: '24px' }}>
                  <div style={{ fontSize: '13px', color: 'var(--text-secondary)' }}>Workflow Summary:</div>
                  <div style={{ fontSize: '14px', fontWeight: '700', margin: '8px 0' }}>"{file.name}" ➜ "{outputName}.png"</div>
                  <div style={{ fontSize: '12px', color: 'var(--text-muted)' }}>Watermark: "{text}" • Opacity: {opacity}% • Position: {pos}</div>
                  <div style={{ fontSize: '12px', color: 'var(--text-muted)' }}>Location: {outputDir}</div>
                </div>
                <button className="abtn primary" onClick={handleStartWatermark}>⚡ Apply Watermark</button>
                <button className="abtn secondary" style={{ marginTop: '10px' }} onClick={() => setStage(2)}>Back to Overlay Settings</button>
             </div>
           ) : (
             <div style={{ textAlign: 'center', padding: '40px 20px' }}>
                <div style={{ fontSize: '40px', marginBottom: '16px' }}>
                  {activeTask.status === "processing" ? "⚙️" : activeTask.status === "completed" ? "✅" : "❌"}
                </div>
                <div className="pt">{activeTask.status === "processing" ? "Protecting Image..." : activeTask.status === "completed" ? "Success" : "Failed"}</div>
                <div className="ps" style={{ marginBottom: '24px' }}>{activeTask.name}</div>
                
                <div className="rm-bar-bg" style={{ height: '8px', marginBottom: '32px' }}>
                  <div className="rm-bar-fill rm-cpu-fill" style={{ 
                    width: `${activeTask.progress || 100}%`,
                    animation: activeTask.status === "processing" ? 'pulse 1.5s infinite' : 'none'
                  }} />
                </div>

                {activeTask.status === "completed" && (
                  <div style={{ display: 'flex', gap: '8px', justifyContent: 'center' }}>
                    <button className="abtn primary" onClick={() => invoke("open_url", { url: activeTask.outputPath }).catch(alert)}>📂 Open File</button>
                    <button className="abtn secondary" onClick={() => invoke("open_in_folder", { path: activeTask.outputPath }).catch(alert)}>📁 Open Folder</button>
                    <button className="abtn primary bl" onClick={() => updateState({ stage: 1, file: null, outputName: "", activeTaskId: null })}>🔄 Protect More</button>
                  </div>
                )}
                {activeTask.status === "failed" && (
                  <div style={{ color: 'var(--red)', background: 'var(--rbg)', padding: '12px', borderRadius: '8px', fontSize: '12px', marginBottom: '16px' }}>{activeTask.error}</div>
                )}
                {activeTask.status === "failed" && <button className="abtn secondary" onClick={() => setActiveTaskId(null)}>Retry Setup</button>}
                {activeTask.status === "processing" && (
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                    <button className="abtn primary" onClick={() => { setStage(1); setFile(null); setActiveTaskId(null); }}>Abort Job</button>
                    <button className="abtn secondary" onClick={() => onBack()}>Run in Background</button>
                  </div>
                )}
             </div>
           )}
        </div>
      )}
    </div>
  );
}

function BatchFolderScreen({ onBack, addTask, updateTask, tasks, state, updateState, deps, onFixDeps }: ToolScreenProps) {
  const { stage, path = "", action = "pdf_to_docx", activeTaskId } = state;
  const [outputDir, saveOutputDir] = useSavedPath("batch");

  const setStage = (s: number) => updateState({ stage: s });
  const setPath = (p: string) => updateState({ path: p });
  const setAction = (a: string) => updateState({ action: a });
  const setActiveTaskId = (id: string | null) => updateState({ activeTaskId: id });

  const activeTask = tasks.find((t: ProcessTask) => t.id === activeTaskId);

  useEffect(() => {
    let unlisten: any;
    const setup = async () => {
      unlisten = await listen("batch_progress", (event: any) => {
        if (activeTaskId) {
          updateTask(activeTaskId, { 
            progress: event.payload.percent,
            timeRemaining: `${event.payload.completed}/${event.payload.total} Files`
          });
        }
      });
    };
    setup();
    return () => { if (unlisten) unlisten(); };
  }, [activeTaskId]);

  const pick = async () => {
    const selected = await open({ directory: true });
    if (selected && !Array.isArray(selected)) {
      setPath(selected);
      setStage(2);
    }
  };

  const pickDir = async () => {
    const s = await open({ directory: true, multiple: false });
    if (s && !Array.isArray(s)) saveOutputDir(s);
  };

  const handleStartBatch = async () => {
    if (!path || !outputDir) return;
    
    const tid = addTask({
      name: `Batch: ${path.split(/[\\/]/).pop()}`,
      tool: "Batch Process",
      inputPath: path,
    });
    setActiveTaskId(tid);

    try {
      const res: any = await invoke("batch_convert_folder", {
        folderPath: path,
        targetFormat: action.split("_to_")[1] || "docx",
        outputPath: outputDir,
        fileType: "document"
      });
      
      if (res.success) {
        updateTask(tid, { status: "completed", progress: 100, outputPath: res.outputPath });
        addActivity({ name: "Batch Folder", meta: "Processed successfully", time: "Just now" });
      } else {
        updateTask(tid, { status: "failed", error: res.errorMessage });
      }
    } catch(e) {
      updateTask(tid, { status: "failed", error: String(e) });
    }
  };

  return (
    <div className="screen active">
      <div className="tool-header">
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          <button className="back-btn" onClick={onBack} style={{ position: 'relative', top: 0 }}>
             <span className="material-symbols-outlined">arrow_back</span>
          </button>
          <div>
            <div className="pt">Batch <span className="bl">Processing</span></div>
            <div className="ps" style={{ marginBottom: 0 }}>Mass-convert files within a folder recursively</div>
          </div>
        </div>
        <StageIndicator current={stage} stages={STAGES} />
      </div>
      
      {stage === 1 && (
        <div className="panel animate-in" style={{ textAlign: 'center', padding: '80px' }}>
          <div className="plabel" style={{ marginBottom: '24px' }}>Stage 1: Select Source Folder</div>
          <div className="dz" onClick={pick}>
            <span className="material-symbols-outlined" style={{ fontSize: '48px', color: 'var(--accent)', marginBottom: '16px' }}>folder_open</span>
            <div className="dz-main">{path ? path.split(/[\\/]/).pop() : "Drop Folder or Browse"}</div>
            <div className="dz-sub">{path || "Recursively scans for compatible files"}</div>
          </div>
          {path && (
            <button className="abtn primary" style={{ marginTop: '32px', width: '100%' }} onClick={() => setStage(2)}>Continue to Batch Action →</button>
          )}
        </div>
      )}

      {stage === 2 && (
        <div className="panel animate-in">
          <div className="plabel">Stage 2: Action & Destination</div>
          
          <div className="fmt-gl">Choose Bulk Action</div>
          <div className="fmtb" style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '12px' }}>
             <div className={`fb ${action === "pdf_to_docx" ? "active" : ""}`} onClick={() => setAction("pdf_to_docx")}>
               <span className="material-symbols-outlined">description</span>
               PDF → DOCX
             </div>
             <div className={`fb ${action === "compress" ? "active" : ""}`} onClick={() => setAction("compress")}>
               <span className="material-symbols-outlined">compress</span>
               Compress All
             </div>
             <div className={`fb ${action === "image_conv" ? "active" : ""}`} onClick={() => setAction("image_conv")}>
               <span className="material-symbols-outlined">image</span>
               Optimize Images
             </div>
          </div>

          <div className="srow" style={{ marginTop: '32px' }}>
            <div className="slabel">Save Results To</div>
            <div className="sfield">
              <span className="material-symbols-outlined sfield-icon">folder</span>
              <input className="sinput" value={outputDir || "No folder selected"} readOnly />
              <button className="sbtn" onClick={pickDir}>Browse</button>
            </div>
          </div>

          <div className="info-card" style={{ marginTop: '24px' }}>
             <span className="material-symbols-outlined" style={{ fontSize: '18px', color: 'var(--accent)' }}>info</span>
             <div className="ps" style={{ marginBottom: 0 }}>Formatica will process all compatible files in the selected source and export results to the destination folder.</div>
          </div>

          <div style={{ display: 'flex', gap: '12px', marginTop: '32px' }}>
            <button className="abtn primary" style={{ flex: 1 }} onClick={() => setStage(3)} disabled={!outputDir || !path}>Review Batch Plan →</button>
            <button className="abtn secondary" onClick={() => setStage(1)}>Back</button>
          </div>
        </div>
      )}

      {stage === 3 && (
        <div className="panel scrollable animate-in">
           <div className="plabel">Stage 3: {activeTask ? "Processing" : "Ready"}</div>
           {!activeTask ? (
             <div style={{ padding: '20px' }}>
                <div className="info-card" style={{ marginBottom: '24px' }}>
                  <div style={{ fontSize: '13px', color: 'var(--text-secondary)' }}>Batch Plan:</div>
                  <div style={{ fontSize: '16px', fontWeight: '700', margin: '8px 0' }}>Action: {action.replace(/_/g,' ').toUpperCase()}</div>
                  <div style={{ fontSize: '12px', color: 'var(--text-muted)' }}>Source: {path}</div>
                  <div style={{ fontSize: '12px', color: 'var(--text-muted)' }}>Destination: {outputDir}</div>
                </div>
                <div style={{ display: 'flex', gap: '12px' }}>
                  <button className="abtn primary" style={{ flex: 1 }} onClick={handleStartBatch}>⚡ Start Batch Processing</button>
                  <button className="abtn secondary" onClick={() => setStage(2)}>Back to Config</button>
                </div>
             </div>
           ) : (
             <div style={{ textAlign: 'center', padding: '40px 20px' }}>
                <div style={{ fontSize: '48px', marginBottom: '20px' }}>
                  {activeTask.status === "processing" ? "⚙️" : activeTask.status === "completed" ? "✅" : "❌"}
                </div>
                <div className="pt">{activeTask.status === "processing" ? "Running Batch Process..." : activeTask.status === "completed" ? "Success" : "Failed"}</div>
                <div className="ps" style={{ marginBottom: '32px' }}>{activeTask.name}</div>
                
                <div className="rm-bar-bg" style={{ height: '8px', borderRadius: '10px', marginBottom: '40px' }}>
                  <div className="rm-bar-fill rm-cpu-fill" style={{ 
                    width: `${activeTask.progress || 100}%`,
                    height: '100%',
                    borderRadius: '10px',
                    animation: activeTask.status === "processing" ? 'pulse 1.5s infinite' : 'none'
                  }} />
                </div>

                {activeTask.status === "completed" && (
                  <div style={{ display: 'flex', gap: '12px', justifyContent: 'center' }}>
                    <button className="abtn primary" onClick={() => invoke("open_in_folder", { path: outputDir }).catch(alert)}>
                      <span className="material-symbols-outlined" style={{ fontSize: '18px', marginRight: '8px' }}>folder_open</span>
                    </div>
  );
}

const DOWNLOAD_STAGES = ["Source", "Config", "Process"];

function DownloadScreen({ onBack, addTask, updateTask, tasks, state, updateState, deps, onFixDeps }: ToolScreenProps) {
  const { stage = 1, url = "", format = "mp4", outputName = "", activeTaskId = null } = state || {};
  const [outputDir, saveOutputDir] = useSavedPath("download");
  const isEngineReady = deps.find((d: DepStatus) => d.name === "ytdlp")?.installed ?? true;

  const setStage = (s: number) => updateState({ stage: s });
  const setUrl = (u: string) => updateState({ url: u });
  const setFormat = (f: string) => updateState({ format: f });
  const setOutputName = (n: string) => updateState({ outputName: n });
  const setActiveTaskId = (id: string | null) => updateState({ activeTaskId: id });

  const activeTask = tasks.find((t: ProcessTask) => t.id === activeTaskId);

  useEffect(() => {
    let unlisten: any;
    const setup = async () => {
      unlisten = await listen("download_progress", (event: any) => {
        const { progress, url: downloadUrl } = event.payload;
        if (downloadUrl === url && activeTaskId) {
          updateTask(activeTaskId, { progress });
        }
      });
    };
    setup();
    return () => { if (unlisten) unlisten.then((f: any) => f()); };
  }, [url, activeTaskId]);

  const handleStartDownload = async () => {
    if (!url || !outputDir) return;
    setStage(3);
    
    const tid = addTask({
      name: `${outputName || "video"}.${format}`,
      tool: "Media Downloader",
      inputPath: url,
    });
    setActiveTaskId(tid);

    try {
      const res: any = await invoke("download_media", {
        url: url,
        outputDir: outputDir,
        outputName: outputName || "",
        format: format
      });
      
      if (res.success) {
        updateTask(tid, { status: "completed", progress: 100, outputPath: res.outputPath });
        addActivity({ name: outputName || "Media", meta: `Downloaded ${format.toUpperCase()}`, time: "Just now" });
      } else {
        updateTask(tid, { status: "failed", error: res.errorMessage });
      }
    } catch(e) {
      updateTask(tid, { status: "failed", error: String(e) });
    }
  };

  return (
    <div className="screen active">
      <div className="tool-header">
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          <button className="back-btn" onClick={onBack} style={{ position: 'relative', top: 0 }}>
             <span className="material-symbols-outlined">arrow_back</span>
          </button>
          <div>
            <div className="pt">Media <span className="bl">Downloader</span></div>
            <div className="ps" style={{ marginBottom: 0 }}>Save online videos or audio for offline use</div>
          </div>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '20px' }}>
          {!isEngineReady && (
            <div className="status-badge error animate-in">
              <span className="material-symbols-outlined" style={{ fontSize: '18px' }}>report</span>
              <span>Engine Missing</span>
              <button className="sbtn-mini" onClick={onFixDeps}>Fix</button>
            </div>
          )}
          <StageIndicator current={stage} stages={DOWNLOAD_STAGES} />
        </div>
      </div>

      {stage === 1 && (
        <div className="panel animate-in" style={{ padding: '80px', textAlign: 'center' }}>
          <div className="plabel" style={{ marginBottom: '32px' }}>Stage 1: Paste Media Link</div>
          <div style={{ maxWidth: '600px', margin: '0 auto' }}>
            <div className="sfield" style={{ marginBottom: '24px' }}>
              <span className="material-symbols-outlined sfield-icon" style={{ fontSize: '24px' }}>link</span>
              <input 
                className="sinput" 
                style={{ padding: '20px 20px 20px 50px', fontSize: '16px' }} 
                placeholder="https://www.youtube.com/watch?v=..."
                value={url}
                onChange={e => setUrl(e.target.value)}
              />
            </div>
            <div className="ps" style={{ opacity: 0.7 }}>Supports YouTube, Vimeo, TikTok and 1000+ more sites</div>
            {url && (
              <button className="abtn primary" style={{ marginTop: '32px', width: '100%' }} onClick={() => setStage(2)}>
                 Analyze Link & Continue →
              </button>
            )}
          </div>
        </div>
      )}

      {stage === 2 && (
        <div className="panel animate-in">
          <div className="plabel">Stage 2: Configure Download</div>
          <div className="two-col" style={{ gap: '32px' }}>
            <div>
              <div className="srow">
                <div className="slabel">Output Filename</div>
                <div className="sfield">
                  <span className="material-symbols-outlined sfield-icon">title</span>
                  <input className="sinput" value={outputName} onChange={e => setOutputName(e.target.value)} placeholder="video_title" />
                </div>
              </div>
              <div className="fmt-gl" style={{ marginTop: '24px' }}>Download Format</div>
              <div className="fmtb" style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                <div className={`fb ${format === "mp4" ? "active" : ""}`} onClick={() => setFormat("mp4")}>
                  <span className="material-symbols-outlined">movie</span>
                  Video (MP4)
                </div>
                <div className={`fb ${format === "mp3" ? "active" : ""}`} onClick={() => setFormat("mp3")}>
                  <span className="material-symbols-outlined">music_note</span>
                  Audio (MP3)
                </div>
              </div>
            </div>
            <div>
              <div className="srow">
                <div className="slabel">Save Location</div>
                <div className="sfield">
                  <span className="material-symbols-outlined sfield-icon">folder</span>
                  <input className="sinput" value={outputDir || "No folder selected"} readOnly />
                  <button className="sbtn" onClick={async () => {
                    const s = await open({ directory: true });
                    if (s && !Array.isArray(s)) saveOutputDir(s);
                  }}>Browse</button>
                </div>
              </div>
              <div className="info-card" style={{ marginTop: '24px' }}>
                <span className="material-symbols-outlined" style={{ fontSize: '18px', color: 'var(--accent)' }}>info</span>
                <div className="ps" style={{ marginBottom: 0 }}>Formatica will download the highest possible quality available for the selected format.</div>
              </div>
            </div>
          </div>
          
          <div style={{ display: 'flex', gap: '12px', marginTop: '40px' }}>
            <button className="abtn primary" style={{ flex: 1 }} onClick={() => setStage(3)} disabled={!url || !outputDir || !isEngineReady}>
              Confirm & Download →
            </button>
            <button className="abtn secondary" onClick={() => setStage(1)}>Change Link</button>
          </div>
          {!isEngineReady && <div style={{ fontSize: '11px', color: 'var(--red)', marginTop: '12px', textAlign: 'center' }}>Please fix the missing engine to proceed.</div>}
        </div>
      )}

      {stage === 3 && (
        <div className="panel animate-in">
          <div className="plabel">Stage 3: {activeTask ? "Downloading" : "Ready"}</div>
          {!activeTask ? (
            <div style={{ padding: '20px' }}>
              <div className="info-card" style={{ marginBottom: '32px' }}>
                <div style={{ fontSize: '13px', color: 'var(--text-secondary)' }}>Download Summary:</div>
                <div style={{ fontSize: '16px', fontWeight: '700', margin: '8px 0', wordBreak: 'break-all' }}>{url}</div>
                <div style={{ fontSize: '12px', color: 'var(--text-muted)' }}>Format: {format.toUpperCase()} • Folder: {outputDir}</div>
              </div>
              <div style={{ display: 'flex', gap: '12px' }}>
                 <button className="abtn primary" style={{ flex: 1 }} onClick={handleStartDownload}>⚡ Start Download</button>
                 <button className="abtn secondary" onClick={() => setStage(2)}>Adjust Config</button>
              </div>
            </div>
          ) : (
            <div style={{ textAlign: 'center', padding: '40px 20px' }}>
              <div style={{ fontSize: '48px', marginBottom: '20px' }}>
                {activeTask.status === "processing" ? "🚀" : activeTask.status === "completed" ? "✅" : "❌"}
              </div>
              <div className="pt">{activeTask.status === "processing" ? "Downloading..." : activeTask.status === "completed" ? "Success" : "Failed"}</div>
              <div className="ps" style={{ marginBottom: '32px' }}>{activeTask.name}</div>
              <div className="rm-bar-bg" style={{ height: '8px', borderRadius: '10px', marginBottom: '40px' }}>
                <div className="rm-bar-fill rm-cpu-fill" style={{ width: `${activeTask.progress ?? 0}%`, height: '100%', borderRadius: '10px' }} />
              </div>

              {activeTask.status === "completed" && (
                <div style={{ display: 'flex', gap: '12px', justifyContent: 'center' }}>
                  <button className="abtn primary" onClick={() => invoke("open_url", { url: activeTask.outputPath }).catch(alert)}>
                     <span className="material-symbols-outlined" style={{ fontSize: '18px', marginRight: '8px' }}>file_open</span>
                     Open File
                  </button>
                  <button className="abtn secondary" onClick={() => invoke("open_in_folder", { path: activeTask.outputPath }).catch(alert)}>
                     <span className="material-symbols-outlined" style={{ fontSize: '18px', marginRight: '8px' }}>folder_open</span>
                     Open Folder
                  </button>
                  <button className="abtn primary bl" onClick={() => updateState({ stage: 1, url: "", outputName: "", activeTaskId: null })}>
                     <span className="material-symbols-outlined" style={{ fontSize: '18px', marginRight: '8px' }}>refresh</span>
                     Download More
                  </button>
                </div>
              )}
              {activeTask.status === "failed" && (
                <div className="info-card error" style={{ marginBottom: '24px' }}>
                   <span className="material-symbols-outlined">error</span>
                   <div className="ps">{activeTask.error}</div>
                </div>
              )}
              {activeTask.status === "failed" && <button className="abtn secondary" onClick={() => setActiveTaskId(null)}>Retry</button>}
            </div>
          )}
        </div>
      )}
    </div>
  );
}

function QueueScreen({ onBack, tasks, removeTask }: { onBack: () => void, tasks: ProcessTask[], removeTask: (id: string) => void }) {
  const activeTasks = tasks.filter((t: ProcessTask) => t.status === "processing");
  const completedTasks = tasks.filter((t: ProcessTask) => t.status === "completed" || t.status === "failed");

  return (
    <div className="screen active">
      <div className="tool-header">
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          <button className="back-btn" onClick={onBack} style={{ position: 'relative', top: 0 }}>
             <span className="material-symbols-outlined">arrow_back</span>
          </button>
          <div>
            <div className="pt">Task <span className="bl">Queue</span></div>
            <div className="ps" style={{ marginBottom: 0 }}>Monitor background processes and job results</div>
          </div>
        </div>
      </div>
      
      <div className="two-col" style={{ marginTop: '24px', gap: '24px' }}>
        <div>
          <div className="panel" style={{ minHeight: '500px' }}>
            <div className="plabel" style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
               <span className="material-symbols-outlined" style={{ fontSize: '18px' }}>hourglass_top</span>
               Active Processes ({activeTasks.length})
            </div>
            {activeTasks.length === 0 ? (
              <div style={{ textAlign: 'center', padding: '140px 20px', opacity: 0.4 }}>
                 <span className="material-symbols-outlined" style={{ fontSize: '48px', marginBottom: '16px' }}>bedtime</span>
                 <div className="ps">All quiet. No active tasks.</div>
              </div>
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                {activeTasks.map((t: ProcessTask) => (
                  <div key={t.id} className="info-card animate-in" style={{ borderLeft: '4px solid var(--accent)', padding: '16px' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '10px' }}>
                      <div style={{ flex: 1 }}>
                        <div style={{ fontSize: '11px', fontWeight: '800', color: 'var(--accent)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>{t.tool}</div>
                        <div style={{ fontSize: '14px', fontWeight: '600', color: 'var(--text-main)', marginTop: '2px' }}>{t.name}</div>
                      </div>
                      <div style={{ fontSize: '14px', fontWeight: '800', color: 'var(--accent)' }}>{t.progress}%</div>
                    </div>
                    <div className="rm-bar-bg" style={{ height: '6px', borderRadius: '10px' }}>
                      <div className="rm-bar-fill rm-cpu-fill" style={{ 
                        width: `${t.progress}%`, 
                        height: '100%', 
                        borderRadius: '10px',
                        animation: 'pulse 1.5s infinite' 
                      }} />
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>

        <div>
          <div className="panel" style={{ minHeight: '500px', display: 'flex', flexDirection: 'column' }}>
            <div className="plabel" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <span className="material-symbols-outlined" style={{ fontSize: '18px' }}>history</span>
                Recent Results
              </div>
              {completedTasks.length > 0 && (
                <button className="sbtn-mini" onClick={() => tasks.forEach(t => (t.status !== 'processing' && removeTask(t.id)))}>
                  Clear History
                </button>
              )}
            </div>
            
            <div className="scrollable-content" style={{ flex: 1, marginTop: '12px' }}>
              {completedTasks.length === 0 ? (
                <div style={{ textAlign: 'center', padding: '140px 20px', opacity: 0.4 }}>
                   <div className="ps">History is empty</div>
                </div>
              ) : (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
                  {[...completedTasks].reverse().map(t => (
                    <div key={t.id} className="info-card animate-in" style={{ padding: '12px' }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: '12px' }}>
                        <div style={{ display: 'flex', gap: '12px', flex: 1 }}>
                          <span className="material-symbols-outlined" style={{ 
                            color: t.status === 'completed' ? 'var(--green)' : 'var(--red)',
                            fontSize: '20px',
                            marginTop: '2px'
                          }}>
                            {t.status === 'completed' ? 'check_circle' : 'cancel'}
                          </span>
                          <div style={{ overflow: 'hidden' }}>
                            <div style={{ fontSize: '13px', fontWeight: '600', textOverflow: 'ellipsis', overflow: 'hidden', whiteSpace: 'nowrap' }}>{t.name}</div>
                            <div style={{ fontSize: '11px', color: 'var(--text-muted)', marginTop: '2px' }}>
                              {t.status === 'completed' ? 'Done' : `Error: ${t.error}`}
                            </div>
                          </div>
                        </div>
                        <button className="icon-btn-small" onClick={() => removeTask(t.id)}>
                           <span className="material-symbols-outlined" style={{ fontSize: '16px' }}>close</span>
                        </button>
                      </div>
                      {t.status === 'completed' && t.outputPath && (
                        <div style={{ display: 'flex', gap: '8px', marginTop: '12px' }}>
                          <button className="sbtn" style={{ flex: 1, fontSize: '11px', padding: '6px' }} onClick={() => invoke("open_url", { url: t.outputPath }).catch(alert)}>
                             <span className="material-symbols-outlined" style={{ fontSize: '14px', marginRight: '4px' }}>visibility</span>
                             View
                          </button>
                          <button className="sbtn" style={{ flex: 1, fontSize: '11px', padding: '6px' }} onClick={() => invoke("open_in_folder", { path: t.outputPath }).catch(alert)}>
                             <span className="material-symbols-outlined" style={{ fontSize: '14px', marginRight: '4px' }}>folder_open</span>
                             Folder
                          </button>
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function ShortcutsScreen({ onBack }: { onBack: () => void }) {
  const shortcuts = [
    { cat: "Navigation", icon: "explore", items: [
      { action: "Convert document", key: "Ctrl + 1" },
      { action: "Images to PDF", key: "Ctrl + 2" },
      { action: "Merge PDF", key: "Ctrl + 3" },
      { action: "Split PDF", key: "Ctrl + 4" },
      { action: "OCR PDF", key: "Ctrl + 5" },
      { action: "Compress video", key: "Ctrl + 6" },
      { action: "Convert image", key: "Ctrl + 7" },
      { action: "Watermark", key: "Ctrl + 8" },
    ]},
    { cat: "System", icon: "settings_input_component", items: [
      { action: "Toggle Theme", key: "Ctrl + D" },
      { action: "Open Queue", key: "Ctrl + Q" },
      { action: "Resource Monitor", key: "Ctrl + M" },
      { action: "Settings", key: "Ctrl + ," },
      { action: "Keyboard Shortcuts", key: "Ctrl + /" },
    ]}
  ];

  return (
    <div className="screen active">
      <div className="tool-header">
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          <button className="back-btn" onClick={onBack} style={{ position: 'relative', top: 0 }}>
             <span className="material-symbols-outlined">arrow_back</span>
          </button>
          <div>
            <div className="pt">Keyboard <span className="bl">Shortcuts</span></div>
            <div className="ps" style={{ marginBottom: 0 }}>Boost your productivity with master commands</div>
          </div>
        </div>
      </div>
      
      <div className="two-col" style={{ marginTop: '24px', gap: '24px' }}>
         {shortcuts.map(s => (
           <div key={s.cat} className="panel animate-in">
             <div className="plabel" style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <span className="material-symbols-outlined" style={{ fontSize: '18px' }}>{s.icon}</span>
                {s.cat}
             </div>
             <div style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
               {s.items.map((i, idx) => (
                 <div key={i.action} className="animate-in" style={{ 
                   display: 'flex', 
                   justifyContent: 'space-between', 
                   alignItems: 'center', 
                   padding: '12px 0', 
                   borderBottom: '1px solid var(--border)',
                   animationDelay: `${idx * 0.05}s`
                 }}>
                   <span style={{ fontSize: '13px', color: 'var(--text-secondary)', fontWeight: '500' }}>{i.action}</span>
                   <div style={{ display: 'flex', gap: '6px' }}>
                     {i.key.split(' + ').map(k => (
                       <kbd key={k} className="modern-kbd">{k}</kbd>
                     ))}
                   </div>
                 </div>
               ))}
             </div>
           </div>
         ))}
      </div>
    </div>
  );
}

function SettingsScreen({ onBack }: { onBack: () => void }) {
  return (
    <div className="screen active">
      <div className="tool-header">
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          <button className="back-btn" onClick={onBack} style={{ position: 'relative', top: 0 }}>
             <span className="material-symbols-outlined">arrow_back</span>
          </button>
          <div>
            <div className="pt">Application <span className="bl">Settings</span></div>
            <div className="ps" style={{ marginBottom: 0 }}>Configure performance, appearance, and defaults</div>
          </div>
        </div>
      </div>
      
      <div className="two-col" style={{ marginTop: '24px', gap: '24px' }}>
        <div className="panel animate-in">
          <div className="plabel" style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <span className="material-symbols-outlined" style={{ fontSize: '18px' }}>videocam</span>
            Video Engine Defaults
          </div>
          <div className="srow">
            <div className="slabel">GPU Acceleration (NVENC)</div>
            <div className="fmtb">
              <div className="fb active">Enabled</div>
              <div className="fb">Disabled</div>
            </div>
          </div>
          <div className="srow" style={{ marginTop: '20px' }}>
            <div className="slabel">FFmpeg Threading</div>
            <div className="fmtb">
              <div className="fb">Single</div>
              <div className="fb active">Multi</div>
            </div>
          </div>
          <div className="srow" style={{ marginTop: '20px' }}>
            <div className="slabel">Default Container</div>
            <div className="fmtb">
              <div className="fb active">MP4</div>
              <div className="fb">MKV</div>
              <div className="fb">MOV</div>
            </div>
          </div>
        </div>

        <div className="panel animate-in" style={{ animationDelay: '0.1s' }}>
          <div className="plabel" style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <span className="material-symbols-outlined" style={{ fontSize: '18px' }}>settings</span>
            General Preferences
          </div>
          <div className="srow">
            <div className="slabel">Max Concurrent Runs</div>
            <div className="fmtb">
              <div className="fb">1</div>
              <div className="fb active">3</div>
              <div className="fb">5</div>
            </div>
          </div>
          <div className="srow" style={{ marginTop: '20px' }}>
            <div className="slabel">Check for Updates</div>
            <div className="fmtb">
              <div className="fb active">Auto</div>
              <div className="fb">Manual</div>
            </div>
          </div>
          <div className="srow" style={{ marginTop: '20px' }}>
             <div className="slabel">System Log Level</div>
             <div className="sfield">
               <span className="material-symbols-outlined sfield-icon">bug_report</span>
               <select className="sinput" style={{ width: '100%', appearance: 'none', background: 'transparent' }}>
                  <option>Information</option>
                  <option>Debugging</option>
                  <option>None</option>
               </select>
               <span className="material-symbols-outlined" style={{ fontSize: '16px', opacity: 0.5, marginRight: '12px' }}>expand_more</span>
             </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function MonitorScreen({ onBack }: { onBack: () => void }) {
  return (
    <div className="screen active">
      <div className="tool-header">
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          <button className="back-btn" onClick={onBack} style={{ position: 'relative', top: 0 }}>
             <span className="material-symbols-outlined">arrow_back</span>
          </button>
          <div>
            <div className="pt">Resource <span className="bl">Monitor</span></div>
            <div className="ps" style={{ marginBottom: 0 }}>Real-time system impact of Formatica engines</div>
          </div>
        </div>
      </div>

      <div className="panel animate-in" style={{ marginTop: '24px', padding: '32px' }}>
        <div className="rm-header" style={{ marginBottom: '32px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
             <span className="material-symbols-outlined" style={{ color: 'var(--accent)' }}>analytics</span>
             <span className="rm-title" style={{ fontSize: '18px', fontWeight: '700' }}>Hardware Performance</span>
          </div>
          <div className="status-badge" style={{ background: 'rgba(0, 208, 132, 0.1)', color: '#00d084', border: '1px solid rgba(0, 208, 132, 0.2)' }}>
             <span className="pulse-dot" style={{ background: '#00d084', marginRight: '8px' }}></span>
             LIVE STREAMING
          </div>
        </div>

        <div className="two-col" style={{ gap: '40px' }}>
          <div className="rm-item">
            <div className="rm-item-top" style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '12px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <span className="material-symbols-outlined" style={{ fontSize: '18px', opacity: 0.7 }}>memory</span>
                <span className="rm-item-label" style={{ fontWeight: '600', fontSize: '13px' }}>CPU Utilization</span>
              </div>
              <span className="rm-item-val" style={{ color: 'var(--accent)', fontWeight: '800' }}>12.4%</span>
            </div>
            <div className="rm-bar-bg" style={{ height: '8px', borderRadius: '10px' }}>
              <div className="rm-bar-fill rm-cpu-fill" style={{ width: '12.4%', height: '100%', borderRadius: '10px' }}></div>
            </div>
          </div>

          <div className="rm-item">
            <div className="rm-item-top" style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '12px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <span className="material-symbols-outlined" style={{ fontSize: '18px', opacity: 0.7 }}>bolt</span>
                <span className="rm-item-label" style={{ fontWeight: '600', fontSize: '13px' }}>GPU Workload (NVENC)</span>
              </div>
              <span className="rm-item-val" style={{ color: '#00d084', fontWeight: '800' }}>8.1%</span>
            </div>
            <div className="rm-bar-bg" style={{ height: '8px', borderRadius: '10px' }}>
              <div className="rm-bar-fill rm-gpu-fill" style={{ width: '8.1%', height: '100%', borderRadius: '10px' }}></div>
            </div>
          </div>
        </div>

        <div className="two-col" style={{ gap: '40px', marginTop: '40px' }}>
          <div className="rm-item">
            <div className="rm-item-top" style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '12px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <span className="material-symbols-outlined" style={{ fontSize: '18px', opacity: 0.7 }}>speed</span>
                <span className="rm-item-label" style={{ fontWeight: '600', fontSize: '13px' }}>Memory Footprint</span>
              </div>
              <span className="rm-item-val" style={{ color: 'var(--amber)', fontWeight: '800' }}>1.24 GB</span>
            </div>
            <div className="rm-bar-bg" style={{ height: '8px', borderRadius: '10px' }}>
              <div className="rm-bar-fill" style={{ width: '45%', height: '100%', borderRadius: '10px', background: 'var(--amber)' }}></div>
            </div>
          </div>

          <div className="rm-item">
             <div className="rm-item-top" style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '12px' }}>
               <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                 <span className="material-symbols-outlined" style={{ fontSize: '18px', opacity: 0.7 }}>developer_board</span>
                 <span className="rm-item-label" style={{ fontWeight: '600', fontSize: '13px' }}>Engine Thread Pool</span>
               </div>
               <span className="rm-item-val" style={{ fontWeight: '800' }}>12 Active</span>
             </div>
             <div className="rm-bar-bg"><div className="rm-bar-fill rm-cpu-fill" style={{ width: '100%', opacity: 0.2 }}></div></div>
          </div>
        </div>
      </div>
    </div>
  );
}
