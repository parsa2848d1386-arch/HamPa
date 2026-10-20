import React from 'react';
import { 
  Plus, 
  Sparkles, 
  Play, 
  Sun, 
  Moon, 
  Sunrise, 
  Sunset, 
  HelpCircle, 
  PanelRight,
  Clock
} from 'lucide-react';
import { useAppStore } from '../../store/useAppStore';

export const DesktopBottomDocks: React.FC = () => {
  const isDark = useAppStore((s) => s.isDark);
  const toggleTheme = useAppStore((s) => s.toggleTheme);
  const setCreateTaskOpen = useAppStore((s) => s.setCreateTaskOpen);
  const setBrainDumpOpen = useAppStore((s) => s.setBrainDumpOpen);
  const setMorningPlanningOpen = useAppStore((s) => s.setMorningPlanningOpen);
  const setEveningReflectionOpen = useAppStore((s) => s.setEveningReflectionOpen);
  const setCheatSheetOpen = useAppStore((s) => s.setCheatSheetOpen);
  const setFocusModalOpen = useAppStore((s) => s.setFocusModalOpen);
  const isTimerRunning = useAppStore((s) => s.isTimerRunning);
  const timerSeconds = useAppStore((s) => s.timerSeconds);
  const isRightInspectorOpen = useAppStore((s) => s.isRightInspectorOpen);
  const toggleRightInspector = useAppStore((s) => s.toggleRightInspector);

  const formatTimer = (sec: number) => {
    const h = Math.floor(sec / 3600);
    const m = Math.floor((sec % 3600) / 60);
    const s = sec % 60;
    if (h > 0) return `${h}:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
    return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
  };

  return (
    <>
      {/* ========================================================
          LEFT BOTTOM DOCK (چپ پایین - دسکتاپ)
          آیین‌های صبح و شب، تغییر تم و راهنما
          ======================================================== */}
      <div className="hidden md:flex fixed bottom-4 left-4 z-40 items-center gap-1.5 p-1.5 rounded-2xl bg-canvas-elevated liquid-glass border border-border-subtle shadow-2xl backdrop-blur-xl select-none transition-all duration-200">
        {/* Morning Ritual */}
        <button
          onClick={() => setMorningPlanningOpen(true)}
          className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl border border-border-subtle hover:bg-black/5 dark:hover:bg-white/10 text-xs text-ink-muted hover:text-ink-primary transition active:scale-95"
          title="آیین صبحگاهی سان‌ساما (تعیین ۳ تسک طلایی)"
        >
          <Sunrise className="w-4 h-4 text-amber-500" />
          <span className="font-medium">آیین صبح</span>
        </button>

        {/* Evening Reflection */}
        <button
          onClick={() => setEveningReflectionOpen(true)}
          className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl border border-border-subtle hover:bg-black/5 dark:hover:bg-white/10 text-xs text-ink-muted hover:text-ink-primary transition active:scale-95"
          title="آیین شبانگاهی و تخلیه ذهن"
        >
          <Sunset className="w-4 h-4 text-indigo-400" />
          <span className="font-medium">آیین شب</span>
        </button>

        {/* Theme Toggle */}
        <button
          onClick={toggleTheme}
          className="p-2 rounded-xl border border-border-subtle hover:bg-black/5 dark:hover:bg-white/10 text-ink-muted hover:text-ink-primary transition active:scale-90"
          title={isDark ? 'تغییر به تم روشن' : 'تغییر به تم تاریک'}
        >
          {isDark ? <Sun className="w-4 h-4 text-amber-400" /> : <Moon className="w-4 h-4 text-indigo-500" />}
        </button>

        {/* Shortcut Cheat Sheet */}
        <button
          onClick={() => setCheatSheetOpen(true)}
          className="p-2 rounded-xl border border-border-subtle hover:bg-black/5 dark:hover:bg-white/10 text-ink-muted hover:text-ink-primary transition active:scale-90"
          title="راهنمای کلیدهای میانبر کیبورد (?)"
        >
          <HelpCircle className="w-4 h-4" />
        </button>
      </div>

      {/* ========================================================
          RIGHT BOTTOM DOCK (راست پایین - دسکتاپ)
          تسک جدید، هوش مصنوعی Brain Dump، تایمر تمرکز و اینسپکتور
          ======================================================== */}
      <div className="hidden md:flex fixed bottom-4 right-4 z-40 items-center gap-2 p-1.5 rounded-2xl bg-canvas-elevated liquid-glass border border-border-subtle shadow-2xl backdrop-blur-xl select-none transition-all duration-200">
        {/* Right Inspector Panel Toggle */}
        <button
          onClick={toggleRightInspector}
          className={`p-2 rounded-xl border transition flex items-center justify-center touch-target ${
            isRightInspectorOpen
              ? 'bg-accent-primary/20 text-accent-primary border-accent-primary/40'
              : 'border-border-subtle hover:bg-black/5 dark:hover:bg-white/10 text-ink-muted hover:text-ink-primary'
          }`}
          title="نمایش / مخفی‌سازی پنل یادداشت و جزئیات تسک"
        >
          <PanelRight className="w-4 h-4" />
        </button>

        {/* Focus Timer Trigger & Live Badge */}
        <button
          onClick={() => setFocusModalOpen(true)}
          className={`flex items-center gap-2 px-3 py-1.5 rounded-xl border text-xs font-bold transition active:scale-95 ${
            isTimerRunning
              ? 'bg-accent-primary/20 text-accent-primary border-accent-primary/50 animate-pulse'
              : 'bg-canvas-secondary border-border-subtle text-ink-muted hover:text-ink-primary hover:bg-black/5 dark:hover:bg-white/10'
          }`}
          title="استودیوی تمرکز و تایمر مطالعه YPT"
        >
          <Play className="w-4 h-4 fill-current text-accent-primary" />
          <span className="font-mono">
            {isTimerRunning ? formatTimer(timerSeconds) : 'تمرکز YPT'}
          </span>
        </button>

        {/* AI Brain Dump */}
        <button
          onClick={() => setBrainDumpOpen(true)}
          className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-canvas-secondary hover:bg-white/10 text-ink-primary border border-border-subtle text-xs font-bold shadow-sm transition active:scale-95"
          title="ذهن‌ریزی هوشمند با هوش مصنوعی (B)"
        >
          <Sparkles className="w-4 h-4 text-accent-primary" />
          <span>Brain Dump</span>
        </button>

        {/* Primary "+ تسک جدید" Button */}
        <button
          onClick={() => setCreateTaskOpen(true)}
          className="flex items-center gap-1.5 px-4 py-2 rounded-xl bg-accent-primary hover:bg-accent-hover text-white text-xs font-black shadow-needle transition active:scale-95"
          title="افزودن فعالیت جدید (C)"
        >
          <Plus className="w-4 h-4" />
          <span>تسک جدید</span>
          <kbd className="hidden xl:inline text-[10px] bg-black/20 px-1 py-0.5 rounded mr-1">C</kbd>
        </button>
      </div>
    </>
  );
};
