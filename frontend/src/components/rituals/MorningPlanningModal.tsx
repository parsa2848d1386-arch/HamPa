import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Sunrise, Sparkles, Check, AlertTriangle, ArrowLeft, Clock, Calendar } from 'lucide-react';
import { useAppStore } from '../../store/useAppStore';
import { formatToPersianDigits } from '../../lib/calendarUtils';
import confetti from 'canvas-confetti';

export const MorningPlanningModal: React.FC = () => {
  const isOpen = useAppStore((s) => s.isMorningPlanningOpen);
  const setOpen = useAppStore((s) => s.setMorningPlanningOpen);
  const tasks = useAppStore((s) => s.tasks);
  const updateTask = useAppStore((s) => s.updateTask);
  const selectedDate = useAppStore((s) => s.selectedDate);
  const user = useAppStore((s) => s.user);

  const [step, setStep] = useState<1 | 2>(1);

  if (!isOpen) return null;

  // Filter tasks for today
  const todayTasks = tasks.filter((t) => t.date === selectedDate);
  const selectedMITs = todayTasks.filter((t) => t.isMIT);

  // Calculate total scheduled minutes
  const totalScheduledMinutes = todayTasks.reduce((acc, t) => acc + t.durationMinutes, 0);
  const capacityMinutes = user.dailyCapacityMinutes || 360;
  const isOverCapacity = totalScheduledMinutes > capacityMinutes;

  const handleToggleMIT = (taskId: string, current: boolean) => {
    if (!current && selectedMITs.length >= 3) {
      alert('حداکثر ۳ تسک را می‌توانید به عنوان اولویت‌های حیاتی (MIT) انتخاب کنید.');
      return;
    }
    updateTask(taskId, { isMIT: !current });
  };

  const handleFinish = () => {
    confetti({
      particleCount: 80,
      spread: 70,
      origin: { y: 0.6 }
    });
    setOpen(false);
    setStep(1);
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

        {/* Modal Container */}
        <motion.div
          initial={{ opacity: 0, scale: 0.95, y: 15 }}
          animate={{ opacity: 1, scale: 1, y: 0 }}
          exit={{ opacity: 0, scale: 0.95, y: 15 }}
          transition={{ type: 'spring', stiffness: 400, damping: 30, mass: 0.8 }}
          className="relative z-10 w-full max-w-xl rounded-squircle-sheet bg-canvas-elevated liquid-glass border border-border-highlight shadow-2xl p-6 md:p-8 overflow-hidden select-none"
        >
          {/* Header */}
          <div className="flex items-center gap-3 pb-5 border-b border-border-subtle">
            <div className="w-10 h-10 rounded-precision-md bg-amber-500/20 text-amber-500 flex items-center justify-center">
              <Sunrise className="w-6 h-6" />
            </div>
            <div>
              <h3 className="text-base md:text-lg font-bold text-ink-primary">
                آیین صبحگاهی سان‌ساما (Morning Planning Ritual)
              </h3>
              <p className="text-xs text-ink-muted">
                انتخاب ۳ تسک دارای بیشترین اولویت (MIT) و سنجش ظرفیت روزانه
              </p>
            </div>
          </div>

          {step === 1 ? (
            <div className="py-5 space-y-4">
              <div className="flex items-center justify-between text-xs text-ink-muted">
                <span>انتخاب ۳ اولویت سرنوشت‌ساز امروز:</span>
                <span className="font-mono text-accent-primary font-bold">
                  {selectedMITs.length} / ۳ انتخاب شده
                </span>
              </div>

              {/* Task Selection List */}
              <div className="max-h-60 overflow-y-auto space-y-2 pr-1">
                {todayTasks.length === 0 ? (
                  <div className="py-8 text-center text-xs text-ink-subtle">
                    تسک ثبت‌شده‌ای برای امروز ندارید. از دکمه Brain Dump برای افزودن استفاده کنید.
                  </div>
                ) : (
                  todayTasks.map((task) => (
                    <div
                      key={task.id}
                      onClick={() => handleToggleMIT(task.id, !!task.isMIT)}
                      className={`flex items-center justify-between p-3 rounded-precision-md border transition cursor-pointer ${
                        task.isMIT
                          ? 'border-amber-500/50 bg-amber-500/10'
                          : 'border-border-subtle hover:border-border-highlight bg-canvas-secondary/40'
                      }`}
                    >
                      <div className="flex items-center gap-2.5">
                        <div
                          className={`w-5 h-5 rounded-precision flex items-center justify-center border transition ${
                            task.isMIT
                              ? 'bg-amber-500 border-amber-500 text-white'
                              : 'border-border-subtle text-transparent'
                          }`}
                        >
                          <Check className="w-3.5 h-3.5" />
                        </div>
                        <span className="text-sm font-medium text-ink-primary">
                          {task.title}
                        </span>
                      </div>
                      <span className="text-xs font-mono text-ink-muted">
                        {task.durationMinutes} دقیقه
                      </span>
                    </div>
                  ))
                )}
              </div>

              {/* Step 1 Actions */}
              <div className="flex justify-between items-center pt-4 border-t border-border-subtle">
                <button
                  onClick={() => setOpen(false)}
                  className="px-4 py-2 rounded-precision-md hover:bg-white/5 text-xs text-ink-muted transition"
                >
                  انصراف
                </button>
                <button
                  onClick={() => setStep(2)}
                  className="flex items-center gap-1.5 px-6 py-2 rounded-precision-md bg-accent-primary hover:bg-accent-hover text-white text-xs font-bold transition shadow-sm"
                >
                  <span>مرحله بعد: بررسی ظرفیت</span>
                  <ArrowLeft className="w-3.5 h-3.5" />
                </button>
              </div>
            </div>
          ) : (
            <div className="py-5 space-y-4">
              {/* Capacity Calculation Banner */}
              <div
                className={`p-4 rounded-precision-md border ${
                  isOverCapacity
                    ? 'bg-red-500/10 border-red-500/30 text-red-300'
                    : 'bg-emerald-500/10 border-emerald-500/30 text-emerald-300'
                }`}
              >
                <div className="flex items-center gap-2 font-bold text-sm mb-1">
                  {isOverCapacity ? (
                    <>
                      <AlertTriangle className="w-4 h-4 text-red-400" />
                      <span>هشدار اضافه بار زمانی! (Over Capacity)</span>
                    </>
                  ) : (
                    <>
                      <Check className="w-4 h-4 text-emerald-400" />
                      <span>برنامه شما در محدوده ظرفیت واقع‌گرایانه است</span>
                    </>
                  )}
                </div>
                <p className="text-xs opacity-90 leading-relaxed">
                  مجموع زمان تسک‌های امروز: {formatToPersianDigits(Math.round(totalScheduledMinutes / 60 * 10) / 10)} ساعت • ظرفیت استاندارد: {formatToPersianDigits(capacityMinutes / 60)} ساعت.
                  {isOverCapacity && ' پیشنهاد می‌کنیم تسک‌های کم‌اهمیت‌تر را به فردا موکول کنید تا از فرسودگی ذهنی جلوگیری شود.'}
                </p>
              </div>

              {/* Selected MITs Summary */}
              <div className="space-y-2">
                <span className="text-xs font-bold text-ink-muted uppercase">
                  ۳ اولویت برتر قطعی شده امروز:
                </span>
                <div className="space-y-1.5">
                  {selectedMITs.map((task, i) => (
                    <div
                      key={task.id}
                      className="flex items-center gap-2 p-2.5 rounded-precision-md bg-canvas-secondary border border-border-subtle text-xs"
                    >
                      <span className="w-5 h-5 rounded-full bg-amber-500/20 text-amber-500 flex items-center justify-center font-bold">
                        {formatToPersianDigits(i + 1)}
                      </span>
                      <span className="font-semibold text-ink-primary flex-1">
                        {task.title}
                      </span>
                      <span className="font-mono text-ink-muted">
                        {task.durationMinutes} دقیقه
                      </span>
                    </div>
                  ))}
                </div>
              </div>

              {/* Step 2 Actions */}
              <div className="flex justify-between items-center pt-4 border-t border-border-subtle">
                <button
                  onClick={() => setStep(1)}
                  className="px-4 py-2 rounded-precision-md hover:bg-white/5 text-xs text-ink-muted transition"
                >
                  بازگشت
                </button>
                <button
                  onClick={handleFinish}
                  className="flex items-center gap-1.5 px-6 py-2 rounded-precision-md bg-accent-primary hover:bg-accent-hover text-white text-xs font-bold transition shadow-needle"
                >
                  <Sparkles className="w-3.5 h-3.5" />
                  <span>تأیید نهایی و شروع روز پرانرژی</span>
                </button>
              </div>
            </div>
          )}
        </motion.div>
      </div>
    </AnimatePresence>
  );
};
