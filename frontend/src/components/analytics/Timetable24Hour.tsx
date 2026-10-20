import React from 'react';
import { getTimetableSlots, formatToPersianDigits } from '../../lib/calendarUtils';
import { useAppStore } from '../../store/useAppStore';

export const Timetable24Hour: React.FC = () => {
  const sessions = useAppStore((s) => s.sessions);
  const subjects = useAppStore((s) => s.subjects);
  const selectedDate = useAppStore((s) => s.selectedDate);

  const slots = getTimetableSlots(); // 144 slots from 05:00 AM

  // Filter sessions for selected date
  const daySessions = sessions.filter((sess) => sess.dateKey === selectedDate);

  // Map each slot to a subject color if a session falls within it
  const getSlotColor = (slotHour: number, slotMinute: number) => {
    const slotMinutesOfDay = slotHour * 60 + slotMinute;

    for (const sess of daySessions) {
      const start = new Date(sess.startedAt);
      const end = new Date(sess.endedAt);
      const startMin = start.getHours() * 60 + start.getMinutes();
      const endMin = end.getHours() * 60 + end.getMinutes();

      if (slotMinutesOfDay >= startMin && slotMinutesOfDay < endMin) {
        const subj = subjects.find((s) => s.id === sess.subjectId);
        return subj ? subj.color : '#FF4700';
      }
    }
    return null;
  };

  return (
    <div className="p-4 md:p-6 rounded-squircle-lg bg-canvas-elevated border border-border-subtle space-y-4">
      <div className="flex items-center justify-between">
        <div>
          <h3 className="text-sm md:text-base font-bold text-ink-primary">
            جدول زمانی ۲۴ ساعته (YPT 10-Minute Timetable)
          </h3>
          <p className="text-xs text-ink-muted">
            ۱۴۴ بلوک ۱۰ دقیقه‌ای از ساعت ۰۵:۰۰ صبح تا ۰۵:۰۰ صبح فردا
          </p>
        </div>
        <div className="flex items-center gap-2 text-xs font-mono">
          <span className="w-2.5 h-2.5 rounded-full bg-accent-primary" />
          <span className="text-ink-muted">سشن‌های مطالعه فعال</span>
        </div>
      </div>

      {/* Grid of 144 blocks (6 blocks per hour, 24 rows) */}
      <div className="grid grid-cols-12 md:grid-cols-24 gap-1 p-3 rounded-precision-md bg-canvas-secondary/50 border border-border-subtle overflow-x-auto">
        {slots.map((slot) => {
          const color = getSlotColor(slot.hour, slot.minute);
          return (
            <div
              key={slot.index}
              title={`زمان: ${slot.timeStr}`}
              className={`h-7 rounded-[3px] transition-all cursor-pointer flex items-center justify-center text-[9px] font-mono border ${
                color
                  ? 'border-transparent shadow-sm'
                  : 'bg-white/[0.03] border-border-subtle/40 hover:bg-white/[0.08]'
              }`}
              style={{ backgroundColor: color || undefined }}
            >
              {slot.minute === 0 && (
                <span className="text-ink-subtle text-[8px] opacity-70">
                  {slot.hour}
                </span>
              )}
            </div>
          );
        })}
      </div>

      {/* Subjects Legend */}
      <div className="flex flex-wrap items-center gap-3 pt-2 text-xs">
        {subjects.map((subj) => (
          <div key={subj.id} className="flex items-center gap-1.5">
            <span
              className="w-2.5 h-2.5 rounded-full"
              style={{ backgroundColor: subj.color }}
            />
            <span className="text-ink-muted">{subj.name}</span>
          </div>
        ))}
      </div>
    </div>
  );
};
