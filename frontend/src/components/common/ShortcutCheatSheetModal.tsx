import React from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X, Keyboard } from 'lucide-react';
import { useAppStore } from '../../store/useAppStore';

const SHORTCUTS = [
  { key: 'Cmd + K', desc: 'باز کردن پالت دستورات سریع (Command Palette)' },
  { key: 'Alt + S', desc: 'باز کردن تنظیمات، تم‌های تلگرامی و پروفایل کاربر' },
  { key: 'H', desc: 'تغییر به داشبورد اصلی چندپنجره‌ای ویجت‌ها' },
  { key: 'C', desc: 'ایجاد تسک یا بلوک جدید در زمان جاری' },
  { key: 'T', desc: 'پرش به امروز و همگام‌سازی زمان‌سنج' },
  { key: 'D', desc: 'تغییر به نمای روزانه (Day Timeline)' },
  { key: 'W', desc: 'تغییر به نمای هفتگی (Week Grid)' },
  { key: 'M', desc: 'تغییر به نمای ماهانه (Month View)' },
  { key: 'F', desc: 'شروع سشن تمرکز استودیویی (Focus Mode)' },
  { key: 'B', desc: 'باز کردن هوش مصنوعی Brain Dump (ذهن‌ریزی)' },
  { key: '?', desc: 'نمایش همین راهنمای کلیدهای میانبر' },
];

export const ShortcutCheatSheetModal: React.FC = () => {
  const isOpen = useAppStore((s) => s.isCheatSheetOpen);
  const setOpen = useAppStore((s) => s.setCheatSheetOpen);

  if (!isOpen) return null;

  return (
    <AnimatePresence>
      <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
        {/* Backdrop */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          onClick={() => setOpen(false)}
          className="fixed inset-0 bg-black/70 backdrop-blur-md"
        />

        {/* Modal Window */}
        <motion.div
          initial={{ opacity: 0, scale: 0.95, y: 15 }}
          animate={{ opacity: 1, scale: 1, y: 0 }}
          exit={{ opacity: 0, scale: 0.95, y: 15 }}
          transition={{ type: 'spring', stiffness: 400, damping: 30, mass: 0.8 }}
          className="relative z-10 w-full max-w-lg rounded-squircle-lg bg-canvas-elevated border border-border-highlight shadow-2xl p-6 overflow-hidden"
        >
          {/* Header */}
          <div className="flex items-center justify-between pb-4 border-b border-border-subtle">
            <div className="flex items-center gap-3">
              <div className="w-9 h-9 rounded-precision-md bg-accent-primary/10 flex items-center justify-center text-accent-primary">
                <Keyboard className="w-5 h-5" />
              </div>
              <div>
                <h3 className="text-base font-bold text-ink-primary">کلیدهای میانبر سرعت بالا</h3>
                <p className="text-xs text-ink-muted">کار با صفحه کلید بدون نیاز به ماوس (Zero-Mouse Velocity)</p>
              </div>
            </div>
            <button
              onClick={() => setOpen(false)}
              className="p-2 rounded-full hover:bg-white/10 text-ink-muted hover:text-ink-primary transition"
            >
              <X className="w-5 h-5" />
            </button>
          </div>

          {/* List */}
          <div className="mt-4 space-y-2.5 max-h-[60vh] overflow-y-auto pr-1">
            {SHORTCUTS.map((sc, i) => (
              <div
                key={i}
                className="flex items-center justify-between p-2.5 rounded-precision-md bg-canvas-secondary/50 border border-border-subtle text-sm"
              >
                <span className="text-ink-muted text-xs md:text-sm">{sc.desc}</span>
                <kbd className="px-2.5 py-1 rounded-precision bg-black/40 border border-border-highlight font-mono text-xs font-semibold text-accent-primary shadow-sm tracking-wider">
                  {sc.key}
                </kbd>
              </div>
            ))}
          </div>

          {/* Footer */}
          <div className="mt-5 pt-3 border-t border-border-subtle flex justify-end">
            <button
              onClick={() => setOpen(false)}
              className="px-4 py-2 rounded-precision-md bg-white/10 hover:bg-white/15 text-sm font-medium text-ink-primary transition"
            >
              متوجه شدم
            </button>
          </div>
        </motion.div>
      </div>
    </AnimatePresence>
  );
};
