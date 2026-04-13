

interface TopBarProps {
  theme: "dark" | "light";
  onThemeToggle: () => void;
  deps: any[];
  onFixDeps: () => void;
}

export function TopBar({ theme, onThemeToggle, deps, onFixDeps }: TopBarProps) {
  const allOk = deps.length > 0 && deps.every((d) => d.installed);

  return (
    <header className="top-app-bar">
      <div className="logo-wrap">
        <div className="logo-icon">F</div>
        <div>
          <div className="appname" style={{ fontWeight: 800, fontSize: '15px' }}>Formatica</div>
          <div className="appsub">The Ethereal Prism</div>
        </div>
      </div>

      <div className="tr">
        <div style={{ display: 'flex', gap: '8px', marginRight: '16px' }}>
          {deps.map((d) => (
            <span
              key={d.name}
              className={`dpill ${d.installed ? "d-ok" : "d-err"}`}
              style={{ fontSize: '9px', opacity: 0.8 }}
            >
              {d.name}
            </span>
          ))}
        </div>
        
        <div className="theme-switch" onClick={onThemeToggle}>
          <span className="material-symbols-outlined" style={{ fontSize: '20px' }}>
            {theme === "dark" ? "light_mode" : "dark_mode"}
          </span>
        </div>
      </div>
    </header>
  );
}
