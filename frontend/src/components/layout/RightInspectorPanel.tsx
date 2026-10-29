import React, { useState } from 'react';
import { 
  X, 
  Clock, 
  Tag, 
  Trash2, 
  CheckCircle2, 
  Circle, 
  Plus, 
  Sparkles,
  Flame,
  Calendar,
  Layers
} from 'lucide-react';
import { useAppStore } from '../../store/useAppStore';
import { NotionBlockEditor } from '../editor/NotionBlockEditor';
import { formatToPersianDigits } from '../../lib/calendarUtils';

export const RightInspectorPanel: React.FC = () => {
  const isOpen = useAppStore((s) => s.isRightInspectorOpen);
  const toggleInspector = useAppStore((s) => s.toggleRightInspector);
  const selectedTaskId = useAppStore((s) => s.selectedTaskId);
  const tasks = useAppStore((s) => s.tasks);
  const updateTask = useAppStore((s) => s.updateTask);
  const deleteTask = useAppStore((s) => s.deleteTask);
  const toggleSubtask = useAppStore((s) => s.toggleSubtask);
  const subjects = useAppStore((s) => s.subjects);

  const [newSubtaskTitle, setNewSubtaskTitle] = useState('');

  if (!isOpen || !selectedTaskId) return null;

  const task = tasks.find((t) => t.id === selectedTaskId);
  if (!task) return null;

  const handleAddSubtask = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newSubtaskTitle.trim()) return;

    const newSubtask = {
      id: `st-${Date.now()}`,
      title: newSubtaskTitle.trim(),
      completed: false,
    };

    updateTask(task.id, {
      subtasks: [...task.subtasks, newSubtask]
    });
    setNewSubtaskTitle('');
  };

  const currentSubject = subjects.find((s) => s.id === task.subjectId);

  return (
    <>
      {/* Mobile Backdrop Overlay (only on < lg, below header) */}
      <div 
        onClick={toggleInspector} 
        className="fixed inset-x-0 bottom-0 top-14 bg-black/60 backdrop-blur-sm z-30 lg:hidden"
        aria-hidden="true" 
      />

      <aside className="fixed inset-y-0 left-0 z-50 w-full sm:w-96 lg:static lg:w-80 xl:w-96 border-r border-border-subtle bg-canvas-elevated liquid-glass flex flex-col h-full overflow-hidden select-none shadow-2xl lg:shadow-none transition-transform duration-300">
        {/* Header */}
        <div className="flex items-center justify-between px-4 py-3 border-b border-border-subtle">
          <div className="flex items-center gap-2">
            <Layers className="w-4 h-4 text-accent-primary" />
            <span className="text-xs font-bold text-ink-muted uppercase">
              پنل بازرسی تسک و یادداشت‌ها
            </span>
          </div>

        <button
          onClick={toggleInspector}
          className="p-1 rounded-full hover:bg-white/10 text-ink-muted hover:text-ink-primary transition"
        >
          <X className="w-4 h-4" />
        </button>
      </div>

      {/* Body Scrollable Content */}
      <div className="flex-1 overflow-y-auto p-4 space-y-5">
        {/* Task Title */}
        <div className="space-y-1">
          <input
            type="text"
            value={task.title}
            onChange={(e) => updateTask(task.id, { title: e.target.value })}
            className="w-full bg-transparent text-base md:text-lg font-bold text-ink-primary outline-none border-b border-transparent focus:border-accent-primary/40 pb-1"
          />

          {/* Subject Badge */}
          {currentSubject && (
            <div className="flex items-center gap-1.5 pt-1">
              <span
                className="w-2.5 h-2.5 rounded-full"
                style={{ backgroundColor: currentSubject.color }}
              />
              <span className="text-xs text-ink-muted font-medium">
                {currentSubject.name}
              </span>
            </div>
          )}
        </div>

        {/* Task Properties Grid */}
        <div className="space-y-2.5 p-3 rounded-precision-md bg-canvas-secondary/50 border border-border-subtle text-xs">
          <div className="flex items-center justify-between">
            <span className="text-ink-muted flex items-center gap-1.5">
              <Clock className="w-3.5 h-3.5 text-accent-primary" />
              زمان‌بندی:
            </span>
            <div className="flex items-center gap-1 font-mono text-ink-primary">
              <input
                type="time"
                value={task.startTime || '09:00'}
                onChange={(e) => updateTask(task.id, { startTime: e.target.value })}
                className="bg-black/30 px-1 py-0.5 rounded border border-border-subtle text-[11px]"
              />
              <span>•</span>
              <input
                type="number"
                min="0"
                step="15"
                value={task.durationMinutes}
                onChange={(e) => updateTask(task.id, { durationMinutes: parseInt(e.target.value, 10) || 0 })}
                className="w-12 bg-black/30 px-1 py-0.5 rounded border border-border-subtle text-[11px]"
              />
              <span>دقیقه</span>
            </div>
          </div>

          <div className="flex items-center justify-between">
            <span className="text-ink-muted flex items-center gap-1.5">
              <Flame className="w-3.5 h-3.5 text-amber-500" />
              اولویت:
            </span>
            <select
              value={task.priority}
              onChange={(e) => updateTask(task.id, { priority: e.target.value as any })}
              className="bg-black/30 border border-border-subtle rounded px-2 py-0.5 text-[11px] text-ink-primary outline-none"
            >
              <option value="low">کم (Low)</option>
              <option value="medium">متوسط (Medium)</option>
              <option value="high">بالا (High)</option>
              <option value="urgent">فوری (Urgent)</option>
            </select>
          </div>

          <div className="flex items-center justify-between">
            <span className="text-ink-muted flex items-center gap-1.5">
              <Sparkles className="w-3.5 h-3.5 text-amber-400" />
              تسک برتر (MIT):
            </span>
            <button
              onClick={() => updateTask(task.id, { isMIT: !task.isMIT })}
              className={`px-2 py-0.5 rounded text-[11px] font-bold transition ${
                task.isMIT
                  ? 'bg-amber-500 text-white shadow-sm'
                  : 'bg-white/10 text-ink-muted hover:text-ink-primary'
              }`}
            >
              {task.isMIT ? 'فعال (MIT)' : 'غیرفعال'}
            </button>
          </div>
        </div>

        {/* Subtasks Section */}
        <div className="space-y-2">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-ink-muted uppercase">
              ریزتسک‌ها (Subtasks)
            </span>
            <span className="text-[11px] font-mono text-ink-subtle">
              {task.subtasks.filter((s) => s.completed).length} / {task.subtasks.length}
            </span>
          </div>

          <div className="space-y-1">
            {task.subtasks.map((st) => (
              <div
                key={st.id}
                onClick={() => toggleSubtask(task.id, st.id)}
                className="flex items-center gap-2 p-1.5 rounded hover:bg-white/5 cursor-pointer text-xs"
              >
                {st.completed ? (
                  <CheckCircle2 className="w-4 h-4 text-emerald-500 flex-shrink-0" />
                ) : (
                  <Circle className="w-4 h-4 text-ink-muted flex-shrink-0" />
                )}
                <span className={`flex-1 ${st.completed ? 'line-through text-ink-muted' : 'text-ink-primary'}`}>
                  {st.title}
                </span>
              </div>
            ))}

            <form onSubmit={handleAddSubtask} className="flex items-center gap-1 pt-1">
              <input
                type="text"
                placeholder="افزودن زیرتسک جدید..."
                value={newSubtaskTitle}
                onChange={(e) => setNewSubtaskTitle(e.target.value)}
                className="flex-1 bg-canvas-secondary px-2.5 py-1 rounded text-xs text-ink-primary outline-none border border-border-subtle"
              />
              <button
                type="submit"
                className="p-1 rounded bg-accent-primary text-white hover:bg-accent-hover transition"
              >
                <Plus className="w-4 h-4" />
              </button>
            </form>
          </div>
        </div>

        {/* Notion Block Note Editor */}
        <NotionBlockEditor taskId={task.id} blocks={task.blocks} />
      </div>

      {/* Footer: Delete Task */}
      <div className="p-3 border-t border-border-subtle flex justify-between items-center bg-canvas-secondary/30">
        <button
          onClick={() => deleteTask(task.id)}
          className="flex items-center gap-1.5 text-xs text-red-400 hover:text-red-300 transition p-1 rounded hover:bg-red-500/10"
        >
          <Trash2 className="w-3.5 h-3.5" />
          <span>حذف این تسک</span>
        </button>
        <span className="text-[10px] text-ink-subtle">
          ذخیره خودکار محلی
        </span>
      </div>
    </aside>
  </>
);
};
