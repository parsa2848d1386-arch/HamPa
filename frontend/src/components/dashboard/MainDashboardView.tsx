import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  Flame, 
  Sparkles, 
  Clock, 
  CheckCircle2, 
  Circle, 
  Play, 
  Pause,
  Plus, 
  ArrowRight, 
  TrendingUp, 
  Calendar, 
  Grid, 
  Zap, 
  Volume2, 
  VolumeX,
  BookOpen, 
  ChevronLeft,
  Coffee,
  Check,
  Award,
  Layers,
  Send,
  Users,
  Target,
  Headphones,
  Maximize2
} from 'lucide-react';
import { useAppStore } from '../../store/useAppStore';
import { SlideToComplete } from '../common/SlideToComplete';
import { 
  gregorianToJalali, 
  PERSIAN_MONTHS, 
  PERSIAN_WEEKDAYS, 
  formatToPersianDigits,
  getTimetableSlots
} from '../../lib/calendarUtils';
import confetti from 'canvas-confetti';
import type { AmbientSoundType } from '../../types';

export const MainDashboardView: React.FC = () => {
  const selectedDate = useAppStore((s) => s.selectedDate);
  const tasks = useAppStore((s) => s.tasks);
  const subjects = useAppStore((s) => s.subjects);
  const user = useAppStore((s) => s.user);
  const sessions = useAppStore((s) => s.sessions);
  const toggleTaskCompleted = useAppStore((s) => s.toggleTaskCompleted);
  const toggleSubtask = useAppStore((s) => s.toggleSubtask);
  const selectTask = useAppStore((s) => s.selectTask);
  const selectedTaskId = useAppStore((s) => s.selectedTaskId);
  const setCreateTaskOpen = useAppStore((s) => s.setCreateTaskOpen);
  const setBrainDumpOpen = useAppStore((s) => s.setBrainDumpOpen);
  const setFocusModalOpen = useAppStore((s) => s.setFocusModalOpen);
  const startFocusSession = useAppStore((s) => s.startFocusSession);
  const pauseTimer = useAppStore((s) => s.pauseTimer);
  const resumeTimer = useAppStore((s) => s.resumeTimer);
  const isTimerRunning = useAppStore((s) => s.isTimerRunning);
  const isTimerPaused = useAppStore((s) => s.isTimerPaused);
  const timerSeconds = useAppStore((s) => s.timerSeconds);
  const activeTaskId = useAppStore((s) => s.activeTaskId);
  const activeSubjectId = useAppStore((s) => s.activeSubjectId);
  const calendarSystem = useAppStore((s) => s.calendarSystem);
  const setViewMode = useAppStore((s) => s.setViewMode);
  const ambientSound = useAppStore((s) => s.ambientSound);
  const setAmbientSound = useAppStore((s) => s.setAmbientSound);

  const activeSubject = subjects.find((s) => s.id === activeSubjectId) || subjects[0];

  // Quick Habit Toggles for Today
  const [habits, setHabits] = useState([
    { id: 'water', label: '۸ لیوان آب', done: false, icon: '💧' },
    { id: 'reading', label: 'مطالعه عمیق روزانه', done: false, icon: '📚' },
    { id: 'exercise', label: 'تحرک و کشش بدنی', done: false, icon: '🏃' },
    { id: 'review', label: 'مرور شبانه فلش‌کارت‌ها', done: false, icon: '🧠' },
  ]);

  // Quick AI input in desktop widget
  const [quickThought, setQuickThought] = useState('');
  const [statusFilter, setStatusFilter] = useState<'all' | 'pending' | 'completed' | 'mit'>('all');
  const [subjectFilter, setSubjectFilter] = useState<string | null>(null);

  // Time of day greeting
  const [greeting, setGreeting] = useState('سلام، وقت به‌خیر');
  useEffect(() => {
    const hour = new Date().getHours();
    if (hour >= 5 && hour < 12) setGreeting('صبح به‌خیر');
    else if (hour >= 12 && hour < 17) setGreeting('ظهر به‌خیر');
    else if (hour >= 17 && hour < 21) setGreeting('عصر به‌خیر');
    else setGreeting('شب به‌خیر');
  }, []);

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

  // Filtered tasks for agenda
  const filteredTodayTasks = todayTasks.filter((t) => {
    if (statusFilter === 'pending' && t.status === 'completed') return false;
    if (statusFilter === 'completed' && t.status !== 'completed') return false;
    if (statusFilter === 'mit' && !t.isMIT) return false;
    if (subjectFilter && t.subjectId !== subjectFilter) return false;
    return true;
  });

  // #1 MIT task or currently selected task
  const currentOrNextTask =
    tasks.find((t) => t.id === selectedTaskId && t.date === selectedDate) ||
    mitTasks.find((t) => t.status !== 'completed') ||
    pendingTasks.find((t) => t.id === activeTaskId) ||
    pendingTasks[0] ||
    todayTasks[0];

  // Today's sessions & total study duration (clean, real computation)
  const todaySessions = sessions.filter((s) => s.dateKey === selectedDate);
  const totalStudiedSeconds = todaySessions.reduce((sum, s) => sum + s.durationSeconds, 0) + (isTimerRunning ? timerSeconds : 0);
  const totalStudiedHours = Math.floor(totalStudiedSeconds / 3600);
  const totalStudiedMinutes = Math.floor((totalStudiedSeconds % 3600) / 60);

  // Daily target (default 6 hours = 360 min)
  const targetMinutes = user.dailyCapacityMinutes || 360;
  const currentMinutesStudied = Math.round(totalStudiedSeconds / 60);
  const progressPercent = Math.min(100, Math.round((currentMinutesStudied / targetMinutes) * 100));

  // D-Day target exam calculation
  const now = new Date();
  const examDate = user.targetExamDate ? new Date(user.targetExamDate) : new Date(now.getFullYear(), 5, 25);
  const diffDays = Math.max(1, Math.ceil((examDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24)));

  // 144-Slot Timetable Ribbon calculation (05:00 AM to 05:00 AM)
  const slots = getTimetableSlots();
  const nowMinutesFrom5AM = (() => {
    const curHour = now.getHours();
    const curMin = now.getMinutes();
    const totalMinutes = curHour * 60 + curMin;
    return (totalMinutes - 300 + 1440) % 1440;
  })();
  const currentSlotIndex = Math.floor(nowMinutesFrom5AM / 10);

  const getSlotColor = (slotHour: number, slotMinute: number) => {
    const slotMinutesOfDay = slotHour * 60 + slotMinute;
    for (const sess of todaySessions) {
      try {
        const start = new Date(sess.startedAt);
        const end = new Date(sess.endedAt);
        const startMin = start.getHours() * 60 + start.getMinutes();
        const endMin = end.getHours() * 60 + end.getMinutes();
        if (slotMinutesOfDay >= startMin && slotMinutesOfDay < endMin) {
          const subj = subjects.find((s) => s.id === sess.subjectId);
          return subj ? subj.color : '#FF4700';
        }
      } catch {
        // Ignored
      }
    }
    return null;
  };

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

  const handleCheerFriend = () => {
    confetti({
      particleCount: 65,
      spread: 70,
      origin: { y: 0.65 }
    });
  };

  const soundOptions: { type: AmbientSoundType; label: string; icon: string }[] = [
    { type: 'rain', label: 'باران', icon: '🌧️' },
    { type: 'cafe', label: 'کافه', icon: '☕' },
    { type: 'binaural_focus', label: 'امواج آلفا', icon: '🧠' },
    { type: 'brown_noise', label: 'نویز آرامش', icon: '🍂' },
  ];

  const handleToggleSound = (type: AmbientSoundType) => {
    if (ambientSound.isPlaying && ambientSound.type === type) {
      setAmbientSound('none');
    } else {
      setAmbientSound(type, 0.5);
    }
  };

  return (
    <div className="flex-1 overflow-y-auto bg-canvas p-3 sm:p-5 lg:p-7 select-none pb-24 md:pb-16 transition-colors duration-200">
      <div className="max-w-7xl mx-auto space-y-5">
        
        {/* ========================================================
            TOP BAR: Master Welcome & Daily Action Capsule
            ======================================================== */}
        <header className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 p-4 md:p-5 rounded-3xl bg-canvas-elevated/70 backdrop-blur-xl border border-white/10 dark:border-white/10 shadow-sm">
          <div className="space-y-1">
            <div className="text-xs font-semibold text-ink-muted flex items-center gap-2">
              <Calendar className="w-3.5 h-3.5 text-accent-primary" />
              <span>{dateLabel}</span>
            </div>
            <h1 className="text-xl md:text-2xl font-black text-ink-primary tracking-tight">
              {greeting}، {user.displayName || 'هم‌پای عزیز'} 👋
            </h1>
            <p className="text-xs text-ink-muted hidden sm:block">
              امروز {formatToPersianDigits(pendingTasks.length)} فعالیت در انتظار داری. آماده‌ای برای ساختن یک رکورد جدید؟
            </p>
          </div>

          <div className="flex items-center gap-2 flex-wrap">
            {/* Streak Flame Badge */}
            <div className="flex items-center gap-2 px-3.5 py-1.5 rounded-2xl bg-gradient-to-l from-orange-500/15 to-amber-500/10 border border-orange-500/30 text-accent-primary font-bold text-xs shadow-sm">
              <Flame className="w-4 h-4 fill-current animate-pulse text-orange-500" />
              <span>{formatToPersianDigits(user.streakDays)} روز پیوستگی مطالعه</span>
            </div>

            {/* Quick Actions */}
            <button
              onClick={() => setCreateTaskOpen(true)}
              className="flex items-center gap-1.5 px-3 py-1.5 rounded-2xl bg-accent-primary hover:bg-accent-hover text-white text-xs font-bold shadow-needle transition active:scale-95 cursor-pointer"
              aria-label="افزودن تسک جدید"
            >
              <Plus className="w-4 h-4" />
              <span className="hidden xs:inline">تسک جدید</span>
            </button>
          </div>
        </header>

        {/* ========================================================
            ROW 1: Flagship Bento Grid (Hero Velocity + Golden MIT + Streak/Exam)
            ======================================================== */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-4 md:gap-5">
          
          {/* 1.1 HERO MASTER FOCUS VELOCITY CARD (Span 6 on LG) */}
          <div className="lg:col-span-6 p-5 md:p-6 rounded-3xl bg-gradient-to-br from-canvas-elevated via-canvas-secondary to-canvas-elevated border border-white/10 dark:border-white/10 shadow-lg relative overflow-hidden flex flex-col justify-between space-y-4">
            
            {/* Top Row: Title & Active Badge */}
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 rounded-xl bg-accent-primary/20 text-accent-primary flex items-center justify-center">
                  <Clock className="w-4 h-4" />
                </div>
                <div>
                  <h2 className="text-sm font-black text-ink-primary">
                    زمان تمرکز خالص امروز (YPT Engine)
                  </h2>
                  <span className="text-[11px] text-ink-muted">
                    هدف: {formatToPersianDigits(Math.round(targetMinutes / 60))} ساعت • تحقق: {formatToPersianDigits(progressPercent)}٪
                  </span>
                </div>
              </div>

              <span className={`text-[11px] font-bold px-2.5 py-1 rounded-full border transition flex items-center gap-1.5 ${
                isTimerRunning 
                  ? 'bg-emerald-500/15 text-emerald-400 border-emerald-500/40 animate-pulse'
                  : 'bg-white/5 text-ink-muted border-border-subtle'
              }`}>
                <span className={`w-2 h-2 rounded-full ${isTimerRunning ? 'bg-emerald-400 shadow-needle' : 'bg-ink-muted'}`} />
                <span>{isTimerRunning ? 'در حال ثبت...' : 'آماده تمرکز'}</span>
              </span>
            </div>

            {/* Center: Radial Progress & Big Numbers */}
            <div className="flex items-center justify-between py-2">
              <div className="space-y-1">
                <div className="text-3xl md:text-4xl font-black text-ink-primary font-mono tracking-tight tabular-nums">
                  {isTimerRunning 
                    ? formatTimer(timerSeconds) 
                    : `${formatToPersianDigits(totalStudiedHours)}س ${formatToPersianDigits(totalStudiedMinutes)}د`}
                </div>
                <div className="text-xs text-ink-muted flex items-center gap-2">
                  <span>جلسات ثبت شده: {formatToPersianDigits(todaySessions.length)}</span>
                  <span>•</span>
                  <span className="text-accent-primary font-bold">باقیمانده تا هدف: {formatToPersianDigits(Math.max(0, Math.round(targetMinutes - currentMinutesStudied)))} دقیقه</span>
                </div>
              </div>

              {/* Radial Gauge Ring */}
              <div className="relative w-24 h-24 flex-shrink-0 flex items-center justify-center">
                <svg className="w-24 h-24 -rotate-90" viewBox="0 0 36 36">
                  <path
                    className="text-white/10 dark:text-white/5"
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
                  <span className="text-base font-black text-ink-primary tabular-nums">
                    {formatToPersianDigits(progressPercent)}٪
                  </span>
                </div>
              </div>
            </div>

            {/* Embedded Ambient Soundscape Quick-Player */}
            <div className="pt-3 border-t border-border-subtle/60 flex flex-col sm:flex-row sm:items-center justify-between gap-2.5">
              <div className="flex items-center gap-1.5 text-xs text-ink-muted">
                <Headphones className="w-3.5 h-3.5 text-indigo-400" />
                <span className="text-[11px] font-bold">اصوات تمرکز:</span>
                <div className="flex items-center gap-1">
                  {soundOptions.map((s) => {
                    const isActive = ambientSound.isPlaying && ambientSound.type === s.type;
                    return (
                      <button
                        key={s.type}
                        onClick={() => handleToggleSound(s.type)}
                        className={`px-2 py-0.5 rounded-lg text-[10px] font-bold transition flex items-center gap-1 cursor-pointer border ${
                          isActive
                            ? 'bg-indigo-500/20 text-indigo-300 border-indigo-500/40 shadow-sm'
                            : 'bg-white/5 hover:bg-white/10 text-ink-muted border-border-subtle'
                        }`}
                        title={isActive ? `توقف ${s.label}` : `پخش ${s.label}`}
                        aria-label={`صدای ${s.label}`}
                      >
                        <span>{s.icon}</span>
                        <span>{s.label}</span>
                      </button>
                    );
                  })}
                </div>
              </div>

              {/* Focus Launcher Button */}
              <button
                onClick={() => setFocusModalOpen(true)}
                className="flex items-center justify-center gap-2 px-4 py-2 rounded-xl bg-accent-primary hover:bg-accent-hover text-white text-xs font-bold shadow-needle transition active:scale-95 cursor-pointer"
                aria-label="باز کردن استودیو تمرکز زنده"
              >
                <Play className="w-3.5 h-3.5 fill-current" />
                <span>{isTimerRunning ? 'مشاهده استودیو' : 'شروع فوکوس'}</span>
              </button>
            </div>
          </div>

          {/* 1.2 GOLDEN MIT FOCUS CARD (Span 3 on LG) */}
          <div className="lg:col-span-3 p-5 rounded-3xl bg-canvas-elevated liquid-glass border border-white/10 dark:border-white/10 shadow-md flex flex-col justify-between space-y-3">
            <div className="flex items-center justify-between pb-2 border-b border-border-subtle">
              <div className="flex items-center gap-2">
                <Sparkles className="w-4 h-4 text-amber-400" />
                <h3 className="text-xs font-bold text-ink-primary">
                  اولویت طلایی امروز (Sunsama MIT)
                </h3>
              </div>
              <span className="text-[10px] font-mono px-2 py-0.5 rounded-full bg-amber-500/20 text-amber-400 font-bold border border-amber-500/30">
                #1 کلیدی
              </span>
            </div>

            {currentOrNextTask ? (
              <div className="space-y-3 flex-1 flex flex-col justify-between">
                <div className="space-y-1.5">
                  <h4 className="text-sm font-bold text-ink-primary line-clamp-2">
                    {currentOrNextTask.title}
                  </h4>
                  <div className="text-xs text-ink-muted flex items-center gap-2 font-mono">
                    <span>{currentOrNextTask.startTime || 'بدون ساعت دقیق'}</span>
                    <span>•</span>
                    <span>{formatToPersianDigits(currentOrNextTask.durationMinutes)} دقیقه</span>
                  </div>
                </div>

                {/* Subtask progress */}
                {currentOrNextTask.subtasks && currentOrNextTask.subtasks.length > 0 && (
                  <div className="space-y-1.5">
                    <div className="flex items-center justify-between text-[11px] text-ink-muted">
                      <span>زیرتسک‌ها</span>
                      <span>
                        {formatToPersianDigits(currentOrNextTask.subtasks.filter(st => st.completed).length)} از {formatToPersianDigits(currentOrNextTask.subtasks.length)}
                      </span>
                    </div>
                    <div className="w-full h-1.5 rounded-full bg-white/5 overflow-hidden">
                      <div
                        className="h-full bg-amber-400 rounded-full transition-all duration-300"
                        style={{
                          width: `${(currentOrNextTask.subtasks.filter(st => st.completed).length / currentOrNextTask.subtasks.length) * 100}%`
                        }}
                      />
                    </div>
                  </div>
                )}

                {/* One-Click Focus Now Button Tagged to Task */}
                <button
                  onClick={() => {
                    startFocusSession(currentOrNextTask.subjectId || subjects[0].id, currentOrNextTask.id, 'stopwatch');
                  }}
                  className="w-full flex items-center justify-center gap-2 py-2 rounded-xl bg-amber-500/20 hover:bg-amber-500/30 text-amber-300 border border-amber-500/40 text-xs font-bold transition active:scale-95 cursor-pointer"
                  aria-label="تمرکز روی این تسک"
                >
                  <Zap className="w-3.5 h-3.5 text-amber-400 fill-current" />
                  <span>تمرکز مستقیم روی این تسک</span>
                </button>
              </div>
            ) : (
              <div className="flex-1 flex flex-col items-center justify-center text-center p-4 text-ink-muted text-xs space-y-2">
                <p>تسک اولویت طلایی برای امروز مشخص نشده است.</p>
                <button
                  onClick={() => setCreateTaskOpen(true)}
                  className="text-accent-primary font-bold hover:underline"
                >
                  + افزودن تسک طلایی
                </button>
              </div>
            )}
          </div>

          {/* 1.3 D-DAY EXAM COUNTDOWN & CONSISTENCY (Span 3 on LG) */}
          <div className="lg:col-span-3 p-5 rounded-3xl bg-canvas-elevated liquid-glass border border-white/10 dark:border-white/10 shadow-md flex flex-col justify-between space-y-3">
            <div className="flex items-center justify-between pb-2 border-b border-border-subtle">
              <div className="flex items-center gap-2">
                <Target className="w-4 h-4 text-accent-primary" />
                <h3 className="text-xs font-bold text-ink-primary">
                  روز‌شمار هدف و آزمون (D-Day)
                </h3>
              </div>
              <span className="text-[10px] font-mono font-bold text-ink-muted">
                D - {formatToPersianDigits(diffDays)}
              </span>
            </div>

            {/* Big Countdown Number */}
            <div className="text-center py-2 space-y-1">
              <div className="text-3xl font-black text-accent-primary font-mono tracking-tight">
                {formatToPersianDigits(diffDays)} روز
              </div>
              <p className="text-[11px] text-ink-muted">
                تا موعد آزمون جامع و هدف تحصیلی
              </p>
            </div>

            {/* 7-Day Consistency Dots */}
            <div className="pt-2 border-t border-border-subtle/60 space-y-1.5">
              <div className="flex items-center justify-between text-[11px] text-ink-muted">
                <span>پیوستگی ۷ روز اخیر</span>
                <span className="font-bold text-accent-primary font-mono">{formatToPersianDigits(user.streakDays)} روز</span>
              </div>
              <div className="grid grid-cols-7 gap-1 text-center">
                {['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'].map((day, i) => (
                  <div key={i} className="flex flex-col items-center gap-1">
                    <span className="text-[9px] text-ink-muted">{day}</span>
                    <div className={`w-3.5 h-3.5 rounded-md transition ${
                      i < Math.min(7, user.streakDays) 
                        ? 'bg-accent-primary/80 shadow-needle' 
                        : 'bg-white/10 border border-border-subtle'
                    }`} />
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>

        {/* ========================================================
            ROW 2: 24-HOUR 10-MINUTE TIMETABLE RIBBON (YPT Signature)
            ======================================================== */}
        <section className="p-5 rounded-3xl bg-canvas-elevated liquid-glass border border-white/10 dark:border-white/10 shadow-md space-y-3">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 pb-2 border-b border-border-subtle">
            <div className="flex items-center gap-2">
              <div className="w-2.5 h-2.5 rounded-full bg-accent-primary shadow-needle" />
              <h3 className="text-sm font-black text-ink-primary">
                جدول زمانی ۲۴ ساعته ۱۰ دقیقه‌ای (YPT 144-Block Visual Ribbon)
              </h3>
              <span className="text-xs text-ink-muted hidden md:inline">
                • مرز روزانه ۰۵:۰۰ صبح تا ۰۵:۰۰ صبح فردا
              </span>
            </div>

            <button
              onClick={() => setViewMode('dual_planner')}
              className="text-xs text-accent-primary font-bold hover:underline flex items-center gap-1 self-end sm:self-auto cursor-pointer"
            >
              <span>مشاهده پلنر دوقلو کامل</span>
              <ChevronLeft className="w-3.5 h-3.5" />
            </button>
          </div>

          {/* 144 Micro-Slots Strip */}
          <div className="relative pt-2 pb-1 overflow-x-auto">
            {/* Timeline hour marks */}
            <div className="flex justify-between text-[10px] text-ink-muted font-mono pb-1 px-1">
              <span>۰۵:۰۰</span>
              <span>۰۸:۰۰</span>
              <span>۱۱:۰۰</span>
              <span>۱۴:۰۰</span>
              <span>۱۷:۰۰</span>
              <span>۲۰:۰۰</span>
              <span>۲۳:۰۰</span>
              <span>۰۲:۰۰</span>
              <span>۰۵:۰۰</span>
            </div>

            {/* Grid of 144 blocks */}
            <div className="grid grid-cols-144 gap-[1px] h-6 p-1 rounded-xl bg-canvas-secondary/70 border border-border-subtle relative min-w-[580px]">
              {slots.map((slot, index) => {
                const color = getSlotColor(slot.hour, slot.minute);
                const isCurrent = index === currentSlotIndex;
                return (
                  <div
                    key={slot.index}
                    title={`${slot.timeStr} ${color ? '• مطالعه ثبت شده' : ''}`}
                    className={`h-full rounded-[2px] transition-all cursor-pointer relative ${
                      color 
                        ? 'shadow-sm opacity-90 hover:opacity-100 hover:scale-110' 
                        : 'bg-white/5 hover:bg-white/10'
                    }`}
                    style={{ backgroundColor: color || undefined }}
                  >
                    {isCurrent && (
                      <div className="absolute inset-y-0 -left-[1px] w-[3px] bg-amber-400 shadow-needle animate-pulse z-10 rounded-full" />
                    )}
                  </div>
                );
              })}
            </div>
          </div>
        </section>

        {/* ========================================================
            ROW 3: Bento Grid (Daily Agenda + Live Study Room + Habits + AI Copilot)
            ======================================================== */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-4 md:gap-5">
          
          {/* 3.1 DAILY AGENDA & TIME-BLOCKS (Span 7 on LG) */}
          <div className="lg:col-span-7 p-5 rounded-3xl bg-canvas-elevated liquid-glass border border-white/10 dark:border-white/10 shadow-md flex flex-col justify-between space-y-4">
            
            <div className="flex items-center justify-between pb-2 border-b border-border-subtle">
              <div className="flex items-center gap-2">
                <Layers className="w-4 h-4 text-accent-primary" />
                <h3 className="text-sm font-bold text-ink-primary">
                  برنامه مطالعاتی امروز ({formatToPersianDigits(filteredTodayTasks.length)})
                </h3>
              </div>

              {/* Status Filter Tabs */}
              <div className="flex items-center gap-1 text-xs">
                {(['all', 'pending', 'completed', 'mit'] as const).map((filter) => {
                  const labels = { all: 'همه', pending: 'در انتظار', completed: 'انجام‌شده', mit: 'طلایی MIT' };
                  const isActive = statusFilter === filter;
                  return (
                    <button
                      key={filter}
                      onClick={() => setStatusFilter(filter)}
                      className={`px-2.5 py-1 rounded-lg text-[11px] font-bold transition cursor-pointer ${
                        isActive
                          ? 'bg-accent-primary text-white shadow-sm'
                          : 'text-ink-muted hover:text-ink-primary'
                      }`}
                    >
                      {labels[filter]}
                    </button>
                  );
                })}
              </div>
            </div>

            {/* Task List */}
            <div className="space-y-2 flex-1 max-h-[380px] overflow-y-auto pr-1">
              {filteredTodayTasks.length === 0 ? (
                <div className="h-44 flex flex-col items-center justify-center text-xs text-ink-muted text-center space-y-2">
                  <p>هیچ تسکی برای این دسته‌بندی یافت نشد.</p>
                  <button
                    onClick={() => setCreateTaskOpen(true)}
                    className="text-accent-primary font-bold hover:underline"
                  >
                    + ایجاد تسک جدید
                  </button>
                </div>
              ) : (
                filteredTodayTasks.map((t) => {
                  const isCurrent = t.id === currentOrNextTask?.id;
                  return (
                    <div
                      key={t.id}
                      onClick={() => selectTask(t.id)}
                      className={`p-3.5 rounded-2xl border transition-all cursor-pointer flex items-center justify-between gap-3 ${
                        t.status === 'completed'
                          ? 'bg-canvas-secondary/40 border-border-subtle opacity-60'
                          : isCurrent
                          ? 'bg-canvas-secondary border-accent-primary/40 shadow-sm'
                          : 'bg-canvas-secondary hover:bg-canvas-secondary/80 border-border-subtle'
                      }`}
                    >
                      <div className="flex items-center gap-3 min-w-0">
                        <button
                          onClick={(e) => {
                            e.stopPropagation();
                            toggleTaskCompleted(t.id);
                          }}
                          className="text-ink-muted hover:text-accent-primary transition cursor-pointer"
                          aria-label={t.status === 'completed' ? 'تغییر به انجام‌نشده' : 'تیک زدن تسک'}
                        >
                          {t.status === 'completed' ? (
                            <CheckCircle2 className="w-5 h-5 text-emerald-400" />
                          ) : (
                            <Circle className="w-5 h-5 text-ink-muted hover:text-accent-primary" />
                          )}
                        </button>

                        <div className="truncate space-y-0.5">
                          <div className="flex items-center gap-2">
                            <span
                              className="w-2 h-2 rounded-full flex-shrink-0"
                              style={{ backgroundColor: t.color || '#FF4700' }}
                            />
                            <span className={`text-xs font-bold truncate ${
                              t.status === 'completed' ? 'line-through text-ink-muted' : 'text-ink-primary'
                            }`}>
                              {t.title}
                            </span>
                            {t.isMIT && (
                              <span className="text-[9px] px-1.5 py-0.2 rounded bg-amber-500/20 text-amber-400 font-bold">
                                MIT
                              </span>
                            )}
                          </div>
                          <div className="text-[10px] text-ink-muted font-mono flex items-center gap-1.5">
                            <span>{t.startTime || 'بدون ساعت'}</span>
                            <span>•</span>
                            <span>{formatToPersianDigits(t.durationMinutes)} دقیقه</span>
                            {t.subtasks.length > 0 && (
                              <>
                                <span>•</span>
                                <span>{formatToPersianDigits(t.subtasks.filter(st => st.completed).length)}/{formatToPersianDigits(t.subtasks.length)} زیرتسک</span>
                              </>
                            )}
                          </div>
                        </div>
                      </div>

                      {/* Quick Focus Button */}
                      <button
                        onClick={(e) => {
                          e.stopPropagation();
                          startFocusSession(t.subjectId || subjects[0].id, t.id, 'stopwatch');
                        }}
                        className="p-2 rounded-xl bg-accent-primary/10 hover:bg-accent-primary text-accent-primary hover:text-white transition cursor-pointer"
                        title="تمرکز روی این تسک"
                        aria-label="شروع تمرکز روی این تسک"
                      >
                        <Play className="w-3.5 h-3.5 fill-current" />
                      </button>
                    </div>
                  );
                })
              )}
            </div>

            {/* Quick Slide-To-Complete Widget for Featured Task */}
            {currentOrNextTask && currentOrNextTask.status !== 'completed' && (
              <div className="pt-2 border-t border-border-subtle/50">
                <SlideToComplete
                  onComplete={() => toggleTaskCompleted(currentOrNextTask.id)}
                  onReset={() => toggleTaskCompleted(currentOrNextTask.id)}
                  isCompleted={false}
                  label={`بکشید برای تیک زدن: ${currentOrNextTask.title} ‹‹`}
                  completedLabel="آفرین! تسک کامل شد 🎉"
                />
              </div>
            )}
          </div>

          {/* 3.2 RIGHT COLUMN: Live Study Room + Habits + AI Copilot (Span 5 on LG) */}
          <div className="lg:col-span-5 space-y-4 md:space-y-5">
            
            {/* LIVE STUDY ROOM RADAR */}
            <div className="p-5 rounded-3xl bg-canvas-elevated liquid-glass border border-white/10 dark:border-white/10 shadow-md space-y-3">
              <div className="flex items-center justify-between pb-2 border-b border-border-subtle">
                <div className="flex items-center gap-2">
                  <Users className="w-4 h-4 text-emerald-400" />
                  <h3 className="text-xs font-bold text-ink-primary">
                    اتاق مطالعه زنده (Study With Me)
                  </h3>
                </div>
                <button
                  onClick={() => setViewMode('study_room')}
                  className="text-xs text-emerald-400 font-bold hover:underline flex items-center gap-1 cursor-pointer"
                >
                  <span>ورود به اتاق</span>
                  <ChevronLeft className="w-3.5 h-3.5" />
                </button>
              </div>

              {/* Active Peers Avatar Strip */}
              <div className="flex items-center justify-between p-3 rounded-2xl bg-canvas-secondary/70 border border-border-subtle">
                <div className="flex items-center gap-2.5">
                  <div className="relative">
                    <div className="w-8 h-8 rounded-full bg-gradient-to-tr from-accent-primary to-amber-500 flex items-center justify-center text-white text-xs font-bold">
                      {user.displayName ? user.displayName.slice(0, 1) : 'هـ'}
                    </div>
                    {isTimerRunning && (
                      <span className="absolute -bottom-0.5 -right-0.5 w-2.5 h-2.5 rounded-full bg-emerald-400 ring-2 ring-canvas-elevated animate-pulse" />
                    )}
                  </div>
                  <div>
                    <div className="text-xs font-bold text-ink-primary">
                      {isTimerRunning ? (user.displayName || 'مطالعه شما در جریان است') : 'اتاق آماده مطالعه'}
                    </div>
                    <div className="text-[10px] text-ink-muted">
                      {isTimerRunning 
                        ? `${activeSubject?.name || 'موضوع کلی'} • ${formatTimer(timerSeconds)}`
                        : 'برای همراهی با دوستان وارد اتاق زنده شوید'}
                    </div>
                  </div>
                </div>

                <button
                  onClick={() => setViewMode('study_room')}
                  className="px-2.5 py-1 rounded-xl bg-accent-primary/10 hover:bg-accent-primary/20 text-accent-primary font-bold text-xs flex items-center gap-1 transition active:scale-90 cursor-pointer"
                  title="ورود به اتاق مطالعه زنده"
                  aria-label="ورود به اتاق"
                >
                  <span>👥</span>
                  <span>ورود</span>
                </button>
              </div>
            </div>

            {/* AI SMART BRAIN DUMP COPILOT */}
            <div className="p-5 rounded-3xl bg-canvas-elevated liquid-glass border border-white/10 dark:border-white/10 shadow-md space-y-3">
              <div className="flex items-center justify-between pb-2 border-b border-border-subtle">
                <div className="flex items-center gap-2">
                  <Sparkles className="w-4 h-4 text-accent-primary" />
                  <h3 className="text-xs font-bold text-ink-primary">
                    دستیار برنامه‌ریزی هوشمند (AI Brain Dump)
                  </h3>
                </div>
                <span className="text-[10px] font-mono font-bold text-accent-primary">
                  زبان طبیعی
                </span>
              </div>

              <form onSubmit={handleQuickCaptureSubmit} className="relative">
                <input
                  type="text"
                  value={quickThought}
                  onChange={(e) => setQuickThought(e.target.value)}
                  placeholder="مثلاً: ۲ ساعت ریاضی فصل ۳ فردا ساعت ۴ عصر..."
                  className="w-full pl-10 pr-3.5 py-2.5 rounded-2xl bg-canvas-secondary border border-border-subtle text-xs text-ink-primary placeholder:text-ink-muted focus:outline-none focus:border-accent-primary focus:ring-1 focus:ring-accent-primary transition"
                />
                <button
                  type="submit"
                  className="absolute left-2 top-1/2 -translate-y-1/2 p-1.5 rounded-xl bg-accent-primary text-white hover:bg-accent-hover transition cursor-pointer"
                  aria-label="تحلیل هوشمند متن"
                >
                  <Send className="w-3.5 h-3.5" />
                </button>
              </form>

              {/* Suggestion Chips */}
              <div className="flex items-center gap-1.5 flex-wrap pt-1 text-[10px]">
                <button
                  type="button"
                  onClick={() => setQuickThought('حل ۲۰ تست حسابان با تایمر ۴۵ دقیقه‌ای')}
                  className="px-2 py-0.5 rounded-lg bg-white/5 hover:bg-white/10 text-ink-muted hover:text-ink-primary border border-border-subtle transition"
                >
                  + تست زمان‌دار حسابان
                </button>
                <button
                  type="button"
                  onClick={() => setQuickThought('مرور خلاصه درس زیست‌شناسی ۹۰ دقیقه')}
                  className="px-2 py-0.5 rounded-lg bg-white/5 hover:bg-white/10 text-ink-muted hover:text-ink-primary border border-border-subtle transition"
                >
                  + مرور زیست‌شناسی
                </button>
              </div>
            </div>

            {/* DAILY MICRO-HABITS TRACKER */}
            <div className="p-5 rounded-3xl bg-canvas-elevated liquid-glass border border-white/10 dark:border-white/10 shadow-md space-y-3">
              <div className="flex items-center justify-between pb-2 border-b border-border-subtle">
                <div className="flex items-center gap-2">
                  <Zap className="w-4 h-4 text-amber-400" />
                  <h3 className="text-xs font-bold text-ink-primary">
                    عادات و ارتقای انرژی
                  </h3>
                </div>
                <span className="text-xs font-mono font-bold text-ink-muted">
                  {formatToPersianDigits(habits.filter(h => h.done).length)} از {formatToPersianDigits(habits.length)}
                </span>
              </div>

              <div className="grid grid-cols-2 gap-2">
                {habits.map((h) => (
                  <button
                    key={h.id}
                    onClick={() => toggleHabit(h.id)}
                    className={`p-2.5 rounded-2xl border flex items-center justify-between transition text-xs cursor-pointer ${
                      h.done
                        ? 'bg-emerald-500/10 border-emerald-500/30 text-emerald-400 font-bold shadow-sm'
                        : 'bg-canvas-secondary border-border-subtle text-ink-muted hover:text-ink-primary'
                    }`}
                  >
                    <div className="flex items-center gap-1.5 truncate">
                      <span>{h.icon}</span>
                      <span className="truncate text-[11px]">{h.label}</span>
                    </div>
                    <Check className={`w-3.5 h-3.5 flex-shrink-0 ${h.done ? 'opacity-100' : 'opacity-20'}`} />
                  </button>
                ))}
              </div>
            </div>

          </div>
        </div>

      </div>
    </div>
  );
};

export default MainDashboardView;
