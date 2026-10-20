import React from 'react';
import { useAppStore } from '../../store/useAppStore';
import type { Task, Priority } from '../../types';
import { 
  AlertCircle, 
  Calendar, 
  UserCheck, 
  Trash, 
  Play, 
  CheckCircle2, 
  Circle,
  Plus
} from 'lucide-react';

interface QuadrantConfig {
  id: Priority;
  title: string;
  subtitle: string;
  color: string;
  borderColor: string;
  icon: React.ElementType;
}

const QUADRANTS: QuadrantConfig[] = [
  {
    id: 'urgent',
    title: '۱. بحرانی و فوری (Do First)',
    subtitle: 'فوراً اقدام شود • ددلاین‌های نزدیک و مسائل حیاتی',
    color: '#EF4444',
    borderColor: 'border-red-500/40',
    icon: AlertCircle,
  },
  {
    id: 'high',
    title: '۲. مهم ولی غیرفوری (Schedule)',
    subtitle: 'برنامه‌ریزی عمیق • رشد تحصیلی، تمرین مفهومی و استراتژی',
    color: '#3B82F6',
    borderColor: 'border-blue-500/40',
    icon: Calendar,
  },
  {
    id: 'medium',
    title: '۳. فوری ولی کم‌اهمیت (Delegate / Automate)',
    subtitle: 'انجام سریع یا واگذاری • کارهای روتین و تماس‌ها',
    color: '#F59E0B',
    borderColor: 'border-amber-500/40',
    icon: UserCheck,
  },
  {
    id: 'low',
    title: '۴. نه فوری و نه مهم (Eliminate)',
    subtitle: 'حذف یا کاهش • وب‌گردی بی‌هدف و کارهای حاشیه‌ای',
    color: '#6B7280',
    borderColor: 'border-gray-500/40',
    icon: Trash,
  },
];

export const EisenhowerMatrixView: React.FC = () => {
  const tasks = useAppStore((s) => s.tasks);
  const updateTask = useAppStore((s) => s.updateTask);
  const selectTask = useAppStore((s) => s.selectTask);
  const startFocusSession = useAppStore((s) => s.startFocusSession);
  const toggleTaskCompleted = useAppStore((s) => s.toggleTaskCompleted);
  const addTask = useAppStore((s) => s.addTask);
  const selectedDate = useAppStore((s) => s.selectedDate);

  const handleQuickAdd = (priority: Priority) => {
    addTask({
      title: 'تسک جدید ماتریس آیزنهاور',
      date: selectedDate,
      startTime: '10:00',
      durationMinutes: 45,
      color: priority === 'urgent' ? '#EF4444' : priority === 'high' ? '#3B82F6' : '#F59E0B',
      priority,
      status: 'todo',
      tags: ['آیزنهاور'],
      subtasks: [],
      blocks: [],
    });
  };

  return (
    <div className="flex-1 overflow-y-auto p-4 md:p-6 bg-canvas select-none">
      <div className="max-w-6xl mx-auto space-y-4">
        {/* Header */}
        <div className="flex items-center justify-between pb-3 border-b border-border-subtle">
          <div>
            <h2 className="text-base md:text-lg font-bold text-ink-primary">
              ماتریس ۴ گانه آیزنهاور (Eisenhower Execution Matrix)
            </h2>
            <p className="text-xs text-ink-muted">
              تفکیک اولویت‌ها بر اساس اضطرار و اهمیت جهت هدایت تمرکز به تسک‌های ربع ۲ (رشد پایدار)
            </p>
          </div>
        </div>

        {/* 2x2 Grid of Quadrants */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {QUADRANTS.map((quad) => {
            const quadTasks = tasks.filter((t) => t.priority === quad.id);
            const Icon = quad.icon;

            return (
              <div
                key={quad.id}
                className={`p-4 rounded-squircle-lg bg-canvas-elevated liquid-glass border ${quad.borderColor} shadow-sm flex flex-col min-h-[280px]`}
              >
                {/* Quadrant Header */}
                <div className="flex items-center justify-between pb-3 border-b border-border-subtle/60">
                  <div className="flex items-center gap-2.5">
                    <div
                      className="w-8 h-8 rounded-precision-md flex items-center justify-center text-white"
                      style={{ backgroundColor: quad.color }}
                    >
                      <Icon className="w-4 h-4" />
                    </div>
                    <div>
                      <h3 className="text-xs md:text-sm font-bold text-ink-primary">
                        {quad.title}
                      </h3>
                      <p className="text-[10px] text-ink-muted">{quad.subtitle}</p>
                    </div>
                  </div>

                  <button
                    onClick={() => handleQuickAdd(quad.id)}
                    className="p-1.5 rounded-precision bg-white/5 hover:bg-white/10 text-ink-muted hover:text-ink-primary transition"
                    title="افزودن تسک در این ربع"
                  >
                    <Plus className="w-4 h-4" />
                  </button>
                </div>

                {/* Tasks List */}
                <div className="flex-1 overflow-y-auto py-3 space-y-2">
                  {quadTasks.length === 0 ? (
                    <div className="py-8 text-center text-xs text-ink-subtle border border-dashed border-border-subtle/50 rounded-precision-md">
                      تسکی در این بخش نیست.
                    </div>
                  ) : (
                    quadTasks.map((task) => {
                      const isDone = task.status === 'completed';
                      return (
                        <div
                          key={task.id}
                          onClick={() => selectTask(task.id)}
                          className={`p-2.5 rounded-precision-md bg-canvas-secondary hover:bg-white/[0.06] border border-border-subtle cursor-pointer transition flex items-center justify-between gap-2 group ${
                            isDone ? 'opacity-60' : ''
                          }`}
                        >
                          <div className="flex items-center gap-2 overflow-hidden flex-1">
                            <button
                              onClick={(e) => {
                                e.stopPropagation();
                                toggleTaskCompleted(task.id);
                              }}
                              className="text-ink-muted hover:text-accent-primary transition flex-shrink-0"
                            >
                              {isDone ? (
                                <CheckCircle2 className="w-4 h-4 text-emerald-500" />
                              ) : (
                                <Circle className="w-4 h-4" />
                              )}
                            </button>
                            <span
                              className={`text-xs font-semibold truncate ${
                                isDone ? 'line-through text-ink-muted' : 'text-ink-primary'
                              }`}
                            >
                              {task.title}
                            </span>
                          </div>

                          <div className="flex items-center gap-1.5">
                            <span className="text-[10px] font-mono text-ink-subtle">
                              {task.durationMinutes}m
                            </span>
                            {!isDone && (
                              <button
                                onClick={(e) => {
                                  e.stopPropagation();
                                  startFocusSession(task.subjectId || 'subj-1', task.id, 'pomodoro');
                                }}
                                className="opacity-0 group-hover:opacity-100 p-1 rounded bg-accent-primary text-white hover:bg-accent-hover transition"
                                title="شروع تمرکز"
                              >
                                <Play className="w-3 h-3 fill-current" />
                              </button>
                            )}
                          </div>
                        </div>
                      );
                    })
                  )}
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
};
