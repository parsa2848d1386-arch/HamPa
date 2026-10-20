import React from 'react';
import { Timetable24Hour } from './Timetable24Hour';
import { HeatmapCalendar } from './HeatmapCalendar';
import { useAppStore } from '../../store/useAppStore';
import { formatToPersianDigits } from '../../lib/calendarUtils';
import { Calendar, Target, TrendingUp, Sparkles } from 'lucide-react';

export const AnalyticsDashboard: React.FC = () => {
  const subjects = useAppStore((s) => s.subjects);
  const tasks = useAppStore((s) => s.tasks);
  const user = useAppStore((s) => s.user);
  const sessions = useAppStore((s) => s.sessions);

  // Compute total studied seconds across all subjects
  const totalStudiedSeconds = subjects.reduce((acc, s) => acc + s.totalSecondsStudied, 0);
  const totalStudiedHours = Math.round((totalStudiedSeconds / 3600) * 10) / 10;

  // Real D-Day target exam calculation based on user.targetExamDate or end of academic semester
  const now = new Date();
  const examDate = user.targetExamDate ? new Date(user.targetExamDate) : new Date(now.getFullYear(), 5, 25);
  const diffDays = Math.max(1, Math.ceil((examDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24)));
  const dDayCountdown = diffDays;

  // Real weekly comparison from actual sessions
  const sevenDaysAgo = new Date(now.getTime() - 7 * 86400000);
  const fourteenDaysAgo = new Date(now.getTime() - 14 * 86400000);
  const thisWeekSecs = sessions
    .filter((s) => {
      try { return new Date(s.startedAt) >= sevenDaysAgo; } catch { return false; }
    })
    .reduce((sum, s) => sum + s.durationSeconds, 0);
  const lastWeekSecs = sessions
    .filter((s) => {
      try {
        const d = new Date(s.startedAt);
        return d >= fourteenDaysAgo && d < sevenDaysAgo;
      } catch { return false; }
    })
    .reduce((sum, s) => sum + s.durationSeconds, 0);

  const weeklyDiffPercent = lastWeekSecs > 0
    ? Math.round(((thisWeekSecs - lastWeekSecs) / lastWeekSecs) * 100)
    : (thisWeekSecs > 0 ? 100 : 0);

  // Real MIT goals fulfillment rate
  const mitTasks = tasks.filter((t) => t.isMIT);
  const completedMITs = mitTasks.filter((t) => t.status === 'completed');
  const mitRate = mitTasks.length > 0
    ? Math.round((completedMITs.length / mitTasks.length) * 100)
    : (tasks.length > 0 ? Math.round((tasks.filter(t => t.status === 'completed').length / tasks.length) * 100) : 100);

  return (
    <div className="flex-1 overflow-y-auto p-4 md:p-6 space-y-6 max-w-6xl mx-auto select-none">
      {/* Top Banner: D-Day & Focus Summary */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {/* D-Day Card */}
        <div className="p-4 md:p-5 rounded-squircle-lg bg-gradient-to-br from-accent-primary/20 via-canvas-elevated to-canvas-elevated border border-accent-primary/40 shadow-lg flex items-center justify-between">
          <div>
            <div className="flex items-center gap-1.5 text-xs font-bold text-accent-primary uppercase mb-1">
              <Target className="w-4 h-4" />
              <span>شمارش معکوس آزمون هدف (D-Day)</span>
            </div>
            <div className="text-2xl md:text-3xl font-black text-ink-primary font-mono tracking-tight">
              D-{formatToPersianDigits(dDayCountdown)}
            </div>
            <div className="text-xs text-ink-muted mt-1">کنکور و ارزشیابی جامع سراسری</div>
          </div>
          <div className="w-12 h-12 rounded-full bg-accent-primary/15 flex items-center justify-center text-accent-primary">
            <Sparkles className="w-6 h-6" />
          </div>
        </div>

        {/* Total Focus Hours */}
        <div className="p-4 md:p-5 rounded-squircle-lg bg-canvas-elevated border border-border-subtle shadow-sm flex items-center justify-between">
          <div>
            <div className="text-xs font-bold text-ink-muted uppercase mb-1">
              مجموع ساعت ثبت شده
            </div>
            <div className="text-2xl md:text-3xl font-black text-ink-primary font-mono">
              {formatToPersianDigits(totalStudiedHours)} ساعت
            </div>
            <div className="text-xs text-emerald-400 mt-1 flex items-center gap-1">
              <TrendingUp className="w-3.5 h-3.5" />
              <span>
                {weeklyDiffPercent >= 0
                  ? `${formatToPersianDigits(weeklyDiffPercent)}٪ رشد تمرکز هفتگی`
                  : `${formatToPersianDigits(Math.abs(weeklyDiffPercent))}٪ کمتر از هفته قبل`}
              </span>
            </div>
          </div>
        </div>

        {/* Daily Capacity Utilization */}
        <div className="p-4 md:p-5 rounded-squircle-lg bg-canvas-elevated border border-border-subtle shadow-sm flex items-center justify-between">
          <div>
            <div className="text-xs font-bold text-ink-muted uppercase mb-1">
              نرخ تحقق اهداف روزانه
            </div>
            <div className="text-2xl md:text-3xl font-black text-ink-primary font-mono">
              {formatToPersianDigits(mitRate)}%
            </div>
            <div className="text-xs text-ink-muted mt-1">
              {mitTasks.length > 0
                ? `${formatToPersianDigits(completedMITs.length)} از ${formatToPersianDigits(mitTasks.length)} اولویت طلایی امروز`
                : 'بر اساس اولویت‌های ثبت‌شده'}
            </div>
          </div>
        </div>
      </div>

      {/* YPT 24-Hour Timetable */}
      <Timetable24Hour />

      {/* GitHub/YPT-style Heatmap */}
      <HeatmapCalendar />

      {/* Subject Distribution Bars */}
      <div className="p-4 md:p-6 rounded-squircle-lg bg-canvas-elevated border border-border-subtle space-y-4">
        <h3 className="text-sm md:text-base font-bold text-ink-primary">
          تفکیک ساعات مطالعه بر اساس دروس و موضوعات
        </h3>

        <div className="space-y-3">
          {subjects.map((subj) => {
            const hours = Math.round((subj.totalSecondsStudied / 3600) * 10) / 10;
            const percentage = totalStudiedSeconds > 0 ? Math.round((subj.totalSecondsStudied / totalStudiedSeconds) * 100) : 0;

            return (
              <div key={subj.id} className="space-y-1.5">
                <div className="flex items-center justify-between text-xs md:text-sm">
                  <div className="flex items-center gap-2">
                    <span
                      className="w-2.5 h-2.5 rounded-full"
                      style={{ backgroundColor: subj.color }}
                    />
                    <span className="font-semibold text-ink-primary">{subj.name}</span>
                  </div>
                  <div className="flex items-center gap-2 font-mono text-ink-muted text-xs">
                    <span>{formatToPersianDigits(hours)} ساعت</span>
                    <span>({formatToPersianDigits(percentage)}%)</span>
                  </div>
                </div>

                {/* Progress Track */}
                <div className="h-2 rounded-full bg-white/5 overflow-hidden">
                  <div
                    className="h-full rounded-full transition-all duration-700 ease-out"
                    style={{
                      width: `${percentage}%`,
                      backgroundColor: subj.color,
                    }}
                  />
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
};
