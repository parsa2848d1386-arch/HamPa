import React from 'react';
import { useAppStore } from '../../store/useAppStore';
import { PERSIAN_WEEKDAYS, PERSIAN_WEEKDAYS_SHORT, formatToPersianDigits, gregorianToJalali } from '../../lib/calendarUtils';
import { Clock } from 'lucide-react';

export const WeekView: React.FC = () => {
  const selectedDate = useAppStore((s) => s.selectedDate);
  const setSelectedDate = useAppStore((s) => s.setSelectedDate);
  const tasks = useAppStore((s) => s.tasks);
  const selectTask = useAppStore((s) => s.selectTask);
  const calendarSystem = useAppStore((s) => s.calendarSystem);

  const currentDate = new Date(selectedDate);
  // Find start of week (Saturday for Jalali, Sunday/Monday for Gregorian)
  const currentDayOfWeek = (currentDate.getDay() + 1) % 7; // Saturday = 0

  const weekDays: { date: Date; dateStr: string; dayName: string; dayNum: string; isSelected: boolean }[] = [];

  for (let i = 0; i < 7; i++) {
    const d = new Date(currentDate);
    d.setDate(currentDate.getDate() - currentDayOfWeek + i);
    const dateStr = d.toISOString().split('T')[0];

    const j = gregorianToJalali(d.getFullYear(), d.getMonth() + 1, d.getDate());
    const dayName = calendarSystem === 'jalali' ? PERSIAN_WEEKDAYS_SHORT[i] : d.toLocaleDateString('en-US', { weekday: 'narrow' });
    const dayNum = calendarSystem === 'jalali' ? formatToPersianDigits(j.jd) : d.getDate().toString();

    weekDays.push({
      date: d,
      dateStr,
      dayName,
      dayNum,
      isSelected: dateStr === selectedDate,
    });
  }

  return (
    <div className="flex-1 flex flex-col h-full overflow-hidden bg-canvas select-none">
      {/* 7 Days Header */}
      <div className="grid grid-cols-7 border-b border-border-subtle bg-canvas-elevated">
        {weekDays.map((w, idx) => (
          <button
            key={idx}
            onClick={() => setSelectedDate(w.dateStr)}
            className={`p-2.5 text-center transition border-r border-border-subtle/50 ${
              w.isSelected
                ? 'bg-accent-primary/10 text-accent-primary border-b-2 border-b-accent-primary font-bold'
                : 'hover:bg-white/5 text-ink-muted'
            }`}
          >
            <div className="text-[11px] uppercase tracking-wider">{w.dayName}</div>
            <div className="text-base font-black font-mono mt-0.5">{w.dayNum}</div>
          </button>
        ))}
      </div>

      {/* 7 Days Columns Content */}
      <div className="flex-1 grid grid-cols-7 overflow-y-auto divide-x divide-x-reverse divide-border-subtle">
        {weekDays.map((w, idx) => {
          const dayTasks = tasks.filter((t) => t.date === w.dateStr);

          return (
            <div
              key={idx}
              className={`p-2 space-y-2 min-h-full ${
                w.isSelected ? 'bg-white/[0.015]' : ''
              }`}
            >
              {dayTasks.length === 0 ? (
                <div className="py-6 text-center text-[10px] text-ink-subtle">
                  بدون تسک
                </div>
              ) : (
                dayTasks.map((task) => (
                  <div
                    key={task.id}
                    onClick={() => selectTask(task.id)}
                    className="p-2 rounded-precision bg-canvas-secondary/80 hover:bg-canvas-secondary border border-border-subtle text-xs cursor-pointer transition shadow-sm space-y-1"
                    style={{ borderRight: `3px solid ${task.color || 'var(--accent-primary)'}` }}
                  >
                    <div className="font-semibold text-ink-primary truncate">
                      {task.title}
                    </div>
                    {task.startTime && (
                      <div className="text-[10px] text-ink-muted font-mono flex items-center gap-1">
                        <Clock className="w-2.5 h-2.5" />
                        <span>{task.startTime}</span>
                        <span>({task.durationMinutes}m)</span>
                      </div>
                    )}
                  </div>
                ))
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
};
