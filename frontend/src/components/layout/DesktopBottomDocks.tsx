import React from 'react';
import { 
  Plus, 
  Sparkles, 
  Sunrise, 
  Sunset, 
  HelpCircle, 
  Sliders,
  FileText
} from 'lucide-react';
import { useAppStore } from '../../store/useAppStore';

export const DesktopBottomDocks: React.FC = () => {
  const setCreateTaskOpen = useAppStore((s) => s.setCreateTaskOpen);
  const setBrainDumpOpen = useAppStore((s) => s.setBrainDumpOpen);
  const setMorningPlanningOpen = useAppStore((s) => s.setMorningPlanningOpen);
  const setEveningReflectionOpen = useAppStore((s) => s.setEveningReflectionOpen);
  const setCheatSheetOpen = useAppStore((s) => s.setCheatSheetOpen);
  const setSettingsOpen = useAppStore((s) => s.setSettingsOpen);
  const isRightInspectorOpen = useAppStore((s) => s.isRightInspectorOpen);
  const toggleRightInspector = useAppStore((s) => s.toggleRightInspector);

  return (
    <>
      {/* ========================================================
          LEFT BOTTOM DOCK (چپ پایین - دسکتاپ)
          آیین‌های روزانه، تنظیمات و راهنمای کلیدها
          ======================================================== */}
      <div className="hidden md:flex fixed bottom-4 left-4 z-40 items-center gap-1.5 p-1.5 rounded-2xl bg-canvas-elevated liquid-glass border border-border-subtle shadow-2xl backdrop-blur-xl select-none transition-all duration-200">
        {/* Morning Ritual */}
        <button
          onClick={() => setMorningPlanningOpen(true)}
          className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl border border-border-subtle hover:bg-black/5 dark:hover:bg-white/10 text-xs text-ink-muted hover:text-ink-primary transition active:scale-95 cursor-pointer"
          title="آیین صبحگاهی سان‌ساما (تعیین ۳ تسک طلایی)"
        >
          <Sunrise className="w-4 h-4 text-amber-500" />
          <span className="font-medium">آیین صبح</span>
        </button>

        {/* Evening Reflection */}
        <button
          onClick={() => setEveningReflectionOpen(true)}
          className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl border border-border-subtle hover:bg-black/5 dark:hover:bg-white/10 text-xs text-ink-muted hover:text-ink-primary transition active:scale-95 cursor-pointer"
          title="آیین شبانگاهی و تخلیه ذهن"
        >
          <Sunset className="w-4 h-4 text-indigo-400" />
          <span className="font-medium">آیین شب</span>
        </button>

        {/* Settings & Themes Quick Link */}
        <button
          onClick={() => setSettingsOpen(true)}
          className="p-2 rounded-xl border border-border-subtle hover:bg-black/5 dark:hover:bg-white/10 text-ink-muted hover:text-accent-primary transition active:scale-90 cursor-pointer"
          title="تنظیمات، تم‌های تلگرامی و پروفایل"
        >
          <Sliders className="w-4 h-4" />
        </button>

        {/* Shortcut Cheat Sheet */}
        <button
          onClick={() => setCheatSheetOpen(true)}
          className="p-2 rounded-xl border border-border-subtle hover:bg-black/5 dark:hover:bg-white/10 text-ink-muted hover:text-ink-primary transition active:scale-90 cursor-pointer"
          title="راهنمای کلیدهای میانبر کیبورد (?)"
        >
          <HelpCircle className="w-4 h-4" />
        </button>
      </div>

      {/* ========================================================
          RIGHT BOTTOM DOCK (راست پایین - دسکتاپ)
          اکشن‌های اصلی: تسک جدید، Brain Dump و یادداشت‌های تسک
          ======================================================== */}
      <div className="hidden md:flex fixed bottom-4 right-4 z-40 items-center gap-2 p-1.5 rounded-2xl bg-canvas-elevated liquid-glass border border-border-subtle shadow-2xl backdrop-blur-xl select-none transition-all duration-200">
        {/* Task Inspector & Block Notes Toggle */}
        <button
          onClick={toggleRightInspector}
          className={`flex items-center gap-1.5 px-2.5 py-1.5 rounded-xl border transition text-xs cursor-pointer ${
            isRightInspectorOpen
              ? 'bg-accent-primary/20 text-accent-primary border-accent-primary/40 font-bold'
              : 'border-border-subtle hover:bg-black/5 dark:hover:bg-white/10 text-ink-muted hover:text-ink-primary'
          }`}
          title="مشاهده یادداشت‌های بلوکی و چک‌لیست تسک انتخابی"
        >
          <FileText className="w-4 h-4" />
          <span className="hidden lg:inline text-[11px]">یادداشت‌ها</span>
        </button>

        {/* AI Brain Dump */}
        <button
          onClick={() => setBrainDumpOpen(true)}
          className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-canvas-secondary hover:bg-white/10 text-ink-primary border border-border-subtle text-xs font-bold shadow-sm transition active:scale-95 cursor-pointer"
          title="ذهن‌ریزی هوشمند با هوش مصنوعی (B)"
        >
          <Sparkles className="w-4 h-4 text-accent-primary" />
          <span>Brain Dump</span>
        </button>

        {/* Primary "+ تسک جدید" Button */}
        <button
          onClick={() => setCreateTaskOpen(true)}
          className="flex items-center gap-1.5 px-4 py-2 rounded-xl bg-accent-primary hover:bg-accent-hover text-white text-xs font-black shadow-needle transition active:scale-95 cursor-pointer"
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
