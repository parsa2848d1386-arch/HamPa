import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { 
  Flame, 
  Sparkles, 
  Clock, 
  CheckCircle2, 
  Circle, 
  Play, 
  Plus, 
  ArrowRight, 
  TrendingUp, 
  Calendar, 
  Grid, 
  Zap, 
  Volume2, 
  BookOpen, 
  ChevronLeft,
  Coffee,
  Check,
  Award,
  Layers,
  Compass
} from 'lucide-react';
import { useAppStore } from '../../store/useAppStore';
import { SlideToComplete } from '../common/SlideToComplete';
import { 
  gregorianToJalali, 
  PERSIAN_MONTHS, 
  PERSIAN_WEEKDAYS, 
  formatToPersianDigits 
} from '../../lib/calendarUtils';
import confetti from 'canvas-confetti';

export const MainDashboardView: React.FC = () => {
  const selectedDate = useAppStore((s) => s.selectedDate);
  const tasks = useAppStore((s) => s.tasks);
  const subjects = useAppStore((s) => s.subjects);
  const user = useAppStore((s) => s.user);
  const sessions = useAppStore((s) => s.sessions);
  const toggleTaskCompleted = useAppStore((s) => s.toggleTaskCompleted);
  const selectTask = useAppStore((s) => s.selectTask);
  const setCreateTaskOpen = useAppStore((s) => s.setCreateTaskOpen);
  const setBrainDumpOpen = useAppStore((s) => s.setBrainDumpOpen);
  const setFocusModalOpen = useAppStore((s) => s.setFocusModalOpen);
  const isTimerRunning = useAppStore((s) => s.isTimerRunning);
  const timerSeconds = useAppStore((s) => s.timerSeconds);
  const activeTaskId = useAppStore((s) => s.activeTaskId);
  const calendarSystem = useAppStore((s) => s.calendarSystem);
  const setViewMode = useAppStore((s) => s.setViewMode);

  // Quick Habit Toggles for Today
  const [habits, setHabits] = useState([
    { id: 'water', label: '۸ لیوان آب', done: true, icon: '💧' },
    { id: 'reading', label: 'مطالعه عمیق ۳ ساعته', done: false, icon: '📚' },
    { id: 'exercise', label: 'تحرک و کشش بدنی', done: true, icon: '🏃' },
    { id: 'review', label: 'مرور شبانه فلش‌کارت‌ها', done: false, icon: '🧠' },
  ]);

  // Quick AI input in desktop widget
  const [quickThought, setQuickThought] = useState('');

  // Date parsing
  const dateObj = new Date(selectedDate);
  const jDate = gregorianToJalali(dateObj.getFullYear(), dateObj.getMonth() + 1, dateObj.getDate());
  const dayOfWeek = PERSIAN_WEEKDAYS[dateObj.getDay() === 6 ? 0 : dateObj.getDay() + 1];
  const dateLabel = calendarSystem === 'jalali'
    ? `${dayOfWeek}، ${formatToPersianDigits(jDate.jd)} ${PERSIAN_MONTHS[jDate.jm - 1]} ${formatToPersianDigits(jDate.jy)}`
    : dateObj.toLocaleDateString('fa-IR', { weekday: 'long', month: 'long', day: 'numeric', year: 'numeric' });

  // Today's tasks
  const todayTasks = tasks.filter((t) => t.date === selectedDate);
  const completedTasks = todayTasks.filter((t) => t.status === 'completed');
  const pendingTasks = todayTasks.filter((t) => t.status !== 'completed');
  const mitTasks = todayTasks.filter((t) => t.isMIT);
  const currentOrNextTask = pendingTasks.find((t) => t.id === activeTaskId) || pendingTasks[0];

  // Today's sessions & total study duration (clean, real computation)
  const todaySessions = sessions.filter((s) => s.dateKey === selectedDate);
  const totalStudiedSeconds = todaySessions.reduce((sum, s) => sum + s.durationSeconds, 0) + (isTimerRunning ? timerSeconds : 0);
  const totalStudiedHours = Math.floor(totalStudiedSeconds / 3600);
  const totalStudiedMinutes = Math.floor((totalStudiedSeconds % 3600) / 60);

  // Daily target (default 6 hours = 360 min)
  const targetMinutes = user.dailyCapacityMinutes || 360;
  const currentMinutesStudied = Math.round(totalStudiedSeconds / 60);
  const progressPercent = Math.min(100, Math.round((currentMinutesStudied / targetMinutes) * 100));

  const formatTimer = (sec: number) => {
    const h = Math.floor(sec / 3600);
    const m = Math.floor((sec % 3600) / 60);
    const s = sec % 60;
    if (h > 0) return `${h}:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
    return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
  };

  const toggleHabit = (id: string) => {
    setHabits(habits.map((h) => (h.id === id ? { ...h, done: !h.done } : h)));
    if (typeof navigator !== 'undefined' && 'vibrate' in navigator) {
      navigator.vibrate(30);
    }
  };

  const handleQuickCaptureSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!quickThought.trim()) return;
    setBrainDumpOpen(true);
  };

  return (
    <div className="flex-1 overflow-y-auto bg-canvas p-3 sm:p-5 lg:p-7 select-none pb-24 md:pb-16 transition-colors duration-200">
      {/* ========================================================
          MOBILE-ONLY DEDICATED WIDGET EXPERIENCE (< md)
          (Distinct mobile widget architecture, touch-responsive)
          ======================================================== */}
      <div className="block md:hidden space-y-4 max-w-lg mx-auto">
        {/* Mobile Header Capsule */}
        <div className="flex items-center justify-between p-3 rounded-2xl bg-canvas-elevated liquid-glass border border-white/10 dark:border-white/10 shadow-sm">
          <div>
            <div className="text-[11px] font-medium text-ink-muted flex items-center gap-1.5">
              <span>{dateLabel}</span>
            </div>
            <h1 className="text-base font-black text-ink-primary mt-0.5">
              سلام، {user.displayName || 'هم‌پای عزیز'} 👋
            </h1>
          </div>

          <div className="flex items-center gap-1.5 px-3 py-1 rounded-full bg-accent-primary/10 border border-accent-primary/30 text-accent-primary font-bold text-xs">
            <Flame className="w-4 h-4 fill-current animate-bounce" />
            <span>{formatToPersianDigits(user.streakDays)} روز پیوستگی</span>
          </div>
        </div>

        {/* 1. Mobile Hero Glance Widget: Radial Progress & Study Time */}
        <div className="p-4 rounded-3xl bg-gradient-to-br from-canvas-elevated via-canvas-secondary to-canvas-elevated border border-border-highlight shadow-lg relative overflow-hidden">
          <div className="flex items-center justify-between">
            <div className="space-y-1">
              <span className="text-[11px] font-bold text-ink-muted uppercase tracking-wider">
                زمان تمرکز خالص امروز
              </span>
              <div className="text-2xl font-black text-ink-primary font-mono tracking-tight">
                {isTimerRunning ? formatTimer(timerSeconds) : `${formatToPersianDigits(totalStudiedHours)}س ${formatToPersianDigits(totalStudiedMinutes)}د`}
              </div>
              <div className="text-xs text-ink-muted flex items-center gap-1">
                <span>هدف: {formatToPersianDigits(Math.round(targetMinutes / 60))} ساعت</span>
                <span>•</span>
                <span className="text-accent-primary font-bold">{formatToPersianDigits(progressPercent)}٪ تحقق</span>
              </div>
            </div>

            {/* Circular Ring */}
            <div className="relative w-16 h-16 flex items-center justify-center">
              <svg className="w-16 h-16 -rotate-90" viewBox="0 0 36 36">
                <path
                  className="text-white/10"
                  strokeWidth="3.5"
                  stroke="currentColor"
                  fill="none"
                  d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                />
                <path
                  className="text-accent-primary transition-all duration-700 ease-out"
                  strokeDasharray={`${progressPercent}, 100`}
                  strokeWidth="3.5"
                  strokeLinecap="round"
                  stroke="currentColor"
                  fill="none"
                  d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                />
              </svg>
              <button
                onClick={() => setFocusModalOpen(true)}
                className="absolute inset-0 m-auto w-10 h-10 rounded-full bg-accent-primary text-white flex items-center justify-center shadow-needle active:scale-90 transition"
              >
                <Play className="w-4 h-4 fill-current ml-0.5" />
              </button>
            </div>
          </div>

          {/* Quick Start Focus Banner */}
          <div className="mt-3 pt-3 border-t border-border-subtle/50 flex items-center justify-between text-xs">
            <span className="text-ink-muted flex items-center gap-1">
              <Zap className="w-3.5 h-3.5 text-amber-400" />
              <span>{isTimerRunning ? 'تایمر در حال ضبط مطالعه...' : 'آماده برای جلسه تمرکز بعدی؟'}</span>
            </span>
            <button
              onClick={() => setFocusModalOpen(true)}
              className="text-accent-primary font-bold hover:underline flex items-center gap-0.5"
            >
              <span>{isTimerRunning ? 'مشاهده تایمر' : 'شروع فوکوس'}</span>
              <ChevronLeft className="w-3.5 h-3.5" />
            </button>
          </div>
        </div>

        {/* 2. Mobile Interactive Slide-To-Complete Widget ("کشیدن برای تیک زدن") */}
        {currentOrNextTask && (
          <div className="p-4 rounded-3xl bg-canvas-elevated liquid-glass border border-border-highlight shadow-md space-y-3">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <span className="w-2.5 h-2.5 rounded-full bg-accent-primary shadow-needle" />
                <span className="text-xs font-bold text-ink-muted uppercase">
                  تسک بعدی در برنامه امروز
                </span>
              </div>
              {currentOrNextTask.isMIT && (
                <span className="text-[10px] px-2 py-0.5 rounded-full bg-amber-500/20 text-amber-400 font-bold border border-amber-500/30">
                  اولویت طلایی MIT
                </span>
              )}
            </div>

            <div className="flex items-center justify-between">
              <div className="space-y-0.5">
                <h3 className="text-sm font-bold text-ink-primary">
                  {currentOrNextTask.title}
                </h3>
                <p className="text-xs text-ink-muted">
                  {currentOrNextTask.startTime ? `شروع: ${currentOrNextTask.startTime}` : 'بدون ساعت دقیق'} • {currentOrNextTask.durationMinutes} دقیقه
                </p>
              </div>
            </div>

            {/* Slide to complete slider */}
            <SlideToComplete
              onComplete={() => toggleTaskCompleted(currentOrNextTask.id)}
              isCompleted={currentOrNextTask.status === 'completed'}
              label="برای تیک زدن به چپ بکشید ‹‹"
              completedLabel="آفرین! تسک کامل شد 🎉"
            />
          </div>
        )}

        {/* 3. Mobile 2x2 Bento Widget Grid */}
        <div className="grid grid-cols-2 gap-3">
          {/* Widget 1: 3 MITs Summary */}
          <div 
            onClick={() => setViewMode('day')}
            className="p-3.5 rounded-2xl bg-canvas-elevated border border-border-subtle shadow-sm flex flex-col justify-between active:scale-[0.98] transition cursor-pointer"
          >
            <div className="flex items-center justify-between text-ink-muted">
              <Sparkles className="w-4 h-4 text-amber-400" />
              <span className="text-[10px] font-mono font-bold">{mitTasks.filter(t => t.status === 'completed').length}/{mitTasks.length}</span>
            </div>
            <div className="mt-2">
              <div className="text-xs font-bold text-ink-primary">اولویت‌های ۳ گانه</div>
              <div className="text-[11px] text-ink-muted mt-0.5">
                {mitTasks.length > 0 ? `${mitTasks.length} تسک طلایی ثبت شده` : 'ثبت با آیین صبحگاهی'}
              </div>
            </div>
          </div>

          {/* Widget 2: Tasks Done Counter */}
          <div 
            onClick={() => setViewMode('day')}
            className="p-3.5 rounded-2xl bg-canvas-elevated border border-border-subtle shadow-sm flex flex-col justify-between active:scale-[0.98] transition cursor-pointer"
          >
            <div className="flex items-center justify-between text-ink-muted">
              <CheckCircle2 className="w-4 h-4 text-emerald-400" />
              <span className="text-[10px] font-mono font-bold">{completedTasks.length}/{todayTasks.length}</span>
            </div>
            <div className="mt-2">
              <div className="text-xs font-bold text-ink-primary">تسک‌های انجام‌شده</div>
              <div className="text-[11px] text-ink-muted mt-0.5">
                {todayTasks.length > 0 ? `${Math.round((completedTasks.length / todayTasks.length) * 100)}٪ بازدهی روز` : 'هنوز تسکی نیست'}
              </div>
            </div>
          </div>

          {/* Widget 3: Eisenhower Matrix Shortcut */}
          <div 
            onClick={() => setViewMode('eisenhower')}
            className="p-3.5 rounded-2xl bg-canvas-elevated border border-border-subtle shadow-sm flex flex-col justify-between active:scale-[0.98] transition cursor-pointer"
          >
            <div className="flex items-center justify-between text-ink-muted">
              <Grid className="w-4 h-4 text-indigo-400" />
              <span className="text-[10px] font-mono font-bold">ماتریس</span>
            </div>
            <div className="mt-2">
              <div className="text-xs font-bold text-ink-primary">تفکیک آیزنهاور</div>
              <div className="text-[11px] text-ink-muted mt-0.5">
                {todayTasks.filter(t => t.priority === 'urgent').length} مورد در ناحیه فوری
              </div>
            </div>
          </div>

          {/* Widget 4: Study Room Shortcut */}
          <div 
            onClick={() => setViewMode('study_room')}
            className="p-3.5 rounded-2xl bg-canvas-elevated border border-border-subtle shadow-sm flex flex-col justify-between active:scale-[0.98] transition cursor-pointer"
          >
            <div className="flex items-center justify-between text-ink-muted">
              <Award className="w-4 h-4 text-accent-primary" />
              <span className="text-[10px] font-mono font-bold text-emerald-400">زنده</span>
            </div>
            <div className="mt-2">
              <div className="text-xs font-bold text-ink-primary">اتاق مطالعه زنده</div>
              <div className="text-[11px] text-ink-muted mt-0.5">مطالعه همگام با هم‌پایان</div>
            </div>
          </div>
        </div>

        {/* 4. Mobile Agenda Horizontal Scroll (امروز در یک نگاه) */}
        <div className="space-y-2">
          <div className="flex items-center justify-between px-1">
            <span className="text-xs font-bold text-ink-primary">
              تایم‌بلاک‌های امروز ({todayTasks.length})
            </span>
            <button
              onClick={() => setViewMode('day')}
              className="text-[11px] text-accent-primary font-bold hover:underline"
            >
              مشاهده تایم‌لاین کامل
            </button>
          </div>

          <div className="flex gap-2.5 overflow-x-auto pb-2 scrollbar-none snap-x">
            {todayTasks.length === 0 ? (
              <div className="w-full p-4 rounded-2xl bg-canvas-elevated border border-border-subtle text-center text-xs text-ink-muted">
                هنوز تسکی برای امروز تعریف نکرده‌اید. با دکمه + اضافه کنید!
              </div>
            ) : (
              todayTasks.map((t) => (
                <div
                  key={t.id}
                  onClick={() => selectTask(t.id)}
                  className={`min-w-[200px] max-w-[220px] p-3 rounded-2xl border transition snap-start flex flex-col justify-between space-y-2 ${
                    t.status === 'completed'
                      ? 'bg-canvas-secondary/50 border-border-subtle opacity-60'
                      : 'bg-canvas-elevated border-border-highlight shadow-sm'
                  }`}
                  style={{
                    borderRightWidth: '4px',
                    borderRightColor: t.color || '#FF4700',
                  }}
                >
                  <div className="space-y-1">
                    <div className="flex items-center justify-between text-[10px] font-mono text-ink-muted">
                      <span>{t.startTime || 'زمان باز'}</span>
                      <span>{t.durationMinutes}دقیقه</span>
                    </div>
                    <div className={`text-xs font-bold line-clamp-2 ${t.status === 'completed' ? 'line-through text-ink-muted' : 'text-ink-primary'}`}>
                      {t.title}
                    </div>
                  </div>

                  <div className="flex items-center justify-between pt-1">
                    <span className="text-[10px] px-2 py-0.5 rounded bg-white/5 text-ink-muted">
                      {t.tags[0] || 'مطالعه'}
                    </span>
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        toggleTaskCompleted(t.id);
                      }}
                      className="p-1 rounded-full text-ink-muted hover:text-accent-primary"
                    >
                      {t.status === 'completed' ? (
                        <CheckCircle2 className="w-4 h-4 text-emerald-400" />
                      ) : (
                        <Circle className="w-4 h-4" />
                      )}
                    </button>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>

        {/* 5. Mobile Daily Habit Checkers */}
        <div className="p-4 rounded-3xl bg-canvas-elevated border border-border-subtle shadow-sm space-y-2.5">
          <span className="text-xs font-bold text-ink-primary block">
            ردیاب عادات و انرژی امروز
          </span>
          <div className="grid grid-cols-2 gap-2 text-xs">
            {habits.map((h) => (
              <button
                key={h.id}
                onClick={() => toggleHabit(h.id)}
                className={`p-2.5 rounded-xl border flex items-center gap-2 text-right transition ${
                  h.done
                    ? 'bg-emerald-500/10 border-emerald-500/30 text-emerald-400 font-bold'
                    : 'bg-canvas-secondary border-border-subtle text-ink-muted hover:text-ink-primary'
                }`}
              >
                <span>{h.icon}</span>
                <span className="truncate flex-1 text-[11px]">{h.label}</span>
                <Check className={`w-3.5 h-3.5 ${h.done ? 'opacity-100' : 'opacity-20'}`} />
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* ========================================================
          DESKTOP MULTI-WINDOW WIDGET DASHBOARD (>= md)
          (Windows-style widget system with rich cards, distributed)
          ======================================================== */}
      <div className="hidden md:block max-w-7xl mx-auto space-y-6">
        {/* Top Hero Banner Window */}
        <div className="p-5 lg:p-6 rounded-3xl bg-gradient-to-r from-canvas-elevated via-canvas-secondary to-canvas-elevated border border-border-highlight shadow-xl flex items-center justify-between">
          <div className="space-y-1">
            <div className="flex items-center gap-2 text-xs font-medium text-ink-muted">
              <Calendar className="w-4 h-4 text-accent-primary" />
              <span>{dateLabel}</span>
              <span>•</span>
              <span className="text-accent-primary font-bold">داشبورد یکپارچه چندپنجره‌ای</span>
            </div>
            <h1 className="text-xl lg:text-2xl font-black text-ink-primary">
              سلام، {user.displayName || 'هم‌پای عزیز'}؛ آماده‌ای برای یک روز پربار؟
            </h1>
            <p className="text-xs text-ink-muted max-w-xl">
              تمام اطلاعات، وضعیت تمرکز زنده، تایم‌بلاک‌ها و اولویت‌های حیاتی امروز در یک نما پیش روی شماست.
            </p>
          </div>

          {/* Quick Metrics Capsule */}
          <div className="flex items-center gap-3">
            <div className="p-3 rounded-2xl bg-canvas-elevated border border-border-subtle flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-accent-primary/20 text-accent-primary flex items-center justify-center">
                <Flame className="w-5 h-5 fill-current" />
              </div>
              <div>
                <div className="text-xs text-ink-muted font-bold">پیوستگی متوالی</div>
                <div className="text-base font-black text-ink-primary font-mono">
                  {formatToPersianDigits(user.streakDays)} روز
                </div>
              </div>
            </div>

            <div className="p-3 rounded-2xl bg-canvas-elevated border border-border-subtle flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-emerald-500/20 text-emerald-400 flex items-center justify-center">
                <CheckCircle2 className="w-5 h-5" />
              </div>
              <div>
                <div className="text-xs text-ink-muted font-bold">تسک‌های انجام‌شده</div>
                <div className="text-base font-black text-ink-primary font-mono">
                  {formatToPersianDigits(completedTasks.length)} از {formatToPersianDigits(todayTasks.length)}
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Multi-Window Desktop Widgets Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
          {/* WINDOW 1: Focus Gauge & YPT Live Pomodoro Widget */}
          <div className="p-5 rounded-3xl bg-canvas-elevated liquid-glass border border-border-subtle shadow-md flex flex-col justify-between space-y-4">
            <div className="flex items-center justify-between pb-3 border-b border-border-subtle">
              <div className="flex items-center gap-2">
                <Clock className="w-4 h-4 text-accent-primary" />
                <h3 className="text-sm font-bold text-ink-primary">
                  زمان تمرکز خالص YPT
                </h3>
              </div>
              <span className={`text-[11px] font-bold px-2 py-0.5 rounded-full ${isTimerRunning ? 'bg-accent-primary/20 text-accent-primary animate-pulse' : 'bg-white/5 text-ink-muted'}`}>
                {isTimerRunning ? 'در حال ثبت...' : 'آماده'}
              </span>
            </div>

            {/* Circular Gauge */}
            <div className="flex items-center justify-around py-2">
              <div className="relative w-28 h-28 flex items-center justify-center">
                <svg className="w-28 h-28 -rotate-90" viewBox="0 0 36 36">
                  <path
                    className="text-white/10"
                    strokeWidth="3.2"
                    stroke="currentColor"
                    fill="none"
                    d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                  />
                  <path
                    className="text-accent-primary transition-all duration-700 ease-out"
                    strokeDasharray={`${progressPercent}, 100`}
                    strokeWidth="3.2"
                    strokeLinecap="round"
                    stroke="currentColor"
                    fill="none"
                    d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                  />
                </svg>
                <div className="absolute inset-0 flex flex-col items-center justify-center font-mono">
                  <span className="text-lg font-black text-ink-primary">
                    {formatToPersianDigits(progressPercent)}٪
                  </span>
                  <span className="text-[9px] text-ink-muted">از هدف امروز</span>
                </div>
              </div>

              <div className="space-y-1.5 text-right">
                <div className="text-xs text-ink-muted">مجموع مطالعه امروز:</div>
                <div className="text-xl font-black font-mono text-ink-primary">
                  {formatToPersianDigits(totalStudiedHours)}ساعت و {formatToPersianDigits(totalStudiedMinutes)}دقیقه
                </div>
                <div className="text-[11px] text-ink-muted">
                  ظرفیت هدف: {formatToPersianDigits(Math.round(targetMinutes / 60))} ساعت
                </div>
              </div>
            </div>

            {/* Launch Focus Studio Button */}
            <button
              onClick={() => setFocusModalOpen(true)}
              className="w-full flex items-center justify-center gap-2 py-2.5 rounded-xl bg-accent-primary hover:bg-accent-hover text-white font-bold text-xs shadow-needle transition active:scale-95"
            >
              <Play className="w-4 h-4 fill-current" />
              <span>{isTimerRunning ? 'ورود به استودیوی تمرکز زنده' : 'شروع جلسه تمرکز جدید'}</span>
            </button>
          </div>

          {/* WINDOW 2: MITs (Most Important Tasks) Window */}
          <div className="p-5 rounded-3xl bg-canvas-elevated liquid-glass border border-border-subtle shadow-md flex flex-col justify-between space-y-4">
            <div className="flex items-center justify-between pb-3 border-b border-border-subtle">
              <div className="flex items-center gap-2">
                <Sparkles className="w-4 h-4 text-amber-400" />
                <h3 className="text-sm font-bold text-ink-primary">
                  ۳ اولویت طلایی روز (Sunsama MITs)
                </h3>
              </div>
              <span className="text-xs font-mono font-bold text-ink-muted">
                {mitTasks.filter(t => t.status === 'completed').length} / {mitTasks.length}
              </span>
            </div>

            {/* MIT List */}
            <div className="space-y-2 flex-1">
              {mitTasks.length === 0 ? (
                <div className="h-full flex flex-col items-center justify-center text-center p-4 text-ink-muted text-xs space-y-2">
                  <p>هنوز تسکی به عنوان اولویت طلایی علامت نخورده است.</p>
                  <button
                    onClick={() => setCreateTaskOpen(true)}
                    className="text-accent-primary font-bold hover:underline"
                  >
                    + افزودن تسک طلایی
                  </button>
                </div>
              ) : (
                mitTasks.slice(0, 3).map((task, idx) => (
                  <div
                    key={task.id}
                    className={`p-3 rounded-xl border transition flex items-center justify-between gap-3 ${
                      task.status === 'completed'
                        ? 'bg-canvas-secondary/50 border-border-subtle opacity-60'
                        : 'bg-canvas-secondary border-border-highlight shadow-sm'
                    }`}
                  >
                    <div className="flex items-center gap-2.5 min-w-0">
                      <span className="w-5 h-5 rounded-full bg-amber-500/20 text-amber-400 font-bold text-xs flex items-center justify-center flex-shrink-0">
                        {idx + 1}
                      </span>
                      <div className="truncate">
                        <div className={`text-xs font-bold truncate ${task.status === 'completed' ? 'line-through text-ink-muted' : 'text-ink-primary'}`}>
                          {task.title}
                        </div>
                        <div className="text-[10px] text-ink-muted font-mono">
                          {task.startTime || 'بدون ساعت'} • {task.durationMinutes}دقیقه
                        </div>
                      </div>
                    </div>

                    <button
                      onClick={() => toggleTaskCompleted(task.id)}
                      className="p-1.5 rounded-lg text-ink-muted hover:text-accent-primary transition"
                    >
                      {task.status === 'completed' ? (
                        <CheckCircle2 className="w-4 h-4 text-emerald-400" />
                      ) : (
                        <Circle className="w-4 h-4" />
                      )}
                    </button>
                  </div>
                ))
              )}
            </div>

            <div className="pt-2 text-left">
              <button
                onClick={() => setViewMode('day')}
                className="text-xs text-accent-primary font-bold hover:underline inline-flex items-center gap-1"
              >
                <span>مشاهده همه در تایم‌لاین</span>
                <ChevronLeft className="w-3.5 h-3.5" />
              </button>
            </div>
          </div>

          {/* WINDOW 3: Today's Schedule Agenda Blocks */}
          <div className="p-5 rounded-3xl bg-canvas-elevated liquid-glass border border-border-subtle shadow-md flex flex-col justify-between space-y-4">
            <div className="flex items-center justify-between pb-3 border-b border-border-subtle">
              <div className="flex items-center gap-2">
                <Layers className="w-4 h-4 text-blue-400" />
                <h3 className="text-sm font-bold text-ink-primary">
                  برنامه زمان‌بندی امروز ({todayTasks.length})
                </h3>
              </div>
              <button
                onClick={() => setCreateTaskOpen(true)}
                className="text-xs text-accent-primary font-bold hover:underline"
              >
                + تسک جدید
              </button>
            </div>

            <div className="space-y-2 flex-1 max-h-56 overflow-y-auto pr-1">
              {todayTasks.length === 0 ? (
                <div className="h-full flex items-center justify-center text-xs text-ink-muted text-center p-4">
                  هیچ تسکی برای این تاریخ ثبت نشده است.
                </div>
              ) : (
                todayTasks.map((t) => (
                  <div
                    key={t.id}
                    onClick={() => selectTask(t.id)}
                    className="p-2.5 rounded-xl bg-canvas-secondary/60 hover:bg-canvas-secondary border border-border-subtle/70 flex items-center justify-between cursor-pointer transition"
                  >
                    <div className="flex items-center gap-2 min-w-0">
                      <span
                        className="w-2 h-2 rounded-full flex-shrink-0"
                        style={{ backgroundColor: t.color || '#FF4700' }}
                      />
                      <span className={`text-xs truncate ${t.status === 'completed' ? 'line-through text-ink-muted' : 'text-ink-primary'}`}>
                        {t.title}
                      </span>
                    </div>
                    <span className="text-[10px] font-mono text-ink-muted flex-shrink-0 mr-2">
                      {t.startTime || `${t.durationMinutes}د`}
                    </span>
                  </div>
                ))
              )}
            </div>

            <div className="pt-2 flex items-center justify-between text-xs text-ink-muted">
              <span>{completedTasks.length} انجام شده</span>
              <span>{pendingTasks.length} باقیمانده</span>
            </div>
          </div>

          {/* WINDOW 4: Eisenhower Snapshot Window */}
          <div className="p-5 rounded-3xl bg-canvas-elevated liquid-glass border border-border-subtle shadow-md space-y-3">
            <div className="flex items-center justify-between pb-2 border-b border-border-subtle">
              <div className="flex items-center gap-2">
                <Grid className="w-4 h-4 text-indigo-400" />
                <h3 className="text-sm font-bold text-ink-primary">
                  ماتریس فوری و مهم (آیزنهاور)
                </h3>
              </div>
              <button
                onClick={() => setViewMode('eisenhower')}
                className="text-xs text-accent-primary font-bold hover:underline"
              >
                نمای ماتریس
              </button>
            </div>

            <div className="grid grid-cols-2 gap-2 text-xs">
              <div 
                onClick={() => setViewMode('eisenhower')}
                className="p-3 rounded-xl bg-red-500/10 border border-red-500/20 cursor-pointer hover:bg-red-500/15 transition"
              >
                <div className="text-red-400 font-bold text-[11px]">Q1: فوری و مهم</div>
                <div className="text-base font-black text-ink-primary mt-1 font-mono">
                  {formatToPersianDigits(todayTasks.filter(t => t.priority === 'urgent').length)}
                </div>
              </div>

              <div 
                onClick={() => setViewMode('eisenhower')}
                className="p-3 rounded-xl bg-blue-500/10 border border-blue-500/20 cursor-pointer hover:bg-blue-500/15 transition"
              >
                <div className="text-blue-400 font-bold text-[11px]">Q2: بااهمیت برنامه‌دار</div>
                <div className="text-base font-black text-ink-primary mt-1 font-mono">
                  {formatToPersianDigits(todayTasks.filter(t => t.priority === 'high').length)}
                </div>
              </div>

              <div 
                onClick={() => setViewMode('eisenhower')}
                className="p-3 rounded-xl bg-amber-500/10 border border-amber-500/20 cursor-pointer hover:bg-amber-500/15 transition"
              >
                <div className="text-amber-400 font-bold text-[11px]">Q3: فوری غیرمهم</div>
                <div className="text-base font-black text-ink-primary mt-1 font-mono">
                  {formatToPersianDigits(todayTasks.filter(t => t.priority === 'medium').length)}
                </div>
              </div>

              <div 
                onClick={() => setViewMode('eisenhower')}
                className="p-3 rounded-xl bg-emerald-500/10 border border-emerald-500/20 cursor-pointer hover:bg-emerald-500/15 transition"
              >
                <div className="text-emerald-400 font-bold text-[11px]">Q4: کم‌اهمیت</div>
                <div className="text-base font-black text-ink-primary mt-1 font-mono">
                  {formatToPersianDigits(todayTasks.filter(t => t.priority === 'low').length)}
                </div>
              </div>
            </div>
          </div>

          {/* WINDOW 5: Subject Study Distribution */}
          <div className="p-5 rounded-3xl bg-canvas-elevated liquid-glass border border-border-subtle shadow-md space-y-3">
            <div className="flex items-center justify-between pb-2 border-b border-border-subtle">
              <div className="flex items-center gap-2">
                <BookOpen className="w-4 h-4 text-emerald-400" />
                <h3 className="text-sm font-bold text-ink-primary">
                  توزیع موضوعات و دروس
                </h3>
              </div>
              <button
                onClick={() => setViewMode('analytics')}
                className="text-xs text-accent-primary font-bold hover:underline"
              >
                تحلیل جامع
              </button>
            </div>

            <div className="space-y-2.5">
              {subjects.slice(0, 4).map((subj) => {
                const hours = Math.round((subj.totalSecondsStudied / 3600) * 10) / 10;
                return (
                  <div key={subj.id} className="space-y-1">
                    <div className="flex items-center justify-between text-xs">
                      <span className="text-ink-primary font-medium">{subj.name}</span>
                      <span className="font-mono text-ink-muted text-[11px]">
                        {formatToPersianDigits(hours)} ساعت
                      </span>
                    </div>
                    <div className="w-full h-1.5 rounded-full bg-white/5 overflow-hidden">
                      <div
                        className="h-full rounded-full transition-all duration-500"
                        style={{
                          width: `${Math.min(100, Math.max(10, (subj.totalSecondsStudied / 28800) * 100))}%`,
                          backgroundColor: subj.color,
                        }}
                      />
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

          {/* WINDOW 6: Daily Habits & Energy Check */}
          <div className="p-5 rounded-3xl bg-canvas-elevated liquid-glass border border-border-subtle shadow-md space-y-3">
            <div className="flex items-center justify-between pb-2 border-b border-border-subtle">
              <div className="flex items-center gap-2">
                <Zap className="w-4 h-4 text-amber-400" />
                <h3 className="text-sm font-bold text-ink-primary">
                  ردیاب عادات و بازسازی انرژی
                </h3>
              </div>
              <span className="text-xs font-mono font-bold text-ink-muted">
                {habits.filter(h => h.done).length} / {habits.length}
              </span>
            </div>

            <div className="space-y-2">
              {habits.map((h) => (
                <button
                  key={h.id}
                  onClick={() => toggleHabit(h.id)}
                  className={`w-full p-2.5 rounded-xl border flex items-center justify-between transition text-xs ${
                    h.done
                      ? 'bg-emerald-500/10 border-emerald-500/30 text-emerald-400 font-bold'
                      : 'bg-canvas-secondary border-border-subtle text-ink-muted hover:text-ink-primary'
                  }`}
                >
                  <div className="flex items-center gap-2">
                    <span>{h.icon}</span>
                    <span>{h.label}</span>
                  </div>
                  <Check className={`w-4 h-4 ${h.done ? 'opacity-100' : 'opacity-20'}`} />
                </button>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
