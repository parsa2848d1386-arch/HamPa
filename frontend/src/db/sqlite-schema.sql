-- ============================================================================
-- بخش ۱: پایگاه داده محلی کلاینت (Local SQLite Schema for PowerSync / wa-sqlite)
-- ============================================================================

-- ۱. جدول محلی بلاک‌ها (Local Universal Blocks)
CREATE TABLE IF NOT EXISTS local_blocks (
    id TEXT PRIMARY KEY NOT NULL, -- UUID v4
    workspace_id TEXT NOT NULL,
    type TEXT NOT NULL,
    properties TEXT NOT NULL DEFAULT '{}', -- JSON String
    content TEXT NOT NULL DEFAULT '[]', -- JSON Array of UUIDs (Render Tree)
    parent_id TEXT NOT NULL,
    parent_type TEXT NOT NULL,
    version INTEGER NOT NULL DEFAULT 1,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    is_deleted INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_local_blocks_parent ON local_blocks(parent_id);
CREATE INDEX IF NOT EXISTS idx_local_blocks_workspace ON local_blocks(workspace_id);
CREATE INDEX IF NOT EXISTS idx_local_blocks_type ON local_blocks(type);

-- ۲. جدول محلی سشن‌های مطالعه (Local Study Sessions)
CREATE TABLE IF NOT EXISTS local_study_sessions (
    id TEXT PRIMARY KEY NOT NULL,
    user_id TEXT NOT NULL,
    subject_block_id TEXT NOT NULL,
    task_block_id TEXT,
    start_time TEXT NOT NULL,
    end_time TEXT NOT NULL,
    duration_seconds INTEGER NOT NULL,
    timer_mode TEXT NOT NULL DEFAULT 'stopwatch',
    is_manual_entry INTEGER NOT NULL DEFAULT 0, -- 0 = Live Timer, 1 = Manual Entry
    logical_date TEXT NOT NULL, -- YYYY-MM-DD calculated via 05:00 AM cutoff
    created_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_local_sessions_date ON local_study_sessions(logical_date);

-- ۳. جدول محلی لاگ‌های استراحت (Local Break Logs)
CREATE TABLE IF NOT EXISTS local_break_logs (
    id TEXT PRIMARY KEY NOT NULL,
    user_id TEXT NOT NULL,
    prev_session_id TEXT NOT NULL,
    next_session_id TEXT,
    start_time TEXT NOT NULL,
    end_time TEXT NOT NULL,
    duration_seconds INTEGER NOT NULL,
    break_tag TEXT,
    discarded_as_end_of_day INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL
);

-- ۴. صف تراکنش‌های همگام‌سازی محلی (Transaction Queue Outbox)
-- تضمین پاسخ‌دهی زیر ۱۰۰ میلی‌ثانیه و پایایی کامل در وضعیت آفلاین
CREATE TABLE IF NOT EXISTS transaction_queue (
    transaction_id TEXT PRIMARY KEY NOT NULL,
    workspace_id TEXT NOT NULL,
    user_id TEXT NOT NULL,
    client_timestamp INTEGER NOT NULL,
    operations TEXT NOT NULL, -- Serialized JSON Array of BlockOperation
    status TEXT NOT NULL DEFAULT 'pending', -- 'pending' | 'syncing' | 'committed' | 'rejected'
    retry_count INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_tx_queue_status ON transaction_queue(status, client_timestamp);
