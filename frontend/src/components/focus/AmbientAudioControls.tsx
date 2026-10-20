import React from 'react';
import { Volume2, VolumeX, Waves, Sparkles, CloudRain, Coffee } from 'lucide-react';
import { useAppStore } from '../../store/useAppStore';
import type { AmbientSoundType } from '../../types';

export const AmbientAudioControls: React.FC = () => {
  const ambientSound = useAppStore((s) => s.ambientSound);
  const setAmbientSound = useAppStore((s) => s.setAmbientSound);

  const sounds: { type: AmbientSoundType; label: string; icon: React.ElementType }[] = [
    { type: 'none', label: 'خاموش', icon: VolumeX },
    { type: 'brown_noise', label: 'امواج قهوه‌ای (عمیق)', icon: Waves },
    { type: 'pink_noise', label: 'امواج صورتی (متعادل)', icon: Waves },
    { type: 'binaural_focus', label: 'فرکانس بای‌نورال 14Hz', icon: Sparkles },
    { type: 'rain', label: 'صدای باران', icon: CloudRain },
    { type: 'cafe', label: 'فضای کافه', icon: Coffee },
  ];

  return (
    <div className="p-3 rounded-precision-md bg-canvas-secondary/60 border border-border-subtle space-y-2.5">
      <div className="flex items-center justify-between">
        <span className="text-xs font-bold text-ink-muted flex items-center gap-1.5">
          <Volume2 className="w-3.5 h-3.5 text-accent-primary" />
          موتور صوتی تمرکز (Ambient Soundscape)
        </span>
        <span className="text-[11px] font-mono text-ink-subtle">
          {Math.round(ambientSound.volume * 100)}%
        </span>
      </div>

      {/* Sound Pills */}
      <div className="flex flex-wrap gap-1.5">
        {sounds.map((snd) => {
          const Icon = snd.icon;
          const isActive = ambientSound.type === snd.type && ambientSound.isPlaying;
          return (
            <button
              key={snd.type}
              onClick={() => {
                if (snd.type === ambientSound.type && ambientSound.isPlaying) {
                  setAmbientSound('none');
                } else {
                  setAmbientSound(snd.type);
                }
              }}
              className={`flex items-center gap-1 px-2.5 py-1 rounded-precision text-xs transition ${
                isActive
                  ? 'bg-accent-primary text-white font-bold shadow-sm'
                  : 'bg-white/5 hover:bg-white/10 text-ink-muted hover:text-ink-primary border border-border-subtle'
              }`}
            >
              <Icon className="w-3 h-3" />
              <span>{snd.label}</span>
            </button>
          );
        })}
      </div>

      {/* Volume Slider */}
      {ambientSound.isPlaying && (
        <div className="flex items-center gap-2 pt-1">
          <VolumeX className="w-3.5 h-3.5 text-ink-subtle" />
          <input
            type="range"
            min="0"
            max="1"
            step="0.05"
            value={ambientSound.volume}
            onChange={(e) => setAmbientSound(ambientSound.type, parseFloat(e.target.value))}
            className="flex-1 accent-accent-primary h-1 bg-white/20 rounded-lg cursor-pointer"
          />
          <Volume2 className="w-3.5 h-3.5 text-ink-subtle" />
        </div>
      )}
    </div>
  );
};
