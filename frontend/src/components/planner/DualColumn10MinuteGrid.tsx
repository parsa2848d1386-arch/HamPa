import React, { useState } from 'react';
import { useAppStore } from '../../store/useAppStore';
import { formatToPersianDigits } from '../../lib/calendarUtils';
import { Columns, SplitSquareVertical, Sparkles, CheckCircle2, Clock } from 'lucide-react';

export const DualColumn10MinuteGrid: React.FC = () => {
  const sessions = useAppStore((s) => s.sessions);
  const tasks = useAppStore((s) => s.tasks);
  const subjects = useAppStore((s) => s.subjects);
  const selectedDate = useAppStore((s) => s.selectedDate);

  const [viewMode, setViewMode] = useState<'split' | 'planned' | 'actual'>('split');

  // ۲۴ ساعت از ساعت ۰۵:۰۰ صبح تا ۰۴:۵۹ صبح فردا
  const hours = Array.from({ length: 24 }, (_, i) => (i + 5) % 24);

  // تسک‌های برنامه‌ریزی‌شده امروز
  const plannedTasks = tasks.filter((t) => t.date === selectedDate);
  // سشن‌های واقعی ثبت‌شده امروز
  const actualSessions = sessions.filter((s) => s.dateKey === selectedDate);

  // تابعی برای تشخیص رنگ سلول ۱۰ دقیقه‌ای برنامه‌ریزی‌شده (Planned)
  const getPlannedCellColor = (hour: number, cellIndex: number) => {
    const slotMinutes = hour * 60 + cellIndex * 10;
    for (const t of plannedTasks) {
      if (t.startTime) {
        const [th, tm] = t.startTime.split(':').map(Number);
        const taskStart = th * 60 + tm;
        const taskEnd = taskStart + t.durationMinutes;
        if (slotMinutes >= taskStart && slotMinutes < taskEnd) {
          return t.color || '#FF4700';
        }
      }
    }
    return null;
  };

  // تابعی برای تشخیص رنگ سلول ۱۰ دقیقه‌ای واقعی مطالعه‌شده (Actual)
  const getActualCellColor = (hour: number, cellIndex: number) => {
    const slotMinutes = hour * 60 + cellIndex * 10;
    for (const s of actualSessions) {
      const start = new Date(s.startedAt);
      const end = new Date(s.endedAt);
      const sStart = start.getHours() * 60 + start.getMinutes();
      const sEnd = end.getHours() * 60 + end.getMinutes();
      if (slotMinutes >= sStart && slotMinutes < sEnd) {
        const subj = subjects.find((sub) => sub.id === s.subjectId);
        return subj ? subj.color : '#10B981';
      }
    }
    return null;
  };

  return (
    <div className="flex-1 flex flex-col h-full overflow-hidden bg-canvas p-3 md:p-6 select-none">
      {/* Header & Controls */}
      <div className="flex items-center justify-between pb-4 border-b border-border-subtle">
        <div className="flex items-center gap-2">
          <div className="w-8 h-8 rounded-precision-md bg-accent-primary/20 text-accent-primary flex items-center justify-center">
            <Columns className="w-4 h-4" />
          </div>
          <div>
            <h2 className="text-sm md:text-base font-bold text-ink-primary">
              پلنر ۱۰ دقیقه‌ای دو ستونه (Motemote Planned vs. Actual Grid)
            </h2>
            <p className="text-[11px] text-ink-muted">
              مقایسه رو در روی برنامه هدف هوش مصنوعی (سمت راست) و عملکرد واقعی ثبت‌شده (سمت چپ)
            </p>
          </div>
        </div>

        {/* View Switcher Pills */}
        <div className="flex items-center p-0.5 rounded-precision bg-canvas-secondary border border-border-subtle text-xs">
          <button
            onClick={() => setViewMode('split')}
            className={`px-2.5 py-1 rounded transition font-medium ${
              viewMode === 'split' ? 'bg-accent-primary text-white font-bold' : 'text-ink-muted'
            }`}
          >
            نمای دو ستونه
          </button>
          <button
            onClick={() => setViewMode('planned')}
            className={`px-2.5 py-1 rounded transition font-medium ${
              viewMode === 'planned' ? 'bg-accent-primary text-white font-bold' : 'text-ink-muted'
            }`}
          >
            فقط هدف (Planned)
          </button>
          <button
            onClick={() => setViewMode('actual')}
            className={`px-2.5 py-1 rounded transition font-medium ${
              viewMode === 'actual' ? 'bg-accent-primary text-white font-bold' : 'text-ink-muted'
            }`}
          >
            فقط واقعیت (Actual)
          </button>
        </div>
      </div>

      {/* Grid Container */}
      <div className="flex-1 overflow-y-auto mt-4 pr-1">
        <div className="space-y-1.5 max-w-4xl mx-auto">
          {hours.map((hour) => {
            const hourLabel = `${hour.toString().padStart(2, '0')}:00`;

            return (
              <div
                key={hour}
                className="flex items-center gap-3 p-1.5 rounded-precision-md bg-canvas-elevated border border-border-subtle/70 hover:border-border-highlight transition"
              >
                {/* Hour Label */}
                <div className="w-12 text-center font-mono text-xs font-bold text-ink-muted tabular-nums">
                  {hourLabel}
                </div>

                {/* Left/Planned Column (if visible) */}
                {(viewMode === 'split' || viewMode === 'planned') && (
                  <div className="flex-1">
                    <div className="grid grid-cols-6 gap-1 h-7">
                      {[0, 1, 2, 3, 4, 5].map((cellIdx) => {
                        const color = getPlannedCellColor(hour, cellIdx);
                        return (
                          <div
                            key={cellIdx}
                            title={`هدف: ${hour}:${cellIdx * 10}`}
                            className={`rounded-[3px] border transition-all ${
                              color
                                ? 'border-transparent shadow-sm'
                                : 'bg-white/[0.03] border-border-subtle/30'
                            }`}
                            style={{ backgroundColor: color || undefined }}
                          />
                        );
                      })}
                    </div>
                  </div>
                )}

                {/* Divider */}
                {viewMode === 'split' && (
                  <div className="w-[1px] h-6 bg-border-subtle" />
                )}

                {/* Right/Actual Column (if visible) */}
                {(viewMode === 'split' || viewMode === 'actual') && (
                  <div className="flex-1">
                    <div className="grid grid-cols-6 gap-1 h-7">
                      {[0, 1, 2, 3, 4, 5].map((cellIdx) => {
                        const color = getActualCellColor(hour, cellIdx);
                        return (
                          <div
                            key={cellIdx}
                            title={`عملکرد واقعی: ${hour}:${cellIdx * 10}`}
                            className={`rounded-[3px] border transition-all ${
                              color
                                ? 'border-transparent shadow-needle'
                                : 'bg-white/[0.03] border-border-subtle/30'
                            }`}
                            style={{ backgroundColor: color || undefined }}
                          />
                        );
                      })}
                    </div>
                  </div>
                )}
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
};
