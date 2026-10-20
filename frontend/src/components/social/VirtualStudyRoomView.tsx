import React, { useState } from 'react';
import { 
  Users, 
  Flame, 
  Volume2, 
  Sparkles, 
  MessageSquare, 
  ShieldCheck, 
  Send, 
  Heart, 
  Award,
  Video,
  Clock,
  Copy,
  Check,
  UserPlus,
  Play
} from 'lucide-react';
import type { StudyRoomPeer, StudyGroupPolicy } from '../../types/schema';
import { formatToPersianDigits } from '../../lib/calendarUtils';
import { useAppStore } from '../../store/useAppStore';
import confetti from 'canvas-confetti';

export const VirtualStudyRoomView: React.FC = () => {
  const user = useAppStore((s) => s.user);
  const isTimerRunning = useAppStore((s) => s.isTimerRunning);
  const timerSeconds = useAppStore((s) => s.timerSeconds);
  const sessions = useAppStore((s) => s.sessions);
  const selectedDate = useAppStore((s) => s.selectedDate);
  const subjects = useAppStore((s) => s.subjects);
  const activeSubjectId = useAppStore((s) => s.activeSubjectId);
  const setFocusModalOpen = useAppStore((s) => s.setFocusModalOpen);

  const activeSubject = subjects.find((s) => s.id === activeSubjectId) || subjects[0];
  const todaySessions = sessions.filter((s) => s.dateKey === selectedDate);
  const myDailyStudySeconds = todaySessions.reduce((acc, s) => acc + s.durationSeconds, 0) + (isTimerRunning ? timerSeconds : 0);

  // Group Leader Moderation Policy State
  const [policy, setPolicy] = useState<StudyGroupPolicy>({
    id: 'grp-1',
    name: 'اتاق مطالعه متمرکز هم‌پای من (Study Room)',
    chat_enabled: true,
    daily_message_quota_per_user: 10,
    creator_user_id: user.uid,
  });

  const [copiedLink, setCopiedLink] = useState(false);
  const [chatMessages, setChatMessages] = useState<{ sender: string; text: string; time: string }[]>([
    { sender: 'سامانه هم‌پا', text: 'به اتاق مطالعه زنده خوش آمدید. سکوت و تمرکز عمیق برقرار است 🤫', time: '۰۹:۰۰' },
  ]);
  const [inputMessage, setInputMessage] = useState('');
  const [myMessagesToday, setMyMessagesToday] = useState(0);

  // Connected study peers (starts clean with user, with ability to invite or add a study partner)
  const [invitedPartners, setInvitedPartners] = useState<StudyRoomPeer[]>([]);
  const [newPartnerName, setNewPartnerName] = useState('');
  const [showAddPartnerModal, setShowAddPartnerModal] = useState(false);

  const formatTimer = (sec: number) => {
    const h = Math.floor(sec / 3600);
    const m = Math.floor((sec % 3600) / 60);
    const s = sec % 60;
    if (h > 0) return `${h}:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
    return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
  };

  const handleCopyInvite = () => {
    navigator.clipboard?.writeText('https://hampa.app/study-room/focus-room-101');
    setCopiedLink(true);
    setTimeout(() => setCopiedLink(false), 2500);
  };

  const handleAddPartner = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newPartnerName.trim()) return;

    const newPeer: StudyRoomPeer = {
      user_id: `peer-${Date.now()}`,
      nickname: newPartnerName.trim(),
      status: 'STUDYING',
      active_subject_name: 'مطالعه هدفمند',
      active_subject_color: '#3B82F6',
      elapsed_seconds: 60,
      daily_study_seconds: 1800,
      messages_sent_today: 0,
    };

    setInvitedPartners([...invitedPartners, newPeer]);
    setNewPartnerName('');
    setShowAddPartnerModal(false);
  };

  const handleSendCheer = (_: string) => {
    confetti({
      particleCount: 50,
      spread: 60,
      origin: { y: 0.7 }
    });
  };

  const handleSendMessage = (e: React.FormEvent) => {
    e.preventDefault();
    if (!inputMessage.trim()) return;

    if (!policy.chat_enabled) {
      alert('چت گروه توسط مدیر موقتاً غیرفعال شده است تا سکوت مطالعه حفظ شود.');
      return;
    }

    if (myMessagesToday >= policy.daily_message_quota_per_user) {
      alert(`سقف مجاز روزانه شما (${policy.daily_message_quota_per_user} پیام) پر شده است. لطفاً به مطالعه بازگردید!`);
      return;
    }

    const now = new Date();
    const timeStr = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`;
    setChatMessages([
      ...chatMessages,
      {
        sender: user.displayName || 'من',
        text: inputMessage.trim(),
        time: timeStr,
      },
    ]);
    setInputMessage('');
    setMyMessagesToday((c) => c + 1);
  };

  return (
    <div className="flex-1 overflow-y-auto p-4 md:p-6 bg-canvas select-none">
      <div className="max-w-6xl mx-auto space-y-6">
        {/* Room Header with Real Status */}
        <div className="p-4 md:p-5 rounded-3xl bg-canvas-elevated liquid-glass border border-border-highlight shadow-lg flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <div className="flex items-center gap-2">
              <span className={`w-3 h-3 rounded-full ${isTimerRunning ? 'bg-emerald-500 animate-ping' : 'bg-amber-400'}`} />
              <h2 className="text-base md:text-lg font-bold text-ink-primary">
                {policy.name}
              </h2>
            </div>
            <p className="text-xs text-ink-muted mt-1">
              اتاق مطالعه آنلاین • وضعیت شما: {isTimerRunning ? 'در حال مطالعه با تمرکز' : 'آماده برای جلسه مطالعه'} • سقف پیام روزانه: {formatToPersianDigits(policy.daily_message_quota_per_user)} عدد
            </p>
          </div>

          {/* Action Buttons: Copy link & Invite */}
          <div className="flex items-center gap-2">
            <button
              onClick={handleCopyInvite}
              className="flex items-center gap-1.5 px-3 py-2 rounded-xl bg-canvas-secondary border border-border-subtle hover:bg-white/10 text-xs font-bold text-ink-primary transition active:scale-95"
            >
              {copiedLink ? <Check className="w-4 h-4 text-emerald-400" /> : <Copy className="w-4 h-4 text-ink-muted" />}
              <span>{copiedLink ? 'لینک کپی شد' : 'کپی لینک دعوت هم‌پا'}</span>
            </button>

            <button
              onClick={() => setShowAddPartnerModal(true)}
              className="flex items-center gap-1.5 px-3 py-2 rounded-xl bg-accent-primary hover:bg-accent-hover text-white text-xs font-bold shadow-needle transition active:scale-95"
            >
              <UserPlus className="w-4 h-4" />
              <span>افزودن هم‌مسیر</span>
            </button>
          </div>
        </div>

        {/* Modal for Adding Study Partner */}
        {showAddPartnerModal && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm">
            <div className="w-full max-w-sm p-5 rounded-3xl bg-canvas-elevated border border-border-highlight shadow-2xl space-y-4">
              <h3 className="text-sm font-bold text-ink-primary">افزودن نام دوست یا هم‌کلاسی مطالعه</h3>
              <form onSubmit={handleAddPartner} className="space-y-3">
                <input
                  type="text"
                  autoFocus
                  placeholder="نام هم‌مسیر (مثال: علی، مریم)..."
                  value={newPartnerName}
                  onChange={(e) => setNewPartnerName(e.target.value)}
                  className="w-full bg-canvas-secondary border border-border-subtle rounded-xl px-3 py-2 text-xs text-ink-primary outline-none focus:border-accent-primary"
                />
                <div className="flex justify-end gap-2">
                  <button
                    type="button"
                    onClick={() => setShowAddPartnerModal(false)}
                    className="px-3 py-1.5 rounded-lg text-xs text-ink-muted hover:bg-white/5"
                  >
                    انصراف
                  </button>
                  <button
                    type="submit"
                    className="px-4 py-1.5 rounded-lg bg-accent-primary text-white text-xs font-bold"
                  >
                    افزودن
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}

        {/* Members Presence Grid & Chat */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Members Presence Grid */}
          <div className="lg:col-span-2 space-y-4">
            <h3 className="text-sm font-bold text-ink-muted uppercase">
              اعضای آنلاین اتاق مطالعه (حضور واقعی)
            </h3>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              {/* Card 1: The REAL Current User */}
              <div className="p-4 rounded-3xl bg-canvas-elevated liquid-glass border-2 border-accent-primary/50 shadow-md flex flex-col justify-between space-y-3">
                <div className="flex items-start justify-between">
                  <div className="flex items-center gap-3">
                    <div className="relative">
                      <div className="w-12 h-12 rounded-full bg-gradient-to-tr from-accent-primary to-amber-500 flex items-center justify-center text-white font-black text-sm shadow-md">
                        {user.displayName ? user.displayName.slice(0, 1) : 'ش'}
                      </div>
                      {isTimerRunning && (
                        <span className="absolute -bottom-1 -right-1 w-4 h-4 rounded-full bg-emerald-500 border-2 border-canvas-elevated" />
                      )}
                    </div>

                    <div>
                      <div className="text-sm font-bold text-ink-primary">
                        {user.displayName || 'من (شما)'}
                      </div>
                      <div className="text-xs text-ink-muted mt-0.5">
                        {isTimerRunning ? 'در حال ضبط مطالعه فعال' : 'آماده به کار'}
                      </div>
                    </div>
                  </div>

                  <button
                    onClick={() => handleSendCheer('خودم')}
                    className="p-2 rounded-full bg-accent-primary/10 hover:bg-accent-primary/20 text-accent-primary transition active:scale-90"
                    title="تشویق"
                  >
                    <Heart className="w-4 h-4 fill-current" />
                  </button>
                </div>

                <div className="p-3 rounded-2xl bg-canvas-secondary border border-border-subtle flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <span
                      className="w-2.5 h-2.5 rounded-full"
                      style={{ backgroundColor: activeSubject?.color || '#FF4700' }}
                    />
                    <span className="text-xs font-semibold text-ink-primary truncate max-w-[120px]">
                      {activeSubject?.name || 'موضوع کلی'}
                    </span>
                  </div>

                  <div className="font-mono text-xs font-bold text-accent-primary">
                    {formatTimer(isTimerRunning ? timerSeconds : myDailyStudySeconds)}
                  </div>
                </div>

                {!isTimerRunning && (
                  <button
                    onClick={() => setFocusModalOpen(true)}
                    className="w-full py-2 rounded-xl bg-accent-primary text-white text-xs font-bold flex items-center justify-center gap-1.5 active:scale-95 transition"
                  >
                    <Play className="w-3.5 h-3.5 fill-current" />
                    <span>شروع تمرکز در این اتاق</span>
                  </button>
                )}
              </div>

              {/* Invited Partners or Empty State */}
              {invitedPartners.map((peer) => (
                <div
                  key={peer.user_id}
                  className="p-4 rounded-3xl bg-canvas-elevated liquid-glass border border-border-subtle shadow-sm flex flex-col justify-between space-y-3"
                >
                  <div className="flex items-start justify-between">
                    <div className="flex items-center gap-3">
                      <div className="w-12 h-12 rounded-full bg-gradient-to-tr from-blue-500 to-indigo-600 flex items-center justify-center text-white font-bold text-sm shadow-md">
                        {peer.nickname.slice(0, 1)}
                      </div>
                      <div>
                        <div className="text-sm font-bold text-ink-primary">{peer.nickname}</div>
                        <div className="text-xs text-ink-muted mt-0.5">هم‌مسیر مطالعه</div>
                      </div>
                    </div>

                    <button
                      onClick={() => handleSendCheer(peer.nickname)}
                      className="p-2 rounded-full bg-accent-primary/10 hover:bg-accent-primary/20 text-accent-primary transition active:scale-90"
                      title="ارسال تشویق"
                    >
                      <Heart className="w-4 h-4 fill-current" />
                    </button>
                  </div>

                  <div className="p-3 rounded-2xl bg-canvas-secondary border border-border-subtle flex items-center justify-between text-xs">
                    <span className="text-ink-muted">{peer.active_subject_name}</span>
                    <span className="font-mono font-bold text-ink-primary">در حال مطالعه</span>
                  </div>
                </div>
              ))}

              {invitedPartners.length === 0 && (
                <div className="p-5 rounded-3xl border border-dashed border-border-subtle flex flex-col items-center justify-center text-center space-y-2">
                  <Users className="w-8 h-8 text-ink-subtle opacity-50" />
                  <div className="text-xs font-bold text-ink-primary">
                    دوستان خود را به اتاق دعوت کنید
                  </div>
                  <p className="text-[11px] text-ink-muted max-w-[200px]">
                    با دکمه «افزودن هم‌مسیر» یا اشتراک لینک، با دوستان واقعی خود مطالعه گروهی کنید.
                  </p>
                </div>
              )}
            </div>
          </div>

          {/* Group Chat Window */}
          <div className="p-4 rounded-3xl bg-canvas-elevated liquid-glass border border-border-subtle shadow-sm flex flex-col h-[480px]">
            <div className="flex items-center justify-between pb-3 border-b border-border-subtle">
              <div className="flex items-center gap-2">
                <MessageSquare className="w-4 h-4 text-accent-primary" />
                <h4 className="text-xs font-bold text-ink-primary">گفتگوی بی‌صدا و تمرکز</h4>
              </div>
              <span className="text-[10px] text-ink-muted font-mono">
                {myMessagesToday}/{policy.daily_message_quota_per_user} پیام
              </span>
            </div>

            {/* Chat Messages */}
            <div className="flex-1 overflow-y-auto py-3 space-y-2.5">
              {chatMessages.map((msg, i) => (
                <div key={i} className="text-xs p-2.5 rounded-xl bg-canvas-secondary/70 border border-border-subtle/50 space-y-1">
                  <div className="flex items-center justify-between text-[10px] text-ink-muted">
                    <span className="font-bold text-accent-primary">{msg.sender}</span>
                    <span className="font-mono">{msg.time}</span>
                  </div>
                  <div className="text-ink-primary">{msg.text}</div>
                </div>
              ))}
            </div>

            {/* Chat Input */}
            <form onSubmit={handleSendMessage} className="pt-2 border-t border-border-subtle flex gap-1.5">
              <input
                type="text"
                placeholder={policy.chat_enabled ? 'پیام کوتاه انگیزشی...' : 'چت در حالت سکوت است'}
                disabled={!policy.chat_enabled}
                value={inputMessage}
                onChange={(e) => setInputMessage(e.target.value)}
                className="flex-1 bg-canvas-secondary border border-border-subtle rounded-xl px-3 py-2 text-xs text-ink-primary outline-none focus:border-accent-primary disabled:opacity-50"
              />
              <button
                type="submit"
                disabled={!policy.chat_enabled || !inputMessage.trim()}
                className="p-2 rounded-xl bg-accent-primary text-white disabled:opacity-40 transition"
              >
                <Send className="w-4 h-4" />
              </button>
            </form>
          </div>
        </div>
      </div>
    </div>
  );
};
