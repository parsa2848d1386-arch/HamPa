import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import type { 
  Task, 
  Subject, 
  StudySession, 
  UserProfile, 
  CalendarSystem, 
  ViewMode, 
  TimerMode, 
  AmbientAudioState, 
  AmbientSoundType,
  BlockNote,
} from '../types';
import type { ParsedDraftItem } from '../lib/brainDumpParser';
import { audioEngine } from '../lib/audioEngine';
import { getTodayKey } from '../lib/calendarUtils';

const DEFAULT_SUBJECTS: Subject[] = [
  { id: 'subj-1', name: 'ریاضی و حسابان', color: '#3B82F6', targetDailyMinutes: 120, totalSecondsStudied: 14400 },
  { id: 'subj-2', name: 'فیزیک پیشرفته', color: '#8B5CF6', targetDailyMinutes: 90, totalSecondsStudied: 9800 },
  { id: 'subj-3', name: 'برنامه‌نویسی و وب', color: '#FF4700', targetDailyMinutes: 180, totalSecondsStudied: 21600 },
  { id: 'subj-4', name: 'زبان انگلیسی', color: '#F59E0B', targetDailyMinutes: 60, totalSecondsStudied: 5400 },
  { id: 'subj-5', name: 'زیست‌شناسی', color: '#10B981', targetDailyMinutes: 90, totalSecondsStudied: 7200 },
];

const INITIAL_BLOCKS: BlockNote[] = [
  { id: 'b1', type: 'heading2', content: 'اهداف جلسه و نکات کلیدی' },
  { id: 'b2', type: 'callout', content: 'تمرکز ۱۰۰٪ روی حل تست‌های چالشی و یادداشت خطاهای پرتکرار.' },
  { id: 'b3', type: 'checklist', content: 'مرور خلاصه درسنامه و روابط مهم', checked: true },
  { id: 'b4', type: 'checklist', content: 'حل تست‌های ۱۰ تا ۳۵ مبحث توابع', checked: false },
  { id: 'b5', type: 'checklist', content: 'بررسی پاسخ‌نامه تشریحی و ثبت نکات در دفترچه', checked: false },
  { id: 'b6', type: 'code', content: '// فرمول کلیدی مساحت زیر نمودار:\n∫ f(x) dx = F(b) - F(a)', language: 'javascript' },
];

const today = getTodayKey();

const DEFAULT_TASKS: Task[] = [
  {
    id: 'task-1',
    title: 'توسعه معماری دیزاین سیستم HamPA',
    description: 'پیاده‌سازی توکن‌های رنگی، زمان‌سنجی کرون و تایم‌لاین بصری',
    subjectId: 'subj-3',
    date: today,
    startTime: '08:30',
    durationMinutes: 90,
    color: '#FF4700',
    priority: 'urgent',
    status: 'in_progress',
    isMIT: true,
    tags: ['طراحی', 'فرانت‌اند', 'معماری'],
    subtasks: [
      { id: 'st-1', title: 'پیاده‌سازی توکن‌های Precision Dark و Mindful Light', completed: true },
      { id: 'st-2', title: 'موتور صوتی Web Audio API و تایمر شناور', completed: true },
      { id: 'st-3', title: 'رندرینگ تایم‌لاین ۲۴ ساعته ۱۰ دقیقه‌ای', completed: false },
    ],
    blocks: INITIAL_BLOCKS,
    totalSecondsStudied: 3600,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  },
  {
    id: 'task-2',
    title: 'حل ۲۰ تست حسابان مبحث حد و پیوستگی',
    description: 'تحلیل تست‌های کنکور سال‌های اخیر با متد زمان‌دار',
    subjectId: 'subj-1',
    date: today,
    startTime: '10:30',
    durationMinutes: 75,
    color: '#3B82F6',
    priority: 'high',
    status: 'todo',
    isMIT: true,
    tags: ['کنکور', 'تست', 'ریاضی'],
    subtasks: [
      { id: 'st-4', title: 'تست‌های ۱ تا ۱۰ بدون پاسخ‌نامه', completed: false },
      { id: 'st-5', title: 'تحلیل نکات غلط و نزده', completed: false },
    ],
    blocks: [],
    totalSecondsStudied: 0,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  },
  {
    id: 'task-3',
    title: 'مرور لغات ۵۰۴ و ریدینگ زبان تخصصی',
    subjectId: 'subj-4',
    date: today,
    startTime: '13:00',
    durationMinutes: 45,
    color: '#F59E0B',
    priority: 'medium',
    status: 'todo',
    isMIT: true,
    tags: ['واژگان', 'انگلیسی'],
    subtasks: [
      { id: 'st-6', title: 'مرور لایتنر درس ۱۲', completed: true },
      { id: 'st-7', title: 'یک متن درک مطلب زمان‌دار', completed: false },
    ],
    blocks: [],
    totalSecondsStudied: 1800,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  },
  {
    id: 'task-4',
    title: 'آزمون شبیه‌ساز فیزیک دوازدهم',
    subjectId: 'subj-2',
    date: today,
    startTime: '15:00',
    durationMinutes: 90,
    color: '#8B5CF6',
    priority: 'high',
    status: 'todo',
    isMIT: false,
    tags: ['آزمون', 'فیزیک'],
    subtasks: [],
    blocks: [],
    totalSecondsStudied: 0,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  },
  {
    id: 'task-5',
    title: 'ریست و استراحت آگاهانه + پیاده‌روی',
    date: today,
    startTime: '17:00',
    durationMinutes: 30,
    color: '#10B981',
    priority: 'low',
    status: 'todo',
    isMIT: false,
    tags: ['سلامت', 'ذهن'],
    subtasks: [],
    blocks: [],
    totalSecondsStudied: 0,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  }
];

const DEFAULT_SESSIONS: StudySession[] = [
  {
    id: 'sess-1',
    subjectId: 'subj-3',
    subjectName: 'برنامه‌نویسی و وب',
    taskId: 'task-1',
    taskTitle: 'توسعه معماری دیزاین سیستم HamPA',
    durationSeconds: 3600,
    startedAt: new Date(Date.now() - 7200000).toISOString(),
    endedAt: new Date(Date.now() - 3600000).toISOString(),
    mode: 'stopwatch',
    dateKey: today,
  },
  {
    id: 'sess-2',
    subjectId: 'subj-4',
    subjectName: 'زبان انگلیسی',
    taskId: 'task-3',
    taskTitle: 'مرور لغات ۵۰۴ و ریدینگ زبان تخصصی',
    durationSeconds: 1800,
    startedAt: new Date(Date.now() - 14400000).toISOString(),
    endedAt: new Date(Date.now() - 12600000).toISOString(),
    mode: 'pomodoro',
    dateKey: today,
  }
];

interface AppState {
  // Navigation & View
  viewMode: ViewMode;
  calendarSystem: CalendarSystem;
  selectedDate: string; // YYYY-MM-DD
  isDark: boolean;
  isLeftSidebarOpen: boolean;
  isRightInspectorOpen: boolean;
  selectedTaskId: string | null;

  // Modals & Rituals
  isMorningPlanningOpen: boolean;
  isEveningReflectionOpen: boolean;
  isBrainDumpOpen: boolean;
  isCommandPaletteOpen: boolean;
  isCheatSheetOpen: boolean;
  isFocusModalOpen: boolean;

  // Focus Timer Engine
  timerMode: TimerMode;
  isTimerRunning: boolean;
  isTimerPaused: boolean;
  timerSeconds: number;
  activeSubjectId: string | null;
  activeTaskId: string | null;
  isPiPVisible: boolean;
  ambientSound: AmbientAudioState;

  // Data
  tasks: Task[];
  subjects: Subject[];
  sessions: StudySession[];
  user: UserProfile;

  // Actions
  setViewMode: (mode: ViewMode) => void;
  setCalendarSystem: (system: CalendarSystem) => void;
  setSelectedDate: (date: string) => void;
  toggleTheme: () => void;
  toggleLeftSidebar: () => void;
  toggleRightInspector: () => void;
  setLeftSidebarOpen: (open: boolean) => void;
  setRightInspectorOpen: (open: boolean) => void;
  selectTask: (taskId: string | null) => void;

  isCreateTaskOpen: boolean;
  setCreateTaskOpen: (open: boolean) => void;
  setMorningPlanningOpen: (open: boolean) => void;
  setEveningReflectionOpen: (open: boolean) => void;
  setBrainDumpOpen: (open: boolean) => void;
  setCommandPaletteOpen: (open: boolean) => void;
  setCheatSheetOpen: (open: boolean) => void;
  setFocusModalOpen: (open: boolean) => void;

  // Task Actions
  addTask: (task: Omit<Task, 'id' | 'createdAt' | 'updatedAt' | 'totalSecondsStudied'>) => void;
  updateTask: (id: string, updates: Partial<Task>) => void;
  deleteTask: (id: string) => void;
  toggleTaskCompleted: (id: string) => void;
  toggleSubtask: (taskId: string, subtaskId: string) => void;
  addBlockNote: (taskId: string, block: Omit<BlockNote, 'id'>) => void;
  updateBlockNote: (taskId: string, blockId: string, content: string) => void;
  deleteBlockNote: (taskId: string, blockId: string) => void;

  // Focus Actions
  startFocusSession: (subjectId: string, taskId?: string, mode?: TimerMode) => void;
  pauseTimer: () => void;
  resumeTimer: () => void;
  stopFocusSession: () => void;
  tickTimer: () => void;
  setPiPVisible: (visible: boolean) => void;
  setAmbientSound: (type: AmbientSoundType, volume?: number) => void;

  // Planning Actions
  applyBrainDumpDrafts: (items: ParsedDraftItem[]) => void;
  setUser: (user: UserProfile) => void;
}

export const useAppStore = create<AppState>()(
  persist(
    (set, get) => ({
      viewMode: 'dashboard',
      calendarSystem: 'jalali',
      selectedDate: today,
      isDark: true,
      isLeftSidebarOpen: typeof window !== 'undefined' ? window.innerWidth >= 1024 : true,
      isRightInspectorOpen: false,
      selectedTaskId: null,

      isCreateTaskOpen: false,
      isMorningPlanningOpen: false,
      isEveningReflectionOpen: false,
      isBrainDumpOpen: false,
      isCommandPaletteOpen: false,
      isCheatSheetOpen: false,
      isFocusModalOpen: false,

      timerMode: 'stopwatch',
      isTimerRunning: false,
      isTimerPaused: false,
      timerSeconds: 0,
      activeSubjectId: 'subj-3',
      activeTaskId: 'task-1',
      isPiPVisible: false,
      ambientSound: { type: 'none', isPlaying: false, volume: 0.5 },

      tasks: DEFAULT_TASKS,
      subjects: DEFAULT_SUBJECTS,
      sessions: DEFAULT_SESSIONS,
      user: {
        uid: 'guest-hampa-user',
        email: 'user@hampa.ir',
        displayName: 'کاربر همراه',
        photoURL: null,
        isGuest: true,
        streakDays: 14,
        lastStudyDate: today,
        dailyCapacityMinutes: 360,
      },

      setViewMode: (viewMode) => set({ viewMode }),
      setCalendarSystem: (calendarSystem) => set({ calendarSystem }),
      setSelectedDate: (selectedDate) => set({ selectedDate }),
      toggleTheme: () => {
        const next = !get().isDark;
        if (next) {
          document.documentElement.classList.add('dark');
        } else {
          document.documentElement.classList.remove('dark');
        }
        set({ isDark: next });
      },
      toggleLeftSidebar: () => set((state) => ({ isLeftSidebarOpen: !state.isLeftSidebarOpen })),
      toggleRightInspector: () => set((state) => ({ isRightInspectorOpen: !state.isRightInspectorOpen })),
      setLeftSidebarOpen: (isLeftSidebarOpen) => set({ isLeftSidebarOpen }),
      setRightInspectorOpen: (isRightInspectorOpen) => set({ isRightInspectorOpen }),
      selectTask: (selectedTaskId) => set({ selectedTaskId, isRightInspectorOpen: !!selectedTaskId }),

      setCreateTaskOpen: (isCreateTaskOpen) => set({ isCreateTaskOpen }),
      setMorningPlanningOpen: (isMorningPlanningOpen) => set({ isMorningPlanningOpen }),
      setEveningReflectionOpen: (isEveningReflectionOpen) => set({ isEveningReflectionOpen }),
      setBrainDumpOpen: (isBrainDumpOpen) => set({ isBrainDumpOpen }),
      setCommandPaletteOpen: (isCommandPaletteOpen) => set({ isCommandPaletteOpen }),
      setCheatSheetOpen: (isCheatSheetOpen) => set({ isCheatSheetOpen }),
      setFocusModalOpen: (isFocusModalOpen) => set({ isFocusModalOpen }),

      addTask: (taskData) => {
        const newTask: Task = {
          ...taskData,
          id: `task-${Date.now()}`,
          totalSecondsStudied: 0,
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString(),
        };
        set((state) => ({ tasks: [newTask, ...state.tasks] }));
      },

      updateTask: (id, updates) => {
        set((state) => ({
          tasks: state.tasks.map((t) => (t.id === id ? { ...t, ...updates, updatedAt: new Date().toISOString() } : t))
        }));
      },

      deleteTask: (id) => {
        set((state) => ({
          tasks: state.tasks.filter((t) => t.id !== id),
          selectedTaskId: state.selectedTaskId === id ? null : state.selectedTaskId,
        }));
      },

      toggleTaskCompleted: (id) => {
        set((state) => ({
          tasks: state.tasks.map((t) => {
            if (t.id === id) {
              const nextStatus = t.status === 'completed' ? 'todo' : 'completed';
              return { ...t, status: nextStatus, updatedAt: new Date().toISOString() };
            }
            return t;
          })
        }));
      },

      toggleSubtask: (taskId, subtaskId) => {
        set((state) => ({
          tasks: state.tasks.map((t) => {
            if (t.id === taskId) {
              const updatedSubtasks = t.subtasks.map((st) => 
                st.id === subtaskId ? { ...st, completed: !st.completed } : st
              );
              return { ...t, subtasks: updatedSubtasks, updatedAt: new Date().toISOString() };
            }
            return t;
          })
        }));
      },

      addBlockNote: (taskId, blockData) => {
        const newBlock: BlockNote = {
          ...blockData,
          id: `b-${Date.now()}-${Math.random().toString(36).substr(2, 4)}`,
        };
        set((state) => ({
          tasks: state.tasks.map((t) => {
            if (t.id === taskId) {
              return { ...t, blocks: [...t.blocks, newBlock], updatedAt: new Date().toISOString() };
            }
            return t;
          })
        }));
      },

      updateBlockNote: (taskId, blockId, content) => {
        set((state) => ({
          tasks: state.tasks.map((t) => {
            if (t.id === taskId) {
              return {
                ...t,
                blocks: t.blocks.map((b) => b.id === blockId ? { ...b, content } : b),
                updatedAt: new Date().toISOString()
              };
            }
            return t;
          })
        }));
      },

      deleteBlockNote: (taskId, blockId) => {
        set((state) => ({
          tasks: state.tasks.map((t) => {
            if (t.id === taskId) {
              return {
                ...t,
                blocks: t.blocks.filter((b) => b.id !== blockId),
                updatedAt: new Date().toISOString()
              };
            }
            return t;
          })
        }));
      },

      startFocusSession: (subjectId, taskId, mode = 'stopwatch') => {
        set({
          activeSubjectId: subjectId,
          activeTaskId: taskId || null,
          timerMode: mode,
          isTimerRunning: true,
          isTimerPaused: false,
          timerSeconds: 0,
          isFocusModalOpen: true,
          isPiPVisible: false,
        });
      },

      pauseTimer: () => set({ isTimerPaused: true }),
      resumeTimer: () => set({ isTimerPaused: false }),

      stopFocusSession: () => {
        const { timerSeconds, activeSubjectId, activeTaskId, subjects, tasks } = get();
        if (timerSeconds > 5 && activeSubjectId) {
          const subject = subjects.find(s => s.id === activeSubjectId);
          const task = tasks.find(t => t.id === activeTaskId);
          
          const newSession: StudySession = {
            id: `sess-${Date.now()}`,
            subjectId: activeSubjectId,
            subjectName: subject?.name || 'مطالعه عمومی',
            taskId: activeTaskId || undefined,
            taskTitle: task?.title,
            durationSeconds: timerSeconds,
            startedAt: new Date(Date.now() - timerSeconds * 1000).toISOString(),
            endedAt: new Date().toISOString(),
            mode: get().timerMode,
            dateKey: getTodayKey(),
          };

          // Increment totals
          const updatedSubjects = subjects.map(s => 
            s.id === activeSubjectId ? { ...s, totalSecondsStudied: s.totalSecondsStudied + timerSeconds } : s
          );

          const updatedTasks = tasks.map(t => 
            t.id === activeTaskId ? { ...t, totalSecondsStudied: t.totalSecondsStudied + timerSeconds } : t
          );

          set({
            sessions: [newSession, ...get().sessions],
            subjects: updatedSubjects,
            tasks: updatedTasks,
          });
        }

        audioEngine.stop();
        set({
          isTimerRunning: false,
          isTimerPaused: false,
          timerSeconds: 0,
          isFocusModalOpen: false,
          isPiPVisible: false,
          ambientSound: { ...get().ambientSound, isPlaying: false }
        });
      },

      tickTimer: () => {
        const { isTimerRunning, isTimerPaused, timerSeconds } = get();
        if (isTimerRunning && !isTimerPaused) {
          set({ timerSeconds: timerSeconds + 1 });
        }
      },

      setPiPVisible: (isPiPVisible) => set({ isPiPVisible }),

      setAmbientSound: (type, volume) => {
        const currentVol = volume !== undefined ? volume : get().ambientSound.volume;
        if (type === 'none') {
          audioEngine.stop();
          set({ ambientSound: { type: 'none', isPlaying: false, volume: currentVol } });
        } else {
          audioEngine.play(type, currentVol);
          set({ ambientSound: { type, isPlaying: true, volume: currentVol } });
        }
      },

      applyBrainDumpDrafts: (draftItems) => {
        const newTasks: Task[] = draftItems.map((item) => ({
          id: `task-${Date.now()}-${Math.random().toString(36).substr(2, 5)}`,
          title: item.title,
          date: getTodayKey(),
          startTime: item.startTime,
          durationMinutes: item.durationMinutes,
          color: item.color,
          priority: item.priority,
          status: 'todo',
          isMIT: false,
          tags: [item.category],
          subtasks: item.suggestedSubtasks.map((st, i) => ({
            id: `st-${Date.now()}-${i}`,
            title: st,
            completed: false,
          })),
          blocks: [],
          totalSecondsStudied: 0,
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString(),
        }));

        set((state) => ({
          tasks: [...newTasks, ...state.tasks],
          isBrainDumpOpen: false
        }));
      },

      setUser: (user) => set({ user }),
    }),
    {
      name: 'hampa-workspace-store',
      partialize: (state) => ({
        calendarSystem: state.calendarSystem,
        isDark: state.isDark,
        tasks: state.tasks,
        subjects: state.subjects,
        sessions: state.sessions,
        user: state.user,
      })
    }
  )
);
