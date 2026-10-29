import type { ThemePreset, AccentColorId } from '../types';

export interface AccentPreset {
  id: AccentColorId;
  name: string;
  nameEn: string;
  primary: string;
  hover: string;
  subtle: string;
  border: string;
}

export const ACCENT_PRESETS: AccentPreset[] = [
  {
    id: 'orange',
    name: 'نارنجی هم‌پا',
    nameEn: 'Flame Orange',
    primary: '#ff4700',
    hover: '#e03e00',
    subtle: 'rgba(255, 71, 0, 0.15)',
    border: 'rgba(255, 71, 0, 0.45)',
  },
  {
    id: 'blue',
    name: 'آبی تلگرام',
    nameEn: 'Telegram Blue',
    primary: '#2481cc',
    hover: '#1b6aa8',
    subtle: 'rgba(36, 129, 204, 0.15)',
    border: 'rgba(36, 129, 204, 0.45)',
  },
  {
    id: 'indigo',
    name: 'نیلی الکتریک',
    nameEn: 'Electric Indigo',
    primary: '#6366f1',
    hover: '#4f46e5',
    subtle: 'rgba(99, 102, 241, 0.15)',
    border: 'rgba(99, 102, 241, 0.45)',
  },
  {
    id: 'emerald',
    name: 'سبز زمردی',
    nameEn: 'Emerald Focus',
    primary: '#10b981',
    hover: '#059669',
    subtle: 'rgba(16, 185, 129, 0.15)',
    border: 'rgba(16, 185, 129, 0.45)',
  },
  {
    id: 'violet',
    name: 'بنفش رویال',
    nameEn: 'Royal Violet',
    primary: '#8b5cf6',
    hover: '#7c3aed',
    subtle: 'rgba(139, 92, 246, 0.15)',
    border: 'rgba(139, 92, 246, 0.45)',
  },
  {
    id: 'amber',
    name: 'کهربایی آفتابی',
    nameEn: 'Warm Amber',
    primary: '#f59e0b',
    hover: '#d97706',
    subtle: 'rgba(245, 158, 11, 0.15)',
    border: 'rgba(245, 158, 11, 0.45)',
  },
  {
    id: 'rose',
    name: 'رز نئونی',
    nameEn: 'Neon Rose',
    primary: '#f43f5e',
    hover: '#e11d48',
    subtle: 'rgba(244, 63, 94, 0.15)',
    border: 'rgba(244, 63, 94, 0.45)',
  },
];

export interface ThemeOption {
  id: ThemePreset;
  title: string;
  badge: string;
  description: string;
  isDark: boolean;
  bgHex: string;
  surfaceHex: string;
  previewHeaderHex: string;
  previewBubbleHex: string;
}

export const THEME_OPTIONS: ThemeOption[] = [
  {
    id: 'telegram',
    title: 'سرمه‌ای تلگرام',
    badge: 'Telegram Dark',
    description: 'رنگ‌آمیزی مشهور و کلاسیک تلگرام دسکتاپ با طیف سرمه‌ای عمیق',
    isDark: true,
    bgHex: '#0e1621',
    surfaceHex: '#17212b',
    previewHeaderHex: '#202b36',
    previewBubbleHex: '#242f3d',
  },
  {
    id: 'midnight',
    title: 'تیره آبسیدین',
    badge: 'Midnight AMOLED',
    description: 'مشکی خالص عمیق برای پنل‌های اولد و مطالعه شبانه بدون خستگی',
    isDark: true,
    bgHex: '#0c0a09',
    surfaceHex: '#141210',
    previewHeaderHex: '#1c1a17',
    previewBubbleHex: '#292524',
  },
  {
    id: 'day',
    title: 'روز مایندفول',
    badge: 'Mindful Clean',
    description: 'سفید مدرن و مینیمال با نور طبیعی، کنتراست بالا و تمرکز تمیز',
    isDark: false,
    bgHex: '#faf9f6',
    surfaceHex: '#ffffff',
    previewHeaderHex: '#f3f1ec',
    previewBubbleHex: '#e5e7eb',
  },
  {
    id: 'sepia',
    title: 'کاغذی گرم (سپیا)',
    badge: 'Warm Book Reader',
    description: 'طیف نسکافه‌ای گرم مشابه برگه‌های کتاب و کتابخوان‌های جوهر الکترونیک',
    isDark: false,
    bgHex: '#f4ede2',
    surfaceHex: '#fbf7f0',
    previewHeaderHex: '#ebe0d0',
    previewBubbleHex: '#dfd2be',
  },
];

export const applyThemeToDocument = (preset: ThemePreset, accentId: AccentColorId): void => {
  if (typeof document === 'undefined') return;
  const root = document.documentElement;

  // 1. Remove all old theme classes
  root.classList.remove('theme-midnight', 'theme-telegram', 'theme-day', 'theme-sepia', 'dark');

  // 2. Set active theme class
  root.classList.add(`theme-${preset}`);
  if (preset === 'midnight' || preset === 'telegram') {
    root.classList.add('dark');
  }

  // 3. Set accent color CSS variables
  const accent = ACCENT_PRESETS.find((a) => a.id === accentId) || ACCENT_PRESETS[0];
  root.style.setProperty('--accent-primary', accent.primary);
  root.style.setProperty('--accent-hover', accent.hover);
  root.style.setProperty('--accent-subtle', accent.subtle);
};
