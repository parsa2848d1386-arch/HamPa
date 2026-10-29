import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  Search, 
  Play, 
  Sun, 
  Sparkles, 
  Calendar, 
  CheckSquare, 
  BarChart3, 
  Sunrise, 
  Sunset,
  HelpCircle,
  Clock,
  LayoutGrid,
  Sliders
} from 'lucide-react';
import { useAppStore } from '../../store/useAppStore';

export const CommandPalette: React.FC = () => {
  const isOpen = useAppStore((s) => s.isCommandPaletteOpen);
  const setOpen = useAppStore((s) => s.setCommandPaletteOpen);
  const setViewMode = useAppStore((s) => s.setViewMode);
  const toggleTheme = useAppStore((s) => s.toggleTheme);
  const setMorningPlanningOpen = useAppStore((s) => s.setMorningPlanningOpen);
  const setEveningReflectionOpen = useAppStore((s) => s.setEveningReflectionOpen);
  const setBrainDumpOpen = useAppStore((s) => s.setBrainDumpOpen);
  const setCheatSheetOpen = useAppStore((s) => s.setCheatSheetOpen);
  const setFocusModalOpen = useAppStore((s) => s.setFocusModalOpen);
  const setSettingsOpen = useAppStore((s) => s.setSettingsOpen);
  const setCalendarSystem = useAppStore((s) => s.setCalendarSystem);
  const calendarSystem = useAppStore((s) => s.calendarSystem);

  const [query, setQuery] = useState('');
  const [selectedIndex, setSelectedIndex] = useState(0);

  // Global hotkeys listener
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      const activeEl = document.activeElement;
      const isInput = activeEl?.tagName === 'INPUT' || activeEl?.tagName === 'TEXTAREA' || (activeEl as HTMLElement)?.isContentEditable;

      // Cmd+K or Ctrl+K
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 'k') {
        e.preventDefault();
        setOpen(!isOpen);
        return;
      }

      // If user is inside an input, do not trigger single-key hotkeys
      if (isInput) return;

      if (e.key === 'c' || e.key === 'C') {
        e.preventDefault();
        setBrainDumpOpen(true);
      } else if (e.key === 't' || e.key === 'T') {
        e.preventDefault();
        useAppStore.getState().setSelectedDate(new Date().toISOString().split('T')[0]);
      } else if (e.key === 'h' || e.key === 'H') {
        e.preventDefault();
        setViewMode('dashboard');
      } else if (e.key === 'd' || e.key === 'D') {
        e.preventDefault();
        setViewMode('day');
      } else if (e.key === 'w' || e.key === 'W') {
        e.preventDefault();
        setViewMode('week');
      } else if (e.key === 'm' || e.key === 'M') {
        e.preventDefault();
        setViewMode('month');
      } else if (e.key === 'f' || e.key === 'F') {
        e.preventDefault();
        setFocusModalOpen(true);
      } else if (e.key === 'b' || e.key === 'B') {
        e.preventDefault();
        setBrainDumpOpen(true);
      } else if (e.key === '?') {
        e.preventDefault();
        setCheatSheetOpen(true);
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [isOpen, setOpen, setViewMode, setFocusModalOpen, setBrainDumpOpen, setCheatSheetOpen]);

  const commands = [
    {
      id: 'view-dashboard',
      title: 'داشبورد اصلی و چندپنجره‌ای ویجت‌ها (Main Dashboard)',
      shortcut: 'H',
      icon: LayoutGrid,
      action: () => { setOpen(false); setViewMode('dashboard'); }
    },
    {
      id: 'brain-dump',
      title: 'هوش مصنوعی Brain Dump (تبدیل گفتار و ذهن‌ریزی به تسک)',
      shortcut: 'B',
      icon: Sparkles,
      action: () => { setOpen(false); setBrainDumpOpen(true); }
    },
    {
      id: 'focus-timer',
      title: 'شروع سشن تمرکز استودیویی (YPT Stopwatch / Pomodoro)',
      shortcut: 'F',
      icon: Play,
      action: () => { setOpen(false); setFocusModalOpen(true); }
    },
    {
      id: 'morning-ritual',
      title: 'آیین صبحگاهی سان‌ساما (تعیین ۳ تسک برتر روز - MIT)',
      shortcut: 'M R',
      icon: Sunrise,
      action: () => { setOpen(false); setMorningPlanningOpen(true); }
    },
    {
      id: 'evening-ritual',
      title: 'آیین شبانگاهی و تخلیه ذهن ۱۰ دقیقه‌ای (Evening Reflection)',
      shortcut: 'E R',
      icon: Sunset,
      action: () => { setOpen(false); setEveningReflectionOpen(true); }
    },
    {
      id: 'view-day',
      title: 'نمای تایم‌لاین بصری روزانه (Day Timeline)',
      shortcut: 'D',
      icon: Clock,
      action: () => { setOpen(false); setViewMode('day'); }
    },
    {
      id: 'view-week',
      title: 'نمای تقویم هفتگی با دقت ۱ پیکسلی (Week Grid)',
      shortcut: 'W',
      icon: Calendar,
      action: () => { setOpen(false); setViewMode('week'); }
    },
    {
      id: 'view-analytics',
      title: 'داشبورد آمار، هیت‌مپ و جدول ۲۴ ساعته',
      shortcut: 'A',
      icon: BarChart3,
      action: () => { setOpen(false); setViewMode('analytics'); }
    },
    {
      id: 'view-kanban',
      title: 'بورد کانبان تسک‌ها و وضعیت‌ها',
      shortcut: 'K',
      icon: CheckSquare,
      action: () => { setOpen(false); setViewMode('kanban'); }
    },
    {
      id: 'toggle-calendar',
      title: calendarSystem === 'jalali' ? 'تغییر تقویم به میلادی (Gregorian)' : 'تغییر تقویم به شمسی (Jalali)',
      shortcut: 'Alt + C',
      icon: Calendar,
      action: () => {
        setOpen(false);
        setCalendarSystem(calendarSystem === 'jalali' ? 'gregorian' : 'jalali');
      }
    },
    {
      id: 'open-settings',
      title: 'تنظیمات، شخصی‌سازی تم‌های تلگرامی و پروفایل کاربر',
      shortcut: 'Alt + S',
      icon: Sliders,
      action: () => { setOpen(false); setSettingsOpen(true); }
    },
    {
      id: 'toggle-theme',
      title: 'تغییر تم تاریک / روشن (Precision Dark / Mindful Light)',
      shortcut: 'Alt + T',
      icon: Sun,
      action: () => { setOpen(false); toggleTheme(); }
    },
    {
      id: 'shortcuts-help',
      title: 'مشاهده راهنمای کامل کلیدهای میانبر',
      shortcut: '?',
      icon: HelpCircle,
      action: () => { setOpen(false); setCheatSheetOpen(true); }
    }
  ];

  const filtered = commands.filter((c) =>
    c.title.toLowerCase().includes(query.toLowerCase()) ||
    c.shortcut.toLowerCase().includes(query.toLowerCase())
  );

  const handleSelect = (action: () => void) => {
    action();
    setQuery('');
  };

  if (!isOpen) return null;

  return (
    <AnimatePresence>
      <div className="fixed inset-0 z-50 flex items-start justify-center pt-[12vh] px-4">
        {/* Backdrop */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          onClick={() => setOpen(false)}
          className="fixed inset-0 bg-black/60 backdrop-blur-md"
        />

        {/* Floating Palette */}
        <motion.div
          initial={{ opacity: 0, scale: 0.96, y: -10 }}
          animate={{ opacity: 1, scale: 1, y: 0 }}
          exit={{ opacity: 0, scale: 0.96, y: -10 }}
          transition={{ type: 'spring', stiffness: 450, damping: 32 }}
          className="relative z-10 w-full max-w-xl rounded-squircle-lg bg-canvas-elevated liquid-glass border border-border-highlight shadow-2xl overflow-hidden"
        >
          {/* Search Input Bar */}
          <div className="flex items-center gap-3 px-4 py-3.5 border-b border-border-subtle">
            <Search className="w-5 h-5 text-ink-muted" />
            <input
              type="text"
              autoFocus
              placeholder="دستور یا عملکرد مورد نظر را جستجو کنید... (مثال: تمرکز، تقویم، ذهن‌ریزی)"
              value={query}
              onChange={(e) => {
                setQuery(e.target.value);
                setSelectedIndex(0);
              }}
              className="flex-1 bg-transparent text-ink-primary placeholder:text-ink-subtle text-sm outline-none font-vazir"
            />
            <kbd className="px-2 py-0.5 rounded-precision bg-white/10 text-[10px] text-ink-muted font-mono">
              ESC
            </kbd>
          </div>

          {/* Results List */}
          <div className="max-h-80 overflow-y-auto p-2 space-y-1">
            {filtered.length === 0 ? (
              <div className="py-8 text-center text-ink-subtle text-sm">
                موردی مطابق با جستجوی شما یافت نشد.
              </div>
            ) : (
              filtered.map((item, index) => {
                const Icon = item.icon;
                return (
                  <button
                    key={item.id}
                    onClick={() => handleSelect(item.action)}
                    onMouseEnter={() => setSelectedIndex(index)}
                    className={`w-full flex items-center justify-between px-3.5 py-2.5 rounded-precision-md text-right transition ${
                      selectedIndex === index
                        ? 'bg-accent-primary/15 text-accent-primary border border-accent-primary/30'
                        : 'text-ink-primary hover:bg-white/5 border border-transparent'
                    }`}
                  >
                    <div className="flex items-center gap-3">
                      <Icon className="w-4 h-4 opacity-80" />
                      <span className="text-xs md:text-sm font-medium">{item.title}</span>
                    </div>
                    <kbd className="px-2 py-0.5 rounded-precision bg-black/30 text-[11px] font-mono text-ink-muted">
                      {item.shortcut}
                    </kbd>
                  </button>
                );
              })
            )}
          </div>

          {/* Footer info */}
          <div className="px-4 py-2 border-t border-border-subtle bg-canvas-secondary/30 flex items-center justify-between text-[11px] text-ink-muted">
            <span>از کلیدهای میانبر برای دسترسی فوق سریع استفاده کنید</span>
            <span>HamPA v1.0 • Cron Inspired</span>
          </div>
        </motion.div>
      </div>
    </AnimatePresence>
  );
};
