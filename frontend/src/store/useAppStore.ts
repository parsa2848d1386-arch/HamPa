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
  ThemePreset,
  AccentColorId,
} from '../types';
import type { ParsedDraftItem } from '../lib/brainDumpParser';
import { audioEngine } from '../lib/audioEngine';
import { getTodayKey } from '../lib/calendarUtils';
import { applyThemeToDocument } from '../lib/themeEngine';

const DEFAULT_SUBJECTS: Subject[] = [
  { id: 'subj-1', name: 'ریاضی و حسابان', color: '#3B82F6', targetDailyMinutes: 120, totalSecondsStudied: 0 },
  { id: 'subj-2', name: 'فیزیک پیشرفته', color: '#8B5CF6', targetDailyMinutes: 90, totalSecondsStudied: 0 },
  { id: 'subj-3', name: 'برنامه‌نویسی و وب', color: '#FF4700', targetDailyMinutes: 180, totalSecondsStudied: 0 },
  { id: 'subj-4', name: 'زبان انگلیسی', color: '#F59E0B', targetDailyMinutes: 60, totalSecondsStudied: 0 },
  { id: 'subj-5', name: 'زیست‌شناسی', color: '#10B981', targetDailyMinutes: 90, totalSecondsStudied: 0 },
];

const INITIAL_BLOCKS: BlockNote[] = [];

const today = getTodayKey();

const DEFAULT_TASKS: Task[] = [];

const DEFAULT_SESSIONS: StudySession[] = [];

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

  // Customization & Study Engine
  themePreset: ThemePreset;
  accentColorId: AccentColorId;
  isSettingsOpen: boolean;
  dayCutoffHour: number; // 5 for 05:00 AM YPT reset
  pomodoroWorkMinutes: number;
  pomodoroBreakMinutes: number;

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
  setSettingsOpen: (open: boolean) => void;
  setThemePreset: (preset: ThemePreset) => void;
  setAccentColorId: (id: AccentColorId) => void;
  setDayCutoffHour: (hour: number) => void;
  setPomodoroSettings: (work: number, breakTime: number) => void;
  updateUserProfile: (updates: Partial<UserProfile>) => void;

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
  setTasks: (tasks: Task[]) => void;
  setSessions: (sessions: StudySession[]) => void;
  setSubjects: (subjects: Subject[]) => void;
  clearAllData: () => void;
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
      activeSubjectId: 'subj-1',
      activeTaskId: null,
      isPiPVisible: false,
      ambientSound: { type: 'none', isPlaying: false, volume: 0.5 },

      themePreset: 'telegram',
      accentColorId: 'orange',
      isSettingsOpen: false,
      dayCutoffHour: 5,
      pomodoroWorkMinutes: 25,
      pomodoroBreakMinutes: 5,

      tasks: DEFAULT_TASKS,
      subjects: DEFAULT_SUBJECTS,
      sessions: DEFAULT_SESSIONS,
      user: {
        uid: 'guest-' + Math.random().toString(36).substring(2, 9),
        email: '',
        displayName: 'کاربر هم‌پا',
        photoURL: null,
        isGuest: true,
        streakDays: 0,
        lastStudyDate: today,
        dailyCapacityMinutes: 360,
        targetExamDate: '',
        targetExamTitle: '',
        bio: '',
      },

      setViewMode: (viewMode) => set({ viewMode }),
      setCalendarSystem: (calendarSystem) => set({ calendarSystem }),
      setSelectedDate: (selectedDate) => set({ selectedDate }),
      toggleTheme: () => {
        const currentPreset = get().themePreset;
        const isCurrentlyDark = currentPreset === 'midnight' || currentPreset === 'telegram';
        const nextPreset: ThemePreset = isCurrentlyDark ? 'day' : 'telegram';
        const nextDark = !isCurrentlyDark;
        set({ themePreset: nextPreset, isDark: nextDark });
        applyThemeToDocument(nextPreset, get().accentColorId);
      },
      setThemePreset: (themePreset) => {
        const isDark = themePreset === 'midnight' || themePreset === 'telegram';
        set({ themePreset, isDark });
        applyThemeToDocument(themePreset, get().accentColorId);
      },
      setAccentColorId: (accentColorId) => {
        set({ accentColorId });
        applyThemeToDocument(get().themePreset, accentColorId);
      },
      setSettingsOpen: (isSettingsOpen) => set({ isSettingsOpen }),
      setDayCutoffHour: (dayCutoffHour) => set({ dayCutoffHour }),
      setPomodoroSettings: (pomodoroWorkMinutes, pomodoroBreakMinutes) => set({ pomodoroWorkMinutes, pomodoroBreakMinutes }),
      updateUserProfile: (updates) => set((state) => ({ user: { ...state.user, ...updates } })),
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
      setTasks: (tasks) => set({ tasks }),
      setSessions: (sessions) => set({ sessions }),
      setSubjects: (subjects) => set({ subjects }),
      clearAllData: () => set({
        tasks: [],
        sessions: [],
        activeTaskId: null,
        subjects: DEFAULT_SUBJECTS,
      }),
    }),
    {
      name: 'hampa-workspace-v3',
      partialize: (state) => ({
        calendarSystem: state.calendarSystem,
        isDark: state.isDark,
        themePreset: state.themePreset,
        accentColorId: state.accentColorId,
        dayCutoffHour: state.dayCutoffHour,
        pomodoroWorkMinutes: state.pomodoroWorkMinutes,
        pomodoroBreakMinutes: state.pomodoroBreakMinutes,
        tasks: state.tasks,
        subjects: state.subjects,
        sessions: state.sessions,
        user: state.user,
      }),
      onRehydrateStorage: () => (state) => {
        if (state) {
          // If previous localStorage contains fake demo tasks, automatically sanitize it
          if (state.tasks && state.tasks.some(t => t.id === 'task-1' || t.title.includes('دیزاین سیستم'))) {
            state.tasks = [];
          }
          if (state.sessions && state.sessions.some(s => s.id === 'sess-1' || s.id === 'sess-2')) {
            state.sessions = [];
          }
          if (state.user && state.user.streakDays === 14 && (state.user.email === 'user@hampa.ir' || state.user.displayName === 'کاربر همراه')) {
            state.user = {
              ...state.user,
              email: '',
              displayName: 'کاربر هم‌پا',
              streakDays: 0,
              targetExamDate: '',
              targetExamTitle: '',
              bio: '',
            };
          }
        }
      }
    }
  )
);
