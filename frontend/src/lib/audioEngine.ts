// Web Audio API Synthesizer for Ambient Soundscape (Pink, Brown, White noise & Binaural beats)
import type { AmbientSoundType } from '../types';

class AudioEngine {
  private ctx: AudioContext | null = null;
  private masterGain: GainNode | null = null;
  private noiseNode: AudioNode | null = null;
  private binauralOscLeft: OscillatorNode | null = null;
  private binauralOscRight: OscillatorNode | null = null;
  private isRunning: boolean = false;
  private currentType: AmbientSoundType = 'none';

  private initContext() {
    if (!this.ctx) {
      const AudioCtx = window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
      this.ctx = new AudioCtx();
      this.masterGain = this.ctx.createGain();
      this.masterGain.connect(this.ctx.destination);
      this.masterGain.gain.setValueAtTime(0.5, this.ctx.currentTime);
    }
    if (this.ctx.state === 'suspended') {
      this.ctx.resume();
    }
  }

  public setVolume(volume: number) {
    if (this.masterGain && this.ctx) {
      const clamped = Math.max(0, Math.min(1, volume));
      this.masterGain.gain.linearRampToValueAtTime(clamped, this.ctx.currentTime + 0.05);
    }
  }

  public stop() {
    if (this.noiseNode) {
      try {
        if ('stop' in this.noiseNode && typeof (this.noiseNode as AudioScheduledSourceNode).stop === 'function') {
          (this.noiseNode as AudioScheduledSourceNode).stop();
        }
        this.noiseNode.disconnect();
      } catch {
        // Ignored
      }
      this.noiseNode = null;
    }

    if (this.binauralOscLeft) {
      try {
        this.binauralOscLeft.stop();
        this.binauralOscLeft.disconnect();
      } catch {
        // Ignored
      }
      this.binauralOscLeft = null;
    }

    if (this.binauralOscRight) {
      try {
        this.binauralOscRight.stop();
        this.binauralOscRight.disconnect();
      } catch {
        // Ignored
      }
      this.binauralOscRight = null;
    }

    this.isRunning = false;
    this.currentType = 'none';
  }

  public play(type: AmbientSoundType, volume: number = 0.5) {
    this.stop();
    if (type === 'none') return;

    this.initContext();
    if (!this.ctx || !this.masterGain) return;

    this.setVolume(volume);
    this.currentType = type;
    this.isRunning = true;

    const bufferSize = 2 * this.ctx.sampleRate;
    const buffer = this.ctx.createBuffer(1, bufferSize, this.ctx.sampleRate);
    const output = buffer.getChannelData(0);

    if (type === 'white_noise') {
      for (let i = 0; i < bufferSize; i++) {
        output[i] = Math.random() * 2 - 1;
      }
      this.playBuffer(buffer);
    } else if (type === 'pink_noise') {
      // Paul Kellet's filter method
      let b0 = 0, b1 = 0, b2 = 0, b3 = 0, b4 = 0, b5 = 0, b6 = 0;
      for (let i = 0; i < bufferSize; i++) {
        const white = Math.random() * 2 - 1;
        b0 = 0.99886 * b0 + white * 0.0555179;
        b1 = 0.99332 * b1 + white * 0.0750759;
        b2 = 0.96900 * b2 + white * 0.1538520;
        b3 = 0.86650 * b3 + white * 0.3104856;
        b4 = 0.55000 * b4 + white * 0.5329522;
        b5 = -0.7616 * b5 - white * 0.0168980;
        output[i] = (b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362) * 0.11;
        b6 = white * 0.115926;
      }
      this.playBuffer(buffer);
    } else if (type === 'brown_noise' || type === 'rain') {
      let lastOut = 0.0;
      for (let i = 0; i < bufferSize; i++) {
        const white = Math.random() * 2 - 1;
        output[i] = (lastOut + (0.02 * white)) / 1.02;
        lastOut = output[i];
        output[i] *= 3.5; // Compensate gain
      }
      this.playBuffer(buffer);
    } else if (type === 'binaural_focus') {
      // 14Hz Beta/Alpha focus beat (200Hz left, 214Hz right)
      const merger = this.ctx.createChannelMerger(2);
      this.binauralOscLeft = this.ctx.createOscillator();
      this.binauralOscRight = this.ctx.createOscillator();

      this.binauralOscLeft.type = 'sine';
      this.binauralOscRight.type = 'sine';
      this.binauralOscLeft.frequency.setValueAtTime(200, this.ctx.currentTime);
      this.binauralOscRight.frequency.setValueAtTime(214, this.ctx.currentTime);

      this.binauralOscLeft.connect(merger, 0, 0);
      this.binauralOscRight.connect(merger, 0, 1);
      merger.connect(this.masterGain);

      this.binauralOscLeft.start();
      this.binauralOscRight.start();
    } else if (type === 'cafe') {
      // Soft gentle filtered brown noise
      let lastOut = 0.0;
      for (let i = 0; i < bufferSize; i++) {
        const white = Math.random() * 2 - 1;
        output[i] = (lastOut + (0.03 * white)) / 1.03;
        lastOut = output[i];
        output[i] *= 2.8;
      }
      this.playBuffer(buffer);
    }
  }

  private playBuffer(buffer: AudioBuffer) {
    if (!this.ctx || !this.masterGain) return;
    const whiteNoise = this.ctx.createBufferSource();
    whiteNoise.buffer = buffer;
    whiteNoise.loop = true;
    whiteNoise.connect(this.masterGain);
    whiteNoise.start(0);
    this.noiseNode = whiteNoise;
  }

  public getStatus() {
    return {
      isPlaying: this.isRunning,
      type: this.currentType
    };
  }
}

export const audioEngine = new AudioEngine();
