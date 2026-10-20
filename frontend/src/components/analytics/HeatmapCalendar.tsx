import React from 'react';
import { Flame, Award, Clock } from 'lucide-react';
import { useAppStore } from '../../store/useAppStore';
import { formatToPersianDigits } from '../../lib/calendarUtils';

export const HeatmapCalendar: React.FC = () => {
  const sessions = useAppStore((s) => s.sessions);
  const user = useAppStore((s) => s.user);

  // Generate last 14 weeks of days (98 days)
  const days: { dateStr: string; dayOfMonth: number; hours: number; level: number }[] = [];
  const now = new Date();

  for (let i = 97; i >= 0; i--) {
    const d = new Date(now);
    d.setDate(d.getDate() - i);
    const dateStr = d.toISOString().split('T')[0];

    // Compute studied hours for this day from actual recorded sessions
    const daySessions = sessions.filter((s) => s.dateKey === dateStr);
    const totalSecs = daySessions.reduce((acc, s) => acc + s.durationSeconds, 0);
    const totalHours = Math.round((totalSecs / 3600) * 10) / 10;

    let level = 0;
    if (totalHours > 6) level = 4;
    else if (totalHours > 4) level = 3;
    else if (totalHours > 2) level = 2;
    else if (totalHours > 0) level = 1;

    days.push({
      dateStr,
      dayOfMonth: d.getDate(),
      hours: totalHours,
      level,
    });
  }

  const getCellColor = (level: number) => {
    switch (level) {
      case 4: return 'bg-[#FF4700] text-white shadow-needle'; // High voltage
      case 3: return 'bg-[#FF7338] text-white';
      case 2: return 'bg-[#FF9F73] text-black/70';
      case 1: return 'bg-[#FFCBB3]/40 text-ink-muted';
      default: return 'bg-white/[0.04] text-ink-subtle hover:bg-white/[0.08]';
    }
  };

  return (
    <div className="p-4 md:p-6 rounded-squircle-lg bg-canvas-elevated border border-border-subtle space-y-4">
      {/* Top Stats Cards */}
      <div className="grid grid-cols-3 gap-3">
        <div className="p-3 rounded-precision-md bg-canvas-secondary/70 border border-border-subtle flex items-center gap-3">
          <div className="w-9 h-9 rounded-full bg-accent-primary/20 text-accent-primary flex items-center justify-center">
            <Flame className="w-5 h-5 fill-current" />
          </div>
          <div>
            <div className="text-base md:text-lg font-black text-ink-primary tabular-nums">
              {formatToPersianDigits(user.streakDays)} روز
            </div>
            <div className="text-[11px] text-ink-muted">تداوم زنجیره مطالعه</div>
          </div>
        </div>

        <div className="p-3 rounded-precision-md bg-canvas-secondary/70 border border-border-subtle flex items-center gap-3">
          <div className="w-9 h-9 rounded-full bg-amber-500/20 text-amber-500 flex items-center justify-center">
            <Clock className="w-5 h-5" />
          </div>
          <div>
            <div className="text-base md:text-lg font-black text-ink-primary tabular-nums">
              {formatToPersianDigits(84)} ساعت
            </div>
            <div className="text-[11px] text-ink-muted">کل تمرکز این ماه</div>
          </div>
        </div>

        <div className="p-3 rounded-precision-md bg-canvas-secondary/70 border border-border-subtle flex items-center gap-3">
          <div className="w-9 h-9 rounded-full bg-emerald-500/20 text-emerald-500 flex items-center justify-center">
            <Award className="w-5 h-5" />
          </div>
          <div>
            <div className="text-base md:text-lg font-black text-ink-primary tabular-nums">
              رتبه ۱۲
            </div>
            <div className="text-[11px] text-ink-muted">رنکینگ ملی YPT</div>
          </div>
        </div>
      </div>

      {/* Heatmap Section */}
      <div className="space-y-2 pt-2">
        <div className="flex items-center justify-between">
          <h4 className="text-xs font-bold text-ink-muted uppercase">
            نقشه حرارتی فعالیت مطالعه (Study Heatmap)
          </h4>
          <span className="text-[11px] text-ink-subtle">
            مرز شبانه‌روز: ۰۵:۰۰ صبح
          </span>
        </div>

        {/* 7 rows x 14 cols grid */}
        <div className="grid grid-flow-col grid-rows-7 gap-1.5 p-3 rounded-precision-md bg-canvas-secondary/40 border border-border-subtle overflow-x-auto">
          {days.map((day, idx) => (
            <div
              key={idx}
              title={`${day.dateStr}: ${day.hours} ساعت مطالعه`}
              className={`w-4 h-4 md:w-5 md:h-5 rounded-[4px] cursor-pointer transition-all ${getCellColor(
                day.level
              )}`}
            />
          ))}
        </div>

        {/* Legend */}
        <div className="flex items-center justify-end gap-2 text-[10px] text-ink-muted pt-1">
          <span>کمتر</span>
          <span className="w-3 h-3 rounded-[2px] bg-white/[0.04]" />
          <span className="w-3 h-3 rounded-[2px] bg-[#FFCBB3]/40" />
          <span className="w-3 h-3 rounded-[2px] bg-[#FF9F73]" />
          <span className="w-3 h-3 rounded-[2px] bg-[#FF7338]" />
          <span className="w-3 h-3 rounded-[2px] bg-[#FF4700]" />
          <span>بیشتر</span>
        </div>
      </div>
    </div>
  );
};
