import React from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Sunset, CheckCircle2, ArrowRightCircle, Sparkles, Trophy } from 'lucide-react';
import { useAppStore } from '../../store/useAppStore';
import { formatToPersianDigits } from '../../lib/calendarUtils';
import confetti from 'canvas-confetti';

export const EveningReflectionModal: React.FC = () => {
  const isOpen = useAppStore((s) => s.isEveningReflectionOpen);
  const setOpen = useAppStore((s) => s.setEveningReflectionOpen);
  const tasks = useAppStore((s) => s.tasks);
  const updateTask = useAppStore((s) => s.updateTask);
  const selectedDate = useAppStore((s) => s.selectedDate);

  if (!isOpen) return null;

  const dayTasks = tasks.filter((t) => t.date === selectedDate);
  const completedTasks = dayTasks.filter((t) => t.status === 'completed');
  const incompleteTasks = dayTasks.filter((t) => t.status !== 'completed');

  const handleRolloverAll = () => {
    // Tomorrow date
    const d = new Date(selectedDate);
    d.setDate(d.getDate() + 1);
    const tomorrowStr = d.toISOString().split('T')[0];

    incompleteTasks.forEach((t) => {
      updateTask(t.id, { date: tomorrowStr });
    });

    confetti({
      particleCount: 100,
      spread: 80,
      origin: { y: 0.5 }
    });

    setOpen(false);
  };

  const handleFinishWithoutRollover = () => {
    confetti({
      particleCount: 70,
      spread: 60,
    });
    setOpen(false);
  };

  return (
    <AnimatePresence>
      <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
        {/* Backdrop */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          onClick={() => setOpen(false)}
          className="fixed inset-0 bg-black/75 backdrop-blur-md"
        />

        {/* Modal Window */}
        <motion.div
          initial={{ opacity: 0, scale: 0.95, y: 15 }}
          animate={{ opacity: 1, scale: 1, y: 0 }}
          exit={{ opacity: 0, scale: 0.95, y: 15 }}
          transition={{ type: 'spring', stiffness: 400, damping: 30, mass: 0.8 }}
          className="relative z-10 w-full max-w-xl rounded-squircle-sheet bg-canvas-elevated liquid-glass border border-border-highlight shadow-2xl p-6 md:p-8 overflow-hidden select-none"
        >
          {/* Header */}
          <div className="flex items-center gap-3 pb-5 border-b border-border-subtle">
            <div className="w-10 h-10 rounded-precision-md bg-indigo-500/20 text-indigo-400 flex items-center justify-center">
              <Sunset className="w-6 h-6" />
            </div>
            <div>
              <h3 className="text-base md:text-lg font-bold text-ink-primary">
                آیین شبانگاهی و تخلیه ذهن ۱۰ دقیقه‌ای (Evening Reflection)
              </h3>
              <p className="text-xs text-ink-muted">
                مرور دستاوردهای روز، انتقال بدون سرزنش کارهای ناتمام و خاتمه کار
              </p>
            </div>
          </div>

          <div className="py-5 space-y-5">
            {/* Celebration stats banner */}
            <div className="p-4 rounded-precision-md bg-emerald-500/10 border border-emerald-500/30 flex items-center gap-3">
              <div className="w-9 h-9 rounded-full bg-emerald-500/20 text-emerald-400 flex items-center justify-center">
                <Trophy className="w-5 h-5" />
              </div>
              <div>
                <div className="text-sm font-bold text-ink-primary">
                  خسته نباشی! امروز {formatToPersianDigits(completedTasks.length)} تسک را با موفقیت تمام کردی.
                </div>
                <div className="text-xs text-emerald-300 mt-0.5">
                  پیوستگی زنجیره تمرکز شما برای فردا حفظ شد.
                </div>
              </div>
            </div>

            {/* Incomplete Tasks Rollover Section */}
            {incompleteTasks.length > 0 && (
              <div className="space-y-2">
                <div className="flex items-center justify-between text-xs text-ink-muted">
                  <span>تسک‌های ناتمام امروز (انتقال خودکار به فردا بدون احساس گناه):</span>
                  <span className="font-mono text-accent-primary font-bold">
                    {formatToPersianDigits(incompleteTasks.length)} تسک
                  </span>
                </div>

                <div className="max-h-48 overflow-y-auto space-y-1.5 pr-1">
                  {incompleteTasks.map((task) => (
                    <div
                      key={task.id}
                      className="flex items-center justify-between p-2.5 rounded-precision-md bg-canvas-secondary border border-border-subtle text-xs"
                    >
                      <span className="text-ink-primary font-medium">{task.title}</span>
                      <span className="text-ink-muted font-mono">{task.durationMinutes} دقیقه</span>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Actions */}
            <div className="flex flex-col sm:flex-row items-center justify-between gap-2.5 pt-4 border-t border-border-subtle">
              <button
                onClick={handleFinishWithoutRollover}
                className="w-full sm:w-auto px-4 py-2 rounded-precision-md hover:bg-white/5 text-xs text-ink-muted transition"
              >
                پایان بدون انتقال تسک‌ها
              </button>

              {incompleteTasks.length > 0 && (
                <button
                  onClick={handleRolloverAll}
                  className="w-full sm:w-auto flex items-center justify-center gap-2 px-6 py-2.5 rounded-precision-md bg-accent-primary hover:bg-accent-hover text-white text-xs font-bold transition shadow-needle"
                >
                  <ArrowRightCircle className="w-4 h-4" />
                  <span>انتقال همه به فردا و خاموشی شبانه</span>
                </button>
              )}
            </div>
          </div>
        </motion.div>
      </div>
    </AnimatePresence>
  );
};
