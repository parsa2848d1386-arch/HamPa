# Project: HamPA (هم‌پا)

## Mission
Build 'HamPA' (هم‌پا), a complete hybrid productivity and planner application unifying Notion's block-based workspace and relational databases with YeolPumTa's (YPT) real-time focus tracking, live study rooms, strict anti-distraction lock, 10-minute visual timetable, and gamified analytics using Flutter.

## Architecture & System Overview
HamPA follows Clean Architecture with a Local-First reactive SQLite backbone via Drift:
1. **Presentation Layer**: Notion Block Editor, 6 Relational Views, Focus HUD, CustomPainter 144-Block Timetable Grid, Live Study Room Grid, Heatmaps. State managed via BLoC / Notifiers.
2. **Domain Layer**: Pure Dart entities (Page, Block, Database, Property, Row, Cell, FocusSession, GridSlot, Streak, RoomMember) and Interactors (AutoLoggingTransaction, FormulaEvaluator, RollupAggregator, TimetableProjector).
3. **Data Layer**: Drift SQLite database (`app_database.dart`), DAOs, and local-first reactive streams.
4. **Infrastructure Layer**: Accelerometer sensor manager, Android foreground service / platform channels, multi-track ambient sound engine, and real-time room signaling.

### Dual Identity Paradigm
Every row in a relational database has a 1:1 dual identity as an underlying `Page` (`is_database_row = TRUE`). Opening any row presents a complete block-based document workspace with nested blocks, embedded databases, and in-session scratchpads.

---

## Feature Inventory (F01–F35)

| # | Feature | Category | Description | Milestone | Mapped AC |
|---|---------|----------|-------------|-----------|-----------|
| **F01** | Hierarchical Page Tree | Workspace | Arbitrary depth nesting of pages and sub-pages in sidebar navigation | M1 | AC1 |
| **F02** | Drag-and-Drop Page Tree | Workspace | Reorder pages and re-parent by dragging in navigation tree | M1 | AC1 |
| **F03** | Local-First Drift Persistence | Workspace | Zero-latency local SQLite persistence with reactive streams | M1 | AC3 |
| **F04** | Rich Text & Headings Blocks | Block Editor | Paragraph, H1/H2/H3 blocks with inline styling (bold, italic, code, links) | M1 | AC1 |
| **F05** | Interactive Checklist Blocks | Block Editor | To-do items with toggleable checkbox, strike-through, and checked timestamp | M1 | AC1, AC8, AC9 |
| **F06** | Callout & Toggle Blocks | Block Editor | Tinted callout boxes with icons; collapsible toggles with nested child blocks | M1 | AC1 |
| **F07** | Code Syntax & LaTeX Math | Block Editor | Code snippets with language highlighting; KaTeX/flutter_math equations | M1 | AC1 |
| **F08** | Rich Property Schema Engine | Relational DB | Dynamic columns: text, number, select, multi-select, status, date, tags, etc. | M2 | AC2 |
| **F09** | Two-Way Database Relations | Relational DB | 1:1, 1:N, N:N linking between rows of different databases | M2 | AC2, AC8 |
| **F10** | Formula Expression Engine | Relational DB | AST evaluator for math, string, date, logic, and cycle detection (`#CYCLE!`) | M2 | AC2, AC8 |
| **F11** | Automatic Rollups & Aggregations | Relational DB | Sum, Average, Min, Max, Count, Percent checked across relations | M2 | AC2, AC8 |
| **F12** | Table View with Inline Editing | Relational DB | Virtualized tabular grid with inline cell editors and footer aggregations | M2 | AC2 |
| **F13** | Kanban Board View | Relational DB | Drag-and-drop card columns grouped by status or select property | M2 | AC2 |
| **F14** | Calendar View (Month/Week) | Relational DB | Date-mapped grid displaying task chips across calendar days | M2 | AC2 |
| **F15** | Timeline / Gantt View | Relational DB | Duration bar chart with drag dependency connector arrows | M2 | AC2 |
| **F16** | List & Gallery Views | Relational DB | Minimalist high-density list and responsive card cover gallery | M2 | AC2 |
| **F17** | Monotonic Background Stopwatch | Focus Engine | Drift-free stopwatch: `elapsed = now - start_epoch - paused_duration` | M3 | AC4 |
| **F18** | Customizable Pomodoro Cycles | Focus Engine | Configurable work & break intervals with audio alerts and cycle tracking | M3 | AC4, AC7 |
| **F19** | Mock Exam Countdown Timers | Focus Engine | Standardized simulation timer with section breakdowns and alert chimes | M3 | AC4 |
| **F20** | Strict Lock & Interruption Log | Anti-Distraction | Lifecycle observer detecting app switches with 10s grace period | M3 | AC5 |
| **F21** | Reference Allowlist | Anti-Distraction | Permitted in-app tools (Scratchpad, Calculator, Ambient sound) | M3 | AC5 |
| **F22** | Flip-to-Focus Sensor Detection | Anti-Distraction | Accelerometer detection ($Z \le -9.2\text{ m/s}^2$) with OLED black mode | M3 | AC4, AC5 |
| **F23** | Multi-Track Ambient Soundscapes | Anti-Distraction | Offline mixer (Rain, White Noise, Cafe, Library, Waves) with volume sliders | M3 | AC4 |
| **F24** | 24-Hour 10-Minute Timetable Grid | Timetable Grid | 144 blocks mapping 05:00 AM–05:00 AM study day to color-coded subjects | M4 | AC6 |
| **F25** | Real-Time Block Painting & Pulse | Timetable Grid | CustomPainter dynamically painting and pulsing the active 10-minute block | M4 | AC6 |
| **F26** | Live Study Rooms Presence | Study Rooms | Real-time tri-state presence (`STUDYING`, `RESTING`, `OFFLINE`) <500ms | M4 | AC7 |
| **F27** | Animated Avatars & Desk Cam | Study Rooms | State-driven vector avatars (reading, resting) or low-latency camera tile | M4 | AC7 |
| **F28** | Groups, Quotas, Cheering | Study Rooms | Peer study quotas, group leaderboards, and instant emoji cheering | M4 | AC7 |
| **F29** | "Focus Now" Launcher Action | Hybrid Bridge | Direct trigger on database rows/blocks launching tagged Focus HUD | M5 | AC8 |
| **F30** | Session Auto-Logging to DB Rows | Hybrid Bridge | Atomic transaction updating `Total Studied Time`, `Sessions Count`, etc. | M5 | AC8 |
| **F31** | In-Session Scratchpad Drawer | Hybrid Bridge | Split-screen note drawer reading/writing to linked page without breaking lock | M5 | AC5, AC9 |
| **F32** | D-Day & Exam Syllabus Countdown | Hybrid Bridge | Countdown widget linked to exam targets and syllabus checklist rollups | M5 | AC4, AC8 |
| **F33** | GitHub-Style Study Heatmaps | Analytics | Annual & monthly 4-level contribution heatmaps with CustomPainter | M6 | AC10 |
| **F34** | 05:00 AM Day-Cutoff Streak Engine | Gamification | Streak calculation preserving night-owl sessions before 05:00 AM | M6 | AC10 |
| **F35** | Multi-Tier Leaderboards & Privacy | Gamification | National, group, and peer leaderboards with Anonymized Mode toggle | M6 | AC7, AC10 |

---

## Milestones Roadmap

| # | Name | Scope & Mapped Features | Dependencies | Status |
|---|------|-------------------------|--------------|--------|
| **M1** | Project Scaffolding & Notion Workspace Engine | Flutter scaffolding, Drift SQLite DB, Pages & Blocks DAOs, Page Tree with drag-and-drop, Block Editor (F01–F07) | None | DONE |
| **M2** | Relational Database Engine & 6 Views | Property schema, Relations, Formula AST parser, Rollups, 6 Views: Table, Kanban, Calendar, Timeline, List, Gallery (F08–F16) | M1 | IN_PROGRESS |
| **M3** | YPT Focus Engine, Stopwatch & Strict Lock | Monotonic stopwatch, Pomodoro, Exam timer, Strict Lock mode, Allowlist, Flip-to-Focus, Ambient sounds (F17–F23) | M1 | PLANNED |
| **M4** | 24-Hour Timetable Grid & Live Study Rooms | 144-block visual timetable (05:00 AM cutoff), CustomPainter, Live Study Rooms tri-state presence, Avatars, Cheering (F24–F28) | M3 | PLANNED |
| **M5** | HamPA Hybrid Synergy Bridge & Scratchpad | "Focus Now" task trigger, Atomic session auto-logging, In-session scratchpad drawer, D-Day & syllabus coupling (F29–F32) | M2, M3, M4 | PLANNED |
| **M6** | Analytics, Heatmaps & Streak Engine | GitHub-style heatmaps, 05:00 AM streak maintenance engine, Leaderboards with privacy controls (F33–F35) | M4, M5 | PLANNED |
| **M7** | 100% E2E Pass & Adversarial Hardening | Phase 1: Pass 100% of E2E Test Suite (Tiers 1-4). Phase 2: Tier 5 adversarial coverage hardening & project sign-off | M1–M6, TEST_READY | PLANNED |

---

## Interface Contracts

### 1. Workspace Engine ↔ Relational Database (`M1 ↔ M2`)
```dart
abstract class IWorkspaceRepository {
  Stream<List<PageEntity>> watchPageTree();
  Future<PageEntity> createPage({String? parentPageId, required String title, String? icon, bool isDatabaseRow = false});
  Future<void> updatePageParent({required String pageId, String? newParentPageId, required double newSortOrder});
  Stream<List<BlockEntity>> watchBlocksForPage(String pageId);
  Future<void> insertBlock(BlockEntity block);
  Future<void> updateBlock(BlockEntity block);
  Future<void> deleteBlock(String blockId);
}
```

### 2. Relational Database ↔ Focus Engine & Bridge (`M2 ↔ M5`)
```dart
abstract class IDatabaseEngineRepository {
  Stream<DatabaseEntity> watchDatabase(String databaseId);
  Stream<List<PropertyEntity>> watchProperties(String databaseId);
  Stream<List<RowEntity>> watchRows(String databaseId);
  Stream<List<CellEntity>> watchCells(String databaseId);
  Stream<List<ViewEntity>> watchViews(String databaseId);

  Future<void> updatePropertyValue({required String rowId, required String propertyId, dynamic value});
  Future<String> createRow(String databaseId); // Automatically creates underlying Page
  Future<void> deleteRow(String rowId);
}
```

### 3. Focus Engine ↔ Timetable & Hybrid Bridge (`M3 ↔ M4, M5`)
```dart
abstract class IFocusEngineService {
  Stream<FocusEngineState> get stateStream;
  FocusEngineState get currentState;

  Future<void> startSession({
    required String subjectId,
    required SessionType sessionType,
    FocusContext? linkedContext,
    int? targetDurationSeconds,
  });
  Future<void> pauseSession();
  Future<void> resumeSession();
  Future<FocusSessionSummary> completeSession({required bool markTaskCompleted});
  Future<void> abandonSession({required String reason});
}
```

### 4. Hybrid Bridge ↔ Data & Analytics (`M5 ↔ M6`)
```dart
abstract class IHybridBridgeService {
  Future<void> launchFocusFromTask(FocusContext context);
  Future<void> executeAutoLogTransaction({
    required FocusSession session,
    required List<FocusInterval> intervals,
    required bool markTaskCompleted,
  });
  Stream<List<BlockEntity>> watchScratchpadBlocks(String pageId);
  Future<void> updateScratchpadBlock(BlockEntity block);
}
```

### 5. Timetable & Analytics Engine (`M4, M6`)
```dart
abstract class ITimetableProjectionEngine {
  List<GridBlockState> projectIntervalsToGrid({
    required DateTime studyDay,
    required List<FocusInterval> intervals,
    required Map<String, SubjectEntity> subjectMap,
  });
  Stream<List<GridBlockState>> watchTodayGrid();
}

abstract class IStreakEngine {
  Future<StreakResult> calculateStreak();
}
```

---

## Code Layout

```
c:\parsa\HamPA\
├── pubspec.yaml
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── constants/             # Day cutoff (05:00), 144-slot grid defs, lock allowlist
│   │   ├── theme/                 # Dark/light theme, subject color palettes
│   │   ├── database/              # Drift SQLite database & DAOs
│   │   │   ├── app_database.dart
│   │   │   ├── daos/
│   │   │   └── tables/
│   │   ├── platform/              # Sensors, audio manager, background lifecycle
│   │   └── utils/                 # Monotonic timer math, formula parser AST, timetable projection
│   └── features/
│       ├── workspace_editor/      # M1: Notion Page Tree & Block Editor
│       ├── workspace_database/    # M2: Relational DB Engine & 6 Views
│       ├── focus_engine/          # M3: Stopwatch, Pomodoro, Exam timers
│       ├── strict_lock/           # M3: Anti-distraction, allowlist, flip sensor
│       ├── timetable_grid/        # M4: 144-Block 24h Timetable CustomPainter
│       ├── study_room/            # M4: Live Study Rooms, avatars, cheering
│       ├── hybrid_bridge/         # M5: "Focus Now", Auto-logging, Scratchpad, D-Day
│       └── analytics_gamification/# M6: Heatmaps, Streak Engine, Leaderboards
└── test/
    ├── unit/
    ├── widget/
    ├── integration/
    └── e2e/                       # E2E Test Suite (Tiers 1-4)
```
