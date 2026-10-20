import React, { useRef, useState, useEffect } from 'react';
import { motion, useMotionValue, useTransform, animate } from 'framer-motion';
import { Check, ChevronLeft, Sparkles, RotateCcw } from 'lucide-react';
import confetti from 'canvas-confetti';

interface SlideToCompleteProps {
  onComplete: () => void;
  onReset?: () => void;
  isCompleted?: boolean;
  label?: string;
  completedLabel?: string;
  className?: string;
}

export const SlideToComplete: React.FC<SlideToCompleteProps> = ({
  onComplete,
  onReset,
  isCompleted = false,
  label = 'برای انجام به چپ بکشید ‹‹',
  completedLabel = 'انجام شد! ✓',
  className = '',
}) => {
  const containerRef = useRef<HTMLDivElement>(null);
  const [completed, setCompleted] = useState(isCompleted);
  const [maxDrag, setMaxDrag] = useState(200);
  const dragX = useMotionValue(0);

  // Measure container width for exact responsive drag bounds
  useEffect(() => {
    const updateBounds = () => {
      if (containerRef.current) {
        const width = containerRef.current.clientWidth;
        // 36px knob + 12px padding
        setMaxDrag(Math.max(80, width - 48));
      }
    };

    updateBounds();
    window.addEventListener('resize', updateBounds);
    return () => window.removeEventListener('resize', updateBounds);
  }, []);

  // Sync with external isCompleted prop
  useEffect(() => {
    setCompleted(isCompleted);
    if (!isCompleted) {
      dragX.set(0);
    }
  }, [isCompleted, dragX]);

  // In RTL, sliding left is negative x values
  const labelOpacity = useTransform(dragX, [0, -Math.max(40, maxDrag * 0.45)], [1, 0.05]);
  const progressWidth = useTransform(dragX, [0, -maxDrag], [40, maxDrag + 44]);
  const progressBg = useTransform(
    dragX,
    [0, -maxDrag * 0.7, -maxDrag],
    ['rgba(16, 185, 129, 0.12)', 'rgba(16, 185, 129, 0.5)', 'rgba(16, 185, 129, 0.95)']
  );

  const handleDragEnd = () => {
    const currentX = dragX.get();
    // If dragged past 55% of track to the left
    if (currentX < -maxDrag * 0.55) {
      animate(dragX, -maxDrag, { type: 'spring', stiffness: 500, damping: 30 });
      setCompleted(true);

      // Trigger tactile haptics if mobile supports
      if (typeof navigator !== 'undefined' && 'vibrate' in navigator) {
        try {
          navigator.vibrate([35, 40, 50]);
        } catch {
          // ignore if vibration blocked
        }
      }

      // Festive confetti burst
      confetti({
        particleCount: 45,
        spread: 65,
        origin: { y: 0.8 },
        colors: ['#FF4700', '#10B981', '#F59E0B', '#3B82F6'],
      });

      onComplete();
    } else {
      // Spring back to right starting point
      animate(dragX, 0, { type: 'spring', stiffness: 500, damping: 30 });
    }
  };

  const handleResetClick = (e: React.MouseEvent) => {
    e.stopPropagation();
    setCompleted(false);
    animate(dragX, 0, { type: 'spring', stiffness: 450, damping: 28 });
    if (onReset) {
      onReset();
    } else {
      // If no explicit reset handler, re-trigger onComplete to toggle back
      onComplete();
    }
  };

  return (
    <div
      ref={containerRef}
      className={`relative h-12 rounded-2xl overflow-hidden select-none border border-border-subtle bg-canvas-secondary/90 touch-none flex items-center transition-all ${className}`}
    >
      {/* Background Fill Progress from Right */}
      <motion.div
        className="absolute right-0 top-0 bottom-0 rounded-2xl pointer-events-none"
        style={{
          width: completed ? '100%' : progressWidth,
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
            onClick={handleResetClick}
            type="button"
            className="flex items-center gap-1 text-[11px] font-medium py-1 px-2.5 rounded-lg bg-black/25 hover:bg-black/40 text-white transition active:scale-95"
            title="بازگرداندن به حالت انجام‌نشده"
          >
            <RotateCcw className="w-3 h-3" />
            <span>لغو تیک</span>
          </button>
        </div>
      ) : (
        <>
          {/* Label In Center */}
          <motion.div
            style={{ opacity: labelOpacity }}
            className="absolute inset-0 flex items-center justify-center pointer-events-none text-xs font-bold text-ink-muted tracking-tight"
          >
            <span className="flex items-center gap-1">
              <span>{label}</span>
            </span>
          </motion.div>

          {/* Left Target Destination Icon */}
          <div className="absolute left-2.5 top-1/2 -translate-y-1/2 w-8 h-8 rounded-xl flex items-center justify-center text-ink-subtle pointer-events-none border border-dashed border-border-subtle/50">
            <Check className="w-4 h-4 opacity-40 text-emerald-500" />
          </div>

          {/* Draggable Knob (Starts on the Right in RTL, slides to Left) */}
          <motion.div
            drag="x"
            dragConstraints={{ left: -maxDrag, right: 0 }}
            dragElastic={0.1}
            onDragEnd={handleDragEnd}
            style={{ x: dragX }}
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
            className="absolute right-1.5 top-1.5 bottom-1.5 w-9 rounded-xl bg-accent-primary text-white shadow-needle flex items-center justify-center cursor-grab active:cursor-grabbing touch-target z-10"
          >
            <ChevronLeft className="w-5 h-5 animate-pulse" />
          </motion.div>
        </>
      )}
    </div>
  );
};

