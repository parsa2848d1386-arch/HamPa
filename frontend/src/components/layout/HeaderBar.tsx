import React from 'react';
import { 
  ChevronRight, 
  ChevronLeft, 
  Search, 
  Clock, 
  Columns, 
  Grid, 
  Users, 
  PenTool, 
  BarChart2, 
  Layout, 
  Columns3, 
  PanelLeft, 
  LayoutGrid,
  Sun,
  Moon,
  Volume2
} from 'lucide-react';
import { useAppStore } from '../../store/useAppStore';
import { formatDateTitle } from '../../lib/calendarUtils';

const NAV_TABS = [
  { id: 'dashboard', label: 'داشبورد', icon: LayoutGrid },
  { id: 'day', label: 'تایم‌لاین', icon: Clock },
  { id: 'dual_planner', label: 'پلنر ۱۰د', icon: Columns },
  { id: 'eisenhower', label: 'آیزنهاور', icon: Grid },
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
  const selectedDate = useAppStore((s) => s.selectedDate);
  const setSelectedDate = useAppStore((s) => s.setSelectedDate);
  const setCommandPaletteOpen = useAppStore((s) => s.setCommandPaletteOpen);
  const isLeftSidebarOpen = useAppStore((s) => s.isLeftSidebarOpen);
  const toggleLeftSidebar = useAppStore((s) => s.toggleLeftSidebar);
  const user = useAppStore((s) => s.user);
  const isDark = useAppStore((s) => s.isDark);
  const toggleTheme = useAppStore((s) => s.toggleTheme);
  const ambientSound = useAppStore((s) => s.ambientSound);
  const setAmbientSound = useAppStore((s) => s.setAmbientSound);
  const isTimerRunning = useAppStore((s) => s.isTimerRunning);
  const timerSeconds = useAppStore((s) => s.timerSeconds);
  const setFocusModalOpen = useAppStore((s) => s.setFocusModalOpen);
  const setSettingsOpen = useAppStore((s) => s.setSettingsOpen);

  const currentDateObj = new Date(selectedDate);
  const timerHours = Math.floor(timerSeconds / 3600);
  const timerMins = Math.floor((timerSeconds % 3600) / 60);
  const timerSecs = timerSeconds % 60;
  const timerDisplay = `${timerHours > 0 ? `${timerHours.toString().padStart(2, '0')}:` : ''}${timerMins.toString().padStart(2, '0')}:${timerSecs.toString().padStart(2, '0')}`;

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
    <header className="h-14 border-b border-border-subtle bg-canvas-elevated liquid-glass sticky top-0 z-50 flex items-center justify-between px-2 sm:px-4 select-none transition-colors duration-200 gap-2">
      {/* ========================================================
          RIGHT / START (RTL): Brand & Date Navigator
          ======================================================== */}
      <div className="flex items-center gap-1.5 sm:gap-2 flex-shrink-0">
        {/* Left Sidebar Toggle Button */}
        <button
          type="button"
          onClick={toggleLeftSidebar}
          className={`p-1.5 rounded-xl border transition flex items-center justify-center cursor-pointer ${
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
        <div className="flex items-center gap-1.5 pl-1.5 border-l border-border-subtle">
          <div className="w-6 h-6 rounded-lg bg-accent-primary flex items-center justify-center text-white font-black text-[11px] shadow-needle">
            هم
          </div>
          <span className="font-black text-xs hidden lg:inline-block text-ink-primary">هم‌پا</span>
        </div>

        {/* Date Controls */}
        <div className="flex items-center gap-1">
          <button
            type="button"
            onClick={handleToday}
            className="px-2 py-1 text-xs font-bold rounded-lg border border-border-subtle hover:bg-white/5 active:scale-95 transition text-ink-primary cursor-pointer"
          >
            امروز
          </button>

          <div className="flex items-center border border-border-subtle rounded-lg overflow-hidden">
            <button
              type="button"
              onClick={handlePrevDay}
              className="p-1 hover:bg-white/5 text-ink-muted hover:text-ink-primary transition cursor-pointer"
              title="روز قبل"
              aria-label="روز قبل"
            >
              <ChevronRight className="w-3.5 h-3.5" />
            </button>
            <button
              type="button"
              onClick={handleNextDay}
              className="p-1 hover:bg-white/5 text-ink-muted hover:text-ink-primary transition cursor-pointer"
              title="روز بعد"
              aria-label="روز بعد"
            >
              <ChevronLeft className="w-3.5 h-3.5" />
            </button>
          </div>

          <span className="text-xs font-bold text-ink-primary whitespace-nowrap hidden sm:inline">
            {formatDateTitle(currentDateObj, calendarSystem)}
          </span>
        </div>
      </div>

      {/* ========================================================
          CENTER: Unified View Switcher (All 9 Tabs Side-by-Side Without Scroll)
          ======================================================== */}
      <nav 
        role="tablist" 
        aria-label="نماهای کاری هم‌پا" 
        className="hidden md:flex items-center justify-center gap-0.5 lg:gap-1 p-0.5 rounded-xl bg-canvas-secondary/70 border border-border-subtle overflow-hidden flex-shrink-0"
      >
        {NAV_TABS.map((tab) => {
          const Icon = tab.icon;
          const isActive = viewMode === tab.id;
          return (
            <button
              key={tab.id}
              role="tab"
              type="button"
              aria-selected={isActive}
              onClick={() => setViewMode(tab.id as any)}
              className={`flex items-center justify-center gap-1 px-1.5 lg:px-2.5 py-1.5 rounded-lg text-xs font-bold transition-all cursor-pointer whitespace-nowrap active:scale-95 ${
                isActive
                  ? 'bg-accent-primary text-white shadow-sm'
                  : 'text-ink-muted hover:text-ink-primary hover:bg-black/5 dark:hover:bg-white/5'
              }`}
              title={tab.label}
            >
              <Icon className="w-3.5 h-3.5 flex-shrink-0" />
              <span className="text-[11px] lg:text-xs">{tab.label}</span>
            </button>
          );
        })}
      </nav>

      {/* ========================================================
          LEFT / END (RTL): Live Status Pills, Search, Theme & Profile
          ======================================================== */}
      <div className="flex items-center gap-1 sm:gap-1.5 flex-shrink-0">
        {/* Live Active Timer Capsule */}
        {isTimerRunning && (
          <button
            type="button"
            onClick={() => setFocusModalOpen(true)}
            className="flex items-center gap-1.5 px-2 py-1 rounded-full bg-accent-primary/15 border border-accent-primary/40 text-accent-primary text-xs font-mono font-bold hover:bg-accent-primary/25 transition active:scale-95 cursor-pointer"
            title="مشاهده استودیو تمرکز زنده"
            aria-label={`تایمر تمرکز فعال: ${timerDisplay}`}
          >
            <span className="w-2 h-2 rounded-full bg-accent-primary shadow-needle animate-pulse" />
            <span className="tabular-nums">{timerDisplay}</span>
          </button>
        )}

        {/* Live Ambient Sound Capsule */}
        {ambientSound.isPlaying && (
          <button
            type="button"
            onClick={() => setAmbientSound('none')}
            className="flex items-center gap-1 px-2 py-1 rounded-full bg-indigo-500/15 border border-indigo-500/40 text-indigo-400 text-xs font-bold hover:bg-indigo-500/25 transition active:scale-95 cursor-pointer"
            title="توقف صدای آرامش‌بخش محیطی"
            aria-label="صدای محیطی در حال پخش - کلیک برای توقف"
          >
            <Volume2 className="w-3 h-3 animate-bounce" />
            <span className="hidden xl:inline text-[11px]">محیطی</span>
          </button>
        )}

        {/* Theme Toggle (Light / Dark Mode) */}
        <button
          type="button"
          onClick={toggleTheme}
          className="p-1.5 rounded-xl border border-border-subtle hover:bg-white/5 text-ink-muted hover:text-ink-primary transition cursor-pointer"
          title={isDark ? 'تغییر به تم روشن Mindful' : 'تغییر به تم تیره Precision'}
          aria-label={isDark ? 'فعال‌سازی تم روشن' : 'فعال‌سازی تم تیره'}
        >
          {isDark ? (
            <Sun className="w-4 h-4 text-amber-400" />
          ) : (
            <Moon className="w-4 h-4 text-indigo-400" />
          )}
        </button>

        {/* Command Palette Trigger */}
        <button
          type="button"
          onClick={() => setCommandPaletteOpen(true)}
          className="p-1.5 rounded-xl border border-border-subtle hover:bg-white/5 text-ink-muted hover:text-ink-primary transition flex items-center gap-1 text-xs cursor-pointer"
          title="جستجو و پالت دستورات (Cmd+K)"
          aria-label="جستجو و پالت دستورات سریع"
        >
          <Search className="w-4 h-4" />
          <kbd className="hidden 2xl:inline text-[10px] font-mono bg-white/5 px-1 py-0.5 rounded border border-border-subtle">⌘K</kbd>
        </button>

        {/* User Profile Avatar & Settings Trigger */}
        <div className="flex items-center pr-1 border-r border-border-subtle">
          <button 
            type="button"
            onClick={() => setSettingsOpen(true)}
            className="group flex items-center gap-1.5 p-0.5 rounded-full hover:ring-2 hover:ring-accent-primary/50 transition cursor-pointer active:scale-95"
            title="تنظیمات، شخصی‌سازی تم و پروفایل کاربری (Alt+S)"
            aria-label="باز کردن تنظیمات و پروفایل کاربری"
          >
            <div 
              className="w-7 h-7 rounded-full bg-gradient-to-tr from-accent-primary to-amber-500 flex items-center justify-center text-white text-xs font-black uppercase shadow-needle transition group-hover:scale-105"
            >
              {user.displayName ? user.displayName.slice(0, 1) : 'ک'}
            </div>
            <span className="hidden 2xl:inline text-xs font-bold text-ink-primary max-w-[80px] truncate">
              {user.displayName || 'کاربر'}
            </span>
          </button>
        </div>
      </div>
    </header>
  );
};
