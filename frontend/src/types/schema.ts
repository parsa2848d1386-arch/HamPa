// ============================================================================
// بخش ۱: تایپ‌های جامع مدل بلاک عمومی، درخت دو اشاره‌گر و پایگاه داده
// Universal Block Model, Two-Pointer Tree, Sync, Sessions & CSP Scheduling
// ============================================================================

export type BlockType =
  | 'page'
  | 'subject'
  | 'task'
  | 'heading_1'
  | 'heading_2'
  | 'heading_3'
  | 'paragraph'
  | 'to_do'
  | 'toggle'
  | 'synced_block'
  | 'stylus_canvas'
  | 'habit'
  | 'database_row';

export type PriorityLevel = 'p1_urgent_important' | 'p2_not_urgent_important' | 'p3_urgent_not_important' | 'p4_neither';
export type TimerMode = 'stopwatch' | 'pomodoro' | 'countdown';
export type BreakTag = 'meal' | 'rest' | 'exercise' | 'social' | 'nap' | 'commute' | 'other';
export type PresenceStatus = 'STUDYING' | 'RESTING' | 'OFFLINE';

// ۱.۱. ساختار عمومی بلاک (The Universal Block Interface)
export interface UniversalBlock<TProps = Record<string, any>> {
  id: string; // UUID v4 تولید شده در کلاینت برای عملکرد کاملاً آفلاین
  workspace_id: string; // کلید شاردینگ و جداسازی منطقی ورک‌اسپیس
  type: BlockType;
  
  // ساختار Properties منعطف و جدا از Type جهت Turn-Into بدون از دست رفتن داده
  properties: {
    title?: string;
    rich_text?: any[];
    color?: string;
    icon?: string;
    checked?: boolean;
    priority?: PriorityLevel;
    estimated_duration_min?: number;
    min_chunk_min?: number;
    max_chunk_min?: number;
    deadline?: string; // ISO String
    repeat_days?: number[]; // [1..7]
    repeat_mode?: 'fixed_date' | 'from_completion';
    splittable?: boolean;
    dependencies?: string[]; // آرایه UUID بلاک‌های پیش‌نیاز
    target_daily_minutes?: number;
    habit_streak?: number;
    multi_completion_target?: number;
    multi_completion_count?: number;
    [key: string]: any;
  } & TProps;

  // درخت رندر رو به پایین (Ordered child block UUIDs)
  content: string[]; // UUID[]

  // درخت دسترسی و والد رو به بالا (Permissions Tree)
  parent_id: string; // UUID
  parent_type: 'workspace' | 'page' | 'subject' | 'task' | 'database';

  version: number;
  created_at: string;
  updated_at: string;
  is_deleted?: boolean;
}

// ۱.۲. سشن مطالعه و زمان‌سنجی (Study Sessions Table)
export interface StudySessionRecord {
  id: string; // UUID v4
  user_id: string;
  subject_block_id: string; // اشاره به بلاک درس
  task_block_id?: string; // اختیاری: اشاره به تسک متناظر
  start_time: string; // ISO 8601
  end_time: string; // ISO 8601
  duration_seconds: number;
  timer_mode: TimerMode;
  
  // قانون ضدتقلب (Anti-Cheat Flag):
  // رکوردهای دستی فقط در آمار شخصی درج می‌شوند و اکیداً از لیدربورد حذف می‌گردند.
  is_manual_entry: boolean;
  
  logical_date: string; // YYYY-MM-DD با مرز ساعت ۰۵:۰۰ صبح
  created_at: string;
}

// ۱.۳. لاگ استراحت و گپ مطالعه (Break Logs Table)
export interface BreakLogRecord {
  id: string;
  user_id: string;
  prev_session_id: string;
  next_session_id?: string;
  start_time: string;
  end_time: string;
  duration_seconds: number;
  
  // قانون گپ حداکثر ۳ ساعته (<3h Rule)
  break_tag?: BreakTag;
  discarded_as_end_of_day: boolean; // اگر > 10800 ثانیه باشد true می‌شود
  created_at: string;
}

// ۱.۴. ساختار تراکنش آفلاین محلی (Transaction Queue Outbox)
export type OperationType = 'insert' | 'update' | 'delete' | 'append_child' | 'remove_child' | 'reorder_children';

export interface BlockOperation {
  op_id: string;
  type: OperationType;
  block_id: string;
  path?: string; // فیلد داخلی properties یا content
  value?: any;
  before_value?: any; // برای اعتبارسنجی خوش‌بینانه و بازگشت (Rollback)
}

export interface SyncTransaction {
  transaction_id: string; // UUID v4
  client_timestamp: number;
  workspace_id: string;
  user_id: string;
  operations: BlockOperation[];
  status: 'pending' | 'syncing' | 'committed' | 'rejected';
  retry_count: number;
}

// ۱.۵. ساختار ورودی و خروجی موتور زمان‌بندی CSP (Auto-Scheduler)
export interface ScheduledTimeSlot {
  task_id: string;
  task_title: string;
  subject_id: string;
  subject_color: string;
  start_time: string; // "HH:mm"
  end_time: string;   // "HH:mm"
  duration_minutes: number;
  is_locked: boolean; // اگر کاربر دستی جابجا کرده باشد قفل می‌شود
  risk_of_deadline_miss: boolean;
}

export interface FixedCalendarEvent {
  id: string;
  title: string;
  start_time: string; // "HH:mm"
  end_time: string;   // "HH:mm"
}

// ۱.۶. ساختار حضور زنده و پیام‌رسانی گروه‌های هم‌پا (Social & Rooms)
export interface StudyRoomPeer {
  user_id: string;
  nickname: string;
  avatar_url?: string;
  status: PresenceStatus;
  active_subject_name?: string;
  active_subject_color?: string;
  elapsed_seconds: number;
  camera_active?: boolean;
  daily_study_seconds: number;
  messages_sent_today: number;
}

export interface StudyGroupPolicy {
  id: string;
  name: string;
  chat_enabled: boolean;
  daily_message_quota_per_user: number; // 0 (بی‌صدا), 10, 50, 9999 (نامحدود)
  creator_user_id: string;
}
