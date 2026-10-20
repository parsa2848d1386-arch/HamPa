import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  X, 
  Plus, 
  Calendar, 
  Clock, 
  Tag, 
  Flame, 
  Sparkles, 
  Check, 
  Sliders, 
  Zap, 
  Repeat, 
  Bell, 
  CheckSquare, 
  Trash2,
  FileText,
  Timer,
  Grid
} from 'lucide-react';
import { useAppStore } from '../../store/useAppStore';
import type { Priority, EnergyLevel, RecurrenceType } from '../../types';

const PRESET_DURATIONS = [
  { label: '۱۵ د', value: 15 },
  { label: '۲۵ د (پومودورو)', value: 25 },
  { label: '۴۵ د', value: 45 },
  { label: '۶۰ د (۱ س)', value: 60 },
  { label: '۹۰ د (۱.۵ س)', value: 90 },
  { label: '۱۲۰ د (۲ س)', value: 120 },
];

const PRESET_TAGS = [
  'مطالعه', 'تست‌زنی', 'مرور', 'پروژه', 'کدنویسی', 'کنکور', 'تمرین', 'کتاب', 'سلامت'
];

const QUICK_TEMPLATES = [
  { label: 'مطالعه عمیق', icon: '📖', duration: 60, priority: 'high' as Priority, energy: 'high' as EnergyLevel, tag: 'مطالعه', pomodoros: 2 },
  { label: 'تست‌زنی زمان‌دار', icon: '⏱️', duration: 45, priority: 'urgent' as Priority, energy: 'high' as EnergyLevel, tag: 'تست‌زنی', pomodoros: 2 },
  { label: 'مرور فلش‌کارت', icon: '🧠', duration: 25, priority: 'medium' as Priority, energy: 'medium' as EnergyLevel, tag: 'مرور', pomodoros: 1 },
  { label: 'حل تمرین', icon: '✍️', duration: 45, priority: 'medium' as Priority, energy: 'medium' as EnergyLevel, tag: 'تمرین', pomodoros: 2 },
  { label: 'پروژه و کدنویسی', icon: '💻', duration: 90, priority: 'high' as Priority, energy: 'high' as EnergyLevel, tag: 'پروژه', pomodoros: 3 },
  { label: 'استراحت آگاهانه', icon: '☕', duration: 15, priority: 'low' as Priority, energy: 'low' as EnergyLevel, tag: 'سلامت', pomodoros: 1 },
];

export const CreateTaskModal: React.FC = () => {
  const isOpen = useAppStore((s) => s.isCreateTaskOpen);
  const setOpen = useAppStore((s) => s.setCreateTaskOpen);
  const addTask = useAppStore((s) => s.addTask);
  const subjects = useAppStore((s) => s.subjects);
  const selectedDate = useAppStore((s) => s.selectedDate);

  // Mode: 'casual' (simple) or 'pro' (advanced)
  const [mode, setMode] = useState<'casual' | 'pro'>('casual');

  // Common Fields
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [subjectId, setSubjectId] = useState(subjects[0]?.id || '');
  const [targetDate, setTargetDate] = useState(selectedDate);
  const [startTime, setStartTime] = useState('09:00');
  const [duration, setDuration] = useState(45);
  const [priority, setPriority] = useState<Priority>('medium');
  const [isMIT, setIsMIT] = useState(false);
  const [tags, setTags] = useState<string[]>(['مطالعه']);
  const [tagInput, setTagInput] = useState('');

  // Pro Fields
  const [energyLevel, setEnergyLevel] = useState<EnergyLevel>('high');
  const [estimatedPomodoros, setEstimatedPomodoros] = useState(2);
  const [recurrence, setRecurrence] = useState<RecurrenceType>('none');
  const [reminderMinutes, setReminderMinutes] = useState(15);
  const [subtasks, setSubtasks] = useState<{ id: string; title: string; completed: boolean }[]>([]);
  const [subtaskInput, setSubtaskInput] = useState('');

  if (!isOpen) return null;

  const selectedSubject = subjects.find((s) => s.id === subjectId) || subjects[0];

  const applyTemplate = (t: typeof QUICK_TEMPLATES[0]) => {
    setTitle(t.label);
    setDuration(t.duration);
    setPriority(t.priority);
    setEnergyLevel(t.energy);
    setEstimatedPomodoros(t.pomodoros);
    if (!tags.includes(t.tag)) {
      setTags([...tags, t.tag]);
    }
  };

  // Calculate approximate end time
  const calculateEndTime = (start: string, durMin: number) => {
    if (!start) return '';
    const [h, m] = start.split(':').map(Number);
    const totalMinutes = h * 60 + m + durMin;
    const endH = Math.floor(totalMinutes / 60) % 24;
    const endM = totalMinutes % 60;
    return `${endH.toString().padStart(2, '0')}:${endM.toString().padStart(2, '0')}`;
  };

  const handleAddTag = (tagToAdd: string) => {
    if (!tags.includes(tagToAdd)) {
      setTags([...tags, tagToAdd]);
    }
  };

  const handleCustomTagKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && tagInput.trim()) {
      e.preventDefault();
      handleAddTag(tagInput.trim());
      setTagInput('');
    }
  };

  const handleRemoveTag = (tagToRemove: string) => {
    setTags(tags.filter((t) => t !== tagToRemove));
  };

  const handleAddSubtask = (e: React.FormEvent | React.KeyboardEvent) => {
    e.preventDefault();
    if (!subtaskInput.trim()) return;
    setSubtasks([
      ...subtasks,
      { id: `st-${Date.now()}-${Math.random()}`, title: subtaskInput.trim(), completed: false },
    ]);
    setSubtaskInput('');
  };

  const handleRemoveSubtask = (id: string) => {
    setSubtasks(subtasks.filter((st) => st.id !== id));
  };

  const handleSetTomorrow = () => {
    const d = new Date(selectedDate);
    d.setDate(d.getDate() + 1);
    setTargetDate(d.toISOString().split('T')[0]);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim()) return;

    addTask({
      title: title.trim(),
      description: description.trim() || undefined,
      date: targetDate || selectedDate,
      startTime: startTime || undefined,
      durationMinutes: Number(duration) || 45,
      color: selectedSubject?.color || '#FF4700',
      subjectId: selectedSubject?.id,
      priority,
      status: 'todo',
      isMIT,
      tags,
      subtasks,
      blocks: [],
      energyLevel: mode === 'pro' ? energyLevel : undefined,
      estimatedPomodoros: mode === 'pro' ? estimatedPomodoros : undefined,
      recurrence: mode === 'pro' ? recurrence : undefined,
      reminderMinutesBefore: mode === 'pro' ? reminderMinutes : undefined,
    });

    // Reset form
    setTitle('');
    setDescription('');
    setTags(['مطالعه']);
    setIsMIT(false);
    setSubtasks([]);
    setOpen(false);
  };

  return (
    <AnimatePresence>
      <div className="fixed inset-0 z-50 flex items-center justify-center p-3 md:p-6 select-none overflow-y-auto">
        {/* Backdrop */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          onClick={() => setOpen(false)}
          className="fixed inset-0 bg-black/75 backdrop-blur-md"
        />

        {/* Modal Sheet */}
        <motion.div
          initial={{ opacity: 0, scale: 0.95, y: 15 }}
          animate={{ opacity: 1, scale: 1, y: 0 }}
          exit={{ opacity: 0, scale: 0.95, y: 15 }}
          transition={{ type: 'spring', stiffness: 450, damping: 32 }}
          className="relative z-10 w-full max-w-xl max-h-[92vh] overflow-y-auto rounded-3xl bg-canvas-elevated liquid-glass border border-border-subtle shadow-2xl p-5 md:p-6"
        >
          {/* Header & Mode Switcher */}
          <div className="flex items-center justify-between pb-4 border-b border-border-subtle">
            <div className="flex items-center gap-3">
              <div className="w-9 h-9 rounded-2xl bg-accent-primary text-white flex items-center justify-center shadow-needle">
                <Plus className="w-5 h-5" />
              </div>
              <div>
                <h3 className="text-base font-bold text-ink-primary">
                  افزودن فعالیت و تسک جدید
                </h3>
                <p className="text-xs text-ink-muted">
                  {mode === 'casual' ? 'ثبت سریع و قالب‌های آماده برای کاربران عادی' : 'تنظیمات تخصصی ماتریس آیزنهاور، زمان‌بندی و زیرتسک‌ها'}
                </p>
              </div>
            </div>

            {/* Mode Toggle Button */}
            <div className="flex items-center gap-2">
              <div className="flex items-center bg-canvas-secondary p-1 rounded-xl border border-border-subtle text-xs">
                <button
                  type="button"
                  onClick={() => setMode('casual')}
                  className={`px-3 py-1 rounded-lg font-bold transition ${
                    mode === 'casual'
                      ? 'bg-accent-primary text-white shadow-sm'
                      : 'text-ink-muted hover:text-ink-primary'
                  }`}
                >
                  عادی
                </button>
                <button
                  type="button"
                  onClick={() => setMode('pro')}
                  className={`px-3 py-1 rounded-lg font-bold transition flex items-center gap-1 ${
                    mode === 'pro'
                      ? 'bg-accent-primary text-white shadow-sm'
                      : 'text-ink-muted hover:text-ink-primary'
                  }`}
                >
                  <Sliders className="w-3.5 h-3.5" />
                  <span>حرفه‌ای</span>
                </button>
              </div>

              <button
                type="button"
                onClick={() => setOpen(false)}
                className="p-1.5 rounded-full hover:bg-black/5 dark:hover:bg-white/10 text-ink-muted hover:text-ink-primary transition"
              >
                <X className="w-5 h-5" />
              </button>
            </div>
          </div>

          {/* Quick Template Chips */}
          <div className="pt-3 pb-1 border-b border-border-subtle">
            <div className="text-[11px] font-bold text-ink-muted mb-1.5 flex items-center gap-1">
              <Sparkles className="w-3.5 h-3.5 text-accent-primary" />
              <span>الگوهای آماده برای ثبت فوری در ۲ ثانیه:</span>
            </div>
            <div className="flex flex-wrap gap-1.5 pb-2">
              {QUICK_TEMPLATES.map((tmpl) => (
                <button
                  key={tmpl.label}
                  type="button"
                  onClick={() => applyTemplate(tmpl)}
                  className="flex items-center gap-1.5 px-2.5 py-1 rounded-xl text-xs bg-canvas-secondary hover:bg-accent-primary/10 hover:border-accent-primary/40 border border-border-subtle text-ink-primary transition active:scale-95"
                >
                  <span>{tmpl.icon}</span>
                  <span className="font-semibold">{tmpl.label}</span>
                  <span className="text-[10px] text-ink-muted font-mono">{tmpl.duration}د</span>
                </button>
              ))}
            </div>
          </div>

          {/* Form */}
          <form onSubmit={handleSubmit} className="py-4 space-y-4">
            {/* Title */}
            <div>
              <label className="block text-xs font-bold text-ink-muted mb-1.5">
                عنوان فعالیت:
              </label>
              <input
                type="text"
                autoFocus
                required
                placeholder="مثال: مطالعه و تست‌زنی حسابان، آماده‌سازی گزارش..."
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                className="w-full bg-canvas-secondary border border-border-subtle focus:border-accent-primary rounded-xl px-3.5 py-2.5 text-sm text-ink-primary outline-none transition"
              />
            </div>

            {/* Target Date Selector */}
            <div>
              <label className="block text-xs font-bold text-ink-muted mb-1 flex items-center gap-1">
                <Calendar className="w-3.5 h-3.5 text-accent-primary" />
                <span>تاریخ اجرای فعالیت:</span>
              </label>
              <div className="flex items-center gap-2">
                <button
                  type="button"
                  onClick={() => setTargetDate(selectedDate)}
                  className={`px-3 py-1.5 rounded-xl text-xs font-bold border transition ${
                    targetDate === selectedDate
                      ? 'bg-accent-primary text-white border-accent-primary shadow-sm'
                      : 'bg-canvas-secondary border-border-subtle text-ink-muted'
                  }`}
                >
                  امروز
                </button>
                <button
                  type="button"
                  onClick={handleSetTomorrow}
                  className={`px-3 py-1.5 rounded-xl text-xs font-bold border transition ${
                    targetDate !== selectedDate
                      ? 'bg-accent-primary text-white border-accent-primary shadow-sm'
                      : 'bg-canvas-secondary border-border-subtle text-ink-muted'
                  }`}
                >
                  فردا
                </button>
                <input
                  type="date"
                  value={targetDate}
                  onChange={(e) => setTargetDate(e.target.value)}
                  className="flex-1 bg-canvas-secondary border border-border-subtle rounded-xl px-3 py-1.5 text-xs text-ink-primary font-mono outline-none"
                />
              </div>
            </div>

            {/* Subject Selector */}
            <div>
              <label className="block text-xs font-bold text-ink-muted mb-1.5">
                موضوع یا درس:
              </label>
              <div className="flex flex-wrap gap-1.5">
                {subjects.map((subj) => (
                  <button
                    key={subj.id}
                    type="button"
                    onClick={() => setSubjectId(subj.id)}
                    className={`flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-medium transition border ${
                      subjectId === subj.id
                        ? 'border-transparent text-white shadow-sm font-bold scale-[1.02]'
                        : 'border-border-subtle bg-white/5 text-ink-muted hover:text-ink-primary'
                    }`}
                    style={{
                      backgroundColor: subjectId === subj.id ? subj.color : undefined,
                    }}
                  >
                    <span
                      className="w-2 h-2 rounded-full"
                      style={{ backgroundColor: subj.color }}
                    />
                    <span>{subj.name}</span>
                  </button>
                ))}
              </div>
            </div>

            {/* Duration Quick Chips & Custom Input */}
            <div>
              <div className="flex items-center justify-between mb-1.5">
                <label className="text-xs font-bold text-ink-muted flex items-center gap-1">
                  <Clock className="w-3.5 h-3.5 text-accent-primary" />
                  <span>مدت زمان:</span>
                </label>
                <div className="flex items-center gap-2">
                  <span className="text-xs font-mono text-ink-primary font-bold">
                    {duration} دقیقه {startTime && `(پایان: ${calculateEndTime(startTime, duration)})`}
                  </span>
                  <div className="flex items-center gap-1 bg-canvas-secondary border border-border-subtle rounded-lg px-2 py-0.5">
                    <input
                      type="number"
                      min="5"
                      max="480"
                      value={duration}
                      onChange={(e) => setDuration(Math.max(5, Number(e.target.value)))}
                      className="w-12 bg-transparent text-center font-mono text-xs font-bold text-ink-primary outline-none"
                    />
                    <span className="text-[10px] text-ink-muted">دقیقه</span>
                  </div>
                </div>
              </div>
              <div className="grid grid-cols-3 sm:grid-cols-6 gap-1.5">
                {PRESET_DURATIONS.map((dur) => (
                  <button
                    key={dur.value}
                    type="button"
                    onClick={() => setDuration(dur.value)}
                    className={`py-1.5 px-2 rounded-xl text-xs font-mono font-semibold border transition ${
                      duration === dur.value
                        ? 'bg-accent-primary border-accent-primary text-white shadow-needle'
                        : 'bg-canvas-secondary border-border-subtle text-ink-muted hover:text-ink-primary'
                    }`}
                  >
                    {dur.label}
                  </button>
                ))}
              </div>
            </div>

            {/* Time Slot & Priority */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div>
                <label className="block text-xs font-bold text-ink-muted mb-1 flex items-center gap-1">
                  <Clock className="w-3.5 h-3.5 text-ink-subtle" />
                  <span>ساعت شروع:</span>
                </label>
                <input
                  type="time"
                  value={startTime}
                  onChange={(e) => setStartTime(e.target.value)}
                  className="w-full bg-canvas-secondary border border-border-subtle rounded-xl px-3 py-2 text-xs font-mono text-ink-primary outline-none focus:border-accent-primary"
                />
              </div>

              <div>
                <label className="block text-xs font-bold text-ink-muted mb-1 flex items-center gap-1">
                  <Flame className="w-3.5 h-3.5 text-amber-500" />
                  <span>اولویت تسک:</span>
                </label>
                <select
                  value={priority}
                  onChange={(e) => setPriority(e.target.value as Priority)}
                  className="w-full bg-canvas-secondary border border-border-subtle rounded-xl px-3 py-2 text-xs text-ink-primary outline-none focus:border-accent-primary"
                >
                  <option value="urgent">فوری و حیاتی (Urgent - Q1)</option>
                  <option value="high">بالا و بااهمیت (High - Q2)</option>
                  <option value="medium">متوسط و عادی (Medium - Q3)</option>
                  <option value="low">کم و سبک (Low - Q4)</option>
                </select>
              </div>
            </div>

            {/* MIT Checkbox / Button */}
            <div className="p-2.5 rounded-xl bg-canvas-secondary border border-border-subtle flex items-center justify-between">
              <div className="flex items-center gap-2">
                <Sparkles className="w-4 h-4 text-amber-400" />
                <div>
                  <div className="text-xs font-bold text-ink-primary">
                    ۳ اولویت طلایی روز (Sunsama MIT)
                  </div>
                  <div className="text-[11px] text-ink-muted">
                    قرارگیری در بالاترین جایگاه تمرکز روز
                  </div>
                </div>
              </div>
              <button
                type="button"
                onClick={() => setIsMIT(!isMIT)}
                className={`px-3 py-1.5 rounded-lg text-xs font-bold border transition flex items-center gap-1 ${
                  isMIT
                    ? 'bg-amber-500 border-amber-500 text-white shadow-sm'
                    : 'border-border-subtle text-ink-muted hover:text-ink-primary'
                }`}
              >
                <Check className={`w-3.5 h-3.5 ${isMIT ? 'opacity-100' : 'opacity-40'}`} />
                <span>{isMIT ? 'فعال به عنوان MIT' : 'غیرفعال'}</span>
              </button>
            </div>

            {/* PRO MODE FIELDS */}
            {mode === 'pro' && (
              <motion.div
                initial={{ opacity: 0, height: 0 }}
                animate={{ opacity: 1, height: 'auto' }}
                exit={{ opacity: 0, height: 0 }}
                className="space-y-4 pt-2 border-t border-border-subtle"
              >
                {/* Description */}
                <div>
                  <label className="block text-xs font-bold text-ink-muted mb-1 flex items-center gap-1">
                    <FileText className="w-3.5 h-3.5 text-ink-subtle" />
                    <span>توضیحات و یادداشت تکمیلی:</span>
                  </label>
                  <textarea
                    rows={2}
                    placeholder="نکات مهم، منابع یا صفحاتی که باید خوانده شوند..."
                    value={description}
                    onChange={(e) => setDescription(e.target.value)}
                    className="w-full bg-canvas-secondary border border-border-subtle focus:border-accent-primary rounded-xl p-2.5 text-xs text-ink-primary outline-none resize-none"
                  />
                </div>

                {/* Visual Eisenhower Quadrant Selector */}
                <div>
                  <label className="block text-xs font-bold text-ink-muted mb-1.5 flex items-center gap-1">
                    <Grid className="w-3.5 h-3.5 text-accent-primary" />
                    <span>دسته‌بندی در ماتریس آیزنهاور (Eisenhower Matrix):</span>
                  </label>
                  <div className="grid grid-cols-2 gap-2">
                    <button
                      type="button"
                      onClick={() => setPriority('urgent')}
                      className={`p-2 rounded-xl text-right border transition ${
                        priority === 'urgent'
                          ? 'border-red-500 bg-red-500/15 text-red-400 font-bold shadow-sm'
                          : 'border-border-subtle bg-canvas-secondary text-ink-muted hover:text-ink-primary'
                      }`}
                    >
                      <div className="text-xs flex items-center justify-between">
                        <span>🔥 فوری و مهم (Q1)</span>
                        <span className="text-[10px] opacity-75">اقدام فوری</span>
                      </div>
                      <div className="text-[10px] opacity-70 mt-0.5">بحران‌ها و کارهای با ددلاین قطعی</div>
                    </button>

                    <button
                      type="button"
                      onClick={() => setPriority('high')}
                      className={`p-2 rounded-xl text-right border transition ${
                        priority === 'high'
                          ? 'border-amber-500 bg-amber-500/15 text-amber-400 font-bold shadow-sm'
                          : 'border-border-subtle bg-canvas-secondary text-ink-muted hover:text-ink-primary'
                      }`}
                    >
                      <div className="text-xs flex items-center justify-between">
                        <span>⭐ مهم، غیرفوری (Q2)</span>
                        <span className="text-[10px] opacity-75">برنامه‌ریزی</span>
                      </div>
                      <div className="text-[10px] opacity-70 mt-0.5">یادگیری عمیق، کنکور و اهداف بزرگ</div>
                    </button>

                    <button
                      type="button"
                      onClick={() => setPriority('medium')}
                      className={`p-2 rounded-xl text-right border transition ${
                        priority === 'medium'
                          ? 'border-blue-500 bg-blue-500/15 text-blue-400 font-bold shadow-sm'
                          : 'border-border-subtle bg-canvas-secondary text-ink-muted hover:text-ink-primary'
                      }`}
                    >
                      <div className="text-xs flex items-center justify-between">
                        <span>⚡ فوری، کم‌اهمیت (Q3)</span>
                        <span className="text-[10px] opacity-75">واگذاری / تجمیع</span>
                      </div>
                      <div className="text-[10px] opacity-70 mt-0.5">پاسخ به پیام‌ها و کارهای جانبی</div>
                    </button>

                    <button
                      type="button"
                      onClick={() => setPriority('low')}
                      className={`p-2 rounded-xl text-right border transition ${
                        priority === 'low'
                          ? 'border-emerald-500 bg-emerald-500/15 text-emerald-400 font-bold shadow-sm'
                          : 'border-border-subtle bg-canvas-secondary text-ink-muted hover:text-ink-primary'
                      }`}
                    >
                      <div className="text-xs flex items-center justify-between">
                        <span>🌱 غیرفوری، کم‌اهمیت (Q4)</span>
                        <span className="text-[10px] opacity-75">حذف / فراغت</span>
                      </div>
                      <div className="text-[10px] opacity-70 mt-0.5">استراحت، سرگرمی و وقفه</div>
                    </button>
                  </div>
                </div>

                {/* Energy & Pomodoro row */}
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  <div>
                    <label className="block text-xs font-bold text-ink-muted mb-1 flex items-center gap-1">
                      <Zap className="w-3.5 h-3.5 text-amber-400" />
                      <span>سطح انرژی مورد نیاز:</span>
                    </label>
                    <div className="grid grid-cols-3 gap-1">
                      <button
                        type="button"
                        onClick={() => setEnergyLevel('high')}
                        className={`py-1.5 px-1 rounded-lg text-xs font-bold border transition ${
                          energyLevel === 'high' ? 'bg-amber-500 text-white border-amber-500' : 'bg-canvas-secondary border-border-subtle text-ink-muted'
                        }`}
                      >
                        ⚡ بالا
                      </button>
                      <button
                        type="button"
                        onClick={() => setEnergyLevel('medium')}
                        className={`py-1.5 px-1 rounded-lg text-xs font-bold border transition ${
                          energyLevel === 'medium' ? 'bg-emerald-500 text-white border-emerald-500' : 'bg-canvas-secondary border-border-subtle text-ink-muted'
                        }`}
                      >
                        🔋 متوسط
                      </button>
                      <button
                        type="button"
                        onClick={() => setEnergyLevel('low')}
                        className={`py-1.5 px-1 rounded-lg text-xs font-bold border transition ${
                          energyLevel === 'low' ? 'bg-blue-500 text-white border-blue-500' : 'bg-canvas-secondary border-border-subtle text-ink-muted'
                        }`}
                      >
                        ☕ کم
                      </button>
                    </div>
                  </div>

                  <div>
                    <label className="block text-xs font-bold text-ink-muted mb-1 flex items-center gap-1">
                      <Timer className="w-3.5 h-3.5 text-red-500" />
                      <span>تخمین پومودورو (۲۵ دقیقه‌ای):</span>
                    </label>
                    <div className="flex items-center gap-2">
                      <input
                        type="range"
                        min="1"
                        max="8"
                        value={estimatedPomodoros}
                        onChange={(e) => setEstimatedPomodoros(Number(e.target.value))}
                        className="flex-1 accent-accent-primary"
                      />
                      <span className="text-xs font-mono font-bold text-ink-primary px-2 py-1 rounded bg-canvas-secondary border border-border-subtle">
                        {estimatedPomodoros} 🍅
                      </span>
                    </div>
                  </div>
                </div>

                {/* Recurrence & Reminder row */}
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  <div>
                    <label className="block text-xs font-bold text-ink-muted mb-1 flex items-center gap-1">
                      <Repeat className="w-3.5 h-3.5 text-ink-subtle" />
                      <span>تکرار هوشمند:</span>
                    </label>
                    <select
                      value={recurrence}
                      onChange={(e) => setRecurrence(e.target.value as RecurrenceType)}
                      className="w-full bg-canvas-secondary border border-border-subtle rounded-xl px-3 py-2 text-xs text-ink-primary outline-none"
                    >
                      <option value="none">بدون تکرار (یکباره)</option>
                      <option value="daily">روزانه</option>
                      <option value="workdays">روزهای کاری (شنبه تا چهارشنبه)</option>
                      <option value="weekly">هفتگی</option>
                      <option value="monthly">ماهانه</option>
                    </select>
                  </div>

                  <div>
                    <label className="block text-xs font-bold text-ink-muted mb-1 flex items-center gap-1">
                      <Bell className="w-3.5 h-3.5 text-ink-subtle" />
                      <span>یادآور قبل از شروع:</span>
                    </label>
                    <select
                      value={reminderMinutes}
                      onChange={(e) => setReminderMinutes(Number(e.target.value))}
                      className="w-full bg-canvas-secondary border border-border-subtle rounded-xl px-3 py-2 text-xs text-ink-primary outline-none"
                    >
                      <option value="0">سر ساعت شروع</option>
                      <option value="5">۵ دقیقه قبل</option>
                      <option value="15">۱۵ دقیقه قبل</option>
                      <option value="30">۳۰ دقیقه قبل</option>
                      <option value="60">۱ ساعت قبل</option>
                    </select>
                  </div>
                </div>

                {/* Subtasks Builder */}
                <div>
                  <label className="block text-xs font-bold text-ink-muted mb-1 flex items-center gap-1">
                    <CheckSquare className="w-3.5 h-3.5 text-accent-primary" />
                    <span>زیرتسک‌ها و چک‌لیست ({subtasks.length}):</span>
                  </label>
                  <div className="space-y-1.5 mb-2">
                    {subtasks.map((st) => (
                      <div
                        key={st.id}
                        className="flex items-center justify-between p-2 rounded-lg bg-canvas-secondary border border-border-subtle text-xs"
                      >
                        <span className="text-ink-primary truncate">{st.title}</span>
                        <button
                          type="button"
                          onClick={() => handleRemoveSubtask(st.id)}
                          className="text-red-400 hover:text-red-300 p-1"
                        >
                          <Trash2 className="w-3.5 h-3.5" />
                        </button>
                      </div>
                    ))}
                  </div>
                  <div className="flex gap-2">
                    <input
                      type="text"
                      placeholder="عنوان زیرتسک جدید..."
                      value={subtaskInput}
                      onChange={(e) => setSubtaskInput(e.target.value)}
                      onKeyDown={(e) => e.key === 'Enter' && handleAddSubtask(e)}
                      className="flex-1 bg-canvas-secondary border border-border-subtle rounded-lg px-3 py-1.5 text-xs text-ink-primary outline-none"
                    />
                    <button
                      type="button"
                      onClick={handleAddSubtask}
                      className="px-3 py-1.5 rounded-lg bg-white/10 hover:bg-white/15 text-xs text-ink-primary font-bold"
                    >
                      افزودن
                    </button>
                  </div>
                </div>
              </motion.div>
            )}

            {/* Tags & Filters */}
            <div>
              <div className="flex items-center justify-between mb-1">
                <label className="text-xs font-bold text-ink-muted flex items-center gap-1">
                  <Tag className="w-3.5 h-3.5 text-ink-subtle" />
                  <span>برچسب‌ها و فیلترها:</span>
                </label>
              </div>

              {/* Preset Tag Chips */}
              <div className="flex flex-wrap gap-1 mb-2">
                {PRESET_TAGS.map((pt) => {
                  const isSelected = tags.includes(pt);
                  return (
                    <button
                      key={pt}
                      type="button"
                      onClick={() => isSelected ? handleRemoveTag(pt) : handleAddTag(pt)}
                      className={`text-[11px] px-2 py-0.5 rounded-md border transition ${
                        isSelected
                          ? 'bg-accent-primary/20 border-accent-primary text-accent-primary font-bold'
                          : 'bg-canvas-secondary border-border-subtle text-ink-muted hover:text-ink-primary'
                      }`}
                    >
                      {pt}
                    </button>
                  );
                })}
              </div>

              {/* Tag Badges + Input */}
              <div className="flex flex-wrap gap-1.5 p-2 rounded-xl bg-canvas-secondary border border-border-subtle min-h-[38px]">
                {tags.map((tag) => (
                  <span
                    key={tag}
                    className="inline-flex items-center gap-1 px-2 py-0.5 rounded-md bg-white/10 text-ink-primary text-xs"
                  >
                    <span>{tag}</span>
                    <button
                      type="button"
                      onClick={() => handleRemoveTag(tag)}
                      className="hover:text-red-400 transition"
                    >
                      <X className="w-3 h-3" />
                    </button>
                  </span>
                ))}
                <input
                  type="text"
                  placeholder="افزودن برچسب دلخواه (با Enter)..."
                  value={tagInput}
                  onChange={(e) => setTagInput(e.target.value)}
                  onKeyDown={handleCustomTagKeyDown}
                  className="bg-transparent text-xs text-ink-primary outline-none flex-1 min-w-[120px]"
                />
              </div>
            </div>

            {/* Actions */}
            <div className="flex items-center justify-between pt-4 border-t border-border-subtle">
              <button
                type="button"
                onClick={() => setOpen(false)}
                className="px-4 py-2 rounded-xl hover:bg-white/5 text-xs text-ink-muted transition"
              >
                انصراف
              </button>

              <button
                type="submit"
                className="flex items-center gap-1.5 px-6 py-2.5 rounded-xl bg-accent-primary hover:bg-accent-hover text-white text-xs font-bold transition shadow-needle active:scale-95"
              >
                <Plus className="w-4 h-4" />
                <span>ثبت و اضافه به برنامه</span>
              </button>
            </div>
          </form>
        </motion.div>
      </div>
    </AnimatePresence>
  );
};
