import { ReactNode } from "react";
import { TopBar } from "./TopBar";
import { Sidebar } from "./Sidebar";
import { HistoryPanel } from "./HistoryPanel";

interface LayoutProps {
  theme: "dark" | "light";
  onThemeToggle: () => void;
  currentScreen: string;
  onNavigate: (screen: string) => void;
  deps: any[];
  onFixDeps: () => void;
  children: ReactNode;
}

export function Layout({
  theme,
  onThemeToggle,
  currentScreen,
  onNavigate,
  deps,
  onFixDeps,
  children,
}: LayoutProps) {
  return (
    <div className={`app theme-${theme}`}>
      <div className="mesh-gradient mesh-gradient-dark" />
      
      <TopBar
        theme={theme}
        onThemeToggle={onThemeToggle}
        deps={deps}
        onFixDeps={onFixDeps}
      />

      <main className="main-viewport scrollbar-hide">
        {children}
      </main>

      <Sidebar currentScreen={currentScreen} onNavigate={onNavigate} />
    </div>
  );
}
