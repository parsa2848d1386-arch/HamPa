-- ============================================================================
-- بخش ۱: پایگاه داده رابطه‌ای سرور (PostgreSQL Schema with JSONB & 5 AM Reset)
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ۱. تابع محاسبه تاریخ منطقی روز مطالعه با مرز ساعت ۰۵:۰۰ صبح
-- سشن‌هایی که بعد از نیمه‌شب تا ۰۴:۵۹:۵۹ بامداد ثبت می‌شوند، متعلق به روز قبل هستند.
CREATE OR REPLACE FUNCTION get_logical_study_date(ts TIMESTAMPTZ, user_tz TEXT DEFAULT 'Asia/Tehran')
RETURNS DATE AS $$
DECLARE
    local_ts TIMESTAMP;
BEGIN
    local_ts := ts AT TIME ZONE user_tz;
    -- اگر ساعت محلی قبل از ۵ صبح بود، یک روز کسر می‌شود
    IF EXTRACT(HOUR FROM local_ts) < 5 THEN
        RETURN (local_ts - INTERVAL '1 day')::DATE;
    ELSE
        RETURN local_ts::DATE;
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ۲. جدول عمومی بلاک‌ها (Universal Blocks Table)
-- تمام موجودیت‌ها (صفحات، دروس، تسک‌ها، پاراگراف‌ها، یادداشت‌های صوتی، بوم قلم) رکورد اتمیک هستند.
CREATE TABLE IF NOT EXISTS blocks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL,
    type VARCHAR(64) NOT NULL,
    
    -- ذخیره‌سازی داده‌های ساخت‌یافته و منعطف مستقل از Type
    properties JSONB NOT NULL DEFAULT '{}'::jsonb,
    
    -- درخت رندر رو به پایین: لیست مرتب شناسه‌های فرزندان برای صفحه‌بندی عرضی و ایندنت
    content UUID[] NOT NULL DEFAULT '{}',
    
    -- درخت دسترسی و مجوز رو به بالا: اشاره‌گر مستقیم به والد جهت اعتبارسنجی سلسله‌مراتبی
    parent_id UUID NOT NULL,
    parent_type VARCHAR(64) NOT NULL,
    
    version INT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE
);

-- ایندکس‌های حیاتی برای سرعت بارگذاری <50ms
CREATE INDEX IF NOT EXISTS idx_blocks_workspace_parent ON blocks(workspace_id, parent_id);
CREATE INDEX IF NOT EXISTS idx_blocks_type ON blocks(type);
CREATE INDEX IF NOT EXISTS idx_blocks_properties_gin ON blocks USING gin(properties);
CREATE INDEX IF NOT EXISTS idx_blocks_updated_at ON blocks(updated_at);

-- ۳. جدول سشن‌های مطالعه (Study Sessions Table)
CREATE TABLE IF NOT EXISTS study_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    subject_block_id UUID NOT NULL REFERENCES blocks(id) ON DELETE CASCADE,
    task_block_id UUID REFERENCES blocks(id) ON DELETE SET NULL,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    duration_seconds INT NOT NULL CHECK (duration_seconds >= 0),
    timer_mode VARCHAR(32) NOT NULL DEFAULT 'stopwatch',
    
    -- فیلد حیاتی ضدتقلب: رکوردهای دستی اکیداً از لیدربورد حذف می‌شوند
    is_manual_entry BOOLEAN NOT NULL DEFAULT FALSE,
    
    -- تاریخ منطقی روز مطالعه محاسبه شده بر اساس مرز ۰۵:۰۰ صبح
    logical_date DATE GENERATED ALWAYS AS (get_logical_study_date(start_time)) STORED,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sessions_user_date ON study_sessions(user_id, logical_date);
CREATE INDEX IF NOT EXISTS idx_sessions_leaderboard ON study_sessions(logical_date, duration_seconds) WHERE is_manual_entry = FALSE;

-- ۴. جدول لاگ‌های استراحت و گپ مطالعه (Break Logs Table)
CREATE TABLE IF NOT EXISTS break_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    prev_session_id UUID NOT NULL REFERENCES study_sessions(id) ON DELETE CASCADE,
    next_session_id UUID REFERENCES study_sessions(id) ON DELETE SET NULL,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    duration_seconds INT NOT NULL,
    
    -- برچسب الزامی استراحت (تغذیه، خواب، ورزش و...)
    break_tag VARCHAR(64),
    
    -- قانون حداکثر ۳ ساعت: اگر > 10800 ثانیه باشد، گپ منقضی شده تلقی می‌شود
    discarded_as_end_of_day BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ۵. جدول گروه‌های مطالعه و سیاست‌های مدیر گروه (Study Groups & Moderation)
CREATE TABLE IF NOT EXISTS study_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    creator_user_id UUID NOT NULL,
    chat_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    daily_message_quota_per_user INT NOT NULL DEFAULT 50, -- سقف روزانه پیام برای حذف حواس‌پرتی
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS group_memberships (
    group_id UUID NOT NULL REFERENCES study_groups(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    role VARCHAR(32) NOT NULL DEFAULT 'member', -- 'leader' | 'moderator' | 'member'
    custom_chat_allowed BOOLEAN NOT NULL DEFAULT TRUE,
    joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (group_id, user_id)
);
