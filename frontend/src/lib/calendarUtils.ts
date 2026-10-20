// Accurate and lightweight Jalali (Solar Hijri) <-> Gregorian algorithm
export interface JalaliDate {
  jy: number; // Jalali year (e.g. 1405)
  jm: number; // Jalali month (1-12)
  jd: number; // Jalali day (1-31)
}

export const PERSIAN_MONTHS = [
  'فروردین', 'اردیبهشت', 'خرداد',
  'تیر', 'مرداد', 'شهریور',
  'مهر', 'آبان', 'آذر',
  'دی', 'بهمن', 'اسفند'
];

export const PERSIAN_WEEKDAYS = [
  'شنبه', 'یکشنبه', 'دوشنبه',
  'سه‌شنبه', 'چهارشنبه', 'پنج‌شنبه', 'جمعه'
];

export const PERSIAN_WEEKDAYS_SHORT = [
  'ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'
];

// Jalaali conversion core
export function gregorianToJalali(gy: number, gm: number, gd: number): JalaliDate {
  const g_d_m = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
  let jy: number;
  if (gy > 1600) {
    jy = 979;
    gy -= 1600;
  } else {
    jy = 0;
    gy -= 621;
  }
  const gy2 = gm > 2 ? gy + 1 : gy;
  let days = 365 * gy + Math.floor((gy2 + 3) / 4) - Math.floor((gy2 + 99) / 100) + Math.floor((gy2 + 399) / 400) - 80 + gd + g_d_m[gm - 1];
  jy += 33 * Math.floor(days / 12053);
  days %= 12053;
  jy += 4 * Math.floor(days / 1461);
  days %= 1461;
  if (days > 365) {
    jy += Math.floor((days - 1) / 365);
    days = (days - 1) % 365;
  }
  let jm: number;
  let jd: number;
  if (days < 186) {
    jm = 1 + Math.floor(days / 31);
    jd = 1 + (days % 31);
  } else {
    jm = 7 + Math.floor((days - 186) / 30);
    jd = 1 + ((days - 186) % 30);
  }
  return { jy, jm, jd };
}

export function jalaliToGregorian(jy: number, jm: number, jd: number): { gy: number; gm: number; gd: number } {
  let gy: number;
  if (jy > 979) {
    gy = 1600;
    jy -= 979;
  } else {
    gy = 621;
  }
  let days = 365 * jy + Math.floor(jy / 33) * 8 + Math.floor(((jy % 33) + 3) / 4) + 78 + jd + (jm < 7 ? (jm - 1) * 31 : (jm - 7) * 30 + 186);
  gy += 400 * Math.floor(days / 146097);
  days %= 146097;
  if (days > 36524) {
    gy += 100 * Math.floor(--days / 36524);
    days %= 36524;
    if (days >= 365) days++;
  }
  gy += 4 * Math.floor(days / 1461);
  days %= 1461;
  if (days > 365) {
    gy += Math.floor((days - 1) / 365);
    days = (days - 1) % 365;
  }
  const sal_a = [0, 31, ((gy % 4 === 0 && gy % 100 !== 0) || gy % 400 === 0) ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
  let gm = 0;
  while (gm < 13 && days >= sal_a[gm]) {
    days -= sal_a[gm];
    gm++;
  }
  return { gy, gm, gd: days + 1 };
}

export function formatToPersianDigits(num: number | string): string {
  const pDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
  return num.toString().replace(/[0-9]/g, (w) => pDigits[+w]);
}

export function formatDateTitle(date: Date, system: 'jalali' | 'gregorian' = 'jalali'): string {
  if (system === 'jalali') {
    const j = gregorianToJalali(date.getFullYear(), date.getMonth() + 1, date.getDate());
    const dayOfWeek = (date.getDay() + 1) % 7; // Saturday = 0 in Iranian week
    const weekName = PERSIAN_WEEKDAYS[dayOfWeek];
    const monthName = PERSIAN_MONTHS[j.jm - 1];
    return `${weekName}، ${formatToPersianDigits(j.jd)} ${monthName} ${formatToPersianDigits(j.jy)}`;
  } else {
    return date.toLocaleDateString('en-US', {
      weekday: 'short',
      month: 'short',
      day: 'numeric',
      year: 'numeric'
    });
  }
}

export function formatShortDate(date: Date, system: 'jalali' | 'gregorian' = 'jalali'): string {
  if (system === 'jalali') {
    const j = gregorianToJalali(date.getFullYear(), date.getMonth() + 1, date.getDate());
    return `${formatToPersianDigits(j.jd)} ${PERSIAN_MONTHS[j.jm - 1]}`;
  } else {
    return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
  }
}

export function getTodayKey(): string {
  const now = new Date();
  return now.toISOString().split('T')[0];
}

// Generate the 144 10-minute slots starting at 05:00 AM (YPT 24-hour cycle)
export function getTimetableSlots(): { index: number; timeStr: string; hour: number; minute: number }[] {
  const slots: { index: number; timeStr: string; hour: number; minute: number }[] = [];
  for (let i = 0; i < 144; i++) {
    const totalMinutes = 5 * 60 + i * 10;
    const hour = Math.floor(totalMinutes / 60) % 24;
    const minute = totalMinutes % 60;
    const hh = hour.toString().padStart(2, '0');
    const mm = minute.toString().padStart(2, '0');
    slots.push({
      index: i,
      timeStr: `${hh}:${mm}`,
      hour,
      minute
    });
  }
  return slots;
}
