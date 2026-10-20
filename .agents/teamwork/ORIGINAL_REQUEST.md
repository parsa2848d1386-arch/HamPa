# Original User Request

## 2026-10-16T16:13:05Z

Building "HamPA" (هم‌پا), a complete hybrid productivity and planner application unifying Notion's block-based workspace and relational databases with YeolPumTa's (YPT) real-time focus tracking, live study rooms, strict anti-distraction lock, 10-minute visual timetable, and gamified analytics using Flutter.

Working directory: c:\parsa\HamPA
Integrity mode: development

## Requirements

### R1. Block-Based Workspace & Relational Database System (Notion Core)
- Hierarchical page tree supporting arbitrary nesting and drag-and-drop organization.
- Modular block-based editor supporting text, headings, interactive checklists, callouts, toggles, code syntax highlighting, and LaTeX math formatting.
- Relational database engine supporting 6 distinct views: Table (inline cell editing & aggregations), Kanban Board (drag-and-drop grouped by status/select), Calendar (monthly/weekly), Timeline/Gantt (dependencies), List, and Gallery.
- Rich property schema: status, select/multi-select, dates, tags, relations between databases, formulas, and automatic rollups.
- Local-first architecture (SQLite / Drift + local cache) for zero-latency offline writing and editing.

### R2. Live Focus Tracking, Pomodoro & Anti-Distraction Mechanics (YPT Core)
- High-precision monotonic background stopwatch (`elapsed = now - start_epoch - paused_duration`), customizable Pomodoro cycles (work/break intervals), and mock exam countdown timers.
- Anti-distraction system: Strict Lock Mode, allowlist for essential reference tools, flip-to-focus sensor detection, and built-in multi-track ambient soundscape player.
- Signature YPT 24-hour visual 10-minute timetable grid mapping every 10-minute block of the day (144 blocks, 05:00 AM - 05:00 AM) to color-coded subjects.
- Live Study Rooms ("Study With Me"): Tri-state real-time presence (`STUDYING`, `RESTING`, `OFFLINE`) showing active subject, elapsed time, and animated Rive/Lottie avatars or WebRTC desk cam.
- Study groups with peer rankings, collective study quotas, and instant cheering reactions.

### R3. Hybrid Synergy & Dynamic Linking Engine (HamPA Bridge)
- "Focus Now" integration on any database row or checklist block: clicking launches the active Focus HUD tagged directly to that task.
- Session auto-logging: upon completion, automatically updates database properties (`Total Studied Time`, `Sessions Count`, `Last Studied Date`, `Progress`).
- In-session scratchpad: distraction-free split drawer allowing note-taking and checklist checking without breaking the lock mode.
- D-Day & Exam countdown widget deeply coupled with study subject milestones and syllabus checklists.

### R4. Analytics, Heatmaps & Gamification Engine
- GitHub-style annual & monthly study heatmaps with intensity thresholds based on study hours.
- Daily streak maintenance engine with customizable day-cutoff hour (05:00 AM) to preserve midnight study sessions.
- National, group, and peer leaderboards with real-time ranking and privacy controls (anonymized mode).

## Acceptance Criteria

### Workspace & Database Engine Verification
- [ ] Nested sub-pages can be created, edited, and rearranged without state loss.
- [ ] Database views switch between Table, Kanban, Calendar, and Timeline with identical underlying data state.
- [ ] Offline edits persist reliably in local Drift SQLite and synchronize upon reconnection without data corruption.

### Focus, Lock & YPT Mechanics Verification
- [ ] Background timer persists accurately with zero drift when the application is minimized or backgrounded.
- [ ] Strict Lock mode detects background/foreground switches and logs interruptions or restricts unauthorized app launches.
- [ ] The 10-minute grid visually paints corresponding time slots with subject colors in real-time.
- [ ] Live study room displays real-time peer status changes within < 500ms latency.

### Hybrid Convergence Verification
- [ ] Triggering focus from a database task automatically registers the elapsed time to that task's rollup and total time property.
- [ ] In-session scratchpad saves edits directly to the linked task's page document.
- [ ] Heatmap and streak counter update immediately when a session finishes.

## Follow-up — 2026-10-16T21:35:56Z

The user has explicitly approved and instructed to start Milestone 2 now ("مایلستون 2 رو شروع کن"). Please finalize Milestone 1 gate approval immediately and dispatch Milestone 2 (Relational Database Engine supporting 6 Views: Table, Kanban, Calendar, Timeline, List, Gallery).


## 2026-10-16T21:36:46Z

User directive: "مایلستون 2 رو شروع کن" (Start Milestone 2 immediately). Finalize Milestone 1 review gate and dispatch the implementation swarm for Milestone 2 (Relational Database Engine supporting 6 Views: Table, Kanban, Calendar, Timeline, List, Gallery).


## 2026-10-17T09:29:27Z

Building "HamPA" (هم‌پا), a complete hybrid productivity and planner application unifying Notion's block-based workspace and relational databases with YeolPumTa's (YPT) real-time focus tracking, live study rooms, strict anti-distraction lock, 10-minute visual timetable, and gamified analytics using Flutter.

Working directory: c:\parsa\HamPA
Integrity mode: development
Requested team: Full team for end-to-end multi-agent fullstack development

## Current Project Checkpoint State
- Carefully read `CHECKPOINT_STATE.md`, `.agents/teamwork/orchestrator_1/PROJECT.md`, and `notion_ypt_planner_architecture_plan.md`.
- Milestone 1 (Notion Workspace & Block Editor Core) is 100% complete with 107/107 unit and widget tests passing, signed off in GATE_STATUS.md. Do not rewrite or regress Milestone 1.
- Milestone 2 (Relational Database Engine & 6 Views): All 5 Drift tables and DAOs, 12 domain entities, formula parser with `#CYCLE!` protection, rollups, and the 6 views UI (Table, Kanban, Calendar, Timeline, List, Gallery) have been coded and pass `flutter analyze` with 0 issues. Resume from here: finalize the widget tests/verification for Milestone 2, review gate, and advance through Milestones 3, 4, 5, 6, and 7.

## Requirements

### R1. Block-Based Workspace & Relational Database System (Notion Core)
- Hierarchical page tree supporting arbitrary nesting and drag-and-drop organization.
- Modular block-based editor supporting text, headings, interactive checklists, callouts, toggles, code syntax highlighting, and LaTeX math formatting.
- Relational database engine supporting 6 distinct views: Table (inline cell editing & aggregations), Kanban Board (drag-and-drop grouped by status/select), Calendar (monthly/weekly), Timeline/Gantt (dependencies), List, and Gallery.
- Rich property schema: status, select/multi-select, dates, tags, relations between databases, formulas, and automatic rollups.
- Local-first architecture (SQLite / Drift + local cache) for zero-latency offline writing and editing.

### R2. Live Focus Tracking, Pomodoro & Anti-Distraction Mechanics (YPT Core)
- High-precision monotonic background stopwatch (`elapsed = now - start_epoch - paused_duration`), customizable Pomodoro cycles (work/break intervals), and mock exam countdown timers.
- Anti-distraction system: Strict Lock Mode, allowlist for essential reference tools, flip-to-focus sensor detection, and built-in multi-track ambient soundscape player.
- Signature YPT 24-hour visual 10-minute timetable grid mapping every 10-minute block of the day (144 blocks, 05:00 AM - 05:00 AM) to color-coded subjects.
- Live Study Rooms ("Study With Me"): Tri-state real-time presence (`STUDYING`, `RESTING`, `OFFLINE`) showing active subject, elapsed time, and animated Rive/Lottie avatars or WebRTC desk cam.
- Study groups with peer rankings, collective study quotas, and instant cheering reactions.

### R3. Hybrid Synergy & Dynamic Linking Engine (HamPA Bridge)
- "Focus Now" integration on any database row or checklist block: clicking launches the active Focus HUD tagged directly to that task.
- Session auto-logging: upon completion, automatically updates database properties (`Total Studied Time`, `Sessions Count`, `Last Studied Date`, `Progress`).
- In-session scratchpad: distraction-free split drawer allowing note-taking and checklist checking without breaking the lock mode.
- D-Day & Exam countdown widget deeply coupled with study subject milestones and syllabus checklists.

### R4. Analytics, Heatmaps & Gamification Engine
- GitHub-style annual & monthly study heatmaps with intensity thresholds based on study hours.
- Daily streak maintenance engine with customizable day-cutoff hour (05:00 AM) to preserve midnight study sessions.
- National, group, and peer leaderboards with real-time ranking and privacy controls (anonymized mode).

## Acceptance Criteria

### Workspace & Database Engine Verification
- [ ] Nested sub-pages can be created, edited, and rearranged without state loss.
- [ ] Database views switch between Table, Kanban, Calendar, and Timeline with identical underlying data state.
- [ ] Offline edits persist reliably in local Drift SQLite and synchronize upon reconnection without data corruption.

### Focus, Lock & YPT Mechanics Verification
- [ ] Background timer persists accurately with zero drift when the application is minimized or backgrounded.
- [ ] Strict Lock mode detects background/foreground switches and logs interruptions or restricts unauthorized app launches.
- [ ] The 10-minute grid visually paints corresponding time slots with subject colors in real-time.
- [ ] Live study room displays real-time peer status changes within < 500ms latency.

### Hybrid Convergence Verification
- [ ] Triggering focus from a database task automatically registers the elapsed time to that task's rollup and total time property.
- [ ] In-session scratchpad saves edits directly to the linked task's page document.
- [ ] Heatmap and streak counter update immediately when a session finishes.


## 2026-10-17T10:06:40Z

DIRECTIVE FOR ACCELERATION & TOKEN OPTIMIZATION:
1. The user requested: "سرعت پیشبرد پروژه رو بیشتر و مصرف توکن رو بهینه تر کن".
2. Accelerate execution: Combine verification and test execution into single concise runs. Skip excessive parallel explorer loops where code already exists.
3. Keep logs, briefings, and updates succinct, action-oriented, and high-density to minimize token consumption.
4. Execute `worker_m2_3` verification swiftly, pass M2 gate with a single consolidated review/audit check rather than spawning excessive redundant subagents, and immediately advance to Milestone 3 (YPT focus, stopwatch & lock).


## 2026-10-17T11:48:05Z

Comprehensive quality assurance, stress testing, and forensic audit of "HamPA" (هم‌پا) across all 6 core milestones using Flutter, ensuring global market production standards (zero analyzer issues, 100% test pass rate across unit, widget, and E2E suites).

Working directory: c:\parsa\HamPA
Integrity mode: development
Requested team: Full team for end-to-end multi-agent verification and audit

## Requirements

### R1. Workspace & Relational Database Quality Audit (Milestones 1 & 2)
- Validate nested page tree hierarchy, Base-36 LexoRank reordering, and cyclic protection.
- Validate block editor rich media renderers (text, checklists, callouts, toggles, syntax-highlighted code, KaTeX LaTeX math).
- Validate all 6 database views (Table, Kanban, Calendar, Timeline, List, Gallery) maintaining 100% identical underlying state during view transitions.
- Validate formula parser arithmetic, built-ins, and circular reference resilience (`#CYCLE!`, `#DIV/0!`).

### R2. YPT Focus Engine, 24-Hour Timetable & Study Rooms Audit (Milestones 3 & 4)
- Validate monotonic delta stopwatch and Pomodoro timing with zero drift across background and pause states.
- Validate strict anti-distraction lock mode and ambient soundscape player.
- Validate 24-hour visual 10-minute timetable grid (144 blocks, 05:00 AM cutoff).
- Validate live study room peer presence states (`STUDYING`, `RESTING`, `OFFLINE`) and real-time cheering interaction.

### R3. HamPA Synergy Bridge & Analytics Engine Audit (Milestones 5 & 6)
- Validate task-to-timer focus invocation and automatic study duration rollup into database task properties.
- Validate in-session scratchpad drawer note persistence without breaking lock mode.
- Validate streak maintenance engine using 05:00 AM day cutoff and 4-tier intensity GitHub-style study heatmap.

## Acceptance Criteria

### Static & Code Integrity
- [ ] `flutter analyze` passes with 0 errors, 0 warnings, and 0 lints across the entire codebase.

### Comprehensive Test Pass
- [ ] 100% pass rate across all unit test suites (`test/unit/`).
- [ ] 100% pass rate across all widget test suites (`test/widget/`).
- [ ] Verification of core E2E scenarios under `test/e2e/`.

### World-Class Market Readiness
- [ ] Adversarial stress checks confirm zero unhandled exceptions, zero UI thread freezing, and data resilience.
