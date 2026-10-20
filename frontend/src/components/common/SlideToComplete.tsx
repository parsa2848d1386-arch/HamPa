import React, { useRef, useState } from 'react';
import { motion, useMotionValue, useTransform, animate } from 'framer-motion';
import { Check, ChevronLeft, Sparkles } from 'lucide-react';
import confetti from 'canvas-confetti';

interface SlideToCompleteProps {
  onComplete: () => void;
  isCompleted?: boolean;
  label?: string;
  completedLabel?: string;
  className?: string;
}

export const SlideToComplete: React.FC<SlideToCompleteProps> = ({
  onComplete,
  isCompleted = false,
  label = 'برای انجام بکشید ‹‹',
  completedLabel = 'انجام شد! ✓',
  className = '',
}) => {
  const containerRef = useRef<HTMLDivElement>(null);
  const [completed, setCompleted] = useState(isCompleted);
  const dragX = useMotionValue(0);

  // In RTL, sliding is to the left (negative x values)
  const opacity = useTransform(dragX, [0, -140], [1, 0.1]);
  const progressBg = useTransform(dragX, [0, -180], ['rgba(16, 185, 129, 0.1)', 'rgba(16, 185, 129, 0.95)']);

  const handleDragEnd = (_: unknown, info: { offset: { x: number } }) => {
    // If dragged sufficiently to the left in RTL
    if (info.offset.x < -100) {
      setCompleted(true);
      // Trigger subtle vibration if mobile supports
      if (typeof navigator !== 'undefined' && 'vibrate' in navigator) {
        navigator.vibrate([35, 50, 45]);
      }
      // Confetti burst
      confetti({
        particleCount: 40,
        spread: 60,
        origin: { y: 0.8 },
        colors: ['#FF4700', '#10B981', '#F59E0B', '#3B82F6'],
      });
      onComplete();
    } else {
      animate(dragX, 0, { type: 'spring', stiffness: 500, damping: 30 });
    }
  };

  const handleReset = (e: React.MouseEvent) => {
    e.stopPropagation();
    setCompleted(false);
    animate(dragX, 0, { type: 'spring', stiffness: 400, damping: 25 });
  };

  return (
    <div
      ref={containerRef}
      className={`relative h-12 rounded-2xl overflow-hidden select-none border border-border-subtle bg-canvas-secondary/80 touch-none flex items-center justify-between p-1.5 transition-all ${className}`}
    >
      {/* Background Fill Progress */}
      <motion.div
        className="absolute inset-0 rounded-2xl pointer-events-none"
        style={{
          backgroundColor: completed ? '#10B981' : progressBg,
        }}
      />

      {completed ? (
        <div className="relative z-10 w-full flex items-center justify-between px-3 text-white font-bold text-xs animate-in fade-in duration-200">
          <span className="flex items-center gap-1.5">
            <Sparkles className="w-4 h-4 text-amber-200" />
            <span>{completedLabel}</span>
          </span>
          <button
            onClick={handleReset}
            type="button"
            className="text-[11px] underline opacity-90 hover:opacity-100 py-1 px-2 rounded-lg bg-black/20"
          >
            لغو تیک
          </button>
        </div>
      ) : (
        <>
          {/* Label In Center */}
          <motion.div
            style={{ opacity }}
            className="absolute inset-0 flex items-center justify-center pointer-events-none text-xs font-bold text-ink-muted tracking-tight"
          >
            <span className="flex items-center gap-1">
              <span>{label}</span>
            </span>
          </motion.div>

          {/* Left Target Destination Icon */}
          <div className="w-9 h-9 rounded-xl flex items-center justify-center text-ink-subtle pointer-events-none">
            <Check className="w-4 h-4 opacity-50" />
          </div>

          {/* Draggable Knob */}
          <motion.div
            drag="x"
            dragConstraints={{ left: -190, right: 0 }}
            dragElastic={0.15}
            onDragEnd={handleDragEnd}
            style={{ x: dragX }}
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
            className="relative z-10 w-9 h-9 rounded-xl bg-accent-primary text-white shadow-needle flex items-center justify-center cursor-grab active:cursor-grabbing touch-target"
          >
            <ChevronLeft className="w-5 h-5 animate-pulse" />
          </motion.div>
        </>
      )}
    </div>
  );
};
