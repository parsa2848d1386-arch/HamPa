import React from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Play, Pause, Maximize2, Square, GripVertical } from 'lucide-react';
import { useAppStore } from '../../store/useAppStore';

export const FloatingPiPWidget: React.FC = () => {
  const isPiPVisible = useAppStore((s) => s.isPiPVisible);
  const setPiPVisible = useAppStore((s) => s.setPiPVisible);
  const isTimerRunning = useAppStore((s) => s.isTimerRunning);
  const isTimerPaused = useAppStore((s) => s.isTimerPaused);
  const timerSeconds = useAppStore((s) => s.timerSeconds);
  const activeSubjectId = useAppStore((s) => s.activeSubjectId);
  const subjects = useAppStore((s) => s.subjects);
  const setFocusModalOpen = useAppStore((s) => s.setFocusModalOpen);
  const pauseTimer = useAppStore((s) => s.pauseTimer);
  const resumeTimer = useAppStore((s) => s.resumeTimer);
  const stopFocusSession = useAppStore((s) => s.stopFocusSession);

  if (!isPiPVisible || !isTimerRunning) return null;

  const currentSubject = subjects.find((s) => s.id === activeSubjectId) || subjects[0];

  const hours = Math.floor(timerSeconds / 3600);
  const mins = Math.floor((timerSeconds % 3600) / 60);
  const secs = timerSeconds % 60;

  const handleExpand = () => {
    setPiPVisible(false);
    setFocusModalOpen(true);
  };

  return (
    <AnimatePresence>
      <motion.div
        drag
        dragMomentum={false}
        dragElastic={0.08}
        initial={{ opacity: 0, y: 30, scale: 0.9 }}
        animate={{ opacity: 1, y: 0, scale: 1 }}
        exit={{ opacity: 0, y: 30, scale: 0.9 }}
        transition={{ type: 'spring', stiffness: 450, damping: 30 }}
        className="fixed bottom-20 md:bottom-6 left-1/2 -translate-x-1/2 z-50 rounded-2xl bg-canvas-elevated liquid-glass border border-border-highlight shadow-2xl p-2 px-3 flex items-center gap-2.5 select-none touch-none"
        style={{ cursor: 'default' }}
      >
        {/* Drag Handle Indicator */}
        <div 
          className="cursor-grab active:cursor-grabbing text-ink-subtle hover:text-ink-primary p-0.5 rounded transition"
          title="برای جابجایی روی صفحه بکشید (Drag)"
        >
          <GripVertical className="w-4 h-4 opacity-70" />
        </div>

        {/* Subject Color Pill */}
        <div
          className="w-3 h-3 rounded-full flex-shrink-0 shadow-needle animate-pulse"
          style={{ backgroundColor: currentSubject.color }}
          title={currentSubject.name}
        />

        {/* Info */}
        <div className="flex flex-col">
          <span className="text-[11px] font-bold text-ink-muted truncate max-w-[110px]">
            {currentSubject.name}
          </span>
          <span className="text-sm font-mono font-black text-ink-primary tabular-nums tracking-tight">
            {hours > 0 && `${hours.toString().padStart(2, '0')}:`}
            {mins.toString().padStart(2, '0')}:{secs.toString().padStart(2, '0')}
          </span>
        </div>

        {/* Controls */}
        <div className="flex items-center gap-1 border-r border-border-subtle pr-2 mr-0.5">
          {isTimerPaused ? (
            <button
              onClick={resumeTimer}
              className="p-1.5 rounded-xl bg-accent-primary text-white hover:bg-accent-hover transition cursor-pointer active:scale-95"
              title="ادامه مطالعه"
              aria-label="ادامه تایمر"
            >
              <Play className="w-3.5 h-3.5 fill-current" />
            </button>
          ) : (
            <button
              onClick={pauseTimer}
              className="p-1.5 rounded-xl bg-white/10 text-ink-primary hover:bg-white/20 transition cursor-pointer active:scale-95"
              title="مکث تایمر"
              aria-label="مکث تایمر"
            >
              <Pause className="w-3.5 h-3.5" />
            </button>
          )}

          <button
            onClick={stopFocusSession}
            className="p-1.5 rounded-xl bg-red-500/20 text-red-400 hover:bg-red-500/30 transition cursor-pointer active:scale-95"
            title="ثبت و پایان جلسه"
            aria-label="پایان جلسه تمرکز"
          >
            <Square className="w-3.5 h-3.5 fill-current" />
          </button>

          <button
            onClick={handleExpand}
            className="p-1.5 rounded-xl bg-white/5 text-ink-muted hover:text-ink-primary hover:bg-white/15 transition cursor-pointer active:scale-95"
            title="بزرگ‌نمایی به استودیو تمرکز"
            aria-label="بزرگ‌نمایی استودیو تمرکز"
          >
            <Maximize2 className="w-3.5 h-3.5" />
          </button>
        </div>
      </motion.div>
    </AnimatePresence>
  );
};
