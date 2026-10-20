import React, { useState } from 'react';
import { 
  Clock, 
  Play, 
  BarChart2, 
  Sparkles, 
  Plus, 
  X, 
  Columns, 
  Grid, 
  Users, 
  PenTool,
  MoreHorizontal,
  LayoutGrid,
  Sunrise,
  Sunset,
  Sun,
  Moon
} from 'lucide-react';
import { useAppStore } from '../../store/useAppStore';
import { motion, AnimatePresence } from 'framer-motion';

export const MobileTabBar: React.FC = () => {
  const viewMode = useAppStore((s) => s.viewMode);
  const setViewMode = useAppStore((s) => s.setViewMode);
  const setCreateTaskOpen = useAppStore((s) => s.setCreateTaskOpen);
  const setBrainDumpOpen = useAppStore((s) => s.setBrainDumpOpen);
  const setFocusModalOpen = useAppStore((s) => s.setFocusModalOpen);
  const setMorningPlanningOpen = useAppStore((s) => s.setMorningPlanningOpen);
  const setEveningReflectionOpen = useAppStore((s) => s.setEveningReflectionOpen);
  const toggleTheme = useAppStore((s) => s.toggleTheme);
  const isDark = useAppStore((s) => s.isDark);
  const isTimerRunning = useAppStore((s) => s.isTimerRunning);

  const [isFabMenuOpen, setIsFabMenuOpen] = useState(false);
  const [isMoreViewsOpen, setIsMoreViewsOpen] = useState(false);

  return (
    <>
      {/* Mobile Fab Actions Popup */}
      <AnimatePresence>
        {isFabMenuOpen && (
          <div className="md:hidden fixed inset-0 z-50 flex items-end justify-center pb-24 px-4 select-none">
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setIsFabMenuOpen(false)}
              className="fixed inset-0 bg-black/60 backdrop-blur-sm"
            />
            <motion.div
              initial={{ opacity: 0, y: 20, scale: 0.95 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              exit={{ opacity: 0, y: 20, scale: 0.95 }}
              transition={{ type: 'spring', stiffness: 450, damping: 30 }}
              className="relative z-10 w-full max-w-xs rounded-3xl bg-canvas-elevated liquid-glass border border-border-subtle shadow-2xl p-4 space-y-2.5"
            >
              <div className="flex items-center justify-between pb-2 border-b border-border-subtle">
                <span className="text-xs font-bold text-ink-primary">ثبت فعالیت جدید</span>
                <button
                  onClick={() => setIsFabMenuOpen(false)}
                  className="p-1 rounded-full hover:bg-white/10 text-ink-muted"
                >
                  <X className="w-4 h-4" />
                </button>
              </div>

              <button
                onClick={() => {
                  setIsFabMenuOpen(false);
                  setCreateTaskOpen(true);
                }}
                className="w-full flex items-center gap-3 p-3 rounded-2xl bg-accent-primary text-white font-bold text-xs shadow-needle active:scale-95 transition"
              >
                <Plus className="w-5 h-5" />
                <span>افزودن تسک جدید (با زمان‌بندی)</span>
              </button>

              <button
                onClick={() => {
                  setIsFabMenuOpen(false);
                  setBrainDumpOpen(true);
                }}
                className="w-full flex items-center gap-3 p-3 rounded-2xl bg-canvas-secondary hover:bg-white/10 text-ink-primary font-bold text-xs border border-border-subtle active:scale-95 transition"
              >
                <Sparkles className="w-5 h-5 text-accent-primary" />
                <span>ذهن‌ریزی با هوش مصنوعی (Brain Dump)</span>
              </button>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      {/* Mobile More Views Sheet */}
      <AnimatePresence>
        {isMoreViewsOpen && (
          <div className="md:hidden fixed inset-0 z-50 flex items-end justify-center pb-24 px-4 select-none">
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setIsMoreViewsOpen(false)}
              className="fixed inset-0 bg-black/60 backdrop-blur-sm"
            />
            <motion.div
              initial={{ opacity: 0, y: 20, scale: 0.95 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              exit={{ opacity: 0, y: 20, scale: 0.95 }}
              transition={{ type: 'spring', stiffness: 450, damping: 30 }}
              className="relative z-10 w-full max-w-sm rounded-3xl bg-canvas-elevated liquid-glass border border-border-subtle shadow-2xl p-4 space-y-3"
            >
              <div className="flex items-center justify-between pb-2 border-b border-border-subtle">
                <span className="text-xs font-bold text-ink-primary">سایر نماها و امکانات</span>
                <button
                  onClick={() => setIsMoreViewsOpen(false)}
                  className="p-1 rounded-full hover:bg-white/10 text-ink-muted"
                >
                  <X className="w-4 h-4" />
                </button>
              </div>

              <div className="grid grid-cols-2 gap-2 text-xs">
                <button
                  onClick={() => { setViewMode('dual_planner'); setIsMoreViewsOpen(false); }}
                  className={`p-3 rounded-2xl flex flex-col items-center gap-1.5 border transition ${
                    viewMode === 'dual_planner' ? 'border-accent-primary bg-accent-primary/10 text-accent-primary font-bold' : 'border-border-subtle bg-canvas-secondary text-ink-muted'
                  }`}
                >
                  <Columns className="w-5 h-5" />
                  <span>پلنر ۱۰ دقیقه‌ای</span>
                </button>

                <button
                  onClick={() => { setViewMode('eisenhower'); setIsMoreViewsOpen(false); }}
                  className={`p-3 rounded-2xl flex flex-col items-center gap-1.5 border transition ${
                    viewMode === 'eisenhower' ? 'border-accent-primary bg-accent-primary/10 text-accent-primary font-bold' : 'border-border-subtle bg-canvas-secondary text-ink-muted'
                  }`}
                >
                  <Grid className="w-5 h-5" />
                  <span>ماتریس آیزنهاور</span>
                </button>

                <button
                  onClick={() => { setViewMode('analytics'); setIsMoreViewsOpen(false); }}
                  className={`p-3 rounded-2xl flex flex-col items-center gap-1.5 border transition ${
                    viewMode === 'analytics' ? 'border-accent-primary bg-accent-primary/10 text-accent-primary font-bold' : 'border-border-subtle bg-canvas-secondary text-ink-muted'
                  }`}
                >
                  <BarChart2 className="w-5 h-5" />
                  <span>آمار جامع YPT</span>
                </button>

                <button
                  onClick={() => { setViewMode('study_room'); setIsMoreViewsOpen(false); }}
                  className={`p-3 rounded-2xl flex flex-col items-center gap-1.5 border transition ${
                    viewMode === 'study_room' ? 'border-accent-primary bg-accent-primary/10 text-accent-primary font-bold' : 'border-border-subtle bg-canvas-secondary text-ink-muted'
                  }`}
                >
                  <Users className="w-5 h-5" />
                  <span>اتاق مطالعه زنده</span>
                </button>

                <button
                  onClick={() => { setViewMode('stylus'); setIsMoreViewsOpen(false); }}
                  className={`p-3 rounded-2xl flex flex-col items-center gap-1.5 border transition ${
                    viewMode === 'stylus' ? 'border-accent-primary bg-accent-primary/10 text-accent-primary font-bold' : 'border-border-subtle bg-canvas-secondary text-ink-muted'
                  }`}
                >
                  <PenTool className="w-5 h-5" />
                  <span>بوم قلم لمسی</span>
                </button>

                <button
                  onClick={() => { toggleTheme(); setIsMoreViewsOpen(false); }}
                  className="p-3 rounded-2xl flex flex-col items-center gap-1.5 border border-border-subtle bg-canvas-secondary text-ink-muted transition"
                >
                  {isDark ? <Sun className="w-5 h-5 text-amber-400" /> : <Moon className="w-5 h-5 text-indigo-500" />}
                  <span>{isDark ? 'تم روشن' : 'تم تاریک'}</span>
                </button>
              </div>

              {/* Quick Ritual Actions in Mobile Sheet */}
              <div className="pt-2 border-t border-border-subtle flex gap-2">
                <button
                  onClick={() => { setIsMoreViewsOpen(false); setMorningPlanningOpen(true); }}
                  className="flex-1 py-2 px-3 rounded-xl bg-canvas-secondary border border-border-subtle text-xs font-bold text-ink-muted hover:text-ink-primary flex items-center justify-center gap-1"
                >
                  <Sunrise className="w-4 h-4 text-amber-500" />
                  <span>آیین صبح</span>
                </button>
                <button
                  onClick={() => { setIsMoreViewsOpen(false); setEveningReflectionOpen(true); }}
                  className="flex-1 py-2 px-3 rounded-xl bg-canvas-secondary border border-border-subtle text-xs font-bold text-ink-muted hover:text-ink-primary flex items-center justify-center gap-1"
                >
                  <Sunset className="w-4 h-4 text-indigo-400" />
                  <span>آیین شب</span>
                </button>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      {/* ========================================================
          FLOATING MOBILE BOTTOM TAB BAR (نوار پایین شناور و بهینه‌شده)
          ======================================================== */}
      <div className="md:hidden fixed bottom-3 inset-x-3 max-w-md mx-auto z-40 bg-canvas-elevated liquid-glass border border-border-subtle rounded-3xl h-16 px-3 flex items-center justify-between shadow-2xl backdrop-blur-2xl">
        {/* Tab 1: Dashboard */}
        <button
          onClick={() => setViewMode('dashboard')}
          className={`relative flex flex-col items-center justify-center gap-1 flex-1 py-1 touch-target transition ${
            viewMode === 'dashboard' ? 'text-accent-primary font-bold' : 'text-ink-muted hover:text-ink-primary'
          }`}
        >
          <LayoutGrid className="w-5 h-5" />
          <span className="text-[10px]">داشبورد</span>
          {viewMode === 'dashboard' && (
            <motion.div
              layoutId="mobileActiveTabIndicator"
              className="absolute -bottom-1 w-4 h-1 rounded-full bg-accent-primary shadow-needle"
              transition={{ type: 'spring', stiffness: 500, damping: 32 }}
            />
          )}
        </button>

        {/* Tab 2: Timeline */}
        <button
          onClick={() => setViewMode('day')}
          className={`relative flex flex-col items-center justify-center gap-1 flex-1 py-1 touch-target transition ${
            viewMode === 'day' ? 'text-accent-primary font-bold' : 'text-ink-muted hover:text-ink-primary'
          }`}
        >
          <Clock className="w-5 h-5" />
          <span className="text-[10px]">تایم‌لاین</span>
          {viewMode === 'day' && (
            <motion.div
              layoutId="mobileActiveTabIndicator"
              className="absolute -bottom-1 w-4 h-1 rounded-full bg-accent-primary shadow-needle"
              transition={{ type: 'spring', stiffness: 500, damping: 32 }}
            />
          )}
        </button>

        {/* Center Floating Action Button (FAB) */}
        <div className="relative -top-5 flex-shrink-0 px-1">
          <motion.button
            whileTap={{ scale: 0.9 }}
            onClick={() => setIsFabMenuOpen(!isFabMenuOpen)}
            className="w-12 h-12 rounded-full bg-accent-primary text-white shadow-needle flex items-center justify-center active:scale-90 transition border-2 border-canvas"
            aria-label="افزودن فعالیت جدید"
          >
            {isFabMenuOpen ? <X className="w-6 h-6" /> : <Plus className="w-6 h-6" />}
          </motion.button>
        </div>

        {/* Tab 3: Focus Studio */}
        <button
          onClick={() => setFocusModalOpen(true)}
          className={`flex flex-col items-center justify-center gap-1 flex-1 py-1 touch-target transition ${
            isTimerRunning ? 'text-accent-primary font-bold animate-pulse' : 'text-ink-muted hover:text-ink-primary'
          }`}
        >
          <Play className="w-5 h-5 fill-current" />
          <span className="text-[10px]">{isTimerRunning ? 'در حال ضبط' : 'تمرکز YPT'}</span>
        </button>

        {/* Tab 4: More Views */}
        <button
          onClick={() => setIsMoreViewsOpen(!isMoreViewsOpen)}
          className={`relative flex flex-col items-center justify-center gap-1 flex-1 py-1 touch-target transition ${
            viewMode !== 'dashboard' && viewMode !== 'day' ? 'text-accent-primary font-bold' : 'text-ink-muted hover:text-ink-primary'
          }`}
        >
          <MoreHorizontal className="w-5 h-5" />
          <span className="text-[10px]">سایر</span>
          {viewMode !== 'dashboard' && viewMode !== 'day' && (
            <motion.div
              layoutId="mobileActiveTabIndicator"
              className="absolute -bottom-1 w-4 h-1 rounded-full bg-accent-primary shadow-needle"
              transition={{ type: 'spring', stiffness: 500, damping: 32 }}
            />
          )}
        </button>
      </div>
    </>
  );
};
