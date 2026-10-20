import React, { useRef, useEffect } from 'react';
import { useAppStore } from '../../store/useAppStore';
import { CurrentTimeIndicator } from './CurrentTimeIndicator';
import { TimeBlockCard } from './TimeBlockCard';

const PIXELS_PER_HOUR = 80;
const HOURS = Array.from({ length: 24 }, (_, i) => i);

export const UnifiedTimeline: React.FC = () => {
  const containerRef = useRef<HTMLDivElement>(null);
  const tasks = useAppStore((s) => s.tasks);
  const selectedDate = useAppStore((s) => s.selectedDate);
  const addTask = useAppStore((s) => s.addTask);

  // Filter tasks for selected date
  const dayTasks = tasks.filter((t) => t.date === selectedDate);

  // Scroll to current time or 8:00 AM on initial mount
  useEffect(() => {
    if (containerRef.current) {
      const now = new Date();
      const currentHour = now.getHours();
      const scrollTarget = Math.max(0, (currentHour - 1) * PIXELS_PER_HOUR);
      containerRef.current.scrollTop = scrollTarget;
    }
  }, []);

  const handleEmptySlotClick = (hour: number) => {
    const timeStr = `${hour.toString().padStart(2, '0')}:00`;
    addTask({
      title: 'تسک جدید زمان‌بندی‌شده',
      date: selectedDate,
      startTime: timeStr,
      durationMinutes: 60,
      color: '#FF4700',
      priority: 'medium',
      status: 'todo',
      tags: ['برنامه‌ریزی'],
      subtasks: [],
      blocks: [],
    });
  };

  return (
    <div
      ref={containerRef}
      className="relative flex-1 h-full overflow-y-auto select-none bg-canvas"
    >
      <div
        className="relative min-w-[340px]"
        style={{ height: `${24 * PIXELS_PER_HOUR}px` }}
      >
        {/* Glowing Current Time Needle */}
        <CurrentTimeIndicator pixelsPerHour={PIXELS_PER_HOUR} />

        {/* 24-Hour Grid & Lines */}
        {HOURS.map((hour) => {
          const top = hour * PIXELS_PER_HOUR;
          const timeLabel = `${hour.toString().padStart(2, '0')}:00`;

          return (
            <div
              key={hour}
              style={{ top: `${top}px`, height: `${PIXELS_PER_HOUR}px` }}
              className="absolute inset-x-0 border-t border-border-subtle flex items-start group"
              onClick={() => handleEmptySlotClick(hour)}
            >
              {/* Hour Label */}
              <div className="w-14 md:w-16 pr-2 md:pr-3 -mt-2.5 text-right text-[11px] font-mono text-ink-subtle select-none">
                {timeLabel}
              </div>

              {/* Grid lane background hover effect */}
              <div className="flex-1 h-full border-r border-border-subtle group-hover:bg-white/[0.015] transition cursor-pointer relative">
                {/* Half-hour subtle dotted marker */}
                <div className="absolute inset-x-0 top-1/2 border-t border-dashed border-border-subtle/40" />
              </div>
            </div>
          );
        })}

        {/* Time Blocks Layer */}
        <div className="absolute inset-y-0 right-14 md:right-16 left-0">
          {dayTasks.map((task) => (
            <TimeBlockCard
              key={task.id}
              task={task}
              pixelsPerHour={PIXELS_PER_HOUR}
            />
          ))}
        </div>
      </div>
    </div>
  );
};
