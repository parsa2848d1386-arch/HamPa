import React, { useState, useEffect, useRef } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  X, 
  Plus, 
  Calendar, 
  Clock, 
  Tag, 
  Sparkles, 
  Check, 
  Zap, 
  ChevronDown,
  Trash2,
  CheckCircle2,
  ListPlus,
  Star,
  CornerDownLeft
} from 'lucide-react';
import { useAppStore } from '../../store/useAppStore';
import type { Priority } from '../../types';
import { formatToPersianDigits } from '../../lib/calendarUtils';

const DURATION_PRESETS = [
  { label: '۱۵د', value: 15 },
  { label: '۲۵د پومودورو', value: 25 },
  { label: '۴۵د استاندارد', value: 45 },
  { label: '۶۰د (۱ ساعت)', value: 60 },
  { label: '۹۰د عمیق', value: 90 },
];

const PRIORITY_OPTIONS: { id: Priority; label: string; color: string }[] = [
  { id: 'low', label: 'عادی', color: '#10B981' },
  { id: 'medium', label: 'متوسط', color: '#3B82F6' },
  { id: 'high', label: 'مهم', color: '#F59E0B' },
  { id: 'urgent', label: 'فوری Q1', color: '#EF4444' },
];

export const CreateTaskModal: React.FC = () => {
  const isOpen = useAppStore((s) => s.isCreateTaskOpen);
  const setOpen = useAppStore((s) => s.setCreateTaskOpen);
  const addTask = useAppStore((s) => s.addTask);
  const subjects = useAppStore((s) => s.subjects);
  const selectedDate = useAppStore((s) => s.selectedDate);

  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [subjectId, setSubjectId] = useState(subjects[0]?.id || '');
  const [targetDate, setTargetDate] = useState(selectedDate);
  const [startTime, setStartTime] = useState('');
  const [duration, setDuration] = useState(45);
  const [priority, setPriority] = useState<Priority>('medium');
  const [isMIT, setIsMIT] = useState(false);
  const [showSubtasks, setShowSubtasks] = useState(false);
  const [subtasks, setSubtasks] = useState<{ id: string; title: string; completed: boolean }[]>([]);
  const [subtaskInput, setSubtaskInput] = useState('');

  // Dropdown popovers
  const [activePopover, setActivePopover] = useState<'subject' | 'duration' | 'priority' | 'time' | null>(null);

  const titleInputRef = useRef<HTMLInputElement>(null);
  const subtaskInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (isOpen) {
      setTargetDate(selectedDate);
      if (subjects.length > 0 && !subjectId) {
        setSubjectId(subjects[0].id);
      }
      setTimeout(() => {
        titleInputRef.current?.focus();
      }, 50);
    } else {
      // Reset form
      setTitle('');
      setDescription('');
      setStartTime('');
      setDuration(45);
      setPriority('medium');
      setIsMIT(false);
      setSubtasks([]);
      setShowSubtasks(false);
      setActivePopover(null);
    }
  }, [isOpen, selectedDate, subjects]);

  if (!isOpen) return null;

  const currentSubject = subjects.find((s) => s.id === subjectId) || subjects[0] || {
    id: 'default',
    name: 'عمومی',
    color: '#FF4700'
  };

  const currentPriorityObj = PRIORITY_OPTIONS.find((p) => p.id === priority) || PRIORITY_OPTIONS[1];

  const handleAddSubtask = (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    if (!subtaskInput.trim()) return;
    setSubtasks([
      ...subtasks,
      { id: `st-${Date.now()}`, title: subtaskInput.trim(), completed: false }
    ]);
    setSubtaskInput('');
    subtaskInputRef.current?.focus();
  };

  const handleRemoveSubtask = (id: string) => {
    setSubtasks(subtasks.filter((st) => st.id !== id));
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Escape') {
      setOpen(false);
    } else if ((e.metaKey || e.ctrlKey) && e.key === 'Enter') {
      handleSubmit(e);
    }
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
      color: currentSubject?.color || '#FF4700',
      subjectId: currentSubject?.id,
      priority,
      status: 'todo',
      isMIT,
      tags: [currentSubject?.name || 'مطالعه'],
      subtasks,
      blocks: [],
    });

    setOpen(false);
  };

  const isToday = targetDate === selectedDate;

  const handleSetTomorrow = () => {
    const d = new Date(selectedDate);
    d.setDate(d.getDate() + 1);
    setTargetDate(d.toISOString().split('T')[0]);
  };

  return (
    <AnimatePresence>
      <div 
        onKeyDown={handleKeyDown}
        className="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-5 select-none"
      >
        {/* Soft Dim Backdrop */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          onClick={() => setOpen(false)}
          className="fixed inset-0 bg-black/60 dark:bg-black/80 backdrop-blur-md"
        />

        {/* Linear / Things 3 Inspired Floating Card */}
        <motion.div
          initial={{ opacity: 0, scale: 0.96, y: 12 }}
          animate={{ opacity: 1, scale: 1, y: 0 }}
          exit={{ opacity: 0, scale: 0.96, y: 12 }}
          transition={{ type: 'spring', stiffness: 500, damping: 32 }}
          className="relative z-10 w-full max-w-lg rounded-3xl bg-canvas-elevated/95 backdrop-blur-2xl border border-white/10 dark:border-white/15 shadow-2xl p-5 md:p-6 space-y-4"
        >
          {/* Header Row: Subject Badge & Close */}
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <span 
                className="w-2.5 h-2.5 rounded-full shadow-needle animate-pulse" 
                style={{ backgroundColor: currentSubject.color }}
              />
              <span className="text-xs font-bold text-ink-muted">
                تسک جدید در «{currentSubject.name}»
              </span>
            </div>

            <button
              onClick={() => setOpen(false)}
              className="p-1 rounded-xl text-ink-muted hover:text-ink-primary hover:bg-white/10 transition cursor-pointer"
              aria-label="بستن"
            >
              <X className="w-4 h-4" />
            </button>
          </div>

          {/* Form */}
          <form onSubmit={handleSubmit} className="space-y-4">
            
            {/* 1. Large Fluid Title Input */}
            <div>
              <input
                ref={titleInputRef}
                type="text"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                placeholder="عنوان فعالیت... (مثلاً: حل ۲۰ تست حسابان)"
                className="w-full bg-transparent border-0 text-base md:text-lg font-black text-ink-primary placeholder:text-ink-muted/40 focus:outline-none focus:ring-0 p-0"
              />
            </div>

            {/* 2. Optional Lightweight Description / Notes */}
            <div>
              <textarea
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                placeholder="یادداشت تکمیلی یا منبع مطالعه (اختیاری)..."
                rows={2}
                className="w-full bg-canvas-secondary/50 border border-border-subtle rounded-2xl p-3 text-xs text-ink-primary placeholder:text-ink-muted/40 focus:outline-none focus:border-accent-primary/60 transition resize-none"
              />
            </div>

            {/* 3. Sleek Smart Pills Row (One-tap customization) */}
            <div className="flex items-center gap-1.5 flex-wrap pt-1">
              
              {/* Subject Selector Pill */}
              <div className="relative">
                <button
                  type="button"
                  onClick={() => setActivePopover(activePopover === 'subject' ? null : 'subject')}
                  className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-canvas-secondary hover:bg-canvas-secondary/80 border border-border-subtle text-xs font-bold text-ink-primary transition cursor-pointer"
                >
                  <span 
                    className="w-2 h-2 rounded-full flex-shrink-0" 
                    style={{ backgroundColor: currentSubject.color }}
                  />
                  <span>{currentSubject.name}</span>
                  <ChevronDown className="w-3 h-3 text-ink-muted opacity-60" />
                </button>

                {/* Subject Dropdown */}
                {activePopover === 'subject' && (
                  <div className="absolute top-full mt-1.5 right-0 z-30 w-48 rounded-2xl bg-canvas-elevated border border-border-subtle shadow-xl p-1.5 space-y-0.5">
                    {subjects.map((s) => (
                      <button
                        key={s.id}
                        type="button"
                        onClick={() => {
                          setSubjectId(s.id);
                          setActivePopover(null);
                        }}
                        className={`w-full flex items-center justify-between px-2.5 py-1.5 rounded-xl text-xs transition cursor-pointer ${
                          s.id === currentSubject.id 
                            ? 'bg-accent-primary/10 text-accent-primary font-bold' 
                            : 'hover:bg-white/5 text-ink-primary'
                        }`}
                      >
                        <div className="flex items-center gap-2">
                          <span className="w-2 h-2 rounded-full" style={{ backgroundColor: s.color }} />
                          <span>{s.name}</span>
                        </div>
                        {s.id === currentSubject.id && <Check className="w-3.5 h-3.5" />}
                      </button>
                    ))}
                  </div>
                )}
              </div>

              {/* Duration Selector Pill */}
              <div className="relative">
                <button
                  type="button"
                  onClick={() => setActivePopover(activePopover === 'duration' ? null : 'duration')}
                  className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-canvas-secondary hover:bg-canvas-secondary/80 border border-border-subtle text-xs font-bold text-ink-primary transition cursor-pointer font-mono"
                >
                  <Clock className="w-3.5 h-3.5 text-accent-primary" />
                  <span>{formatToPersianDigits(duration)} دقیقه</span>
                  <ChevronDown className="w-3 h-3 text-ink-muted opacity-60" />
                </button>

                {/* Duration Presets Dropdown */}
                {activePopover === 'duration' && (
                  <div className="absolute top-full mt-1.5 right-0 z-30 w-44 rounded-2xl bg-canvas-elevated border border-border-subtle shadow-xl p-1.5 space-y-0.5">
                    {DURATION_PRESETS.map((p) => (
                      <button
                        key={p.value}
                        type="button"
                        onClick={() => {
                          setDuration(p.value);
                          setActivePopover(null);
                        }}
                        className={`w-full flex items-center justify-between px-2.5 py-1.5 rounded-xl text-xs transition cursor-pointer ${
                          p.value === duration 
                            ? 'bg-accent-primary/10 text-accent-primary font-bold' 
                            : 'hover:bg-white/5 text-ink-primary'
                        }`}
                      >
                        <span>{p.label}</span>
                        {p.value === duration && <Check className="w-3.5 h-3.5" />}
                      </button>
                    ))}
                  </div>
                )}
              </div>

              {/* Priority Pill */}
              <div className="relative">
                <button
                  type="button"
                  onClick={() => setActivePopover(activePopover === 'priority' ? null : 'priority')}
                  className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-canvas-secondary hover:bg-canvas-secondary/80 border border-border-subtle text-xs font-bold text-ink-primary transition cursor-pointer"
                >
                  <span 
                    className="w-2 h-2 rounded-full" 
                    style={{ backgroundColor: currentPriorityObj.color }}
                  />
                  <span>{currentPriorityObj.label}</span>
                  <ChevronDown className="w-3 h-3 text-ink-muted opacity-60" />
                </button>

                {activePopover === 'priority' && (
                  <div className="absolute top-full mt-1.5 right-0 z-30 w-40 rounded-2xl bg-canvas-elevated border border-border-subtle shadow-xl p-1.5 space-y-0.5">
                    {PRIORITY_OPTIONS.map((p) => (
                      <button
                        key={p.id}
                        type="button"
                        onClick={() => {
                          setPriority(p.id);
                          setActivePopover(null);
                        }}
                        className={`w-full flex items-center justify-between px-2.5 py-1.5 rounded-xl text-xs transition cursor-pointer ${
                          p.id === priority 
                            ? 'bg-accent-primary/10 text-accent-primary font-bold' 
                            : 'hover:bg-white/5 text-ink-primary'
                        }`}
                      >
                        <div className="flex items-center gap-2">
                          <span className="w-2 h-2 rounded-full" style={{ backgroundColor: p.color }} />
                          <span>{p.label}</span>
                        </div>
                        {p.id === priority && <Check className="w-3.5 h-3.5" />}
                      </button>
                    ))}
                  </div>
                )}
              </div>

              {/* Start Time Pill */}
              <div className="flex items-center px-2.5 py-1 rounded-xl bg-canvas-secondary border border-border-subtle text-xs text-ink-muted">
                <Clock className="w-3.5 h-3.5 ml-1 text-ink-muted opacity-60" />
                <input
                  type="time"
                  value={startTime}
                  onChange={(e) => setStartTime(e.target.value)}
                  placeholder="زمان"
                  className="bg-transparent text-ink-primary font-mono text-xs focus:outline-none cursor-pointer"
                  title="ساعت شروع (اختیاری)"
                />
              </div>

              {/* Date Toggle: Today vs Tomorrow */}
              <button
                type="button"
                onClick={() => {
                  if (isToday) {
                    handleSetTomorrow();
                  } else {
                    setTargetDate(selectedDate);
                  }
                }}
                className={`flex items-center gap-1 px-3 py-1.5 rounded-xl text-xs font-bold transition cursor-pointer border ${
                  isToday 
                    ? 'bg-canvas-secondary text-ink-primary border-border-subtle' 
                    : 'bg-indigo-500/15 text-indigo-400 border-indigo-500/30'
                }`}
                title="تغییر تاریخ بین امروز و فردا"
              >
                <Calendar className="w-3.5 h-3.5" />
                <span>{isToday ? 'امروز' : 'فردا'}</span>
              </button>

              {/* Sunsama Golden MIT Toggle Button */}
              <button
                type="button"
                onClick={() => setIsMIT(!isMIT)}
                className={`flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-bold transition cursor-pointer border ${
                  isMIT 
                    ? 'bg-amber-500/20 text-amber-300 border-amber-500/50 shadow-sm' 
                    : 'bg-canvas-secondary text-ink-muted hover:text-ink-primary border-border-subtle'
                }`}
                title="علامت‌گذاری به عنوان اولویت طلایی روز"
              >
                <Star className={`w-3.5 h-3.5 ${isMIT ? 'fill-amber-400 text-amber-400' : ''}`} />
                <span>اولویت طلایی MIT</span>
              </button>
            </div>

            {/* 4. Progressive Subtasks Checklist (Clean Disclosure) */}
            <div className="space-y-2 pt-1 border-t border-border-subtle/50">
              <div className="flex items-center justify-between">
                <button
                  type="button"
                  onClick={() => setShowSubtasks(!showSubtasks)}
                  className="flex items-center gap-1.5 text-xs text-ink-muted hover:text-accent-primary font-bold transition cursor-pointer"
                >
                  <ListPlus className="w-3.5 h-3.5" />
                  <span>
                    {subtasks.length > 0 
                      ? `${formatToPersianDigits(subtasks.length)} زیرتسک افزوده شده` 
                      : '+ افزودن زیرتسک و مراحل'}
                  </span>
                </button>
              </div>

              {showSubtasks && (
                <div className="space-y-2 p-3 rounded-2xl bg-canvas-secondary/50 border border-border-subtle">
                  {/* Subtask list */}
                  {subtasks.length > 0 && (
                    <div className="space-y-1.5 max-h-32 overflow-y-auto pr-1">
                      {subtasks.map((st) => (
                        <div
                          key={st.id}
                          className="flex items-center justify-between p-1.5 px-2 rounded-xl bg-canvas-elevated border border-border-subtle text-xs"
                        >
                          <span className="text-ink-primary">{st.title}</span>
                          <button
                            type="button"
                            onClick={() => handleRemoveSubtask(st.id)}
                            className="text-ink-muted hover:text-red-400 transition"
                          >
                            <Trash2 className="w-3.5 h-3.5" />
                          </button>
                        </div>
                      ))}
                    </div>
                  )}

                  {/* Add Subtask Input */}
                  <div className="flex items-center gap-2">
                    <input
                      ref={subtaskInputRef}
                      type="text"
                      value={subtaskInput}
                      onChange={(e) => setSubtaskInput(e.target.value)}
                      onKeyDown={(e) => {
                        if (e.key === 'Enter') {
                          e.preventDefault();
                          handleAddSubtask();
                        }
                      }}
                      placeholder="عنوان مرحله جدید را بنویسید و Enter بزنید..."
                      className="flex-1 bg-transparent border-0 text-xs text-ink-primary placeholder:text-ink-muted/50 focus:outline-none"
                    />
                    <button
                      type="button"
                      onClick={() => handleAddSubtask()}
                      className="px-2.5 py-1 rounded-xl bg-white/10 hover:bg-white/20 text-ink-primary text-xs font-bold transition"
                    >
                      افزودن
                    </button>
                  </div>
                </div>
              )}
            </div>

            {/* 5. Footer Row: Keyboard Shortcut Hint & Submit */}
            <div className="flex items-center justify-between pt-3 border-t border-border-subtle/80">
              <div className="text-[11px] text-ink-muted hidden sm:flex items-center gap-1.5">
                <kbd className="font-mono bg-white/5 border border-border-subtle px-1.5 py-0.5 rounded text-[10px]">
                  Cmd+Enter
                </kbd>
                <span>برای ثبت فوری</span>
              </div>

              <div className="flex items-center gap-2 w-full sm:w-auto justify-end">
                <button
                  type="button"
                  onClick={() => setOpen(false)}
                  className="px-4 py-2 rounded-xl text-xs font-bold text-ink-muted hover:text-ink-primary hover:bg-white/5 transition cursor-pointer"
                >
                  انصراف
                </button>
                <button
                  type="submit"
                  disabled={!title.trim()}
                  className="flex items-center justify-center gap-1.5 px-5 py-2.5 rounded-xl bg-accent-primary hover:bg-accent-hover disabled:opacity-40 text-white font-bold text-xs shadow-needle transition active:scale-95 cursor-pointer"
                >
                  <Plus className="w-4 h-4" />
                  <span>ایجاد تسک</span>
                </button>
              </div>
            </div>

          </form>
        </motion.div>
      </div>
    </AnimatePresence>
  );
};

export default CreateTaskModal;
