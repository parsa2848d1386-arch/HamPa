import React from 'react';
import { motion } from 'framer-motion';
import { 
  ChevronRight, 
  ChevronLeft, 
  Sparkles, 
  Search, 
  Clock, 
  Columns, 
  Grid, 
  Users, 
  PenTool, 
  BarChart2, 
  Layout, 
  Columns3, 
  Plus, 
  PanelLeft, 
  PanelRight,
  LayoutGrid
} from 'lucide-react';
import { useAppStore } from '../../store/useAppStore';
import { formatDateTitle } from '../../lib/calendarUtils';

const NAV_TABS = [
  { id: 'dashboard', label: 'داشبورد', icon: LayoutGrid },
  { id: 'day', label: 'تایم‌لاین', icon: Clock },
  { id: 'dual_planner', label: 'پلنر ۱۰ دقیقه‌ای', icon: Columns },
  { id: 'eisenhower', label: 'ماتریس آیزنهاور', icon: Grid },
  { id: 'kanban', label: 'کانبان', icon: Layout },
  { id: 'analytics', label: 'آمار YPT', icon: BarChart2 },
  { id: 'study_room', label: 'اتاق زنده', icon: Users },
  { id: 'stylus', label: 'بوم قلم', icon: PenTool },
  { id: 'week', label: 'هفتگی', icon: Columns3 },
] as const;

export const HeaderBar: React.FC = () => {
  const viewMode = useAppStore((s) => s.viewMode);
  const setViewMode = useAppStore((s) => s.setViewMode);
  const calendarSystem = useAppStore((s) => s.calendarSystem);
  const setCalendarSystem = useAppStore((s) => s.setCalendarSystem);
  const selectedDate = useAppStore((s) => s.selectedDate);
  const setSelectedDate = useAppStore((s) => s.setSelectedDate);
  const setCommandPaletteOpen = useAppStore((s) => s.setCommandPaletteOpen);
  const isLeftSidebarOpen = useAppStore((s) => s.isLeftSidebarOpen);
  const toggleLeftSidebar = useAppStore((s) => s.toggleLeftSidebar);
  const user = useAppStore((s) => s.user);

  const currentDateObj = new Date(selectedDate);

  const handlePrevDay = () => {
    const d = new Date(currentDateObj);
    d.setDate(d.getDate() - 1);
    setSelectedDate(d.toISOString().split('T')[0]);
  };

  const handleNextDay = () => {
    const d = new Date(currentDateObj);
    d.setDate(d.getDate() + 1);
    setSelectedDate(d.toISOString().split('T')[0]);
  };

  const handleToday = () => {
    setSelectedDate(new Date().toISOString().split('T')[0]);
  };

  return (
    <header className="h-14 border-b border-border-subtle bg-canvas-elevated liquid-glass sticky top-0 z-40 flex items-center justify-between px-3 md:px-5 select-none transition-colors duration-200">
      {/* ========================================================
          RIGHT / START (RTL): Brand & Date Navigator
          ======================================================== */}
      <div className="flex items-center gap-2 md:gap-3">
        {/* Left Sidebar Toggle Button */}
        <button
          onClick={toggleLeftSidebar}
          className={`p-1.5 rounded-xl border transition flex items-center justify-center touch-target ${
            isLeftSidebarOpen
              ? 'bg-accent-primary/20 text-accent-primary border-accent-primary/40'
              : 'border-border-subtle hover:bg-white/5 text-ink-muted hover:text-ink-primary'
          }`}
          title="سایدبار تقویم و دروس"
          aria-label="سایدبار تقویم"
        >
          <PanelLeft className="w-4 h-4" />
        </button>

        {/* Brand Pill */}
        <div className="flex items-center gap-2 pl-2 border-l border-border-subtle">
          <div className="w-7 h-7 rounded-xl bg-accent-primary flex items-center justify-center text-white font-black text-xs shadow-needle">
            هم
          </div>
          <span className="font-black text-sm tracking-tight hidden sm:inline-block text-ink-primary">هم‌پا</span>
        </div>

        {/* Date Controls */}
        <div className="flex items-center gap-1">
          <button
            onClick={handleToday}
            className="px-2.5 py-1 text-xs font-semibold rounded-lg border border-border-subtle hover:bg-white/5 active:scale-95 transition text-ink-primary"
          >
            امروز
          </button>

          <div className="flex items-center border border-border-subtle rounded-lg overflow-hidden">
            <button
              onClick={handlePrevDay}
              className="p-1 hover:bg-white/5 text-ink-muted hover:text-ink-primary transition"
              title="روز قبل"
            >
              <ChevronRight className="w-4 h-4" />
            </button>
            <button
              onClick={handleNextDay}
              className="p-1 hover:bg-white/5 text-ink-muted hover:text-ink-primary transition"
              title="روز بعد"
            >
              <ChevronLeft className="w-4 h-4" />
            </button>
          </div>

          <span className="text-xs md:text-sm font-bold text-ink-primary mr-1 whitespace-nowrap">
            {formatDateTitle(currentDateObj, calendarSystem)}
          </span>
        </div>

        {/* Dual Calendar Switcher */}
        <div className="hidden xl:flex items-center p-0.5 rounded-lg bg-canvas-secondary border border-border-subtle text-[11px]">
          <button
            onClick={() => setCalendarSystem('jalali')}
            className={`px-2 py-0.5 rounded-md transition font-medium ${
              calendarSystem === 'jalali'
                ? 'bg-accent-primary text-white font-bold shadow-sm'
                : 'text-ink-muted hover:text-ink-primary'
            }`}
          >
            شمسی
          </button>
          <button
            onClick={() => setCalendarSystem('gregorian')}
            className={`px-2 py-0.5 rounded-md transition font-medium ${
              calendarSystem === 'gregorian'
                ? 'bg-accent-primary text-white font-bold shadow-sm'
                : 'text-ink-muted hover:text-ink-primary'
            }`}
          >
            میلادی
          </button>
        </div>
      </div>

      {/* ========================================================
          CENTER: Clean View Switcher (Desktop Navigation Tabs)
          ======================================================== */}
      <div className="hidden md:flex items-center p-0.5 rounded-xl bg-canvas-secondary border border-border-subtle text-xs overflow-x-auto max-w-[680px]">
        {NAV_TABS.map((tab) => {
          const Icon = tab.icon;
          const isActive = viewMode === tab.id;
          return (
            <button
              key={tab.id}
              onClick={() => setViewMode(tab.id as any)}
              className={`relative flex items-center gap-1.5 px-3 py-1.5 rounded-lg transition-colors whitespace-nowrap text-xs ${
                isActive ? 'text-white font-bold' : 'text-ink-muted hover:text-ink-primary'
              }`}
            >
              {isActive && (
                <motion.div
                  layoutId="headerActiveTab"
                  className="absolute inset-0 bg-accent-primary rounded-lg shadow-sm"
                  transition={{ type: 'spring', stiffness: 500, damping: 35 }}
                />
              )}
              <Icon className="w-3.5 h-3.5 relative z-10" />
              <span className="relative z-10">{tab.label}</span>
            </button>
          );
        })}
      </div>

      {/* ========================================================
          LEFT / END (RTL): Command Palette & User Profile
          (Uncluttered, clean!)
          ======================================================== */}
      <div className="flex items-center gap-2">
        {/* Command Palette Trigger */}
        <button
          onClick={() => setCommandPaletteOpen(true)}
          className="p-1.5 md:px-2.5 md:py-1 rounded-xl border border-border-subtle hover:bg-white/5 text-ink-muted hover:text-ink-primary transition flex items-center gap-1.5 text-xs"
          title="جستجو و پالت دستورات (Cmd+K)"
        >
          <Search className="w-4 h-4" />
          <span className="hidden lg:inline text-ink-muted">جستجو</span>
          <kbd className="hidden lg:inline text-[10px] font-mono bg-white/5 px-1 py-0.5 rounded border border-border-subtle">⌘K</kbd>
        </button>

        {/* User Profile Avatar */}
        <div className="flex items-center gap-2 pr-1 border-r border-border-subtle">
          <div className="w-7 h-7 rounded-full bg-gradient-to-tr from-accent-primary to-amber-500 flex items-center justify-center text-white text-xs font-bold uppercase shadow-sm">
            {user.displayName ? user.displayName.slice(0, 1) : 'ک'}
          </div>
        </div>
      </div>
    </header>
  );
};
