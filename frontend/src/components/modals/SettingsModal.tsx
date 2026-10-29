import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  X, 
  Palette, 
  User, 
  Clock, 
  Database, 
  Check, 
  Flame, 
  Calendar, 
  Sliders, 
  Volume2, 
  Download, 
  Upload,
  Sparkles,
  ShieldCheck,
  Target,
  Cloud,
  RefreshCw,
  LogOut,
  LogIn,
  AlertCircle,
  Trash2
} from 'lucide-react';
import { useAppStore } from '../../store/useAppStore';
import { THEME_OPTIONS, ACCENT_PRESETS } from '../../lib/themeEngine';
import type { ThemePreset, AccentColorId, CalendarSystem } from '../../types';
import { formatToPersianDigits } from '../../lib/calendarUtils';
import { 
  loginWithGoogle, 
  loginWithEmail, 
  signupWithEmail, 
  loginAsGuest, 
  logoutUser,
  syncUserProfileToCloud,
  syncTasksToCloud,
  syncSessionsToCloud,
  fetchCloudUserData
} from '../../lib/firebase';
import { googleDriveService } from '../../lib/googleDrive';

type SettingsTab = 'appearance' | 'profile' | 'focus' | 'data';

export const SettingsModal: React.FC = () => {
  const isSettingsOpen = useAppStore((s) => s.isSettingsOpen);
  const setSettingsOpen = useAppStore((s) => s.setSettingsOpen);

  const themePreset = useAppStore((s) => s.themePreset);
  const setThemePreset = useAppStore((s) => s.setThemePreset);
  const accentColorId = useAppStore((s) => s.accentColorId);
  const setAccentColorId = useAppStore((s) => s.setAccentColorId);

  const calendarSystem = useAppStore((s) => s.calendarSystem);
  const setCalendarSystem = useAppStore((s) => s.setCalendarSystem);

  const user = useAppStore((s) => s.user);
  const updateUserProfile = useAppStore((s) => s.updateUserProfile);

  const dayCutoffHour = useAppStore((s) => s.dayCutoffHour);
  const setDayCutoffHour = useAppStore((s) => s.setDayCutoffHour);
  const pomodoroWorkMinutes = useAppStore((s) => s.pomodoroWorkMinutes);
  const pomodoroBreakMinutes = useAppStore((s) => s.pomodoroBreakMinutes);
  const setPomodoroSettings = useAppStore((s) => s.setPomodoroSettings);
  const setFocusModalOpen = useAppStore((s) => s.setFocusModalOpen);

  const tasks = useAppStore((s) => s.tasks);
  const sessions = useAppStore((s) => s.sessions);
  const subjects = useAppStore((s) => s.subjects);
  const setTasks = useAppStore((s) => s.setTasks);
  const setSessions = useAppStore((s) => s.setSessions);
  const clearAllData = useAppStore((s) => s.clearAllData);

  const [activeTab, setActiveTab] = useState<SettingsTab>('appearance');

  // Local Profile Form State
  const [displayName, setDisplayName] = useState(user.displayName || 'کاربر هم‌پا');
  const [email, setEmail] = useState(user.email || '');
  const [password, setPassword] = useState('');
  const [isSignUpMode, setIsSignUpMode] = useState(false);
  const [authLoading, setAuthLoading] = useState(false);
  const [authFeedback, setAuthFeedback] = useState<{ type: 'success' | 'error'; message: string } | null>(null);

  const [bio, setBio] = useState(user.bio || '');
  const [targetExamTitle, setTargetExamTitle] = useState(user.targetExamTitle || '');
  const [targetExamDate, setTargetExamDate] = useState(user.targetExamDate || '');
  const [dailyCapacityMinutes, setDailyCapacityMinutes] = useState(user.dailyCapacityMinutes || 360);
  const [profileSaved, setProfileSaved] = useState(false);

  // Cloud & Google Drive states
  const [driveConnected, setDriveConnected] = useState(googleDriveService.isConnected());
  const [driveTokenInput, setDriveTokenInput] = useState('');
  const [driveLoading, setDriveLoading] = useState(false);
  const [cloudSyncLoading, setCloudSyncLoading] = useState(false);
  const [cloudFeedback, setCloudFeedback] = useState<{ type: 'success' | 'error'; message: string } | null>(null);

  // Focus engine local settings
  const [cutoffActive, setCutoffActive] = useState(dayCutoffHour === 5);
  const [workTime, setWorkTime] = useState(pomodoroWorkMinutes);
  const [breakTime, setBreakTime] = useState(pomodoroBreakMinutes);

  useEffect(() => {
    setDisplayName(user.displayName || 'کاربر هم‌پا');
    setEmail(user.email || '');
    setBio(user.bio || '');
    setTargetExamTitle(user.targetExamTitle || '');
    setTargetExamDate(user.targetExamDate || '');
    setDailyCapacityMinutes(user.dailyCapacityMinutes || 360);
  }, [user]);

  if (!isSettingsOpen) return null;

  // Calculate Days Remaining to Target Exam (D-Day)
  const calcDDay = (dateStr: string) => {
    if (!dateStr) return 0;
    try {
      const target = new Date(dateStr).getTime();
      const today = new Date().setHours(0, 0, 0, 0);
      const diffDays = Math.ceil((target - today) / (1000 * 60 * 60 * 24));
      return diffDays;
    } catch {
      return 0;
    }
  };

  const daysLeft = calcDDay(targetExamDate);

  const handleSaveProfile = (e: React.FormEvent) => {
    e.preventDefault();
    updateUserProfile({
      displayName: displayName.trim() || 'کاربر هم‌پا',
      email: email.trim() || null,
      bio: bio.trim(),
      targetExamTitle: targetExamTitle.trim(),
      targetExamDate,
      dailyCapacityMinutes,
    });
    setProfileSaved(true);
    setTimeout(() => setProfileSaved(false), 2500);
  };

  const handleGoogleAuth = async () => {
    setAuthLoading(true);
    setAuthFeedback(null);
    try {
      const fbUser = await loginWithGoogle();
      updateUserProfile({
        uid: fbUser.uid,
        displayName: fbUser.displayName || 'کاربر گوگل',
        email: fbUser.email,
        photoURL: fbUser.photoURL,
        isGuest: false,
      });
      setDriveConnected(googleDriveService.isConnected());
      setAuthFeedback({ type: 'success', message: `خوش آمدید، ${fbUser.displayName || fbUser.email}` });
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      setAuthFeedback({ type: 'error', message: `ورود با گوگل انجام نشد: ${msg}` });
    } finally {
      setAuthLoading(false);
    }
  };

  const handleEmailAuth = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email || !password) {
      setAuthFeedback({ type: 'error', message: 'لطفاً ایمیل و رمز عبور را وارد کنید.' });
      return;
    }
    setAuthLoading(true);
    setAuthFeedback(null);
    try {
      let fbUser;
      if (isSignUpMode) {
        fbUser = await signupWithEmail(email, password);
        setAuthFeedback({ type: 'success', message: 'حساب کاربری جدید با موفقیت ساخته شد.' });
      } else {
        fbUser = await loginWithEmail(email, password);
        setAuthFeedback({ type: 'success', message: 'ورود به حساب با موفقیت انجام شد.' });
      }
      updateUserProfile({
        uid: fbUser.uid,
        displayName: fbUser.displayName || email.split('@')[0],
        email: fbUser.email,
        isGuest: false,
      });
      setPassword('');
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      setAuthFeedback({ type: 'error', message: `خطا: ${msg}` });
    } finally {
      setAuthLoading(false);
    }
  };

  const handleGuestAuth = async () => {
    setAuthLoading(true);
    setAuthFeedback(null);
    try {
      const fbUser = await loginAsGuest();
      updateUserProfile({
        uid: fbUser.uid,
        isGuest: true,
      });
      setAuthFeedback({ type: 'success', message: 'به عنوان کاربر مهمان وارد شدید.' });
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      setAuthFeedback({ type: 'error', message: `خطا: ${msg}` });
    } finally {
      setAuthLoading(false);
    }
  };

  const handleLogout = async () => {
    await logoutUser();
    updateUserProfile({
      uid: 'guest-' + Math.random().toString(36).substring(2, 9),
      displayName: 'کاربر هم‌پا',
      email: '',
      photoURL: null,
      isGuest: true,
    });
    setDriveConnected(false);
    setAuthFeedback({ type: 'success', message: 'با موفقیت خارج شدید.' });
  };

  // Google Drive Handlers
  const handleDriveBackup = async () => {
    setDriveLoading(true);
    setCloudFeedback(null);
    try {
      const backupPayload = {
        version: '2.4.0',
        timestamp: new Date().toISOString(),
        appName: 'HamPA',
        user,
        tasks,
        subjects,
        sessions,
      };
      const res = await googleDriveService.uploadBackup(backupPayload);
      if (res.success) {
        setCloudFeedback({ type: 'success', message: 'پشتیبان با موفقیت در فولدر HamPA گوگل درایو ذخیره شد.' });
      } else {
        setCloudFeedback({ type: 'error', message: res.error || 'خطا در پشتیبان‌گیری در گوگل درایو.' });
      }
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      setCloudFeedback({ type: 'error', message: msg });
    } finally {
      setDriveLoading(false);
    }
  };

  const handleDriveRestore = async () => {
    if (!window.confirm('آیا از بازیابی اطلاعات از گوگل درایو اطمینان دارید؟ اطلاعات فعلی با نسخه پشتیبان جایگزین خواهد شد.')) return;
    setDriveLoading(true);
    setCloudFeedback(null);
    try {
      const res = await googleDriveService.downloadLatestBackup();
      if (res.success && res.data) {
        const d = res.data;
        if (Array.isArray(d.tasks)) setTasks(d.tasks as any);
        if (Array.isArray(d.sessions)) setSessions(d.sessions as any);
        if (d.user) updateUserProfile(d.user as any);
        setCloudFeedback({ type: 'success', message: 'اطلاعات با موفقیت از گوگل درایو بازیابی شد.' });
      } else {
        setCloudFeedback({ type: 'error', message: res.error || 'فایلی در گوگل درایو یافت نشد.' });
      }
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      setCloudFeedback({ type: 'error', message: msg });
    } finally {
      setDriveLoading(false);
    }
  };

  // Firestore Sync Handlers
  const handlePushToFirestore = async () => {
    setCloudSyncLoading(true);
    setCloudFeedback(null);
    try {
      await syncUserProfileToCloud(user.uid, user);
      await syncTasksToCloud(user.uid, tasks);
      await syncSessionsToCloud(user.uid, sessions);
      setCloudFeedback({ type: 'success', message: 'اطلاعات با پایگاه داده ابری Firestore همگام‌سازی شد.' });
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      setCloudFeedback({ type: 'error', message: `خطا در همگام‌سازی: ${msg}` });
    } finally {
      setCloudSyncLoading(false);
    }
  };

  const handlePullFromFirestore = async () => {
    setCloudSyncLoading(true);
    setCloudFeedback(null);
    try {
      const cloudData = await fetchCloudUserData(user.uid);
      if (cloudData) {
        if (cloudData.tasks && cloudData.tasks.length > 0) setTasks(cloudData.tasks);
        if (cloudData.sessions && cloudData.sessions.length > 0) setSessions(cloudData.sessions);
        if (cloudData.profile) updateUserProfile(cloudData.profile);
        setCloudFeedback({ type: 'success', message: 'اطلاعات ابری با موفقیت دریافت و اعمال شد.' });
      } else {
        setCloudFeedback({ type: 'error', message: 'داده‌ای در سرور ابری یافت نشد.' });
      }
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      setCloudFeedback({ type: 'error', message: msg });
    } finally {
      setCloudSyncLoading(false);
    }
  };

  const handleResetWorkspace = () => {
    if (window.confirm('آیا از پاکسازی کامل تسک‌ها و جلسات اطمینان دارید؟ تمام اطلاعات فیک یا تستی حذف شده و یک بوم خالی در اختیارتان قرار می‌گیرد.')) {
      clearAllData();
      setCloudFeedback({ type: 'success', message: 'فضای کاری کاملاً پاکسازی و آماده استفاده واقعی شد.' });
    }
  };

  const handleCutoffToggle = (active: boolean) => {
    setCutoffActive(active);
    setDayCutoffHour(active ? 5 : 0);
  };

  const handlePomodoroChange = (w: number, b: number) => {
    setWorkTime(w);
    setBreakTime(b);
    setPomodoroSettings(w, b);
  };

  const handleExportData = () => {
    const data = {
      exportDate: new Date().toISOString(),
      user,
      tasks,
      sessions,
    };
    const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `hampa-backup-${new Date().toISOString().split('T')[0]}.json`;
    a.click();
    URL.revokeObjectURL(url);
  };

  const currentAccent = ACCENT_PRESETS.find((a) => a.id === accentColorId) || ACCENT_PRESETS[0];

  return (
    <AnimatePresence>
      <div 
        className="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-5 bg-black/60 backdrop-blur-md"
        role="dialog"
        aria-modal="true"
        aria-labelledby="settings-modal-title"
      >
        <motion.div
          initial={{ opacity: 0, scale: 0.95, y: 15 }}
          animate={{ opacity: 1, scale: 1, y: 0 }}
          exit={{ opacity: 0, scale: 0.95, y: 15 }}
          transition={{ type: 'spring', damping: 28, stiffness: 380 }}
          className="w-full max-w-3xl max-h-[90vh] flex flex-col rounded-2xl bg-canvas-elevated liquid-glass border border-border-highlight shadow-2xl overflow-hidden text-ink-primary font-vazir"
        >
          {/* Header */}
          <div className="flex items-center justify-between px-5 py-4 border-b border-border-subtle bg-canvas/40">
            <div className="flex items-center gap-2.5">
              <div 
                className="w-8 h-8 rounded-xl flex items-center justify-center text-white shadow-sm"
                style={{ backgroundColor: currentAccent.primary }}
              >
                <Sliders className="w-4 h-4" />
              </div>
              <div>
                <h2 id="settings-modal-title" className="text-sm font-black text-ink-primary">
                  تنظیمات و شخصی‌سازی پیشرفته
                </h2>
                <p className="text-[11px] text-ink-muted">
                  تم‌های تلگرامی، شخصی‌سازی رنگ‌ها، پروفایل و استودیو مطالعه YPT
                </p>
              </div>
            </div>

            <button
              onClick={() => setSettingsOpen(false)}
              className="p-1.5 rounded-xl border border-border-subtle hover:bg-white/10 text-ink-muted hover:text-ink-primary transition"
              aria-label="بستن تنظیمات"
            >
              <X className="w-4 h-4" />
            </button>
          </div>

          {/* Tab Navigation */}
          <div className="flex items-center gap-1 px-5 pt-3 border-b border-border-subtle bg-canvas/20 overflow-x-auto select-none">
            <button
              onClick={() => setActiveTab('appearance')}
              className={`flex items-center gap-2 px-3.5 py-2 rounded-t-xl text-xs font-bold border-b-2 transition ${
                activeTab === 'appearance'
                  ? 'border-accent-primary text-accent-primary bg-accent-primary/10'
                  : 'border-transparent text-ink-muted hover:text-ink-primary hover:bg-white/5'
              }`}
            >
              <Palette className="w-3.5 h-3.5" />
              <span>ظاهر و تم تلگرامی</span>
            </button>

            <button
              onClick={() => setActiveTab('profile')}
              className={`flex items-center gap-2 px-3.5 py-2 rounded-t-xl text-xs font-bold border-b-2 transition ${
                activeTab === 'profile'
                  ? 'border-accent-primary text-accent-primary bg-accent-primary/10'
                  : 'border-transparent text-ink-muted hover:text-ink-primary hover:bg-white/5'
              }`}
            >
              <User className="w-3.5 h-3.5" />
              <span>پروفایل و هدف D-Day</span>
            </button>

            <button
              onClick={() => setActiveTab('focus')}
              className={`flex items-center gap-2 px-3.5 py-2 rounded-t-xl text-xs font-bold border-b-2 transition ${
                activeTab === 'focus'
                  ? 'border-accent-primary text-accent-primary bg-accent-primary/10'
                  : 'border-transparent text-ink-muted hover:text-ink-primary hover:bg-white/5'
              }`}
            >
              <Clock className="w-3.5 h-3.5" />
              <span>موتور تمرکز YPT</span>
            </button>

            <button
              onClick={() => setActiveTab('data')}
              className={`flex items-center gap-2 px-3.5 py-2 rounded-t-xl text-xs font-bold border-b-2 transition ${
                activeTab === 'data'
                  ? 'border-accent-primary text-accent-primary bg-accent-primary/10'
                  : 'border-transparent text-ink-muted hover:text-ink-primary hover:bg-white/5'
              }`}
            >
              <Database className="w-3.5 h-3.5" />
              <span>پشتیبان‌گیری و داده‌ها</span>
            </button>
          </div>

          {/* Modal Body / Tab Contents */}
          <div className="flex-1 overflow-y-auto p-5 sm:p-6 space-y-6">
            {/* ========================================================
                TAB 1: APPEARANCE & TELEGRAM THEMES
                ======================================================== */}
            {activeTab === 'appearance' && (
              <div className="space-y-6">
                {/* 1. Theme Selection Cards (Telegram Style) */}
                <div>
                  <div className="flex items-center justify-between mb-3">
                    <label className="text-xs font-black text-ink-primary flex items-center gap-1.5">
                      <Sparkles className="w-3.5 h-3.5 text-accent-primary" />
                      <span>انتخاب تم پایه (الهام‌گرفته از تلگرام دسکتاپ)</span>
                    </label>
                    <span className="text-[11px] text-ink-muted">۴ تم مهندسی‌شده</span>
                  </div>

                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                    {THEME_OPTIONS.map((opt) => {
                      const isSelected = themePreset === opt.id;
                      return (
                        <div
                          key={opt.id}
                          onClick={() => setThemePreset(opt.id)}
                          className={`relative p-3.5 rounded-xl border-2 cursor-pointer transition-all ${
                            isSelected
                              ? 'border-accent-primary bg-accent-primary/5 shadow-md scale-[1.01]'
                              : 'border-border-subtle hover:border-border-highlight bg-canvas-secondary/50'
                          }`}
                        >
                          {/* Mini Mockup Window */}
                          <div 
                            className="w-full h-20 rounded-lg p-2 mb-2.5 flex flex-col justify-between border border-white/10 shadow-inner overflow-hidden"
                            style={{ backgroundColor: opt.bgHex }}
                          >
                            {/* Mini Header */}
                            <div 
                              className="h-4 rounded px-1.5 flex items-center justify-between text-[9px]"
                              style={{ backgroundColor: opt.previewHeaderHex, color: opt.isDark ? '#fff' : '#111' }}
                            >
                              <span className="font-bold">هم‌پا</span>
                              <div className="w-2 h-2 rounded-full" style={{ backgroundColor: currentAccent.primary }} />
                            </div>

                            {/* Mini Task / Chat Bubble */}
                            <div className="flex items-center gap-1.5">
                              <div 
                                className="flex-1 h-5 rounded px-2 flex items-center justify-between text-[8px]"
                                style={{ backgroundColor: opt.previewBubbleHex, color: opt.isDark ? '#e2e8f0' : '#1f2937' }}
                              >
                                <span className="truncate">مطالعه ریاضی و فیزیک</span>
                                <span className="font-mono text-[7px] text-ink-muted">45m</span>
                              </div>
                              <div 
                                className="w-5 h-5 rounded flex items-center justify-center text-[8px] text-white font-bold"
                                style={{ backgroundColor: currentAccent.primary }}
                              >
                                ✓
                              </div>
                            </div>
                          </div>

                          {/* Info & Radio */}
                          <div className="flex items-start justify-between">
                            <div>
                              <div className="flex items-center gap-1.5">
                                <span className="text-xs font-bold text-ink-primary">{opt.title}</span>
                                <span className="text-[10px] px-1.5 py-0.2 rounded bg-black/10 dark:bg-white/10 text-ink-muted font-mono">
                                  {opt.badge}
                                </span>
                              </div>
                              <p className="text-[11px] text-ink-muted mt-0.5 leading-snug">
                                {opt.description}
                              </p>
                            </div>

                            {/* Radio Pill */}
                            <div 
                              className={`w-4 h-4 rounded-full border-2 flex items-center justify-center flex-shrink-0 mt-0.5 transition ${
                                isSelected ? 'border-accent-primary bg-accent-primary text-white' : 'border-border-subtle'
                              }`}
                            >
                              {isSelected && <Check className="w-2.5 h-2.5 stroke-[3]" />}
                            </div>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </div>

                {/* 2. Accent Color Palette (Telegram 7-Color Circles) */}
                <div>
                  <div className="flex items-center justify-between mb-3">
                    <label className="text-xs font-black text-ink-primary flex items-center gap-1.5">
                      <Palette className="w-3.5 h-3.5 text-accent-primary" />
                      <span>پالت رنگ‌های تاکیدی (Accent Color)</span>
                    </label>
                    <span className="text-[11px] font-bold text-accent-primary">
                      {currentAccent.name}
                    </span>
                  </div>

                  <div className="flex items-center justify-between gap-2 p-3 rounded-xl bg-canvas-secondary border border-border-subtle">
                    {ACCENT_PRESETS.map((accent) => {
                      const isSelected = accentColorId === accent.id;
                      return (
                        <button
                          key={accent.id}
                          onClick={() => setAccentColorId(accent.id)}
                          className={`relative group flex flex-col items-center gap-1.5 transition-transform active:scale-95`}
                          title={`${accent.name} (${accent.nameEn})`}
                        >
                          <div
                            className={`w-8 h-8 sm:w-9 sm:h-9 rounded-full flex items-center justify-center transition-all ${
                              isSelected
                                ? 'ring-4 ring-offset-2 ring-offset-canvas shadow-lg scale-110'
                                : 'hover:scale-105 opacity-80 hover:opacity-100'
                            }`}
                            style={{ 
                              backgroundColor: accent.primary,
                              boxShadow: isSelected ? `0 0 14px ${accent.primary}` : undefined,
                            }}
                          >
                            {isSelected && (
                              <Check className="w-4 h-4 text-white stroke-[3] drop-shadow" />
                            )}
                          </div>
                          <span className="text-[10px] font-medium text-ink-muted hidden sm:inline">
                            {accent.name.split(' ')[0]}
                          </span>
                        </button>
                      );
                    })}
                  </div>
                </div>

                {/* 3. Live Interactive Theme Preview */}
                <div>
                  <label className="text-xs font-black text-ink-primary mb-2 block">
                    پیش‌نمایش زنده المان‌های رابط کاربری با تم انتخابی:
                  </label>
                  <div className="p-4 rounded-xl border border-border-highlight bg-canvas-elevated liquid-glass shadow-lg flex flex-col sm:flex-row items-center justify-between gap-3">
                    <div className="flex items-center gap-3 w-full sm:w-auto">
                      <div 
                        className="w-10 h-10 rounded-xl flex items-center justify-center text-white shadow-needle font-bold text-sm"
                        style={{ backgroundColor: currentAccent.primary }}
                      >
                        ✓
                      </div>
                      <div>
                        <div className="flex items-center gap-2">
                          <span className="text-xs font-bold text-ink-primary">مرور تست‌های جمع‌بندی کنکور</span>
                          <span 
                            className="text-[10px] px-2 py-0.5 rounded-full font-bold"
                            style={{ 
                              backgroundColor: currentAccent.subtle, 
                              color: currentAccent.primary 
                            }}
                          >
                            تسک طلایی (MIT)
                          </span>
                        </div>
                        <p className="text-[11px] text-ink-muted">مدت تخمینی: ۴۵ دقیقه • زیست‌شناسی تخصصی</p>
                      </div>
                    </div>

                    <button
                      type="button"
                      onClick={() => {
                        setSettingsOpen(false);
                        setFocusModalOpen(true);
                      }}
                      className="px-4 py-2 rounded-xl text-white text-xs font-bold shadow-needle transition active:scale-95 flex items-center gap-1.5 w-full sm:w-auto justify-center cursor-pointer"
                      style={{ backgroundColor: currentAccent.primary }}
                      title="ورود به استودیو تمرکز"
                    >
                      <Flame className="w-3.5 h-3.5" />
                      <span>شروع تمرکز فوری</span>
                    </button>
                  </div>
                </div>

                {/* 4. Calendar System Selector */}
                <div className="p-4 rounded-xl bg-canvas-secondary border border-border-subtle flex items-center justify-between">
                  <div className="flex items-center gap-2.5">
                    <Calendar className="w-4 h-4 text-accent-primary" />
                    <div>
                      <span className="text-xs font-bold text-ink-primary">سیستم گاه‌شماری پیش‌فرض</span>
                      <p className="text-[11px] text-ink-muted">نمایش تقویم در نوار بالا، سایدبار و پلنر</p>
                    </div>
                  </div>

                  <div className="flex items-center gap-1 p-1 rounded-xl bg-canvas border border-border-subtle text-xs">
                    <button
                      onClick={() => setCalendarSystem('jalali')}
                      className={`px-3 py-1.5 rounded-lg font-bold transition ${
                        calendarSystem === 'jalali'
                          ? 'bg-accent-primary text-white shadow-sm'
                          : 'text-ink-muted hover:text-ink-primary'
                      }`}
                    >
                      خورشیدی (جلالی)
                    </button>
                    <button
                      onClick={() => setCalendarSystem('gregorian')}
                      className={`px-3 py-1.5 rounded-lg font-bold transition ${
                        calendarSystem === 'gregorian'
                          ? 'bg-accent-primary text-white shadow-sm'
                          : 'text-ink-muted hover:text-ink-primary'
                      }`}
                    >
                      میلادی (Gregorian)
                    </button>
                  </div>
                </div>
              </div>
            )}

            {/* ========================================================
                TAB 2: USER PROFILE & TARGET EXAM (D-DAY)
                ======================================================== */}
            {activeTab === 'profile' && (
              <div className="space-y-6">
                {/* Firebase Authentication & Cloud Identity Capsule */}
                <div className="p-4 rounded-2xl bg-canvas-secondary border border-border-subtle space-y-3">
                  <div className="flex items-center justify-between pb-2 border-b border-border-subtle">
                    <div className="flex items-center gap-2">
                      <Cloud className="w-4 h-4 text-accent-primary" />
                      <span className="text-xs font-bold text-ink-primary">
                        اتصال به حساب ابری (Firebase & Google Identity)
                      </span>
                    </div>
                    <span className={`text-[10px] px-2 py-0.5 rounded-full font-bold border ${
                      !user.isGuest 
                        ? 'bg-emerald-500/15 text-emerald-400 border-emerald-500/30' 
                        : 'bg-amber-500/15 text-amber-400 border-amber-500/30'
                    }`}>
                      {!user.isGuest ? 'متصل به حساب ابری' : 'حالت مهمان محلی'}
                    </span>
                  </div>

                  {/* Feedback Message */}
                  {authFeedback && (
                    <div className={`p-2.5 rounded-xl text-xs font-semibold flex items-center gap-2 ${
                      authFeedback.type === 'success' 
                        ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/30' 
                        : 'bg-rose-500/10 text-rose-400 border border-rose-500/30'
                    }`}>
                      {authFeedback.type === 'success' ? <Check className="w-4 h-4" /> : <AlertCircle className="w-4 h-4" />}
                      <span>{authFeedback.message}</span>
                    </div>
                  )}

                  {!user.isGuest ? (
                    <div className="flex items-center justify-between pt-1">
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-xl bg-accent-primary flex items-center justify-center text-white font-black text-sm">
                          {user.displayName ? user.displayName.slice(0, 1) : 'ک'}
                        </div>
                        <div>
                          <div className="text-xs font-bold text-ink-primary">{user.displayName}</div>
                          <div className="text-[11px] text-ink-muted">{user.email || 'حساب بدون ایمیل'}</div>
                        </div>
                      </div>

                      <button
                        type="button"
                        onClick={handleLogout}
                        className="px-3 py-1.5 rounded-xl bg-white/5 hover:bg-rose-500/20 text-rose-400 border border-border-subtle text-xs font-bold flex items-center gap-1.5 transition active:scale-95"
                      >
                        <LogOut className="w-3.5 h-3.5" />
                        <span>خروج از حساب</span>
                      </button>
                    </div>
                  ) : (
                    <div className="space-y-3 pt-1">
                      {/* One-Click Google Login with Google Drive Scope */}
                      <button
                        type="button"
                        disabled={authLoading}
                        onClick={handleGoogleAuth}
                        className="w-full py-2.5 rounded-xl bg-white hover:bg-zinc-100 text-zinc-900 text-xs font-bold flex items-center justify-center gap-2 shadow-sm transition active:scale-98 disabled:opacity-50"
                      >
                        <svg className="w-4 h-4" viewBox="0 0 24 24">
                          <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
                          <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
                          <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.06H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.94l2.85-2.22.81-.63z"/>
                          <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.06l3.66 2.84c.87-2.6 3.3-4.52 6.16-4.52z"/>
                        </svg>
                        <span>{authLoading ? 'در حال اتصال...' : 'ورود سریع با حساب Google'}</span>
                      </button>

                      {/* Or Email/Password */}
                      <form onSubmit={handleEmailAuth} className="space-y-2.5 pt-2 border-t border-border-subtle">
                        <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                          <input
                            type="email"
                            value={email}
                            onChange={(e) => setEmail(e.target.value)}
                            placeholder="ایمیل شما (example@gmail.com)"
                            className="w-full px-3 py-2 rounded-xl bg-canvas border border-border-subtle text-xs text-ink-primary focus:outline-none focus:border-accent-primary"
                          />
                          <input
                            type="password"
                            value={password}
                            onChange={(e) => setPassword(e.target.value)}
                            placeholder="رمز عبور"
                            className="w-full px-3 py-2 rounded-xl bg-canvas border border-border-subtle text-xs text-ink-primary focus:outline-none focus:border-accent-primary"
                          />
                        </div>

                        <div className="flex items-center justify-between gap-2 pt-1">
                          <button
                            type="button"
                            onClick={() => setIsSignUpMode(!isSignUpMode)}
                            className="text-[11px] text-accent-primary hover:underline"
                          >
                            {isSignUpMode ? 'حساب کاربری دارید؟ ورود' : 'حساب ندارید؟ ثبت‌نام جدید'}
                          </button>

                          <div className="flex items-center gap-2">
                            <button
                              type="button"
                              onClick={handleGuestAuth}
                              className="px-3 py-1.5 rounded-lg text-[11px] text-ink-muted hover:bg-white/5"
                            >
                              ادامه به عنوان مهمان
                            </button>
                            <button
                              type="submit"
                              disabled={authLoading}
                              className="px-4 py-1.5 rounded-xl bg-accent-primary hover:bg-accent-hover text-white text-xs font-bold transition active:scale-95 disabled:opacity-50"
                            >
                              {authLoading ? 'لطفاً صبر کنید...' : (isSignUpMode ? 'ثبت‌نام در هم‌پا' : 'ورود به حساب')}
                            </button>
                          </div>
                        </div>
                      </form>
                    </div>
                  )}
                </div>

                {/* Profile Form Details */}
                <form onSubmit={handleSaveProfile} className="space-y-5">
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <div>
                      <label className="text-xs font-bold text-ink-primary block mb-1.5">
                        نام نمایشی شما:
                      </label>
                      <input
                        type="text"
                        value={displayName}
                        onChange={(e) => setDisplayName(e.target.value)}
                        placeholder="نام شما..."
                        className="w-full px-3.5 py-2.5 rounded-xl bg-canvas border border-border-subtle text-xs text-ink-primary focus:outline-none focus:border-accent-primary"
                      />
                    </div>

                    <div>
                      <label className="text-xs font-bold text-ink-primary block mb-1.5">
                        ایمیل کاربری:
                      </label>
                      <input
                        type="email"
                        value={email}
                        onChange={(e) => setEmail(e.target.value)}
                        placeholder="user@example.com"
                        className="w-full px-3.5 py-2.5 rounded-xl bg-canvas border border-border-subtle text-xs text-ink-primary focus:outline-none focus:border-accent-primary"
                      />
                    </div>
                  </div>

                  <div>
                    <label className="text-xs font-bold text-ink-primary block mb-1.5">
                      شعار تمرکز یا هدف انگیزه شخصی:
                    </label>
                    <input
                      type="text"
                      value={bio}
                      onChange={(e) => setBio(e.target.value)}
                      placeholder="مثال: هر روز یک قدم نزدیک‌تر به موفقیت"
                      className="w-full px-3.5 py-2.5 rounded-xl bg-canvas border border-border-subtle text-xs text-ink-primary focus:outline-none focus:border-accent-primary"
                    />
                  </div>

                  {/* Target Exam & D-Day Countdown Card */}
                  <div className="p-4 rounded-xl border border-accent-primary/40 bg-accent-primary/5 space-y-3">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        <Target className="w-4 h-4 text-accent-primary" />
                        <span className="text-xs font-black text-ink-primary">
                          آزمون هدف و روزشمار معکوس (D-Day)
                        </span>
                      </div>

                      <div className="flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-accent-primary text-white text-xs font-black font-mono shadow-sm">
                        <span>D-{daysLeft > 0 ? daysLeft : 0}</span>
                        <span className="text-[10px] font-normal">({formatToPersianDigits(daysLeft)} روز)</span>
                      </div>
                    </div>

                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 pt-1">
                      <div>
                        <label className="text-[11px] font-bold text-ink-muted block mb-1">
                          عنوان آزمون یا هدف اصلی:
                        </label>
                        <input
                          type="text"
                          value={targetExamTitle}
                          onChange={(e) => setTargetExamTitle(e.target.value)}
                          placeholder="کنکور سراسری، آزمون وکالت، آیلتس..."
                          className="w-full px-3 py-2 rounded-lg bg-canvas border border-border-subtle text-xs text-ink-primary focus:outline-none focus:border-accent-primary"
                        />
                      </div>

                      <div>
                        <label className="text-[11px] font-bold text-ink-muted block mb-1">
                          تاریخ آزمون (میلادی برای شمارش):
                        </label>
                        <input
                          type="date"
                          value={targetExamDate}
                          onChange={(e) => setTargetExamDate(e.target.value)}
                          className="w-full px-3 py-2 rounded-lg bg-canvas border border-border-subtle text-xs text-ink-primary focus:outline-none focus:border-accent-primary font-mono"
                        />
                      </div>
                    </div>
                  </div>

                  {/* Daily Study Capacity Slider */}
                  <div>
                    <div className="flex items-center justify-between mb-1.5">
                      <label className="text-xs font-bold text-ink-primary">
                        ظرفیت مطالعه روزانه (Daily Capacity):
                      </label>
                      <span className="text-xs font-bold text-accent-primary font-mono">
                        {formatToPersianDigits(Math.floor(dailyCapacityMinutes / 60))} ساعت و {formatToPersianDigits(dailyCapacityMinutes % 60)} دقیقه ({formatToPersianDigits(dailyCapacityMinutes)}m)
                      </span>
                    </div>
                    <input
                      type="range"
                      min="120"
                      max="840"
                      step="30"
                      value={dailyCapacityMinutes}
                      onChange={(e) => setDailyCapacityMinutes(Number(e.target.value))}
                      className="w-full accent-accent-primary cursor-pointer"
                    />
                    <div className="flex justify-between text-[10px] text-ink-muted mt-1">
                      <span>۲ ساعت (مینیمال)</span>
                      <span>۶ ساعت (استاندارد)</span>
                      <span>۱۰ ساعت (حرفه‌ای کنکور)</span>
                      <span>۱۴ ساعت</span>
                    </div>
                  </div>

                  {/* Save Profile Button */}
                  <div className="flex items-center justify-end gap-3 pt-3 border-t border-border-subtle">
                    {profileSaved && (
                      <span className="text-xs text-emerald-400 font-bold flex items-center gap-1 animate-fade-in">
                        <Check className="w-3.5 h-3.5" />
                        تغییرات پروفایل با موفقیت ذخیره شد
                      </span>
                    )}
                    <button
                      type="submit"
                      className="px-5 py-2 rounded-xl bg-accent-primary hover:bg-accent-hover text-white text-xs font-black shadow-needle transition active:scale-95 cursor-pointer"
                    >
                      ذخیره اطلاعات کاربری
                    </button>
                  </div>
                </form>
              </div>
            )}

            {/* ========================================================
                TAB 3: YPT FOCUS ENGINE PREFERENCES
                ======================================================== */}
            {activeTab === 'focus' && (
              <div className="space-y-5">
                {/* 05:00 AM Cutoff Rule (The iconic YPT feature) */}
                <div className="p-4 rounded-xl bg-canvas-secondary border border-border-subtle flex items-start justify-between gap-4">
                  <div>
                    <div className="flex items-center gap-2">
                      <Clock className="w-4 h-4 text-accent-primary" />
                      <span className="text-xs font-bold text-ink-primary">
                        قانون ریست ۵ صبح (YPT 05:00 AM Day-Cutoff)
                      </span>
                    </div>
                    <p className="text-[11px] text-ink-muted mt-1 leading-relaxed">
                      در متد برنامه‌ریزی YPT، مطالعه پس از نیمه‌شب تا ساعت ۰۵:۰۰ بامداد به عنوان بخشی از روز گذشته محسوب می‌شود تا گزارش مطالعه شبانه شما یکپارچه بماند و زنجیره پیوستگی قطع نشود.
                    </p>
                  </div>

                  <button
                    type="button"
                    onClick={() => handleCutoffToggle(!cutoffActive)}
                    className={`relative inline-flex h-6 w-11 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none ${
                      cutoffActive ? 'bg-accent-primary' : 'bg-white/20'
                    }`}
                  >
                    <span
                      className={`inline-block h-5 w-5 transform rounded-full bg-white shadow-lg transition duration-200 ease-in-out ${
                        cutoffActive ? '-translate-x-5' : 'translate-x-0'
                      }`}
                    />
                  </button>
                </div>

                {/* Pomodoro Work/Break Presets */}
                <div className="p-4 rounded-xl bg-canvas-secondary border border-border-subtle space-y-3">
                  <span className="text-xs font-bold text-ink-primary block">
                    تنظیمات پیش‌فرض پومودورو استودیو تمرکز:
                  </span>

                  <div className="grid grid-cols-3 gap-2">
                    {[
                      { title: 'کلاسیک (25/5)', work: 25, brk: 5 },
                      { title: 'تمرکز عمیق (50/10)', work: 50, brk: 10 },
                      { title: 'ماراتن التردین (90/20)', work: 90, brk: 20 },
                    ].map((preset) => {
                      const isActive = workTime === preset.work && breakTime === preset.brk;
                      return (
                        <button
                          key={preset.title}
                          type="button"
                          onClick={() => handlePomodoroChange(preset.work, preset.brk)}
                          className={`p-2.5 rounded-xl border text-center transition ${
                            isActive
                              ? 'border-accent-primary bg-accent-primary/10 text-accent-primary font-bold'
                              : 'border-border-subtle bg-canvas text-ink-muted hover:text-ink-primary'
                          }`}
                        >
                          <div className="text-xs">{preset.title}</div>
                          <div className="text-[10px] text-ink-muted font-mono mt-0.5">
                            {preset.work}m کار / {preset.brk}m استراحت
                          </div>
                        </button>
                      );
                    })}
                  </div>
                </div>

                {/* Audio Engine Defaults */}
                <div className="p-4 rounded-xl bg-canvas-secondary border border-border-subtle flex items-center justify-between">
                  <div className="flex items-center gap-2.5">
                    <Volume2 className="w-4 h-4 text-accent-primary" />
                    <div>
                      <span className="text-xs font-bold text-ink-primary">
                        موتور صدای فراگیر و امبینت بیلیورال
                      </span>
                      <p className="text-[11px] text-ink-muted">
                        پشتیبانی از صدای باران، کافه شلوغ، نویز قهوه‌ای و فرکانس تمرکز ۴۰ هرتز
                      </p>
                    </div>
                  </div>
                  <span className="text-xs font-bold text-emerald-400">Web Audio API فعال</span>
                </div>
              </div>
            )}

            {/* ========================================================
                TAB 4: DATA MANAGEMENT & CLOUD BACKUP
                ======================================================== */}
            {activeTab === 'data' && (
              <div className="space-y-5">
                {/* Global Cloud Feedback */}
                {cloudFeedback && (
                  <div className={`p-3 rounded-xl text-xs font-semibold flex items-center gap-2 ${
                    cloudFeedback.type === 'success' 
                      ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/30' 
                      : 'bg-rose-500/10 text-rose-400 border border-rose-500/30'
                  }`}>
                    {cloudFeedback.type === 'success' ? <Check className="w-4 h-4" /> : <AlertCircle className="w-4 h-4" />}
                    <span>{cloudFeedback.message}</span>
                  </div>
                )}

                {/* 1. GOOGLE DRIVE BACKUP & CLOUD STORAGE */}
                <div className="p-4 rounded-2xl bg-canvas-secondary border border-border-subtle space-y-3">
                  <div className="flex items-center justify-between pb-2 border-b border-border-subtle">
                    <div className="flex items-center gap-2">
                      <svg className="w-5 h-5" viewBox="0 0 87.3 78" fill="none">
                        <path d="M6.6 66.85l3.85 6.65c.8 1.4 1.95 2.5 3.3 3.3l13.75-23.8H0c0 1.55.4 3.1 1.2 4.5l5.4 9.35z" fill="#0066DA"/>
                        <path d="M43.65 25L29.9 1.2C28.55.4 27 0 25.45 0H18.2c-1.55 0-3.1.4-4.5 1.2L0 25h43.65z" fill="#00AC47"/>
                        <path d="M73.55 76.8c1.35-.8 2.5-1.9 3.3-3.3l1.6-2.75 7.65-13.25c.8-1.4 1.2-2.95 1.2-4.5H43.65l13.75 23.8h16.15z" fill="#EA4335"/>
                        <path d="M43.65 25L57.4 1.2C56.05.4 54.5 0 52.95 0h-7.3c-1.55 0-3.1.4-4.5 1.2L27.5 25h16.15z" fill="#00832D"/>
                        <path d="M87.3 53.05c0-1.55-.4-3.1-1.2-4.5l-13.7-23.75-13.75-23.8c-1.35-.8-2.9-1.2-4.45-1.2H43.65l29.9 51.75 13.75.05c0 .5-.05 1-.1 1.45h.1z" fill="#FFBA00"/>
                        <path d="M43.65 25L27.5 53.05l-13.75 23.8c1.35.8 2.9 1.2 4.45 1.2h49.45c1.55 0 3.1-.4 4.5-1.2L57.4 53.05 43.65 25z" fill="#2684FC"/>
                      </svg>
                      <div>
                        <span className="text-xs font-bold text-ink-primary">
                          پشتیبان‌گیری ابری در Google Drive شخصی
                        </span>
                        <p className="text-[10px] text-ink-muted">
                          ذخیره مستقیم یک نسخه امن در پوشه اختصاصی HamPA در گوگل درایو
                        </p>
                      </div>
                    </div>

                    <span className={`text-[10px] px-2 py-0.5 rounded-full font-bold border ${
                      driveConnected 
                        ? 'bg-emerald-500/15 text-emerald-400 border-emerald-500/30' 
                        : 'bg-white/5 text-ink-muted border-border-subtle'
                    }`}>
                      {driveConnected ? 'متصل به Drive' : 'عدم اتصال'}
                    </span>
                  </div>

                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 pt-1">
                    <button
                      type="button"
                      disabled={driveLoading}
                      onClick={handleDriveBackup}
                      className="py-2.5 px-3 rounded-xl bg-accent-primary hover:bg-accent-hover text-white text-xs font-bold flex items-center justify-center gap-2 transition active:scale-95 disabled:opacity-50 cursor-pointer shadow-sm"
                    >
                      <Upload className="w-4 h-4" />
                      <span>{driveLoading ? 'در حال ارسال...' : 'ارسال نسخه پشتیبان به Drive'}</span>
                    </button>

                    <button
                      type="button"
                      disabled={driveLoading}
                      onClick={handleDriveRestore}
                      className="py-2.5 px-3 rounded-xl bg-canvas border border-border-subtle hover:bg-white/5 text-ink-primary text-xs font-bold flex items-center justify-center gap-2 transition active:scale-95 disabled:opacity-50 cursor-pointer"
                    >
                      <Download className="w-4 h-4 text-emerald-400" />
                      <span>{driveLoading ? 'در حال دریافت...' : 'بازیابی اطلاعات از Drive'}</span>
                    </button>
                  </div>
                </div>

                {/* 2. CLOUD FIRESTORE SYNCHRONIZATION */}
                <div className="p-4 rounded-2xl bg-canvas-secondary border border-border-subtle space-y-3">
                  <div className="flex items-center justify-between pb-2 border-b border-border-subtle">
                    <div className="flex items-center gap-2">
                      <Cloud className="w-4 h-4 text-amber-500" />
                      <div>
                        <span className="text-xs font-bold text-ink-primary">
                          پایگاه داده ابری Firebase Firestore
                        </span>
                        <p className="text-[10px] text-ink-muted">
                          همگام‌سازی زمان واقعی تسک‌ها و جلسات مطالعه بین همه دستگاه‌ها
                        </p>
                      </div>
                    </div>
                  </div>

                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 pt-1">
                    <button
                      type="button"
                      disabled={cloudSyncLoading}
                      onClick={handlePushToFirestore}
                      className="py-2 px-3 rounded-xl bg-canvas border border-border-subtle hover:bg-white/5 text-ink-primary text-xs font-bold flex items-center justify-center gap-2 transition active:scale-95 disabled:opacity-50 cursor-pointer"
                    >
                      <RefreshCw className={`w-3.5 h-3.5 text-accent-primary ${cloudSyncLoading ? 'animate-spin' : ''}`} />
                      <span>همگام‌سازی محلی با Firestore</span>
                    </button>

                    <button
                      type="button"
                      disabled={cloudSyncLoading}
                      onClick={handlePullFromFirestore}
                      className="py-2 px-3 rounded-xl bg-canvas border border-border-subtle hover:bg-white/5 text-ink-primary text-xs font-bold flex items-center justify-center gap-2 transition active:scale-95 disabled:opacity-50 cursor-pointer"
                    >
                      <Download className="w-3.5 h-3.5 text-amber-400" />
                      <span>دریافت آخرین نسخه از Firestore</span>
                    </button>
                  </div>
                </div>

                {/* 3. WORKSPACE STATS */}
                <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
                  <div className="p-3 rounded-xl bg-canvas border border-border-subtle">
                    <span className="text-[10px] text-ink-muted block">کل تسک‌های شما</span>
                    <span className="text-sm font-black text-ink-primary font-mono mt-1 block">
                      {formatToPersianDigits(tasks.length)} فعالیت
                    </span>
                  </div>

                  <div className="p-3 rounded-xl bg-canvas border border-border-subtle">
                    <span className="text-[10px] text-ink-muted block">جلسات مطالعه ثبت‌شده</span>
                    <span className="text-sm font-black text-ink-primary font-mono mt-1 block">
                      {formatToPersianDigits(sessions.length)} جلسه
                    </span>
                  </div>

                  <div className="p-3 rounded-xl bg-canvas border border-border-subtle col-span-2 sm:col-span-1">
                    <span className="text-[10px] text-ink-muted block">وضعیت ذخیره‌سازی</span>
                    <span className="text-xs font-bold text-emerald-400 mt-1 block">
                      Local-First + Cloud
                    </span>
                  </div>
                </div>

                {/* 4. LOCAL JSON BACKUP */}
                <div className="pt-1">
                  <button
                    type="button"
                    onClick={handleExportData}
                    className="w-full py-2.5 rounded-xl border border-border-subtle bg-canvas hover:bg-white/5 text-xs font-bold text-ink-primary flex items-center justify-center gap-2 transition active:scale-98 cursor-pointer"
                  >
                    <Download className="w-4 h-4 text-accent-primary" />
                    <span>دانلود نسخه پشتیبان آفلاین (JSON Export)</span>
                  </button>
                </div>

                {/* 5. DANGER ZONE: CLEAR WORKSPACE */}
                <div className="p-3.5 rounded-2xl bg-rose-500/5 border border-rose-500/20 space-y-2">
                  <div className="flex items-center justify-between">
                    <div>
                      <span className="text-xs font-bold text-rose-400">پاکسازی کامل فضای کاری</span>
                      <p className="text-[10px] text-ink-muted">حذف تمامی تسک‌ها، جلسات و برگشت به بوم کاملاً سفید و بدون داده فیک</p>
                    </div>

                    <button
                      type="button"
                      onClick={handleResetWorkspace}
                      className="px-3 py-1.5 rounded-xl bg-rose-500/15 hover:bg-rose-500/25 text-rose-400 border border-rose-500/30 text-xs font-bold flex items-center gap-1.5 transition active:scale-95 cursor-pointer"
                    >
                      <Trash2 className="w-3.5 h-3.5" />
                      <span>ریست کامل</span>
                    </button>
                  </div>
                </div>
              </div>
            )}
          </div>

          {/* Modal Footer */}
          <div className="px-5 py-3.5 border-t border-border-subtle bg-canvas/30 flex items-center justify-between text-xs text-ink-muted">
            <span className="text-[11px]">هم‌پا نسخه 2.4.0 • پلتفرم هیبریدی نوشن + YPT</span>
            <button
              onClick={() => setSettingsOpen(false)}
              className="px-4 py-1.5 rounded-lg border border-border-subtle hover:bg-white/10 text-ink-primary font-medium transition"
            >
              بستن
            </button>
          </div>
        </motion.div>
      </div>
    </AnimatePresence>
  );
};
