import { useAppStore } from '../../store/useAppStore';
import type { Task, TaskStatus } from '../../types';
import { Plus, CheckCircle2, Clock, Sparkles } from 'lucide-react';

const COLUMNS: { status: TaskStatus; title: string; color: string }[] = [
  { status: 'todo', title: 'در انتظار انجام (To Do)', color: '#6366F1' },
  { status: 'in_progress', title: 'در حال انجام (In Progress)', color: '#FF4700' },
  { status: 'completed', title: 'تکمیل شده (Completed)', color: '#10B981' },
];

export const KanbanView: React.FC = () => {
  const tasks = useAppStore((s) => s.tasks);
  const selectedDate = useAppStore((s) => s.selectedDate);
  const updateTask = useAppStore((s) => s.updateTask);
  const selectTask = useAppStore((s) => s.selectTask);
  const addTask = useAppStore((s) => s.addTask);

  const dayTasks = tasks.filter((t) => t.date === selectedDate);

  const handleAddTaskToColumn = (status: TaskStatus) => {
    addTask({
      title: 'تسک جدید کانبان',
      date: selectedDate,
      startTime: '11:00',
      durationMinutes: 45,
      color: status === 'in_progress' ? '#FF4700' : '#6366F1',
      priority: 'medium',
      status,
      tags: ['کانبان'],
      subtasks: [],
      blocks: [],
    });
  };

  return (
    <div className="flex-1 overflow-x-auto p-4 md:p-6 bg-canvas select-none">
      <div className="flex gap-4 md:gap-6 min-w-[760px] h-full items-start">
        {COLUMNS.map((col) => {
          const colTasks = dayTasks.filter((t) => t.status === col.status);

          return (
            <div
              key={col.status}
              className="flex-1 min-w-[260px] max-w-sm rounded-squircle-lg bg-canvas-elevated liquid-glass border border-border-subtle flex flex-col max-h-full"
            >
              {/* Column Header */}
              <div className="p-3.5 border-b border-border-subtle flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <span
                    className="w-2.5 h-2.5 rounded-full"
                    style={{ backgroundColor: col.color }}
                  />
                  <span className="text-xs font-bold text-ink-primary">
                    {col.title}
                  </span>
                  <span className="text-xs font-mono text-ink-muted">
                    ({colTasks.length})
                  </span>
                </div>

                <button
                  onClick={() => handleAddTaskToColumn(col.status)}
                  className="p-1 hover:bg-white/10 rounded text-ink-muted hover:text-ink-primary transition"
                  title="افزودن تسک"
                >
                  <Plus className="w-4 h-4" />
                </button>
              </div>

              {/* Tasks Cards List */}
              <div className="flex-1 overflow-y-auto p-3 space-y-2.5">
                {colTasks.length === 0 ? (
                  <div className="py-8 text-center text-xs text-ink-subtle border border-dashed border-border-subtle rounded-precision-md">
                    هیچ تسکی در این ستون نیست.
                  </div>
                ) : (
                  colTasks.map((task) => (
                    <div
                      key={task.id}
                      onClick={() => selectTask(task.id)}
                      className="p-3 rounded-precision-md bg-canvas-secondary hover:bg-white/[0.06] border border-border-subtle cursor-pointer transition space-y-2 group shadow-sm"
                    >
                      <div className="flex items-start justify-between gap-2">
                        <span className="text-xs md:text-sm font-semibold text-ink-primary">
                          {task.title}
                        </span>
                        {task.isMIT && (
                          <span className="px-1.5 py-0.2 rounded bg-amber-500/20 text-amber-500 text-[10px] font-bold">
                            MIT
                          </span>
                        )}
                      </div>

                      <div className="flex items-center justify-between text-[11px] text-ink-muted font-mono pt-1 border-t border-border-subtle/50">
                        <div className="flex items-center gap-1">
                          <Clock className="w-3 h-3 text-accent-primary" />
                          <span>{task.durationMinutes} دقیقه</span>
                        </div>

                        {/* Status switcher pills */}
                        <div className="flex gap-1">
                          {COLUMNS.map((otherCol) => {
                            if (otherCol.status === col.status) return null;
                            return (
                              <button
                                key={otherCol.status}
                                onClick={(e) => {
                                  e.stopPropagation();
                                  updateTask(task.id, { status: otherCol.status });
                                }}
                                className="px-1.5 py-0.5 rounded text-[10px] bg-white/5 hover:bg-white/15 text-ink-subtle hover:text-ink-primary transition"
                              >
                                به {otherCol.status === 'completed' ? 'تکمیل' : otherCol.status === 'in_progress' ? 'جاری' : 'انتظار'}
                              </button>
                            );
                          })}
                        </div>
                      </div>
                    </div>
                  ))
                )}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};
