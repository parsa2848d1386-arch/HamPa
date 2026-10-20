import React from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Play, Pause, Maximize2, Square } from 'lucide-react';
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
        initial={{ opacity: 0, y: 30, scale: 0.9 }}
        animate={{ opacity: 1, y: 0, scale: 1 }}
        exit={{ opacity: 0, y: 30, scale: 0.9 }}
        transition={{ type: 'spring', stiffness: 450, damping: 30 }}
        className="fixed bottom-20 md:bottom-6 left-4 md:left-6 z-50 rounded-precision-md bg-canvas-elevated liquid-glass border border-border-highlight shadow-2xl p-2.5 flex items-center gap-3"
      >
        {/* Subject Color Pill */}
        <div
          className="w-3 h-3 rounded-full flex-shrink-0 shadow-needle animate-pulse"
          style={{ backgroundColor: currentSubject.color }}
        />

        {/* Info */}
        <div className="flex flex-col">
          <span className="text-[11px] font-semibold text-ink-muted truncate max-w-[120px]">
            {currentSubject.name}
          </span>
          <span className="text-sm font-mono font-black text-ink-primary tabular-nums">
            {hours > 0 && `${hours.toString().padStart(2, '0')}:`}
            {mins.toString().padStart(2, '0')}:{secs.toString().padStart(2, '0')}
          </span>
        </div>

        {/* Controls */}
        <div className="flex items-center gap-1 border-r border-border-subtle pr-2 mr-1">
          {isTimerPaused ? (
            <button
              onClick={resumeTimer}
              className="p-1.5 rounded-precision bg-accent-primary text-white hover:bg-accent-hover transition"
              title="ادامه"
            >
              <Play className="w-3.5 h-3.5 fill-current" />
            </button>
          ) : (
            <button
              onClick={pauseTimer}
              className="p-1.5 rounded-precision bg-white/10 text-ink-primary hover:bg-white/20 transition"
              title="مکث"
            >
              <Pause className="w-3.5 h-3.5" />
            </button>
          )}

          <button
            onClick={stopFocusSession}
            className="p-1.5 rounded-precision bg-red-500/20 text-red-400 hover:bg-red-500/30 transition"
            title="پایان"
          >
            <Square className="w-3.5 h-3.5 fill-current" />
          </button>

          <button
            onClick={handleExpand}
            className="p-1.5 rounded-precision bg-white/5 text-ink-muted hover:text-ink-primary hover:bg-white/15 transition"
            title="بزرگ‌نمایی استودیو"
          >
            <Maximize2 className="w-3.5 h-3.5" />
          </button>
        </div>
      </motion.div>
    </AnimatePresence>
  );
};
