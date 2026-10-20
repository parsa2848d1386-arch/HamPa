// Local Heuristic NLP Parser & Optional Gemini API Brain Dump Engine
import type { Priority } from '../types';

export interface ParsedDraftItem {
  id: string;
  title: string;
  startTime?: string;
  durationMinutes: number;
  color: string;
  category: string;
  suggestedSubtasks: string[];
  priority: Priority;
}

const CATEGORY_COLORS: Record<string, string> = {
  'ریاضی و هندسه': '#3B82F6', // Blue
  'فیزیک': '#8B5CF6',         // Purple
  'شیمی': '#EC4899',          // Pink
  'زیست‌شناسی': '#10B981',     // Emerald
  'برنامه‌نویسی و وب': '#FF4700', // Cron/HamPA Orange
  'زبان انگلیسی': '#F59E0B',   // Amber
  'مطالعه عمومی': '#6366F1',   // Indigo
  'ورزش و سلامت': '#14B8A6',   // Teal
};

export function parseBrainDumpText(rawText: string): ParsedDraftItem[] {
  if (!rawText.trim()) return [];

  // Split into lines or sentences
  const lines = rawText
    .split(/\n|(?<=[.!?؛])\s+/)
    .map(l => l.trim())
    .filter(l => l.length > 2);

  const items: ParsedDraftItem[] = [];
  let currentHourOffset = 9; // Default starting at 09:00 AM if no time mentioned

  for (const line of lines) {
    let cleanTitle = line;
    let duration = 45;
    let startTime: string | undefined = undefined;
    let priority: Priority = 'medium';

    // 1. Detect Priority
    if (/فوری|حیاتی|حتما|مهم|urgent|asap/i.test(line)) {
      priority = 'urgent';
      cleanTitle = cleanTitle.replace(/فوری|حیاتی|حتما|مهم|urgent|asap/gi, '').trim();
    }

    // 2. Detect Times: e.g. "ساعت 10", "14:30", "10:00"
    const timeMatch = line.match(/(?:ساعت\s*)?(\d{1,2})(?::(\d{2}))?\s*(صبح|عصر|شب)?/);
    if (timeMatch) {
      let hour = parseInt(timeMatch[1], 10);
      const min = timeMatch[2] ? parseInt(timeMatch[2], 10) : 0;
      const period = timeMatch[3];

      if (period === 'عصر' || period === 'شب') {
        if (hour < 12) hour += 12;
      }
      if (hour >= 0 && hour <= 23) {
        startTime = `${hour.toString().padStart(2, '0')}:${min.toString().padStart(2, '0')}`;
      }
    }

    // If no explicit time was found, assign sequential time blocks
    if (!startTime) {
      startTime = `${currentHourOffset.toString().padStart(2, '0')}:00`;
      currentHourOffset = (currentHourOffset + 1) % 22;
      if (currentHourOffset < 8) currentHourOffset = 8;
    }

    // 3. Detect Duration: e.g. "۲ ساعت", "30 دقیقه", "1.5 ساعت", "45 min"
    const durationMinMatch = line.match(/(\d+)\s*(?:دقیقه|دقیقه|min)/);
    const durationHourMatch = line.match(/(\d+(?:\.\d+)?)\s*(?:ساعت|ساعت|hour|hr)/);

    if (durationMinMatch) {
      duration = parseInt(durationMinMatch[1], 10);
    } else if (durationHourMatch) {
      duration = Math.round(parseFloat(durationHourMatch[1]) * 60);
    }

    // 4. Category and Color Prediction
    let category = 'مطالعه عمومی';
    let color = '#6366F1';
    let suggestedSubtasks: string[] = [];

    if (/ریاضی|حسابان|دیفرانسیل|جبر|آمار/i.test(line)) {
      category = 'ریاضی و هندسه';
      color = CATEGORY_COLORS[category];
      suggestedSubtasks = ['مرور فرمول‌ها و قضایا', 'حل تست‌های آموزشی', 'تحلیل تست‌های زمان‌دار'];
    } else if (/فیزیک|مکانیک|مغناطیس|الکتریسیته/i.test(line)) {
      category = 'فیزیک';
      color = CATEGORY_COLORS[category];
      suggestedSubtasks = ['خلاصه‌نویسی روابط', 'بررسی تمرین‌های کتاب', 'رفع اشکال مبحثی'];
    } else if (/شیمی|استوکیومتری|آلی|اسید/i.test(line)) {
      category = 'شیمی';
      color = CATEGORY_COLORS[category];
      suggestedSubtasks = ['مرور واکنش‌ها و حفظیات', 'محاسبات استوکیومتری', 'نکته‌برداری در دفترچه'];
    } else if (/زیست|ژنتیک|سلولی|گیاهی/i.test(line)) {
      category = 'زیست‌شناسی';
      color = CATEGORY_COLORS[category];
      suggestedSubtasks = ['خواندن دقیق متن کتاب درسی', 'حاشیه‌نویسی شکل‌ها', 'تست‌زنی ترکیبی و مفهومی'];
    } else if (/برنامه|کد|پروژه|react|flutter|frontend|باگ/i.test(line)) {
      category = 'برنامه‌نویسی و وب';
      color = CATEGORY_COLORS[category];
      suggestedSubtasks = ['طراحی ساختار ماژولار', 'پیاده‌سازی کامپوننت و لاجیک', 'تست و رفع خطاها'];
    } else if (/زبان|انگلیسی|لغت|گرامر|english/i.test(line)) {
      category = 'زبان انگلیسی';
      color = CATEGORY_COLORS[category];
      suggestedSubtasks = ['مرور فلش‌کارت لغات', 'تست کلوز تست و ریدینگ', 'تحلیل خطاهای لیسنینگ'];
    } else {
      suggestedSubtasks = ['آماده‌سازی پیش‌نیازها', 'اجرای مرحله اول', 'ارزیابی و جمع‌بندی'];
    }

    // Clean up title text from bullet prefixes and extra words
    cleanTitle = cleanTitle.replace(/^[-*•\d+.]\s*/, '').trim();

    items.push({
      id: `draft-${Date.now()}-${Math.random().toString(36).substring(2, 7)}`,
      title: cleanTitle,
      startTime,
      durationMinutes: duration,
      color,
      category,
      suggestedSubtasks,
      priority,
    });
  }

  return items;
}
