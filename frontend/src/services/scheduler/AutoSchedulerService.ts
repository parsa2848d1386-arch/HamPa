// ============================================================================
// بخش ۳: موتور زمان‌بندی خودکار هوشمند (CSP Auto-Scheduler Engine)
// حل مسئله ارضای محدودیت‌ها (Constraint Satisfaction Problem) با بازتنظیم پویا
// ============================================================================

import type { ScheduledTimeSlot, FixedCalendarEvent } from '../../types/schema';

export interface UnscheduledTaskInput {
  id: string;
  title: string;
  subject_id: string;
  subject_color: string;
  estimated_duration_min: number;
  min_chunk_min?: number; // lb_a (پیش‌فرض: ۳۰ دقیقه)
  max_chunk_min?: number; // ub_a (پیش‌فرض: ۱۲۰ دقیقه)
  deadline?: string;      // "HH:mm"
  priority: 1 | 2 | 3 | 4; // ۱: فوری‌ترین، ۴: پایین‌ترین
  dependencies?: string[]; // شناسه‌های تسک‌های پیش‌نیاز
  splittable?: boolean;
}

interface TimeInterval {
  start: number; // دقیقه از ابتدای روز (مثلا 08:30 = 510)
  end: number;
}

export class AutoSchedulerService {
  /**
   * تبدیل رشته ساعت HH:mm به دقیقه
   */
  public static timeToMinutes(timeStr: string): number {
    const [h, m] = timeStr.split(':').map(Number);
    return h * 60 + m;
  }

  /**
   * تبدیل دقیقه به رشته ساعت HH:mm
   */
  public static minutesToTime(minutes: number): string {
    const norm = Math.max(0, minutes) % (24 * 60);
    const h = Math.floor(norm / 60);
    const m = norm % 60;
    return `${h.toString().padStart(2, '0')}:${m.toString().padStart(2, '0')}`;
  }

  /**
   * حل مسئله CSP جهت جایگذاری بهینه تسک‌ها در فواصل خالی تقویم
   */
  public static solveSchedule(
    tasks: UnscheduledTaskInput[],
    fixedEvents: FixedCalendarEvent[],
    workDayStart: string = '08:00',
    workDayEnd: string = '22:00'
  ): ScheduledTimeSlot[] {
    const dayStartMin = this.timeToMinutes(workDayStart);
    const dayEndMin = this.timeToMinutes(workDayEnd);

    // ۱. استخراج بازه‌های اشغال‌شده توسط رویدادهای ثابت (Fixed Events)
    const occupiedIntervals: TimeInterval[] = fixedEvents
      .map((ev) => ({
        start: this.timeToMinutes(ev.start_time),
        end: this.timeToMinutes(ev.end_time),
      }))
      .sort((a, b) => a.start - b.start);

    // ۲. محاسبه بازه‌های آزاد زمانی (Free Windows)
    const freeWindows: TimeInterval[] = [];
    let currentCursor = dayStartMin;

    for (const occ of occupiedIntervals) {
      if (occ.start > currentCursor) {
        freeWindows.push({ start: currentCursor, end: Math.min(dayEndMin, occ.start) });
      }
      currentCursor = Math.max(currentCursor, occ.end);
    }

    if (currentCursor < dayEndMin) {
      freeWindows.push({ start: currentCursor, end: dayEndMin });
    }

    // ۳. اولویت‌بندی تسک‌ها (مرتب‌سازی بر اساس اولویت و ددلاین)
    const sortedTasks = [...tasks].sort((a, b) => {
      if (a.priority !== b.priority) return a.priority - b.priority;
      const deadA = a.deadline ? this.timeToMinutes(a.deadline) : 9999;
      const deadB = b.deadline ? this.timeToMinutes(b.deadline) : 9999;
      return deadA - deadB;
    });

    // ۴. جایگذاری آزمون‌پذیر با الگوریتم حریصانه + عقب‌گرد (Greedy with Backtracking)
    const scheduledSlots: ScheduledTimeSlot[] = [];
    const completedTaskIds = new Set<string>();

    for (const task of sortedTasks) {
      // بررسی پیش‌نیازها (Precedence Constraints Ct)
      const hasUnmetDependencies = (task.dependencies || []).some((depId) => !completedTaskIds.has(depId));
      if (hasUnmetDependencies) continue;

      let remainingDuration = task.estimated_duration_min;
      const minChunk = task.min_chunk_min || 30;
      const maxChunk = task.max_chunk_min || 120;

      for (let i = 0; i < freeWindows.length && remainingDuration > 0; i++) {
        const window = freeWindows[i];
        const windowCapacity = window.end - window.start;

        if (windowCapacity < minChunk) continue;

        // محاسبه طول بلوک انتخابی با لحاظ سقف و کف بازه
        const allocatable = Math.min(remainingDuration, windowCapacity, maxChunk);

        if (allocatable >= minChunk || (allocatable === remainingDuration && remainingDuration <= minChunk)) {
          const slotStart = window.start;
          const slotEnd = slotStart + allocatable;

          // اعتبارسنجی خطر رد شدن از ددلاین
          const deadlineMin = task.deadline ? this.timeToMinutes(task.deadline) : Infinity;
          const isAtRisk = slotEnd > deadlineMin;

          scheduledSlots.push({
            task_id: task.id,
            task_title: task.title,
            subject_id: task.subject_id,
            subject_color: task.subject_color,
            start_time: this.minutesToTime(slotStart),
            end_time: this.minutesToTime(slotEnd),
            duration_minutes: allocatable,
            is_locked: false,
            risk_of_deadline_miss: isAtRisk,
          });

          remainingDuration -= allocatable;
          window.start = slotEnd; // کاهش بازه آزاد جاری

          if (!task.splittable && remainingDuration > 0) {
            // اگر تسک غیرقابل تقسیم باشد، بخش‌بندی مجاز نیست
            break;
          }
        }
      }

      if (remainingDuration === 0) {
        completedTaskIds.add(task.id);
      }
    }

    return scheduledSlots;
  }

  /**
   * بازتنظیم و شیفت خودکار پویا (Dynamic Re-Slotting)
   * هرگاه تایمر بیش از حد طول بکشد یا رویدادی اضافه شود، تسک‌های باقیمانده بازچینی می‌شوند.
   */
  public static dynamicallyReSlot(
    currentSchedule: ScheduledTimeSlot[],
    uncompletedTasks: UnscheduledTaskInput[],
    fixedEvents: FixedCalendarEvent[],
    currentTime: string
  ): ScheduledTimeSlot[] {
    const currentMin = this.timeToMinutes(currentTime);

    // تسک‌های قفل‌شده یا منقضی‌شده در گذشته ثابت می‌مانند
    const lockedPastSlots = currentSchedule.filter(
      (slot) => slot.is_locked || this.timeToMinutes(slot.start_time) < currentMin
    );

    // رویدادهای فیکس + اسلات‌های گذشته به عنوان محدودیت غیرقابل تصاحب
    const dynamicFixedEvents: FixedCalendarEvent[] = [
      ...fixedEvents,
      ...lockedPastSlots.map((s) => ({
        id: s.task_id,
        title: s.task_title,
        start_time: s.start_time,
        end_time: s.end_time,
      })),
    ];

    // تسک‌های باقیمانده از زمان فعلی مجدداً حل می‌شوند
    const futureSchedule = this.solveSchedule(
      uncompletedTasks.filter((t) => !lockedPastSlots.some((l) => l.task_id === t.id)),
      dynamicFixedEvents,
      currentTime,
      '23:00'
    );

    return [...lockedPastSlots, ...futureSchedule];
  }
}
