import React, { useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  Play, 
  Pause, 
  Square, 
  Minimize2, 
  X, 
  Sparkles, 
  Clock, 
  Flame, 
  CheckCircle2,
  BookOpen
} from 'lucide-react';
import { useAppStore } from '../../store/useAppStore';
import { AmbientAudioControls } from './AmbientAudioControls';

export const FocusTimerModal: React.FC = () => {
  const isOpen = useAppStore((s) => s.isFocusModalOpen);
  const setOpen = useAppStore((s) => s.setFocusModalOpen);
  const isTimerRunning = useAppStore((s) => s.isTimerRunning);
  const isTimerPaused = useAppStore((s) => s.isTimerPaused);
  const timerSeconds = useAppStore((s) => s.timerSeconds);
  const timerMode = useAppStore((s) => s.timerMode);
  const activeSubjectId = useAppStore((s) => s.activeSubjectId);
  const activeTaskId = useAppStore((s) => s.activeTaskId);
  const subjects = useAppStore((s) => s.subjects);
  const tasks = useAppStore((s) => s.tasks);

  const startFocusSession = useAppStore((s) => s.startFocusSession);
  const pauseTimer = useAppStore((s) => s.pauseTimer);
  const resumeTimer = useAppStore((s) => s.resumeTimer);
  const stopFocusSession = useAppStore((s) => s.stopFocusSession);
  const setPiPVisible = useAppStore((s) => s.setPiPVisible);

  if (!isOpen) return null;

  const currentSubject = subjects.find((s) => s.id === activeSubjectId) || subjects[0];
  const currentTask = tasks.find((t) => t.id === activeTaskId);

  // Format Display Time
  let displaySeconds = timerSeconds;
  if (timerMode === 'pomodoro') {
    const POMO_TARGET = 25 * 60;
    displaySeconds = Math.max(0, POMO_TARGET - timerSeconds);
  }

  const hours = Math.floor(displaySeconds / 3600);
  const mins = Math.floor((displaySeconds % 3600) / 60);
  const secs = displaySeconds % 60;

  const handleMinimize = () => {
    setOpen(false);
    if (isTimerRunning) {
      setPiPVisible(true);
    }
  };

  return (
    <AnimatePresence>
      <div className="fixed inset-0 z-50 flex items-center justify-center p-3 md:p-6">
        {/* Fullscreen Backdrop (Zero-distraction warm black) */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          className="fixed inset-0 bg-[#0f0d0a]/95 backdrop-blur-xl"
        />

        {/* Studio Window */}
        <motion.div
          initial={{ opacity: 0, scale: 0.96, y: 15 }}
          animate={{ opacity: 1, scale: 1, y: 0 }}
          exit={{ opacity: 0, scale: 0.96, y: 15 }}
          transition={{ type: 'spring', stiffness: 400, damping: 30, mass: 0.8 }}
          className="relative z-10 w-full max-w-2xl rounded-squircle-sheet bg-canvas-elevated liquid-glass border border-border-highlight shadow-2xl p-6 md:p-8 flex flex-col justify-between overflow-hidden"
        >
          {/* Top Bar: Subject Pill, Minimize, Close */}
          <div className="flex items-center justify-between pb-6 border-b border-border-subtle">
            <div className="flex items-center gap-2.5">
              <span
                className="w-3.5 h-3.5 rounded-full shadow-needle"
                style={{ backgroundColor: currentSubject.color }}
              />
              <span className="font-bold text-sm text-ink-primary">
                {currentSubject.name}
              </span>
              {currentTask && (
                <span className="text-xs text-ink-muted truncate max-w-[200px]">
                  • {currentTask.title}
                </span>
              )}
            </div>

            <div className="flex items-center gap-2">
              <button
                onClick={handleMinimize}
                className="p-2 rounded-full hover:bg-white/10 text-ink-muted hover:text-ink-primary transition"
                title="کوچک کردن به حالت شناور PiP"
              >
                <Minimize2 className="w-5 h-5" />
              </button>
              <button
                onClick={() => setOpen(false)}
                className="p-2 rounded-full hover:bg-white/10 text-ink-muted hover:text-ink-primary transition"
                title="بستن"
              >
                <X className="w-5 h-5" />
              </button>
            </div>
          </div>

          {/* Center: Large High-Precision Monospaced Clock */}
          <div className="py-12 md:py-16 text-center select-none">
            <div className="inline-block relative">
              <div className="text-6xl md:text-8xl font-black font-mono tracking-tight text-ink-primary timer-display drop-shadow-md">
                {hours > 0 && `${hours.toString().padStart(2, '0')}:`}
                {mins.toString().padStart(2, '0')}:{secs.toString().padStart(2, '0')}
              </div>

              {isTimerRunning && !isTimerPaused && (
                <div className="mt-3 inline-flex items-center gap-1.5 px-3 py-1 rounded-pill bg-accent-primary/20 text-accent-primary text-xs font-semibold animate-pulse">
                  <span className="w-2 h-2 rounded-full bg-accent-primary" />
                  <span>در حال ضبط سشن تمرکز فعال</span>
                </div>
              )}
              {isTimerPaused && (
                <div className="mt-3 inline-flex items-center gap-1.5 px-3 py-1 rounded-pill bg-amber-500/20 text-amber-500 text-xs font-semibold">
                  <span>مکث موقت</span>
                </div>
              )}
            </div>

            {/* Mode Selector */}
            <div className="mt-6 flex justify-center gap-2">
              <button
                onClick={() => startFocusSession(currentSubject.id, activeTaskId || undefined, 'stopwatch')}
                className={`px-3 py-1 rounded-precision text-xs font-medium transition ${
                  timerMode === 'stopwatch'
                    ? 'bg-accent-primary text-white font-bold'
                    : 'bg-white/5 text-ink-muted hover:text-ink-primary'
                }`}
              >
                کرنومتر آزاد (Stopwatch)
              </button>
              <button
                onClick={() => startFocusSession(currentSubject.id, activeTaskId || undefined, 'pomodoro')}
                className={`px-3 py-1 rounded-precision text-xs font-medium transition ${
                  timerMode === 'pomodoro'
                    ? 'bg-accent-primary text-white font-bold'
                    : 'bg-white/5 text-ink-muted hover:text-ink-primary'
                }`}
              >
                پومودورو ۲۵ دقیقه (Pomodoro)
              </button>
            </div>
          </div>

          {/* Ambient Sound Engine */}
          <div className="mb-6">
            <AmbientAudioControls />
          </div>

          {/* Bottom Actions: Play, Pause, Finish */}
          <div className="flex items-center justify-center gap-4 pt-4 border-t border-border-subtle">
            {!isTimerRunning ? (
              <button
                onClick={() => startFocusSession(currentSubject.id, activeTaskId || undefined, timerMode)}
                className="flex items-center gap-2 px-8 py-3.5 rounded-precision-md bg-accent-primary hover:bg-accent-hover text-white text-base font-bold shadow-needle transition active:scale-95"
              >
                <Play className="w-5 h-5 fill-current" />
                <span>شروع تمرکز</span>
              </button>
            ) : isTimerPaused ? (
              <button
                onClick={resumeTimer}
                className="flex items-center gap-2 px-8 py-3.5 rounded-precision-md bg-accent-primary hover:bg-accent-hover text-white text-base font-bold shadow-needle transition active:scale-95"
              >
                <Play className="w-5 h-5 fill-current" />
                <span>ادامه تمرکز</span>
              </button>
            ) : (
              <button
                onClick={pauseTimer}
                className="flex items-center gap-2 px-8 py-3.5 rounded-precision-md bg-white/10 hover:bg-white/15 text-white text-base font-bold transition active:scale-95 border border-border-highlight"
              >
                <Pause className="w-5 h-5" />
                <span>مکث</span>
              </button>
            )}

            {isTimerRunning && (
              <button
                onClick={stopFocusSession}
                className="flex items-center gap-2 px-6 py-3.5 rounded-precision-md bg-red-500/20 hover:bg-red-500/30 text-red-400 text-base font-bold border border-red-500/30 transition active:scale-95"
              >
                <Square className="w-5 h-5 fill-current" />
                <span>پایان و ثبت در جدول</span>
              </button>
            )}
          </div>
        </motion.div>
      </div>
    </AnimatePresence>
  );
};
