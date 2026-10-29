export type Priority = 'low' | 'medium' | 'high' | 'urgent';
export type TaskStatus = 'todo' | 'in_progress' | 'completed' | 'cancelled';

export interface Subtask {
  id: string;
  title: string;
  completed: boolean;
}

export type BlockType = 
  | 'text' 
  | 'heading1' 
  | 'heading2' 
  | 'heading3' 
  | 'checklist' 
  | 'quote' 
  | 'code' 
  | 'callout' 
  | 'divider';

export interface BlockNote {
  id: string;
  type: BlockType;
  content: string;
  checked?: boolean;
  language?: string;
  color?: string;
}

export type EnergyLevel = 'high' | 'medium' | 'low';
export type RecurrenceType = 'none' | 'daily' | 'workdays' | 'weekly' | 'monthly';

export interface Task {
  id: string;
  title: string;
  description?: string;
  subjectId?: string;
  date: string; // YYYY-MM-DD (Gregorian internally, converted to Jalali in UI)
  startTime?: string; // "HH:mm" (e.g., "09:30")
  durationMinutes: number; // e.g., 45, 90 (0 for quick reminders)
  color: string; // Hex or token
  priority: Priority;
  status: TaskStatus;
  isMIT?: boolean; // Sunsama Most Important Task
  tags: string[];
  subtasks: Subtask[];
  blocks: BlockNote[];
  totalSecondsStudied: number;
  energyLevel?: EnergyLevel;
  estimatedPomodoros?: number;
  recurrence?: RecurrenceType;
  reminderMinutesBefore?: number;
  createdAt: string;
  updatedAt: string;
}

export interface Subject {
  id: string;
  name: string;
  color: string;
  icon?: string;
  targetDailyMinutes: number;
  totalSecondsStudied: number;
}

export type TimerMode = 'stopwatch' | 'pomodoro' | 'countdown';

export interface StudySession {
  id: string;
  subjectId: string;
  subjectName: string;
  taskId?: string;
  taskTitle?: string;
  durationSeconds: number;
  startedAt: string; // ISO String
  endedAt: string; // ISO String
  mode: TimerMode;
  dateKey: string; // YYYY-MM-DD
}

export type AmbientSoundType = 
  | 'none' 
  | 'white_noise' 
  | 'pink_noise' 
  | 'brown_noise' 
  | 'binaural_focus' 
  | 'rain' 
  | 'cafe';

export interface AmbientAudioState {
  type: AmbientSoundType;
  isPlaying: boolean;
  volume: number; // 0.0 to 1.0
}

export type ThemePreset = 'midnight' | 'telegram' | 'day' | 'sepia';
export type AccentColorId = 'orange' | 'blue' | 'indigo' | 'emerald' | 'violet' | 'amber' | 'rose';

export interface UserProfile {
  uid: string;
  email: string | null;
  displayName: string | null;
  photoURL: string | null;
  isGuest: boolean;
  streakDays: number;
  lastStudyDate: string; // YYYY-MM-DD
  dailyCapacityMinutes: number; // default 360 (6 hours)
  targetExamDate?: string; // Target exam ISO date or YYYY-MM-DD
  targetExamTitle?: string; // Target exam title (e.g. "کنکور سراسری")
  bio?: string;
}

export type CalendarSystem = 'jalali' | 'gregorian';
export type ViewMode = 
  | 'dashboard'
  | 'day' 
  | 'week' 
  | 'month' 
  | 'kanban' 
  | 'focus' 
  | 'analytics' 
  | 'eisenhower' 
  | 'dual_planner' 
  | 'study_room' 
  | 'stylus';
export type DeviceType = 'mobile' | 'tablet' | 'desktop';

export interface BrainDumpDraft {
  id: string;
  rawText: string;
  parsedTasks: {
    id: string;
    title: string;
    startTime?: string;
    durationMinutes: number;
    color: string;
    suggestedSubtasks: string[];
    priority: Priority;
  }[];
}
