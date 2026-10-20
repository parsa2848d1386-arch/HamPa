import React from 'react';
import { motion } from 'framer-motion';
import { CheckCircle2, Circle, Play, Tag, Sparkles } from 'lucide-react';
import type { Task } from '../../types';
import { useAppStore } from '../../store/useAppStore';
import confetti from 'canvas-confetti';

interface TimeBlockCardProps {
  task: Task;
  pixelsPerHour: number;
}

export const TimeBlockCard: React.FC<TimeBlockCardProps> = ({ task, pixelsPerHour }) => {
  const selectTask = useAppStore((s) => s.selectTask);
  const selectedTaskId = useAppStore((s) => s.selectedTaskId);
  const toggleTaskCompleted = useAppStore((s) => s.toggleTaskCompleted);
  const startFocusSession = useAppStore((s) => s.startFocusSession);

  const isSelected = selectedTaskId === task.id;

  // Calculate start time in hours
  let startHour = 9;
  let startMin = 0;
  if (task.startTime) {
    const parts = task.startTime.split(':');
    startHour = parseInt(parts[0], 10);
    startMin = parseInt(parts[1], 10);
  }

  const top = (startHour + startMin / 60) * pixelsPerHour;
  // Calculate height proportional to duration, minimum 32px for 0-minute / short reminders
  const height = Math.max(34, (task.durationMinutes / 60) * pixelsPerHour);

  // End time calculation
  const totalMinutes = startHour * 60 + startMin + task.durationMinutes;
  const endHour = Math.floor(totalMinutes / 60) % 24;
  const endMin = totalMinutes % 60;
  const timeRangeStr = `${task.startTime || '09:00'} - ${endHour.toString().padStart(2, '0')}:${endMin.toString().padStart(2, '0')}`;

  const isCompleted = task.status === 'completed';

  const completedSubtasksCount = task.subtasks.filter((st) => st.completed).length;

  return (
    <motion.div
      layoutId={`task-card-${task.id}`}
      initial={{ opacity: 0, y: 5 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, scale: 0.95 }}
      transition={{ type: 'spring', stiffness: 400, damping: 30, mass: 0.8 }}
      onClick={() => selectTask(task.id)}
      style={{
        top: `${top}px`,
        height: `${height}px`,
      }}
      className={`absolute inset-x-2 md:inset-x-4 rounded-precision-md p-2.5 cursor-pointer transition-all border group overflow-hidden ${
        isSelected
          ? 'ring-2 ring-accent-primary border-transparent shadow-lg bg-canvas-elevated'
          : 'border-border-subtle hover:border-border-highlight bg-canvas-secondary/70 hover:bg-canvas-secondary'
      } ${isCompleted ? 'opacity-60' : ''}`}
    >
      {/* Accent strip */}
      <div
        className="absolute top-0 right-0 bottom-0 w-1.5"
        style={{ backgroundColor: task.color || 'var(--accent-primary)' }}
      />

      <div className="flex flex-col h-full justify-between pr-2">
        {/* Top Row: Checkbox, Title & Time */}
        <div className="flex items-start justify-between gap-2">
          <div className="flex items-start gap-2 overflow-hidden">
            <button
              onClick={(e) => {
                e.stopPropagation();
                if (!isCompleted) {
                  confetti({
                    particleCount: 35,
                    spread: 55,
                    origin: { y: 0.65 },
                    colors: ['#FF4700', '#10B981', '#F59E0B'],
                  });
                  if (typeof navigator !== 'undefined' && 'vibrate' in navigator) {
                    navigator.vibrate(25);
                  }
                }
                toggleTaskCompleted(task.id);
              }}
              className="mt-0.5 text-ink-muted hover:text-accent-primary transition flex-shrink-0 active:scale-90"
              aria-label="تغییر وضعیت انجام تسک"
            >
              {isCompleted ? (
                <CheckCircle2 className="w-4 h-4 text-emerald-500" />
              ) : (
                <Circle className="w-4 h-4" />
              )}
            </button>

            <div className="min-w-0">
              <div className="flex items-center gap-1.5 flex-wrap">
                <span
                  className={`text-xs md:text-sm font-semibold truncate ${
                    isCompleted ? 'line-through text-ink-muted' : 'text-ink-primary'
                  }`}
                >
                  {task.title}
                </span>

                {task.isMIT && (
                  <span className="px-1.5 py-0.2 rounded-precision bg-amber-500/15 text-amber-500 text-[10px] font-bold inline-flex items-center gap-0.5">
                    <Sparkles className="w-2.5 h-2.5" />
                    MIT
                  </span>
                )}
              </div>

              {height > 55 && (
                <div className="flex items-center gap-2 mt-1 text-[11px] text-ink-muted font-mono">
                  <span>{timeRangeStr}</span>
                  <span>•</span>
                  <span>{task.durationMinutes} دقیقه</span>
                </div>
              )}
            </div>
          </div>

          {/* Quick Focus Button */}
          {!isCompleted && (
            <button
              onClick={(e) => {
                e.stopPropagation();
                startFocusSession(task.subjectId || 'subj-1', task.id, 'pomodoro');
              }}
              className="opacity-0 group-hover:opacity-100 transition p-1 rounded-precision bg-accent-primary/20 text-accent-primary hover:bg-accent-primary hover:text-white"
              title="شروع تمرکز با پومودورو"
            >
              <Play className="w-3.5 h-3.5" />
            </button>
          )}
        </div>

        {/* Bottom Row: Subtasks & Tags (only if height permits) */}
        {height >= 85 && (
          <div className="flex items-center justify-between text-[11px] text-ink-muted pt-2 border-t border-border-subtle/50 mt-1">
            <div className="flex items-center gap-1">
              {task.tags.map((tag, i) => (
                <span
                  key={i}
                  className="px-1.5 py-0.5 rounded-precision bg-white/5 border border-border-subtle text-[10px]"
                >
                  {tag}
                </span>
              ))}
            </div>

            {task.subtasks.length > 0 && (
              <span className="font-mono text-[10px]">
                {completedSubtasksCount} / {task.subtasks.length} زیرتسک
              </span>
            )}
          </div>
        )}
      </div>
    </motion.div>
  );
};
