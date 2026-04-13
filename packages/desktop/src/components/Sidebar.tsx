interface SidebarProps {
  currentScreen: string;
  onNavigate: (screen: string) => void;
}

export function Sidebar({ currentScreen, onNavigate }: SidebarProps) {
  const items = [
    { id: "home", icon: "home", label: "Home" },
    { id: "queue", icon: "bolt", label: "Queue" },
    { id: "monitor", icon: "monitoring", label: "Monitor" },
    { id: "settings", icon: "settings", label: "Settings" },
  ];

  return (
    <nav className="navigation-dock">
      {items.map((item) => (
        <div
          key={item.id}
          className={`dock-item ${currentScreen === item.id ? "active" : ""}`}
          onClick={() => onNavigate(item.id)}
          title={item.label}
        >
          <span className="material-symbols-outlined">{item.icon}</span>
        </div>
      ))}
    </nav>
  );
}
