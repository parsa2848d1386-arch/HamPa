import React, { useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { useAppStore } from './store/useAppStore';
import { HeaderBar } from './components/layout/HeaderBar';
import { LeftSidebar } from './components/layout/LeftSidebar';
import { RightInspectorPanel } from './components/layout/RightInspectorPanel';
import { CommandPalette } from './components/layout/CommandPalette';
import { MobileTabBar } from './components/layout/MobileTabBar';
import { DesktopBottomDocks } from './components/layout/DesktopBottomDocks';
import { MainDashboardView } from './components/dashboard/MainDashboardView';
import { UnifiedTimeline } from './components/timeline/UnifiedTimeline';
import { WeekView } from './components/views/WeekView';
import { KanbanView } from './components/views/KanbanView';
import { AnalyticsDashboard } from './components/analytics/AnalyticsDashboard';
import { DualColumn10MinuteGrid } from './components/planner/DualColumn10MinuteGrid';
import { EisenhowerMatrixView } from './components/matrix/EisenhowerMatrixView';
import { VirtualStudyRoomView } from './components/social/VirtualStudyRoomView';
import { StylusCanvasLayer } from './components/canvas/StylusCanvasLayer';
import { FocusTimerModal } from './components/focus/FocusTimerModal';
import { FloatingPiPWidget } from './components/focus/FloatingPiPWidget';
import { AIBrainDumpDrawer } from './components/rituals/AIBrainDumpDrawer';
import { MorningPlanningModal } from './components/rituals/MorningPlanningModal';
import { EveningReflectionModal } from './components/rituals/EveningReflectionModal';
import { ShortcutCheatSheetModal } from './components/common/ShortcutCheatSheetModal';
import { CreateTaskModal } from './components/modals/CreateTaskModal';

export const App: React.FC = () => {
  const isDark = useAppStore((s) => s.isDark);
  const viewMode = useAppStore((s) => s.viewMode);

  // Set dark class on HTML element based on initial state
  useEffect(() => {
    if (isDark) {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
  }, [isDark]);

  return (
    <div className="flex flex-col h-screen w-screen overflow-hidden bg-canvas text-ink-primary font-vazir antialiased select-none">
      {/* Top Precision Header Bar (Airy & Uncluttered) */}
      <HeaderBar />

      {/* Main Workspace (3-Zone High-Density Layout) */}
      <main className="flex-1 flex overflow-hidden relative pb-20 md:pb-16">
        {/* Zone 1: Collapsible Left Mini-Month & Category Inbox */}
        <LeftSidebar />

        {/* Zone 2: Center Interactive View Port */}
        <div className="flex-1 flex flex-col h-full overflow-hidden relative">
          <AnimatePresence mode="wait">
            <motion.div
              key={viewMode}
              initial={{ opacity: 0, y: 5 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -5 }}
              transition={{ duration: 0.15, ease: 'easeOut' }}
              className="flex-1 flex flex-col h-full overflow-hidden relative"
            >
              {viewMode === 'dashboard' && <MainDashboardView />}
              {viewMode === 'day' && <UnifiedTimeline />}
              {viewMode === 'dual_planner' && <DualColumn10MinuteGrid />}
              {viewMode === 'eisenhower' && <EisenhowerMatrixView />}
              {viewMode === 'study_room' && <VirtualStudyRoomView />}
              {viewMode === 'stylus' && <StylusCanvasLayer />}
              {viewMode === 'week' && <WeekView />}
              {viewMode === 'kanban' && <KanbanView />}
              {viewMode === 'analytics' && <AnalyticsDashboard />}
            </motion.div>
          </AnimatePresence>
        </div>

        {/* Zone 3: Contextual Right Inspector Panel (Notion Blocks + Subtasks) */}
        <RightInspectorPanel />
      </main>

      {/* Desktop Distributed Action & Ritual Docks (Bottom-Left and Bottom-Right) */}
      <DesktopBottomDocks />

      {/* Mobile Floating Thumb Reach Tab Bar */}
      <MobileTabBar />

      {/* Persistent Floating Picture-in-Picture Bar */}
      <FloatingPiPWidget />

      {/* Modals & Overlays */}
      <CreateTaskModal />
      <FocusTimerModal />
      <AIBrainDumpDrawer />
      <MorningPlanningModal />
      <EveningReflectionModal />
      <CommandPalette />
      <ShortcutCheatSheetModal />
    </div>
  );
};

export default App;
