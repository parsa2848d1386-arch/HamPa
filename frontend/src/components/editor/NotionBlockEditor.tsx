import React, { useState } from 'react';
import { 
  Plus, 
  Trash2, 
  CheckSquare, 
  Square, 
  Heading1, 
  Heading2, 
  Type, 
  Code, 
  AlertCircle, 
  Quote, 
  Minus,
  Sparkles
} from 'lucide-react';
import type { BlockNote, BlockType } from '../../types';
import { useAppStore } from '../../store/useAppStore';

interface NotionBlockEditorProps {
  taskId: string;
  blocks: BlockNote[];
}

export const NotionBlockEditor: React.FC<NotionBlockEditorProps> = ({ taskId, blocks }) => {
  const addBlockNote = useAppStore((s) => s.addBlockNote);
  const updateBlockNote = useAppStore((s) => s.updateBlockNote);
  const deleteBlockNote = useAppStore((s) => s.deleteBlockNote);

  const [activeSlashIndex, setActiveSlashIndex] = useState<number | null>(null);

  const blockTypeOptions: { type: BlockType; label: string; icon: React.ElementType }[] = [
    { type: 'text', label: 'متن ساده (Text)', icon: Type },
    { type: 'heading1', label: 'تیتر بزرگ (Heading 1)', icon: Heading1 },
    { type: 'heading2', label: 'تیتر متوسط (Heading 2)', icon: Heading2 },
    { type: 'checklist', label: 'چک‌لیست تعاملی (To-do)', icon: CheckSquare },
    { type: 'callout', label: 'کادر توجه (Callout)', icon: AlertCircle },
    { type: 'code', label: 'بلوک کد / فرمول (Code)', icon: Code },
    { type: 'quote', label: 'نقل‌قول (Quote)', icon: Quote },
    { type: 'divider', label: 'خط جداکننده (Divider)', icon: Minus },
  ];

  const handleInsertBlock = (type: BlockType) => {
    addBlockNote(taskId, {
      type,
      content: '',
      checked: false,
    });
    setActiveSlashIndex(null);
  };

  const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement | HTMLTextAreaElement>, index: number, block: BlockNote) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      addBlockNote(taskId, {
        type: block.type === 'checklist' ? 'checklist' : 'text',
        content: '',
        checked: false,
      });
    } else if (e.key === 'Backspace' && block.content === '' && blocks.length > 1) {
      e.preventDefault();
      deleteBlockNote(taskId, block.id);
    }
  };

  const handleContentChange = (index: number, block: BlockNote, value: string) => {
    if (value.startsWith('/')) {
      setActiveSlashIndex(index);
    } else {
      setActiveSlashIndex(null);
    }
    updateBlockNote(taskId, block.id, value);
  };

  return (
    <div className="space-y-2 py-2">
      <div className="flex items-center justify-between pb-2 border-b border-border-subtle mb-3">
        <span className="text-xs font-bold text-ink-muted uppercase tracking-wider flex items-center gap-1.5">
          <Sparkles className="w-3.5 h-3.5 text-accent-primary" />
          یادداشت‌های بلوکی نوشن (Block Notes)
        </span>
        <button
          onClick={() => handleInsertBlock('text')}
          className="flex items-center gap-1 px-2 py-0.5 rounded-precision text-xs text-ink-muted hover:text-ink-primary hover:bg-white/5 transition"
        >
          <Plus className="w-3.5 h-3.5" />
          <span>افزودن بلوک</span>
        </button>
      </div>

      {blocks.length === 0 ? (
        <div className="py-6 text-center border border-dashed border-border-subtle rounded-precision-md">
          <p className="text-xs text-ink-subtle mb-2">هنوز یادداشتی برای این تسک ثبت نشده است.</p>
          <button
            onClick={() => handleInsertBlock('text')}
            className="px-3 py-1 rounded-precision bg-white/5 hover:bg-white/10 text-xs font-medium text-ink-primary transition"
          >
            شروع یادداشت‌برداری با /
          </button>
        </div>
      ) : (
        blocks.map((block, index) => {
          return (
            <div key={block.id} className="group relative flex items-start gap-2 py-1">
              {/* Drag / Action Handle */}
              <div className="opacity-0 group-hover:opacity-100 transition flex items-center pt-1.5 -mr-1">
                <button
                  onClick={() => deleteBlockNote(taskId, block.id)}
                  className="p-1 rounded hover:bg-red-500/10 text-ink-subtle hover:text-red-400 transition"
                  title="حذف بلوک"
                >
                  <Trash2 className="w-3 h-3" />
                </button>
              </div>

              {/* Block Content Renderers */}
              <div className="flex-1 min-w-0">
                {block.type === 'heading1' && (
                  <input
                    type="text"
                    value={block.content}
                    onChange={(e) => handleContentChange(index, block, e.target.value)}
                    onKeyDown={(e) => handleKeyDown(e, index, block)}
                    placeholder="تیتر ۱..."
                    className="w-full bg-transparent text-lg md:text-xl font-black text-ink-primary outline-none border-b border-transparent focus:border-accent-primary/40 pb-0.5"
                  />
                )}

                {block.type === 'heading2' && (
                  <input
                    type="text"
                    value={block.content}
                    onChange={(e) => handleContentChange(index, block, e.target.value)}
                    onKeyDown={(e) => handleKeyDown(e, index, block)}
                    placeholder="تیتر ۲..."
                    className="w-full bg-transparent text-base md:text-lg font-bold text-ink-primary outline-none border-b border-transparent focus:border-accent-primary/40 pb-0.5"
                  />
                )}

                {block.type === 'checklist' && (
                  <div className="flex items-start gap-2">
                    <button
                      onClick={() => {
                        const updated = !block.checked;
                        useAppStore.getState().updateTask(taskId, {
                          blocks: blocks.map((b) => (b.id === block.id ? { ...b, checked: updated } : b))
                        });
                      }}
                      className="mt-1 text-ink-muted hover:text-accent-primary transition"
                    >
                      {block.checked ? (
                        <CheckSquare className="w-4 h-4 text-emerald-500" />
                      ) : (
                        <Square className="w-4 h-4" />
                      )}
                    </button>
                    <input
                      type="text"
                      value={block.content}
                      onChange={(e) => handleContentChange(index, block, e.target.value)}
                      onKeyDown={(e) => handleKeyDown(e, index, block)}
                      placeholder="آیتم چک‌لیست..."
                      className={`w-full bg-transparent text-sm outline-none ${
                        block.checked ? 'line-through text-ink-muted' : 'text-ink-primary'
                      }`}
                    />
                  </div>
                )}

                {block.type === 'callout' && (
                  <div className="p-3 rounded-precision-md bg-accent-primary/10 border border-accent-primary/20 flex items-start gap-2.5">
                    <AlertCircle className="w-4 h-4 text-accent-primary mt-0.5 flex-shrink-0" />
                    <textarea
                      rows={2}
                      value={block.content}
                      onChange={(e) => handleContentChange(index, block, e.target.value)}
                      placeholder="نکته مهم یا راهبرد کلیدی..."
                      className="w-full bg-transparent text-xs md:text-sm text-ink-primary outline-none resize-none"
                    />
                  </div>
                )}

                {block.type === 'code' && (
                  <div className="p-2.5 rounded-precision-md bg-black/60 border border-border-subtle font-mono text-xs text-amber-300">
                    <textarea
                      rows={3}
                      value={block.content}
                      onChange={(e) => handleContentChange(index, block, e.target.value)}
                      placeholder="// کد یا فرمول ریاضی LaTeX..."
                      className="w-full bg-transparent text-xs text-emerald-400 outline-none resize-none font-mono"
                    />
                  </div>
                )}

                {block.type === 'quote' && (
                  <div className="pr-3 border-r-2 border-accent-primary">
                    <input
                      type="text"
                      value={block.content}
                      onChange={(e) => handleContentChange(index, block, e.target.value)}
                      onKeyDown={(e) => handleKeyDown(e, index, block)}
                      placeholder="نقل‌قول..."
                      className="w-full bg-transparent text-sm italic text-ink-muted outline-none"
                    />
                  </div>
                )}

                {block.type === 'divider' && (
                  <div className="my-2 border-t border-border-subtle" />
                )}

                {block.type === 'text' && (
                  <input
                    type="text"
                    value={block.content}
                    onChange={(e) => handleContentChange(index, block, e.target.value)}
                    onKeyDown={(e) => handleKeyDown(e, index, block)}
                    placeholder="برای نوشتن تایپ کنید یا کلید / را فشار دهید..."
                    className="w-full bg-transparent text-sm text-ink-primary outline-none"
                  />
                )}

                {/* Slash Menu Popup */}
                {activeSlashIndex === index && (
                  <div className="absolute right-0 mt-1 z-30 w-64 rounded-precision-md bg-canvas-elevated liquid-glass border border-border-highlight shadow-xl p-1.5 space-y-1">
                    <div className="px-2 py-1 text-[10px] font-bold text-ink-muted uppercase">
                      تبدیل بلوک (Slash Command)
                    </div>
                    {blockTypeOptions.map((opt) => {
                      const Icon = opt.icon;
                      return (
                        <button
                          key={opt.type}
                          onClick={() => {
                            useAppStore.getState().updateTask(taskId, {
                              blocks: blocks.map((b) =>
                                b.id === block.id ? { ...b, type: opt.type, content: b.content.replace(/^\//, '') } : b
                              )
                            });
                            setActiveSlashIndex(null);
                          }}
                          className="w-full flex items-center gap-2 px-2.5 py-1.5 rounded-precision text-xs text-ink-primary hover:bg-accent-primary/20 hover:text-accent-primary transition text-right"
                        >
                          <Icon className="w-3.5 h-3.5" />
                          <span>{opt.label}</span>
                        </button>
                      );
                    })}
                  </div>
                )}
              </div>
            </div>
          );
        })
      )}
    </div>
  );
};
