import React, { useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X } from 'lucide-react';

interface BottomSheetProps {
  isOpen: boolean;
  onClose: () => void;
  title?: string;
  children: React.ReactNode;
}

export const BottomSheet: React.FC<BottomSheetProps> = ({ isOpen, onClose, title, children }) => {
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose();
    };
    if (isOpen) {
      window.addEventListener('keydown', handleKeyDown);
      document.body.style.overflow = 'hidden';
    }
    return () => {
      window.removeEventListener('keydown', handleKeyDown);
      document.body.style.overflow = '';
    };
  }, [isOpen, onClose]);

  return (
    <AnimatePresence>
      {isOpen && (
        <>
          {/* Backdrop */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.2 }}
            onClick={onClose}
            className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm"
            aria-hidden="true"
          />

          {/* Sheet Container */}
          <motion.div
            initial={{ y: '100%' }}
            animate={{ y: 0 }}
            exit={{ y: '100%' }}
            transition={{ type: 'spring', stiffness: 400, damping: 30, mass: 0.8 }}
            className="fixed inset-x-0 bottom-0 z-50 max-h-[90vh] flex flex-col rounded-t-squircle-sheet bg-canvas-elevated liquid-glass border-t border-border-highlight shadow-2xl overflow-hidden"
            role="dialog"
            aria-modal="true"
          >
            {/* Drag Handle */}
            <div className="flex justify-center pt-3 pb-2 cursor-grab active:cursor-grabbing">
              <div className="w-12 h-1.5 rounded-pill bg-white/20" />
            </div>

            {/* Header */}
            {title && (
              <div className="flex items-center justify-between px-6 pb-3 border-b border-border-subtle">
                <h3 className="text-base font-bold text-ink-primary">{title}</h3>
                <button
                  onClick={onClose}
                  className="p-2 -m-2 rounded-full hover:bg-white/10 active:scale-95 transition touch-target text-ink-muted hover:text-ink-primary"
                  aria-label="بستن پنجره"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>
            )}

            {/* Scrollable Content */}
            <div className="flex-1 overflow-y-auto px-6 py-4">
              {children}
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
};
