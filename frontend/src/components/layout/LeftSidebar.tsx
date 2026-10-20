import React, { useState } from 'react';
import { 
  Calendar as CalendarIcon, 
  Inbox, 
  Plus, 
  ChevronRight, 
  ChevronLeft, 
  Tag, 
  BookOpen, 
  ChevronDown,
  Layers,
  Circle,
  X
} from 'lucide-react';
import { useAppStore } from '../../store/useAppStore';
import { 
  gregorianToJalali, 
  PERSIAN_MONTHS, 
  PERSIAN_WEEKDAYS_SHORT, 
  formatToPersianDigits 
} from '../../lib/calendarUtils';

export const LeftSidebar: React.FC = () => {
  const isOpen = useAppStore((s) => s.isLeftSidebarOpen);
  const toggleLeftSidebar = useAppStore((s) => s.toggleLeftSidebar);
  const calendarSystem = useAppStore((s) => s.calendarSystem);
  const selectedDate = useAppStore((s) => s.selectedDate);
  const setSelectedDate = useAppStore((s) => s.setSelectedDate);
  const subjects = useAppStore((s) => s.subjects);
  const tasks = useAppStore((s) => s.tasks);
  const addTask = useAppStore((s) => s.addTask);
  const selectTask = useAppStore((s) => s.selectTask);

  const [quickTitle, setQuickTitle] = useState('');

  if (!isOpen) return null;

  const currentDateObj = new Date(selectedDate);
  const jDate = gregorianToJalali(
    currentDateObj.getFullYear(),
    currentDateObj.getMonth() + 1,
    currentDateObj.getDate()
  );

  // Month navigation
  const monthName = calendarSystem === 'jalali' 
    ? `${PERSIAN_MONTHS[jDate.jm - 1]} ${formatToPersianDigits(jDate.jy)}`
    : currentDateObj.toLocaleDateString('en-US', { month: 'long', year: 'numeric' });

  // Generate 30 days grid for the mini month
  const daysInMonth = calendarSystem === 'jalali' ? (jDate.jm <= 6 ? 31 : 30) : 31;
  const currentDayNum = calendarSystem === 'jalali' ? jDate.jd : currentDateObj.getDate();

  const handleQuickAdd = (e: React.FormEvent) => {
    e.preventDefault();
    if (!quickTitle.trim()) return;

    addTask({
      title: quickTitle.trim(),
      date: selectedDate,
      startTime: '10:00',
      durationMinutes: 45,
      color: '#FF4700',
      priority: 'medium',
      status: 'todo',
      tags: ['تسک سریع'],
      subtasks: [],
      blocks: [],
    });
    setQuickTitle('');
  };

  return (
    <>
      {/* Mobile Backdrop Overlay (only on < lg) */}
      <div 
        onClick={toggleLeftSidebar} 
        className="fixed inset-0 bg-black/60 backdrop-blur-sm z-40 lg:hidden"
        aria-hidden="true" 
      />

      <aside className="fixed inset-y-0 right-0 z-50 w-72 lg:static lg:w-64 xl:w-72 border-l border-border-subtle bg-canvas-elevated liquid-glass flex flex-col h-full overflow-hidden select-none shadow-2xl lg:shadow-none transition-transform duration-300">
        {/* Mini Month Header with Mobile Close Button */}
        <div className="p-3 border-b border-border-subtle">
          <div className="flex items-center justify-between pb-2">
            <div className="flex items-center gap-1.5">
              <span className="text-xs font-bold text-ink-primary">
                {monthName}
              </span>
            </div>
            
            <div className="flex items-center gap-1 text-ink-muted">
              <button className="p-1 hover:bg-white/5 rounded">
                <ChevronRight className="w-3.5 h-3.5" />
              </button>
              <button className="p-1 hover:bg-white/5 rounded">
                <ChevronLeft className="w-3.5 h-3.5" />
              </button>
              {/* Close button on mobile */}
              <button 
                onClick={toggleLeftSidebar}
                className="lg:hidden p-1 mr-1 hover:bg-white/10 rounded text-ink-muted hover:text-ink-primary"
                title="بستن سایدبار"
              >
                <X className="w-4 h-4" />
              </button>
            </div>
          </div>

        {/* Days of week short */}
        <div className="grid grid-cols-7 gap-1 text-center text-[10px] text-ink-subtle pb-1">
          {PERSIAN_WEEKDAYS_SHORT.map((w, i) => (
            <div key={i}>{w}</div>
          ))}
        </div>

        {/* Month Days Grid */}
        <div className="grid grid-cols-7 gap-1 text-center text-xs">
          {Array.from({ length: daysInMonth }, (_, i) => i + 1).map((d) => {
            const isToday = d === currentDayNum;
            return (
              <button
                key={d}
                onClick={() => {
                  const target = new Date();
                  target.setDate(d);
                  setSelectedDate(target.toISOString().split('T')[0]);
                }}
                className={`h-7 rounded-precision flex items-center justify-center font-mono text-[11px] transition ${
                  isToday
                    ? 'bg-accent-primary text-white font-bold shadow-sm'
                    : 'text-ink-muted hover:bg-white/5 hover:text-ink-primary'
                }`}
              >
                {calendarSystem === 'jalali' ? formatToPersianDigits(d) : d}
              </button>
            );
          })}
        </div>
      </div>

      {/* Inbox & Category Lists */}
      <div className="flex-1 overflow-y-auto p-3 space-y-4">
        {/* Quick Add Task */}
        <form onSubmit={handleQuickAdd} className="relative">
          <input
            type="text"
            placeholder="+ افزودن سریع تسک..."
            value={quickTitle}
            onChange={(e) => setQuickTitle(e.target.value)}
            className="w-full bg-canvas-secondary/70 border border-border-subtle rounded-precision-md px-3 py-1.5 text-xs text-ink-primary outline-none focus:border-accent-primary"
          />
        </form>

        {/* Subjects List */}
        <div className="space-y-1.5">
          <span className="text-[10px] font-bold text-ink-muted uppercase tracking-wider">
            موضوعات و دروس مطالعه
          </span>
          <div className="space-y-1">
            {subjects.map((subj) => (
              <div
                key={subj.id}
                className="flex items-center justify-between px-2.5 py-1.5 rounded-precision hover:bg-white/5 text-xs text-ink-muted hover:text-ink-primary cursor-pointer transition"
              >
                <div className="flex items-center gap-2">
                  <span
                    className="w-2.5 h-2.5 rounded-full"
                    style={{ backgroundColor: subj.color }}
                  />
                  <span>{subj.name}</span>
                </div>
                <span className="text-[10px] font-mono text-ink-subtle">
                  {Math.round(subj.totalSecondsStudied / 3600)}h
                </span>
              </div>
            ))}
          </div>
        </div>

        {/* Today's Tasks Summary List */}
        <div className="space-y-1.5">
          <span className="text-[10px] font-bold text-ink-muted uppercase tracking-wider">
            صندوق ورودی امروز ({tasks.filter((t) => t.date === selectedDate).length})
          </span>
          <div className="space-y-1">
            {tasks
              .filter((t) => t.date === selectedDate)
              .map((task) => (
                <div
                  key={task.id}
                  onClick={() => selectTask(task.id)}
                  className="flex items-center gap-2 px-2.5 py-1.5 rounded-precision bg-canvas-secondary/40 hover:bg-canvas-secondary border border-border-subtle/40 text-xs text-ink-primary cursor-pointer transition"
                >
                  <Circle className="w-3 h-3 text-ink-muted flex-shrink-0" />
                  <span className="truncate flex-1">{task.title}</span>
                  {task.startTime && (
                    <span className="font-mono text-[10px] text-ink-muted">
                      {task.startTime}
                    </span>
                  )}
                </div>
              ))}
          </div>
        </div>
      </div>
    </aside>
  </>
);
};
