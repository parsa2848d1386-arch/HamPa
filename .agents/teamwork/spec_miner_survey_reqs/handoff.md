# Requirements & Feature Specification Handoff Report

**Agent**: `teamwork_preview_spec_miner` (Requirements & Feature Spec Miner)  
**Working Directory**: `c:\parsa\HamPA\.agents\teamwork\spec_miner_survey_reqs`  
**Parent Orchestrator Conversation ID**: `22d8faaf-eb90-463c-99a6-32a4eb94320e`  
**Timestamp**: 2026-10-16T16:22:00Z  

---

## 1. Observation

Direct examination of authoritative input documents:

### 1.1 Source Files Examined
1. `c:\parsa\HamPA\.agents\teamwork\ORIGINAL_REQUEST.md` (Lines 1–54)
2. `c:\parsa\HamPA\.agents\teamwork\spec_miner_survey_reqs\DISPATCH.md` (Lines 1–20)

### 1.2 Verbatim Requirements Observed
- **Product Vision (Line 5)**:
  > "Building 'HamPA' (هم‌پا), a complete hybrid productivity and planner application unifying Notion's block-based workspace and relational databases with YeolPumTa's (YPT) real-time focus tracking, live study rooms, strict anti-distraction lock, 10-minute visual timetable, and gamified analytics using Flutter."

- **R1: Block-Based Workspace & Relational Database System (Lines 12–18)**:
  - "Hierarchical page tree supporting arbitrary nesting and drag-and-drop organization."
  - "Modular block-based editor supporting text, headings, interactive checklists, callouts, toggles, code syntax highlighting, and LaTeX math formatting."
  - "Relational database engine supporting 6 distinct views: Table (inline cell editing & aggregations), Kanban Board (drag-and-drop grouped by status/select), Calendar (monthly/weekly), Timeline/Gantt (dependencies), List, and Gallery."
  - "Rich property schema: status, select/multi-select, dates, tags, relations between databases, formulas, and automatic rollups."
  - "Local-first architecture (SQLite / Drift + local cache) for zero-latency offline writing and editing."

- **R2: Live Focus Tracking, Pomodoro & Anti-Distraction Mechanics (Lines 19–25)**:
  - "High-precision monotonic background stopwatch (`elapsed = now - start_epoch - paused_duration`), customizable Pomodoro cycles (work/break intervals), and mock exam countdown timers."
  - "Anti-distraction system: Strict Lock Mode, allowlist for essential reference tools, flip-to-focus sensor detection, and built-in multi-track ambient soundscape player."
  - "Signature YPT 24-hour visual 10-minute timetable grid mapping every 10-minute block of the day (144 blocks, 05:00 AM - 05:00 AM) to color-coded subjects."
  - "Live Study Rooms ('Study With Me'): Tri-state real-time presence (`STUDYING`, `RESTING`, `OFFLINE`) showing active subject, elapsed time, and animated Rive/Lottie avatars or WebRTC desk cam."
  - "Study groups with peer rankings, collective study quotas, and instant cheering reactions."

- **R3: Hybrid Synergy & Dynamic Linking Engine (Lines 26–31)**:
  - "'Focus Now' integration on any database row or checklist block: clicking launches the active Focus HUD tagged directly to that task."
  - "Session auto-logging: upon completion, automatically updates database properties (`Total Studied Time`, `Sessions Count`, `Last Studied Date`, `Progress`)."
  - "In-session scratchpad: distraction-free split drawer allowing note-taking and checklist checking without breaking the lock mode."
  - "D-Day & Exam countdown widget deeply coupled with study subject milestones and syllabus checklists."

- **R4: Analytics, Heatmaps & Gamification Engine (Lines 32–36)**:
  - "GitHub-style annual & monthly study heatmaps with intensity thresholds based on study hours."
  - "Daily streak maintenance engine with customizable day-cutoff hour (05:00 AM) to preserve midnight study sessions."
  - "National, group, and peer leaderboards with real-time ranking and privacy controls (anonymized mode)."

- **Acceptance Criteria (Lines 37–54)**:
  - AC1: "Nested sub-pages can be created, edited, and rearranged without state loss."
  - AC2: "Database views switch between Table, Kanban, Calendar, and Timeline with identical underlying data state."
  - AC3: "Offline edits persist reliably in local Drift SQLite and synchronize upon reconnection without data corruption."
  - AC4: "Background timer persists accurately with zero drift when the application is minimized or backgrounded."
  - AC5: "Strict Lock mode detects background/foreground switches and logs interruptions or restricts unauthorized app launches."
  - AC6: "The 10-minute grid visually paints corresponding time slots with subject colors in real-time."
  - AC7: "Live study room displays real-time peer status changes within < 500ms latency."
  - AC8: "Triggering focus from a database task automatically registers the elapsed time to that task's rollup and total time property."
  - AC9: "In-session scratchpad saves edits directly to the linked task's page document."
  - AC10: "Heatmap and streak counter update immediately when a session finishes."

---

## 2. Logic Chain

1. **Architecture Decomposition**:
   - The user request requires a deep synergy between two disparate domains: an asynchronous, local-first document/database graph (Notion) and a high-frequency, real-time, time-series sensory engine (YPT).
   - This necessitates 10 discrete functional clusters:
     1. Workspace & Navigation Tree
     2. Modular Block Editor
     3. Relational Database Schema & Calculations
     4. Relational Database Views
     5. Stopwatch & Focus Engine
     6. Anti-Distraction & Sensory System
     7. 24-Hour 10-Minute Timetable Grid
     8. Live Study Rooms & Social Presence
     9. HamPA Hybrid Bridge
     10. Analytics, Heatmaps & Gamification
   
2. **Local-First & Data Integrity**:
   - Because offline edits must persist reliably without corruption (AC3), the core entity store must reside in local SQLite via Drift ORM, backed by immutable change logs / dirty flags for sync.
   - The document model (pages/blocks) and database model (schemas/rows/cells/relations/formulas/rollups) must share transactional SQLite tables.

3. **High-Precision Time Accounting**:
   - Standard Flutter `Timer.periodic` drifts when the main thread is busy or when the OS suspends the app process in background.
   - Monotonic time tracking (`SystemClock.elapsedRealtime` / `Stopwatch.elapsedMilliseconds`) with persistent start timestamps (`start_epoch`, `accumulated_pause_ms`) guarantees mathematical zero drift across app lifecycle transitions (AC4).

4. **Visual Timetable Mathematics**:
   - A day is defined not from 00:00 to 24:00, but from 05:00 AM to 05:00 AM next day (144 blocks of 10 minutes).
   - Any session spanning 05:00 AM must be split across the boundary: interval before 05:00 AM belongs to Day $D-1$, interval after belongs to Day $D$.

5. **Closed-Loop Hybrid Convergence**:
   - When a focus session runs on a database row or checklist block (F29), the timer emits time deltas that update the task entity upon session end (F30).
   - This in turn triggers foreign-key relations (F09), re-evaluates formulas (F10), updates parent rollups (F11), marks scratchpad edits into the page document (F31), recalculates syllabus completion (F32), refreshes the daily timetable grid (F24/F25), and updates heatmaps and streaks (F33/F34).

---

## 3. Caveats

1. **Platform Differences for Strict Lock Enforcement (F20, F21)**:
   - On Android, overlay permissions and `AccessibilityService` / `UsageStatsManager` allow robust detection and interception of non-whitelisted apps.
   - On iOS, sandbox constraints restrict killing or blocking other apps directly; iOS implementation relies on `WidgetsBindingObserver` lifecycle transitions, Screen Time API (FamilyControls/ManagedSettings), and interruption strike penalties.
2. **Sensor Hardware Availability (F22)**:
   - Desktop platforms (Windows/macOS/Linux) and web lack accelerometer/proximity hardware for Flip-to-Focus. The feature must gracefully detect sensor presence and disable the toggle on unsupported platforms.
3. **WebRTC Media Server Requirements (F27)**:
   - Real-time peer desk cam streaming requires STUN/TURN traversal and an SFU (e.g. LiveKit or mediasoup) for multi-peer rooms beyond small mesh topologies. Animated Rive/Lottie avatars serve as the default zero-bandwidth fallback.
4. **Formula Calculation Complexity (F10)**:
   - Dynamic formula evaluation requires an Abstract Syntax Tree (AST) parser with cycle detection to prevent stack overflow when users configure recursive dependencies (e.g. `A = B + 1`, `B = A + 1`).

---

## 4. Conclusion: Complete Requirements & Feature Inventory

### 4.1 Master Feature Table (Features Discovered)

| # | Category | Feature | Description | Inputs | Outputs | Error Behavior | Discovered Via |
|---|----------|---------|-------------|--------|---------|----------------|----------------|
| **F01** | Workspace | Hierarchical Page Tree | Arbitrary depth nesting of pages and sub-pages in sidebar navigation | Parent page ID, title, icon/emoji | Reactive page tree, breadcrumbs, navigation routes | Circular parenting rejected with `ValidationError`; orphaned pages rescued to root | R1, AC1 |
| **F02** | Workspace | Drag-and-Drop Page Organization | Reorder pages and re-parent by dragging in navigation tree | Source page ID, target parent ID, target sort index | Persisted sort orders, re-rendered sidebar tree | Moving parent into own descendant prohibited; snap back on error | R1, AC1 |
| **F03** | Workspace | Local-First Drift SQLite Persistence | Synchronous local persistence with local memory cache before network sync | CRUD operations, block mutations | Zero-latency UI response (<16ms), dirty sync flags | SQLite transaction rollback on write error; optimistic UI rollback | R1, AC3 |
| **F04** | Block Editor | Rich Text & Headings Blocks | Modular paragraph and H1/H2/H3 blocks with inline styling (bold, italic, underline, code, links) | Keystrokes, markdown prefixes (`# `, `## `), selection ranges | Block JSON deltas, rendered rich text | Malformed markdown treated as literal string; unclosed formatting auto-closed | R1, AC1 |
| **F05** | Block Editor | Interactive Checklist Blocks | To-do items with toggleable checkbox and strikethrough text | Slash command `/todo`, checkbox tap, enter key | Block JSON with `checked: bool`, strike-through styling | Invalid block JSON schema normalized to default unchecked | R1, AC1, AC8, AC9 |
| **F06** | Block Editor | Callout & Toggle Container Blocks | Stylized callout box with icon/tint; collapsible toggle container with nested child blocks | Slash command `/callout` or `/toggle`, child block IDs | Collapsible accordion UI, callout border & icon container | Nesting depth capped at 20 levels to prevent UI overflow; state preserved on fold | R1, AC1 |
| **F07** | Block Editor | Code Syntax Highlighting & LaTeX Math | Code snippet blocks with language themes; inline & display LaTeX math equations via KaTeX/flutter_math | Language identifier, code text, raw LaTeX math string | Formatted syntax code widget, rendered vector math equations | Unsupported language falls back to plaintext; invalid LaTeX renders inline error badge | R1, AC1 |
| **F08** | Relational DB | Rich Property Schema Engine | Dynamic column definitions supporting text, number, select, multi-select, status, date, tags, url, checkbox | Schema field name, type enum, select options configuration | Schema metadata table in SQLite, dynamic cell editors | Duplicate column names rejected; non-coercible type changes prompt confirmation | R1, AC2 |
| **F09** | Relational DB | Two-Way Database Relations | Relational linking between rows of different databases (1:1, 1:N, N:N) | Source DB ID, Target DB ID, row IDs | Foreign key junction records, interactive relation pills | Deleting target row cleans junction references (referential integrity) | R1, AC2, AC8 |
| **F10** | Relational DB | Formula Expression Engine | Mathematical, string, date, and logical evaluations across row properties | Expression AST, row property values | Evaluated cell value (number, text, date, bool) | Division by zero returns null/#DIV0; cycle detected returns #CYCLE!; syntax errors flagged | R1, AC2, AC8 |
| **F11** | Relational DB | Automatic Rollups & Aggregations | Aggregates values of related rows (Sum, Average, Min, Max, Count, Percent checked) | Relation property, target column, aggregation function | Computed rollup value on row; column footer totals | Empty relation set returns 0 or null; non-numeric target falls back to count | R1, AC2, AC8 |
| **F12** | Relational DB | Table View with Inline Editing | Spreadsheet grid with virtualized scrolling, inline editing, column reorder/resize, and footer aggregations | Database rows, column config, cell keyboard/tap edits | Virtualized data table, reactive aggregation footer | Scroll boundary clamping; input validation rejects incompatible cell values | R1, AC2 |
| **F13** | Relational DB | Kanban Board View | Drag-and-drop card columns grouped by status or select options | Group-by column ID, card items, drag-drop coordinates | Card move events, updated status property on row | Drag to collapsed column expands or cancels; optimistic move reverts on DB error | R1, AC2 |
| **F14** | Relational DB | Calendar View (Monthly & Weekly) | Date-mapped view displaying items across day cells with month/week toggles | Date property identifier, visible date window | Calendar grid with colored event chips, current day marker | Items with null date grouped in "Unscheduled" drawer; multi-day spans clamp to bounds | R1, AC2 |
| **F15** | Relational DB | Timeline / Gantt View | Chronological bar chart showing task durations and drag-and-drop dependency links | Start date, end date, dependency relation | Gantt bar widgets, SVG dependency connector lines | Cyclic dependency detected and prohibited; end date auto-adjusted if before start | R1, AC2 |
| **F16** | Relational DB | List & Gallery Views | Compact vertical item list; visual card grid displaying image/content previews | Display property list, card size, preview source | Minimal list view or responsive image grid cards | Missing image preview renders subject color placeholder; text clamped with ellipsis | R1, AC2 |
| **F17** | Focus Engine | Monotonic Background Stopwatch | Drift-free study timer using monotonic device timestamps: `elapsed = now - start_epoch - paused_duration` | Start, pause, resume, stop user triggers; monotonic clock | High-precision ticker (HH:MM:SS), saved session record | Device clock modification detected via uptime; negative paused duration clamped to 0 | R2, AC4 |
| **F18** | Focus Engine | Customizable Pomodoro Cycles | Configurable work & break intervals with audio/vibration alerts and cycle counters | Work duration, short/long break duration, cycle target | Stage indicator (`FOCUSING`, `SHORT_BREAK`, `LONG_BREAK`), progress ring | Premature stop prompts user to record partial time or discard; 0-duration rejected | R2, AC4, AC7 |
| **F19** | Focus Engine | Mock Exam Countdown Timers | Standardized exam simulation timer with section breakdowns, warning bells, and auto-submit | Total duration, section split timetable, warning intervals | Remaining countdown display, section progress bar | App crash or device reboot resumes timer accounting for real elapsed time; locks at 0 | R2, AC4 |
| **F20** | Anti-Distraction | Strict Lock Mode & Interruption Logger | High-discipline overlay detecting background/foreground transitions and logging unauthorized exits | App lifecycle state changes, home button presses | Interruption count, interruption duration log, penalty screen | System emergencies (incoming calls) exempted; unauthorized switches log timestamp/app | R2, AC5 |
| **F21** | Anti-Distraction | Application Reference Allowlist | Whitelist of permitted reference tools (Calculator, Dictionary, PDFs) accessible during lock | Package identifiers of permitted apps, app launch event | Filtered quick-launch dock, bypass of lock penalty | Blacklisted apps (social, games) rejected from allowlist; non-whitelisted launch penalized | R2, AC5 |
| **F22** | Anti-Distraction | Flip-to-Focus Sensor Detection | Accelerometer & proximity sensor detection to auto-start/pause timer when phone is face down | Hardware accelerometer (Z-axis) & proximity distance | Auto start/pause event, haptic confirmation feedback | Missing sensor hardware disables toggle cleanly; 1.5s debounce prevents accidental bumps | R2, AC4, AC5 |
| **F23** | Anti-Distraction | Multi-Track Ambient Soundscapes | Offline ambient mixer (Rain, White Noise, Cafe, Campfire, Library) with individual volume sliders | Sound selection toggles, per-track volume (0.0–1.0) | Multi-channel blended audio stream, notification player | Audio focus loss (e.g. phone call) pauses audio; ducking audio on Pomodoro bells | R2, AC4 |
| **F24** | Timetable Grid | 24-Hour 10-Minute Timetable Grid | Visual matrix of 144 discrete 10-minute blocks covering 05:00 AM to 05:00 AM next day | Daily study session intervals `[start, end, subject_id]` | 144-block color-coded visual grid, subject breakdown | Sessions crossing 05:00 AM cutoff split between consecutive days; partial blocks shaded | R2, AC6 |
| **F25** | Timetable Grid | Real-Time Block Painting & Pulsing | Dynamically paints and pulses the active 10-minute slot during a running study session | Active subject color, wall clock seconds | Live updating canvas block, fill percentage indicator | System sleep/wake refreshes block paint immediately; DST shifts recalculate block index | R2, AC6 |
| **F26** | Study Rooms | Live Study Rooms & Tri-State Presence | Real-time virtual study rooms with tri-state status: `STUDYING`, `RESTING`, `OFFLINE` (<500ms latency) | User status updates, room join/leave events | Member grid showing names, subject tags, live elapsed timers | Ungraceful disconnect marked OFFLINE after 30s heartbeat timeout; auto-reconnect | R2, AC7 |
| **F27** | Study Rooms | Animated Avatars & WebRTC Desk Cam | Rive/Lottie avatars reflecting active study state or real-time WebRTC desk camera stream | Presence state machine, camera video frames | Animated vector character or low-latency video tile | Camera permission denial falls back to animated avatar; low bandwidth lowers video bitrate | R2, AC7 |
| **F28** | Study Rooms | Groups, Quotas, Cheering Reactions | Study groups with collective study quotas, peer rankings, and real-time cheering emoji animations | Cheering emoji tap (👏, 🔥, 💪, ☕), study aggregates | Floating particle animations, group progress bar, rank table | Cheering rate limit (max 5 per 10s) prevents spamming; leaving group keeps past stats | R2, AC7 |
| **F29** | Hybrid Bridge | "Focus Now" Launcher Action | Direct action button on database rows or checklist blocks launching tagged Focus HUD | Row ID / Block ID, subject association | Focus HUD overlay populated with task context and subject | Deleted task during session keeps timer alive and prompts re-association at end | R3, AC8 |
| **F30** | Hybrid Bridge | Session Auto-Logging to DB Rows | Automatically updates `Total Studied Time`, `Sessions Count`, `Last Studied Date`, `Progress` | Completed session record (task_id, duration, timestamp) | Updated SQLite database row, refreshed rollups/formulas | Locked/invalid task writes session to general log with orphan flag for manual resolution | R3, AC8 |
| **F31** | Hybrid Bridge | In-Session Scratchpad Drawer | Split-screen drawer during active focus/lock for note-taking and checklist checking without breaking lock | Keystrokes, checklist taps inside drawer | Real-time debounced writes to linked task's page document | Drawer write failure retries locally; content never discarded even on abnormal exit | R3, AC5, AC9 |
| **F32** | Hybrid Bridge | D-Day & Exam Syllabus Countdown | Countdown widget linked to exam milestones and syllabus checklist completion percentages | Target date, linked syllabus database filter | Remaining days badge (`D-XX`), syllabus progress arc | Target date in past switches to `D+XX days ago`; empty syllabus shows 100% or N/A | R3, AC4, AC8 |
| **F33** | Analytics | GitHub-Style Study Heatmaps | Annual & monthly contribution heatmaps with 4 intensity levels based on study hours | Daily aggregated study seconds from SQLite | Color-coded grid matrix with hover tooltips | Leap years handled with 366 cells; zero-study days render as empty baseline cells | R4, AC10 |
| **F34** | Gamification | Daily Streak Engine with 05:00 AM Cutoff | Streak maintenance engine using 05:00 AM day demarcation to preserve midnight study sessions | Session timestamps, day-cutoff setting (05:00 AM), threshold | Current streak counter, longest streak, freeze shields | Sessions between 00:00 and 05:00 AM credited to preceding calendar study day | R4, AC10 |
| **F35** | Gamification | Multi-Tier Leaderboards & Privacy Controls | National, group, and peer leaderboards with real-time rankings and "Anonymized Mode" toggle | Aggregated study durations, user privacy settings | Ranked leaderboard list with names or "Anonymous #ID" | Disconnected client shows cached rankings with offline badge; ties broken by earliest epoch | R4, AC7, AC10 |

---

### 4.2 Acceptance Criteria Mapping Matrix

All 10 acceptance criteria from `ORIGINAL_REQUEST.md` map to specific features and have deterministic test assertions:

| Acceptance Criteria | Description | Mapped Features | Deterministic Verification Test Assertion |
|---------------------|-------------|-----------------|-------------------------------------------|
| **AC1** | Nested sub-pages can be created, edited, and rearranged without state loss. | **F01, F02, F04, F05, F06, F07** | 1. Create root page $P_1$.<br>2. Create child page $P_2$ inside $P_1$, and grandchild $P_3$ inside $P_2$.<br>3. Populate $P_3$ with headings, checklists, callouts, and code blocks.<br>4. Drag $P_3$ to be a direct sibling of $P_1$.<br>5. Restart app process and re-query SQLite: assert $P_3$ parent is `null`, sort order index matches dropped position, and all block contents are bit-for-bit identical. |
| **AC2** | Database views switch between Table, Kanban, Calendar, and Timeline with identical underlying data state. | **F08, F09, F10, F11, F12, F13, F14, F15, F16** | 1. Insert 5 rows with properties (`Status`, `Date`, `Duration`) into database in Table view.<br>2. Switch to Kanban view: assert 5 cards appear in correct status columns.<br>3. Drag Card 1 from "Todo" to "Done".<br>4. Switch to Calendar view: assert Card 1 renders on its assigned date.<br>5. Switch to Timeline view: assert Gantt bar duration matches `Duration`.<br>6. Switch back to Table view: assert Row 1 `Status` equals "Done" with no data divergence across views. |
| **AC3** | Offline edits persist reliably in local Drift SQLite and synchronize upon reconnection without data corruption. | **F03** | 1. Set network state to `OFFLINE`.<br>2. Perform 20 block additions, edits, and deletions across 3 pages.<br>3. Terminate app process via `SIGKILL`.<br>4. Re-launch app in offline mode: assert all 20 modifications exist in local Drift SQLite.<br>5. Switch network state to `ONLINE`: assert sync queue flushes dirty records to remote endpoint and marks records clean with zero data loss. |
| **AC4** | Background timer persists accurately with zero drift when the application is minimized or backgrounded. | **F17, F18, F19, F22, F23, F32** | 1. Start stopwatch at monotonic timestamp $T_0$.<br>2. Send application to background (trigger `AppLifecycleState.paused`).<br>3. Wait exactly 300 seconds (5 minutes) verified via external monotonic system clock.<br>4. Restore application to foreground (trigger `AppLifecycleState.resumed`).<br>5. Read stopwatch elapsed time: assert $|elapsed - 300,000\text{ ms}| < 50\text{ ms}$ (zero cumulative drift). |
| **AC5** | Strict Lock mode detects background/foreground switches and logs interruptions or restricts unauthorized app launches. | **F20, F21, F31** | 1. Enable Strict Lock mode and start focus session.<br>2. Trigger background lifecycle event (user switches to home screen or unapproved app).<br>3. Wait 4 seconds and return to HamPA.<br>4. Assert `interruptions_count` increments from 0 to 1.<br>5. Assert `interruption_duration_seconds` records 4 seconds.<br>6. Launch whitelisted app (e.g. Calculator): assert no interruption is logged. |
| **AC6** | The 10-minute grid visually paints corresponding time slots with subject colors in real-time. | **F24, F25** | 1. Assign color `#4CAF50` (Green) to subject "Mathematics".<br>2. Start focus session at 10:00:00 AM for Mathematics.<br>3. At 10:05:00 AM (mid-block), inspect visual painter output: assert block index 30 (10:00–10:10 AM) is active with partial fill ratio 0.5 and color `#4CAF50`.<br>4. At 10:20:00 AM, assert blocks 30 (10:00–10:10) and 31 (10:10–10:20) are fully painted `#4CAF50`. |
| **AC7** | Live study room displays real-time peer status changes within < 500ms latency. | **F18, F26, F27, F28, F35** | 1. Connect Client A and Client B to Study Room #101.<br>2. Client A transitions from `RESTING` to `STUDYING` at timestamp $T_{\text{action}}$.<br>3. Client B listener receives presence update event at timestamp $T_{\text{received}}$.<br>4. Assert $T_{\text{received}} - T_{\text{action}} < 500\text{ ms}$.<br>5. Assert Client B UI updates Client A's status pill to `STUDYING` and triggers study animation. |
| **AC8** | Triggering focus from a database task automatically registers the elapsed time to that task's rollup and total time property. | **F05, F08, F09, F10, F11, F29, F30, F32** | 1. Create Project row with Rollup `Sum(Tasks.Total Studied Time)`.<br>2. Create Task 1 linked to Project with initial `Total Studied Time` = 0.<br>3. Click "Focus Now" on Task 1 and run session for 1800 seconds (30m).<br>4. Stop and save session: assert Task 1 `Total Studied Time` = 1800, `Sessions Count` = 1, `Last Studied Date` = Today.<br>5. Assert Project rollup value updates to 1800 seconds reactively. |
| **AC9** | In-session scratchpad saves edits directly to the linked task's page document. | **F05, F31** | 1. Start focus session linked to Task Document $D_1$.<br>2. Open in-session scratchpad drawer.<br>3. Type new markdown line `## Session Notes\n- [ ] Review Proof 4.2`.<br>4. Complete focus session.<br>5. Navigate to $D_1$ page document in workspace: assert block heading "Session Notes" and checklist block "Review Proof 4.2" are present in page block hierarchy in Drift SQLite. |
| **AC10** | Heatmap and streak counter update immediately when a session finishes. | **F33, F34, F35** | 1. Note pre-session state: Date = `2026-10-16`, Heatmap cell intensity = Level 0 (0 hrs), Streak = 3 days.<br>2. Complete a focus session of 3,600 seconds (1 hour).<br>3. Query analytics store immediately upon session save: assert `2026-10-16` heatmap intensity updates to Level 1.<br>4. Assert daily streak counter increments from 3 to 4 days without app restart. |

---

### 4.3 Detailed Edge Cases & Boundary Conditions

| # | Feature | Input / Trigger Condition | Observed / Required System Behavior |
|---|---------|---------------------------|--------------------------------------|
| **E01** | F24, F34 | Study session starts at 04:30 AM and finishes at 05:30 AM (crosses 05:00 AM cutoff) | Session is split at the 05:00 AM boundary: 30 minutes (04:30–05:00) is credited to yesterday's study day and timetable grid; 30 minutes (05:00–05:30) is credited to today's study day and grid. |
| **E02** | F34 | User studies between 01:00 AM and 03:00 AM after midnight | Because 01:00 AM–03:00 AM is prior to the 05:00 AM day-cutoff, this session is credited to the preceding calendar day, maintaining the user's night-owl study streak without breaking continuity. |
| **E03** | F17 | User manually advances or sets back device system clock while stopwatch is running | Stopwatch engine uses monotonic elapsed boot time (`SystemClock.elapsedRealtime` or `Stopwatch.elapsedMicroseconds`); changes to wall clock `DateTime.now()` do not alter elapsed time calculation. Negative durations are impossible. |
| **E04** | F17, F19 | OS kills HamPA background process due to low memory (OOM killer) while timer is active | On relaunch, HamPA reads the persistent session record (`start_epoch`, `last_persisted_pause_epoch`). It computes elapsed time using the device boot timestamp to verify no reboot occurred. Timer resumes accurately. |
| **E05** | F17 | Device reboots or battery dies while focus timer was running | On app restart after boot, HamPA detects device boot timestamp is greater than session start timestamp. It caps session elapsed time at the shutdown epoch recorded by background heartbeat, preventing inflated hours. |
| **E06** | F10 | User creates circular formula reference (e.g. Property A depends on B, B depends on A) | Dependency graph cycle detection (Tarjan's/DFS) catches the loop during AST compilation; affected cells display `#CYCLE!` error badge instead of crashing or freezing the UI thread. |
| **E07** | F10 | Formula divides by zero or references an unpopulated/null numeric property | Formula engine returns `null` or `#DIV/0!` badge; downstream rollups and dependent columns treat the cell as null rather than propagating unhandled exceptions. |
| **E08** | F11 | Rollup targets a relation where all linked rows are deleted or empty | Rollup function returns default scalar value: `0` for Count/Sum/Percent, `null` for Average/Median/Min/Max. |
| **E09** | F01, F02 | User drags Page A into Page B, where Page B is already a child of Page A | Re-parenting engine checks ancestor chain of target; circular move is prohibited; drag gesture is rejected with visual bounce-back. |
| **E10** | F03 | Concurrent offline edits on two devices for the same database row or page block | Last-Write-Wins (LWW) resolution based on Lamport timestamps at property/field granularity, preventing whole-row or whole-page clobbering. |
| **E11** | F07 | User types malformed or invalid LaTeX formula (e.g. unclosed `\frac{...}`) | Formula renderer catches syntax parse exception, displays red underline warning with error offset, and maintains editor stability. |
| **E12** | F20 | Incoming emergency phone call, alarm clock, or Amber Alert occurs during Strict Lock Mode | System broadcast receiver / lifecycle listener detects incoming telephony call; pauses lock enforcement and does not count event as an unauthorized distraction penalty. |
| **E13** | F20 | User enters Android Split-Screen / Multi-Window mode or iOS Stage Manager during Strict Lock | App detects window focus change (`window.onFocusChanged`); prompts full-screen focus requirement and triggers warning overlay. |
| **E14** | F21 | User launches allowed app (Calculator), which attempts to open external browser link | Accessibility / Intent monitor detects unauthorized package launch (Browser) triggered from within whitelist app; intercepts and redirects back to HamPA or presents distraction warning. |
| **E15** | F22 | User enables Flip-to-Focus on desktop or tablet without proximity/gyro sensors | System checks hardware sensor availability via `sensors_plus`; if unavailable, Flip-to-Focus switch is disabled with informational tooltip. |
| **E16** | F22 | Phone placed face-down on shaky table or user nudges phone momentarily | 1,500ms hysteresis/debounce delay applied: timer only starts/pauses when phone remains face-down or face-up continuously for >1.5 seconds. |
| **E17** | F23 | Incoming phone call or other app requests audio focus while ambient soundscape is playing | Ambient audio player registers `AudioTrack` focus listener; cleanly pauses audio on `AUDIOFOCUS_LOSS_TRANSIENT` and resumes when call ends. |
| **E18** | F26 | User in live study room loses Wi-Fi connection abruptly (no graceful exit message) | Room server runs 30-second heartbeat ping; when 3 consecutive pings fail, server updates user status to `OFFLINE` and notifies peers. |
| **E19** | F28 | Malicious user or bot spams cheering emojis (100 clicks/sec) to another user | Client and server enforce token-bucket rate limiter (maximum 5 cheering reactions per 10-second window); excess requests dropped silently. |
| **E20** | F29, F30 | User starts focus on Task X, but deletes Task X from workspace while timer is still running | When session ends, HamPA detects task ID is orphaned; persists elapsed time in raw study log and displays modal: "Original task deleted. Reassign session to another task or save to general study log?" |
| **E21** | F31 | In-session scratchpad open when phone battery abruptly dies | Scratchpad input stream debounces and flushes delta writes to local SQLite every 2 seconds; maximum loss on abrupt battery cutoff is ≤2 seconds of typing. |
| **E22** | F32 | D-Day target exam date is set in the past (e.g. 5 days ago) | Countdown widget shifts from countdown mode (`D-5`) to anniversary/overdue mode (`D+5 days ago`) with distinct neutral color styling. |
| **E23** | F33 | Leap year day count (366 days) in annual heatmap grid | Heatmap layout dynamically computes days in current Gregorian year (366 in leap years) and appends the 366th day cell without grid overflow. |
| **E24** | F34 | User changes custom day-cutoff setting from 05:00 AM to 03:00 AM | Historical session raw timestamps remain unchanged; aggregation view recalculates daily totals and streaks using the updated cutoff boundary. |
| **E25** | F35 | User enables "Anonymized Mode" on public/national leaderboard | Server obfuscates username to `Anonymous #<Hash>` and masks subject names to `General Study`, ensuring strict privacy compliance while preserving competitive rank. |

---

## 5. Verification Method

To independently verify this specification against authoritative sources and validate its implementation:

1. **Document Fidelity Check**:
   - Verify line-by-line concordance with `c:\parsa\HamPA\.agents\teamwork\ORIGINAL_REQUEST.md`:
     - Requirements R1 through R4: check coverage against F01–F35 in Section 4.1.
     - Acceptance Criteria AC1 through AC10: check verification assertions against Section 4.2.
   - Command:
     ```powershell
     Select-String -Path "c:\parsa\HamPA\.agents\teamwork\ORIGINAL_REQUEST.md" -Pattern "R1|R2|R3|R4|Acceptance Criteria"
     ```

2. **Acceptance Criteria Full Coverage Check**:
   - Verify that all 10 Acceptance Criteria are mapped with 100% coverage:
     - AC1 -> F01, F02, F04, F05, F06, F07
     - AC2 -> F08, F09, F10, F11, F12, F13, F14, F15, F16
     - AC3 -> F03
     - AC4 -> F17, F18, F19, F22, F23, F32
     - AC5 -> F20, F21, F31
     - AC6 -> F24, F25
     - AC7 -> F18, F26, F27, F28, F35
     - AC8 -> F05, F08, F09, F10, F11, F29, F30, F32
     - AC9 -> F05, F31
     - AC10 -> F33, F34, F35

3. **Edge Case Determinism**:
   - Check that all 25 edge cases (E01–E25) describe unambiguous inputs and deterministic expected behaviors.

4. **Future Test Harness Verification**:
   - When project code is scaffolded, automated tests can directly verify these assertions via:
     ```powershell
     flutter test test/workspace/...
     flutter test test/database/...
     flutter test test/focus/...
     flutter test test/timetable/...
     flutter test test/social/...
     flutter test test/analytics/...
     ```
