import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  Sparkles, 
  Mic, 
  MicOff, 
  X, 
  Calendar, 
  Clock, 
  Check, 
  Trash2, 
  ArrowLeft,
  SlidersHorizontal
} from 'lucide-react';
import { useAppStore } from '../../store/useAppStore';
import { parseBrainDumpText } from '../../lib/brainDumpParser';
import type { ParsedDraftItem } from '../../lib/brainDumpParser';
import confetti from 'canvas-confetti';

export const AIBrainDumpDrawer: React.FC = () => {
  const isOpen = useAppStore((s) => s.isBrainDumpOpen);
  const setOpen = useAppStore((s) => s.setBrainDumpOpen);
  const applyBrainDumpDrafts = useAppStore((s) => s.applyBrainDumpDrafts);

  const [rawText, setRawText] = useState('');
  const [draftItems, setDraftItems] = useState<ParsedDraftItem[]>([]);
  const [isRecording, setIsRecording] = useState(false);

  if (!isOpen) return null;

  const handleParse = (text: string) => {
    setRawText(text);
    const parsed = parseBrainDumpText(text);
    setDraftItems(parsed);
  };

  // Web Speech API Voice Dictation
  const handleToggleVoice = () => {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const win = window as any;
    const SpeechRecognitionClass = win.SpeechRecognition || win.webkitSpeechRecognition;

    if (!SpeechRecognitionClass) {
      alert('مرورگر شما از قابلیت تشخیص گفتار صوتی پشتیبانی نمی‌کند.');
      return;
    }

    if (isRecording) {
      setIsRecording(false);
      return;
    }

    try {
      const recognition = new SpeechRecognitionClass();
      recognition.lang = 'fa-IR';
      recognition.interimResults = false;

      recognition.onstart = () => setIsRecording(true);
      recognition.onend = () => setIsRecording(false);
      recognition.onerror = () => setIsRecording(false);

      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      recognition.onresult = (event: any) => {
        const transcript = event.results[0][0].transcript;
        const newText = rawText ? `${rawText}\n${transcript}` : transcript;
        handleParse(newText);
      };

      recognition.start();
    } catch {
      setIsRecording(false);
    }
  };

  const handleUpdateItem = (id: string, updates: Partial<ParsedDraftItem>) => {
    setDraftItems((items) =>
      items.map((it) => (it.id === id ? { ...it, ...updates } : it))
    );
  };

  const handleDeleteItem = (id: string) => {
    setDraftItems((items) => items.filter((it) => it.id !== id));
  };

  const handleApply = () => {
    if (draftItems.length === 0) return;
    applyBrainDumpDrafts(draftItems);
    confetti({
      particleCount: 90,
      spread: 70,
      origin: { y: 0.6 }
    });
    setRawText('');
    setDraftItems([]);
  };

  const samplePrompt = "ساعت ۱۰ تا ۱۱:۳۰ حل تست شیمی مبحث اسیدها\nساعت ۱۵ مطالعه فصل ۴ فیزیک ۲ ساعت خیلی مهم\nبررسی باگ‌های پروژه فرانت‌اند ساعت ۱۸ ۴۵ دقیقه";

  return (
    <AnimatePresence>
      <div className="fixed inset-0 z-50 flex items-center justify-center p-3 md:p-6 select-none">
        {/* Backdrop */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          onClick={() => setOpen(false)}
          className="fixed inset-0 bg-black/70 backdrop-blur-md"
        />

        {/* Drawer Window */}
        <motion.div
          initial={{ opacity: 0, scale: 0.96, y: 15 }}
          animate={{ opacity: 1, scale: 1, y: 0 }}
          exit={{ opacity: 0, scale: 0.96, y: 15 }}
          transition={{ type: 'spring', stiffness: 400, damping: 30, mass: 0.8 }}
          className="relative z-10 w-full max-w-2xl max-h-[90vh] rounded-squircle-sheet bg-canvas-elevated liquid-glass border border-border-highlight shadow-2xl p-6 flex flex-col overflow-hidden"
        >
          {/* Header */}
          <div className="flex items-center justify-between pb-4 border-b border-border-subtle">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-precision-md bg-accent-primary/20 text-accent-primary flex items-center justify-center shadow-needle">
                <Sparkles className="w-5 h-5" />
              </div>
              <div>
                <h3 className="text-base font-bold text-ink-primary">
                  هوش مصنوعی Brain Dump (ذهن‌ریزی هوشمند)
                </h3>
                <p className="text-xs text-ink-muted">
                  افکار یا برنامه پراکنده روزتان را بنویسید یا بگویید تا به بلوک‌های منظم تایم‌لاین تبدیل شوند
                </p>
              </div>
            </div>

            <button
              onClick={() => setOpen(false)}
              className="p-2 rounded-full hover:bg-white/10 text-ink-muted hover:text-ink-primary transition"
            >
              <X className="w-5 h-5" />
            </button>
          </div>

          {/* Content Area */}
          <div className="flex-1 overflow-y-auto py-4 space-y-4 pr-1">
            {/* Input Bar & Voice dictation */}
            <div className="relative rounded-precision-md bg-canvas-secondary/80 border border-border-subtle p-3">
              <textarea
                rows={3}
                value={rawText}
                onChange={(e) => handleParse(e.target.value)}
                placeholder="اینجا بنویسید... (مثال: فردا ساعت ۱۰ تا ۱۱:۳۰ حل تست شیمی، عصر ساعت ۱۶ فیزیک ۲ ساعت، فوری)"
                className="w-full bg-transparent text-sm text-ink-primary outline-none resize-none font-vazir placeholder:text-ink-subtle"
              />

              <div className="flex items-center justify-between pt-2 border-t border-border-subtle/50 text-xs">
                <button
                  onClick={() => handleParse(samplePrompt)}
                  className="text-[11px] text-accent-primary hover:underline"
                >
                  درج نمونه آزمایشی
                </button>

                <button
                  onClick={handleToggleVoice}
                  className={`flex items-center gap-1.5 px-3 py-1 rounded-precision text-xs font-semibold transition ${
                    isRecording
                      ? 'bg-red-500 text-white animate-pulse'
                      : 'bg-white/10 hover:bg-white/15 text-ink-primary'
                  }`}
                >
                  {isRecording ? <MicOff className="w-3.5 h-3.5" /> : <Mic className="w-3.5 h-3.5" />}
                  <span>{isRecording ? 'در حال شنیدن...' : 'ورودی صوتی'}</span>
                </button>
              </div>
            </div>

            {/* Interactive Staging Draft Section */}
            {draftItems.length > 0 && (
              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-bold text-ink-muted uppercase flex items-center gap-1.5">
                    <SlidersHorizontal className="w-3.5 h-3.5 text-accent-primary" />
                    پیش‌نویس تعاملی تفکیک‌شده (Staging Draft):
                  </span>
                  <span className="text-xs font-mono text-ink-muted">
                    {draftItems.length} تسک استخراج شد
                  </span>
                </div>

                <div className="space-y-2.5">
                  {draftItems.map((item) => (
                    <div
                      key={item.id}
                      className="p-3.5 rounded-precision-md bg-canvas-secondary border border-border-subtle space-y-2.5"
                    >
                      {/* Top Row: Title, Color & Delete */}
                      <div className="flex items-center justify-between gap-2">
                        <div className="flex items-center gap-2 flex-1">
                          <input
                            type="color"
                            value={item.color}
                            onChange={(e) => handleUpdateItem(item.id, { color: e.target.value })}
                            className="w-6 h-6 rounded cursor-pointer border-0 bg-transparent"
                            title="تغییر رنگ دسته‌بندی"
                          />
                          <input
                            type="text"
                            value={item.title}
                            onChange={(e) => handleUpdateItem(item.id, { title: e.target.value })}
                            className="flex-1 bg-transparent text-sm font-semibold text-ink-primary outline-none border-b border-transparent focus:border-accent-primary/40"
                          />
                        </div>

                        <button
                          onClick={() => handleDeleteItem(item.id)}
                          className="p-1.5 rounded hover:bg-red-500/10 text-ink-subtle hover:text-red-400 transition"
                        >
                          <Trash2 className="w-3.5 h-3.5" />
                        </button>
                      </div>

                      {/* Time & Duration Controls */}
                      <div className="flex items-center gap-4 text-xs font-mono text-ink-muted">
                        <div className="flex items-center gap-1.5">
                          <Clock className="w-3.5 h-3.5 text-accent-primary" />
                          <span>ساعت شروع:</span>
                          <input
                            type="time"
                            value={item.startTime || '09:00'}
                            onChange={(e) => handleUpdateItem(item.id, { startTime: e.target.value })}
                            className="bg-black/30 border border-border-subtle rounded px-1.5 py-0.5 text-ink-primary text-xs outline-none"
                          />
                        </div>

                        <div className="flex items-center gap-1.5">
                          <span>مدت:</span>
                          <input
                            type="number"
                            min="15"
                            step="15"
                            value={item.durationMinutes}
                            onChange={(e) => handleUpdateItem(item.id, { durationMinutes: parseInt(e.target.value, 10) || 30 })}
                            className="w-14 bg-black/30 border border-border-subtle rounded px-1.5 py-0.5 text-ink-primary text-xs outline-none"
                          />
                          <span>دقیقه</span>
                        </div>
                      </div>

                      {/* Suggested Micro-Subtasks */}
                      {item.suggestedSubtasks.length > 0 && (
                        <div className="pt-2 border-t border-border-subtle/50 space-y-1">
                          <span className="text-[10px] text-ink-subtle uppercase">
                            ریزتسک‌های پیشنهادی هوش مصنوعی:
                          </span>
                          <div className="flex flex-wrap gap-1.5">
                            {item.suggestedSubtasks.map((st, idx) => (
                              <span
                                key={idx}
                                className="px-2 py-0.5 rounded-precision bg-white/5 border border-border-subtle text-[11px] text-ink-muted"
                              >
                                ✓ {st}
                              </span>
                            ))}
                          </div>
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>

          {/* Footer Actions */}
          <div className="flex items-center justify-between pt-4 border-t border-border-subtle">
            <button
              onClick={() => setOpen(false)}
              className="px-4 py-2 rounded-precision-md hover:bg-white/5 text-xs text-ink-muted transition"
            >
              انصراف
            </button>

            <button
              disabled={draftItems.length === 0}
              onClick={handleApply}
              className={`flex items-center gap-2 px-6 py-2.5 rounded-precision-md text-xs font-bold transition shadow-needle ${
                draftItems.length > 0
                  ? 'bg-accent-primary hover:bg-accent-hover text-white active:scale-95'
                  : 'bg-white/10 text-ink-subtle cursor-not-allowed'
              }`}
            >
              <Check className="w-4 h-4" />
              <span>اعمال در تایم‌لاین ({draftItems.length} تسک)</span>
            </button>
          </div>
        </motion.div>
      </div>
    </AnimatePresence>
  );
};
