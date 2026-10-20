# Technical Architecture & System Design Handoff Report: HamPA (هم‌پا)

**Agent**: `teamwork_preview_explorer` (Architecture & Technical Stack Explorer)  
**Working Directory**: `c:\parsa\HamPA\.agents\teamwork\explorer_survey_arch`  
**Parent Orchestrator Conversation ID**: `22d8faaf-eb90-463c-99a6-32a4eb94320e`  
**Date**: 2026-10-16T16:25:00Z  

---

## 1. Observation

### 1.1 Sources & Authoritative Inputs Examined
1. `c:\parsa\HamPA\.agents\teamwork\ORIGINAL_REQUEST.md` (Lines 1–54): Defines core mission, R1, R2, R3, R4, and 10 Acceptance Criteria.
2. `c:\parsa\HamPA\.agents\teamwork\explorer_survey_arch\DISPATCH.md` (Lines 1–32): Assigned technical scope covering Notion blocks + 6-view relational DB, YPT timer + lock + 144 grid + study rooms, hybrid bridge, analytics/gamification, Drift SQLite storage, and clean module interfaces.
3. `c:\parsa\HamPA\.agents\teamwork\orchestrator_1\plan.md` (Lines 1–49): Global project phases and milestone breakdown.
4. `c:\parsa\HamPA\.agents\teamwork\spec_miner_survey_reqs\handoff.md`: Exhaustive requirements inventory decomposing R1–R4 into features F01–F35 and boundary conditions.

### 1.2 Verbatim Requirements & Constraints
- **Unifying Vision (ORIGINAL_REQUEST.md, Line 5)**:
  > "Building 'HamPA' (هم‌پا), a complete hybrid productivity and planner application unifying Notion's block-based workspace and relational databases with YeolPumTa's (YPT) real-time focus tracking, live study rooms, strict anti-distraction lock, 10-minute visual timetable, and gamified analytics using Flutter."
- **R1 Notion Core (Lines 12–18)**:
  - "Hierarchical page tree supporting arbitrary nesting and drag-and-drop organization."
  - "Modular block-based editor supporting text, headings, interactive checklists, callouts, toggles, code syntax highlighting, and LaTeX math formatting."
  - "Relational database engine supporting 6 distinct views: Table (inline cell editing & aggregations), Kanban Board (drag-and-drop grouped by status/select), Calendar (monthly/weekly), Timeline/Gantt (dependencies), List, and Gallery."
  - "Rich property schema: status, select/multi-select, dates, tags, relations between databases, formulas, and automatic rollups."
  - "Local-first architecture (SQLite / Drift + local cache) for zero-latency offline writing and editing."
- **R2 YPT Core (Lines 19–25)**:
  - "High-precision monotonic background stopwatch (`elapsed = now - start_epoch - paused_duration`), customizable Pomodoro cycles (work/break intervals), and mock exam countdown timers."
  - "Anti-distraction system: Strict Lock Mode, allowlist for essential reference tools, flip-to-focus sensor detection, and built-in multi-track ambient soundscape player."
  - "Signature YPT 24-hour visual 10-minute timetable grid mapping every 10-minute block of the day (144 blocks, 05:00 AM - 05:00 AM) to color-coded subjects."
  - "Live Study Rooms ('Study With Me'): Tri-state real-time presence (`STUDYING`, `RESTING`, `OFFLINE`) showing active subject, elapsed time, and animated Rive/Lottie avatars or WebRTC desk cam."
  - "Study groups with peer rankings, collective study quotas, and instant cheering reactions."
- **R3 Hybrid Bridge (Lines 26–31)**:
  - "'Focus Now' integration on any database row or checklist block: clicking launches the active Focus HUD tagged directly to that task."
  - "Session auto-logging: upon completion, automatically updates database properties (`Total Studied Time`, `Sessions Count`, `Last Studied Date`, `Progress`)."
  - "In-session scratchpad: distraction-free split drawer allowing note-taking and checklist checking without breaking the lock mode."
  - "D-Day & Exam countdown widget deeply coupled with study subject milestones and syllabus checklists."
- **R4 Analytics & Gamification (Lines 32–36)**:
  - "GitHub-style annual & monthly study heatmaps with intensity thresholds based on study hours."
  - "Daily streak maintenance engine with customizable day-cutoff hour (05:00 AM) to preserve midnight study sessions."
  - "National, group, and peer leaderboards with real-time ranking and privacy controls (anonymized mode)."
- **Acceptance Criteria (Lines 37–54)**:
  - AC1 (Nested pages), AC2 (6 Views identical state), AC3 (Offline Drift SQLite persistence), AC4 (Zero timer drift backgrounded), AC5 (Strict lock interruption detection), AC6 (10-minute grid real-time painting), AC7 (Live study room < 500ms latency), AC8 (Focus Now rollup/time registration), AC9 (Scratchpad saves to linked task page), AC10 (Heatmap/streak instant update).

---

## 2. Logic Chain

1. **Domain Disparity & Unification**:
   - Notion represents an asynchronous, hierarchical document-graph model (Pages, Blocks, Relational Schemas, Polymorphic Cells).
   - YPT represents a real-time, high-frequency, sensory time-series model (Millisecond monotonic clocks, OS lifecycle states, 10-minute timetable matrix, WebRTC/WebSocket presence).
   - In HamPA, these two paradigms cannot live in silos. The fundamental architectural bridge is the **Task-Session Dual Identity**:
     - *Every database row is an underlying Page*.
     - *Every focus session can bind directly to a database row or checklist block*.
     - *Every completed session triggers an atomic SQLite transaction updating the database row's properties, which reactively triggers formulas, rollups, 144-grid projections, heatmaps, and streak calculations*.

2. **Local-First SQLite / Drift Reactive Backbone**:
   - To satisfy AC3 (offline writing with zero data corruption) and AC2 (identical underlying state across 6 views), the single source of truth must be a local relational database using Drift (Dart SQLite).
   - Reactive streams (`Stream<List<T>>` via Drift `watch()`) ensure that whenever a cell or session updates, all 6 views and the 144-block timetable re-render automatically without manual state invalidation.

3. **High-Precision Monotonic Time Accounting**:
   - Standard Dart `Timer.periodic` is flawed for background operations: when iOS/Android backgrounds or suspends the application, timers stop ticking or skip intervals, violating AC4.
   - Using monotonic wall-clock delta calculation:
     $$\text{elapsed} = (\text{is\_running} \ ? \ (\text{now\_ms} - \text{interval\_start\_ms}) : 0) + \text{accumulated\_active\_ms}$$
     guarantees mathematical invariance regardless of thread sleep, OS throttling, or device restart.

4. **Timetable Mathematics (05:00 AM Cutoff)**:
   - High school and university students routinely study across midnight (e.g., 23:00 to 03:00). A calendar-day cutoff at 00:00 causes session fragmentation and destroys streak motivation.
   - Defining a study day $D$ from 05:00:00 to 04:59:59 (1440 minutes = 144 blocks of 10 minutes) ensures study sessions belonging to the student's natural "waking/study cycle" stay unified. Sessions crossing 05:00:00 are cleanly bisected.

5. **Strict Lock & In-Session Scratchpad Integration**:
   - Strict lock must detect app switches (AC5) via Flutter `AppLifecycleListener`. However, students need to take notes without leaving the lock.
   - The solution is an **In-Session Scratchpad Drawer**: an embedded, distraction-free split sheet running inside the lock screen's navigation context that directly reads and writes to the linked task's page block tree without triggering OS lifecycle transitions or breaking lock.

---

## 3. Caveats & Platform Boundaries

1. **Platform Differences for Strict Lock**:
   - **Android**: Supports foreground service notifications with action buttons, `AppLifecycleListener`, and optional system overlay / `UsageStatsManager` / `AccessibilityService` for hardware-level enforcement.
   - **iOS**: Apple sandbox policies forbid killing third-party apps. Strict lock on iOS relies on `WidgetsBindingObserver` detecting `AppLifecycleState.paused` / `inactive`, starting a grace-period countdown (10s), and applying session failure / interruption penalties if the user navigates away, combined with Live Activities (ActivityKit) for ongoing timer display.
   - **Desktop (Windows/macOS/Linux)**: Monitors window focus / blur via `WindowListener` (`window_manager`), displaying floating always-on-top HUD.
2. **Sensor Hardware Availability**:
   - Flip-to-Focus requires an accelerometer. On devices or desktop platforms without accelerometer hardware, the system gracefully falls back to manual "Place in Focus Mode" button without throwing runtime exceptions.
3. **WebRTC Live Study Rooms vs Audio/Presence**:
   - Desk-cam streaming requires significant uplink/downlink bandwidth. The architecture provides a tiered fallback:
     - Tier 1: Real-time Presence + Animated Lottie/Rive avatars (ultralow bandwidth, <1 KB/s).
     - Tier 2: WebRTC SFU/Mesh video stream (opt-in desk cam, capped at 360p 15fps to preserve device thermals).

---

## 4. Conclusion & Complete Technical Architecture

### 4.1 Global Architectural Paradigm

HamPA follows **Clean Architecture** separated into 4 distinct layers:
```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                       │
│  - Flutter UI Widgets (Page Tree, Block Editor, 6 DB Views) │
│  - Focus HUD, Timetable Grid Painter, Heatmap CustomPainter  │
│  - State Management: Bloc / Riverpod / Notifiers            │
└──────────────────────────────┬──────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────┐
│                       DOMAIN LAYER                          │
│  - Pure Dart Entities (Page, Block, Database, Property,     │
│    Row, Cell, FocusSession, GridSlot, Streak, RoomMember)   │
│  - Interactors & UseCases (StartSession, LogSession,        │
│    EvaluateFormula, ComputeRollup, ProjectTimetableGrid)    │
│  - Repository & Gateway Contracts (Pure Interfaces)         │
└──────────────────────────────┬──────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────┐
│                        DATA LAYER                           │
│  - Local-First Drift SQLite Database & DAOs                 │
│  - Transaction Manager (Atomic Auto-Logging & Rollups)      │
│  - Local Sync Log & Offline Mutation Queue                  │
└──────────────────────────────┬──────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────┐
│                    INFRASTRUCTURE LAYER                     │
│  - Hardware Sensors (SensorsPlus - Accelerometer)           │
│  - Monotonic Clock & Foreground Service Platform Channels   │
│  - Ambient Soundscape Multi-Track Audio Engine              │
│  - Real-Time Signaling (Supabase / WebSocket / WebRTC)      │
└─────────────────────────────────────────────────────────────┘
```

---

### 4.2 R1: Block-Based Workspace & Relational Database System (Notion Core)

#### 4.2.1 Page Tree & Hierarchical Block Data Model
- **Page Tree**: Infinite nested hierarchy.
  - Table `pages`:
    ```sql
    CREATE TABLE pages (
      id TEXT NOT NULL PRIMARY KEY,
      parent_page_id TEXT, -- NULL for root pages
      title TEXT NOT NULL,
      icon TEXT,
      cover_image_url TEXT,
      is_database_row BOOLEAN NOT NULL DEFAULT FALSE,
      is_archived BOOLEAN NOT NULL DEFAULT FALSE,
      sort_order REAL NOT NULL DEFAULT 0.0,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      FOREIGN KEY (parent_page_id) REFERENCES pages (id) ON DELETE CASCADE
    );
    CREATE INDEX idx_pages_parent ON pages(parent_page_id);
    ```
- **Modular Block Editor Model**:
  - Table `blocks`:
    ```sql
    CREATE TABLE blocks (
      id TEXT NOT NULL PRIMARY KEY,
      page_id TEXT NOT NULL,
      parent_block_id TEXT, -- NULL for top-level page blocks; non-null for toggles/nested lists
      block_type TEXT NOT NULL, -- 'text', 'heading_1', 'heading_2', 'heading_3', 'checklist', 'callout', 'toggle', 'code', 'math', 'divider', 'quote', 'database_inline'
      order_key TEXT NOT NULL, -- Fractional index (LexoRank) for O(1) reordering
      content_json TEXT NOT NULL, -- Type-specific JSON payload
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      is_archived BOOLEAN NOT NULL DEFAULT FALSE,
      FOREIGN KEY (page_id) REFERENCES pages (id) ON DELETE CASCADE,
      FOREIGN KEY (parent_block_id) REFERENCES blocks (id) ON DELETE CASCADE
    );
    CREATE INDEX idx_blocks_page_order ON blocks(page_id, order_key);
    CREATE INDEX idx_blocks_parent ON blocks(parent_block_id);
    ```
  - **Block Content Payloads (`content_json`)**:
    - `text`: `{"spans": [{"text": "Hello ", "bold": true, "italic": false, "color": null}, {"text": "world", "href": "https://..."}]}`
    - `heading_1` / `heading_2` / `heading_3`: `{"text": "Section Title", "isCollapsed": false}`
    - `checklist`: `{"text": "Complete Calculus problem set 3", "isCompleted": true, "checkedAt": 1729094400000}`
    - `callout`: `{"icon": "💡", "backgroundColor": "amber_tint", "text": "Remember integration by parts"}`
    - `toggle`: `{"title": "Detailed Proof", "isOpen": true}` (children blocks reference `parent_block_id = this.id`)
    - `code`: `{"code": "void main() {}", "language": "dart", "showLineNumbers": true}`
    - `math`: `{"latex": "\\int_{a}^{b} f(x) dx = F(b) - F(a)", "isDisplayMode": true}`
    - `database_inline`: `{"databaseId": "db-123", "defaultViewId": "view-456"}`

#### 4.2.2 Relational Database Schema & Dual Identity
- **The Dual Identity Architecture**: In HamPA, **every database row is also an underlying `Page`**. When a row is created in `database_rows`, a corresponding record in `pages` with `is_database_row = TRUE` is created transactionally. This allows clicking any row in any database view to open a complete distraction-free Notion page with sub-blocks, embedded databases, and linked scratchpads!

- **Schema Tables in Drift SQLite**:
  ```sql
  -- 1. Database Definition
  CREATE TABLE databases (
    id TEXT NOT NULL PRIMARY KEY,
    page_id TEXT NOT NULL, -- Parent page where database is hosted
    title TEXT NOT NULL,
    description TEXT,
    icon TEXT,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    FOREIGN KEY (page_id) REFERENCES pages (id) ON DELETE CASCADE
  );

  -- 2. Property Definitions (Columns)
  CREATE TABLE database_properties (
    id TEXT NOT NULL PRIMARY KEY,
    database_id TEXT NOT NULL,
    name TEXT NOT NULL,
    type TEXT NOT NULL, -- 'title', 'text', 'number', 'select', 'multi_select', 'status', 'date', 'checkbox', 'url', 'email', 'phone', 'relation', 'rollup', 'formula', 'created_time', 'last_edited_time'
    config_json TEXT NOT NULL DEFAULT '{}', 
    -- config_json stores:
    --   for select/multi_select: {"options": [{"id": "opt1", "name": "Urgent", "color": "red"}]}
    --   for status: {"groups": [{"name": "To Do", "options": [...]}, {"name": "In Progress"}, {"name": "Done"}]}
    --   for relation: {"targetDatabaseId": "db_targets", "symmetricPropertyId": "prop_rev", "isDualDirection": true}
    --   for rollup: {"relationPropertyId": "prop_rel", "targetPropertyId": "prop_time", "calculation": "sum"}
    --   for formula: {"expression": "prop('Estimated') - prop('Total Studied Time')", "returnType": "number"}
    position REAL NOT NULL,
    FOREIGN KEY (database_id) REFERENCES databases (id) ON DELETE CASCADE
  );
  CREATE INDEX idx_properties_db ON database_properties(database_id, position);

  -- 3. Database Rows
  CREATE TABLE database_rows (
    id TEXT NOT NULL PRIMARY KEY,
    database_id TEXT NOT NULL,
    page_id TEXT NOT NULL UNIQUE, -- 1:1 Dual Identity link to pages table
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    is_archived BOOLEAN NOT NULL DEFAULT FALSE,
    FOREIGN KEY (database_id) REFERENCES databases (id) ON DELETE CASCADE,
    FOREIGN KEY (page_id) REFERENCES pages (id) ON DELETE CASCADE
  );
  CREATE INDEX idx_rows_db ON database_rows(database_id);

  -- 4. Strongly-Typed Dynamic Cells
  CREATE TABLE database_cells (
    id TEXT NOT NULL PRIMARY KEY,
    row_id TEXT NOT NULL,
    property_id TEXT NOT NULL,
    text_val TEXT,
    number_val REAL,
    boolean_val BOOLEAN,
    date_val INTEGER, -- Epoch milliseconds
    json_val TEXT, -- For multi-select option IDs, structured date ranges {"start": ..., "end": ..., "includeTime": true}
    FOREIGN KEY (row_id) REFERENCES database_rows (id) ON DELETE CASCADE,
    FOREIGN KEY (property_id) REFERENCES database_properties (id) ON DELETE CASCADE,
    UNIQUE (row_id, property_id)
  );
  CREATE INDEX idx_cells_row_prop ON database_cells(row_id, property_id);
  CREATE INDEX idx_cells_number ON database_cells(property_id, number_val);
  CREATE INDEX idx_cells_date ON database_cells(property_id, date_val);

  -- 5. Foreign Relations Junction
  CREATE TABLE database_relations (
    id TEXT NOT NULL PRIMARY KEY,
    property_id TEXT NOT NULL,
    from_row_id TEXT NOT NULL,
    to_row_id TEXT NOT NULL,
    FOREIGN KEY (property_id) REFERENCES database_properties (id) ON DELETE CASCADE,
    FOREIGN KEY (from_row_id) REFERENCES database_rows (id) ON DELETE CASCADE,
    FOREIGN KEY (to_row_id) REFERENCES database_rows (id) ON DELETE CASCADE
  );
  CREATE INDEX idx_relations_from ON database_relations(from_row_id, property_id);
  CREATE INDEX idx_relations_to ON database_relations(to_row_id, property_id);

  -- 6. Unified Database Views
  CREATE TABLE database_views (
    id TEXT NOT NULL PRIMARY KEY,
    database_id TEXT NOT NULL,
    name TEXT NOT NULL,
    view_type TEXT NOT NULL, -- 'table', 'kanban', 'calendar', 'timeline', 'list', 'gallery'
    filter_tree_json TEXT NOT NULL DEFAULT '{"operator": "AND", "filters": []}',
    sort_configs_json TEXT NOT NULL DEFAULT '[]',
    group_by_property_id TEXT,
    visible_property_ids_json TEXT NOT NULL DEFAULT '[]',
    view_settings_json TEXT NOT NULL DEFAULT '{}',
    FOREIGN KEY (database_id) REFERENCES databases (id) ON DELETE CASCADE
  );
  CREATE INDEX idx_views_db ON database_views(database_id);
  ```

#### 4.2.3 The 6 Unified Database Views Architecture
All 6 views query the **same single underlying dataset** and project it into specific UI layouts:
1. **Table View**:
   - Tabular grid with sticky title column and virtualized row scrolling (`flutter_list_view` / `SliverList`).
   - Column reordering & interactive resizing.
   - Inline cell editors: popover for select/status, calendar picker for dates, toggle for checkboxes.
   - Footer Aggregations: `sum`, `average`, `min`, `max`, `count_all`, `percent_checked`, `percent_empty` calculated in real-time.
2. **Kanban View**:
   - Columns dynamically generated from the target `status` or `select` property options.
   - Supports dragging cards across columns; on drop, triggers an atomic cell update:
     `UPDATE database_cells SET text_val = ? WHERE row_id = ? AND property_id = ?`.
   - Sub-grouping & collapsible column state.
3. **Calendar View**:
   - Mapped to a user-selected `date` property (or date range `json_val`).
   - Renders 7-day or 30-day grid with Persian/Gregorian date support.
   - Multi-day items span horizontal bars across consecutive cells.
   - Drag-and-drop cards between dates updates `date_val`.
4. **Timeline / Gantt View**:
   - Mapped to `start_date` and `end_date` properties.
   - Dependency linking: Uses `database_relations` where relation property represents "Blocked By" / "Dependent On".
   - Renders SVG / Canvas connecting arrows between dependent bars.
   - Zoom scales: Day, Week, Month, Quarter.
   - Interactive bar edge drag-resizing.
5. **List View**:
   - Minimalist, high-density row list.
   - Displays icon, row title, tag chips, and right-aligned property widgets (e.g. quick status dropdown, time spent badge).
6. **Gallery View**:
   - Responsive card grid (`SliverGridDelegateWithMaxCrossAxisExtent`).
   - Configurable card preview: Page cover image, first image block in page, or attachment property.
   - Configurable card sizes (Small: 120px, Medium: 180px, Large: 240px).

#### 4.2.4 Formula & Rollup Reactive Engine
- **Formula Parser Engine**:
  - Pure Dart Lexer & Recursive Descent Parser producing an AST:
    - Binary Operators: `+`, `-`, `*`, `/`, `^`, `==`, `!=`, `<`, `>`, `<=`, `>=`.
    - Logical: `and(a, b)`, `or(a, b)`, `not(a)`.
    - Conditional: `if(condition, thenExpr, elseExpr)`.
    - Text: `concat(...)`, `contains(str, substr)`, `length(str)`, `upper(str)`, `lower(str)`.
    - Date: `now()`, `dateBetween(d1, d2, "days"|"hours"|"minutes")`, `formatDate(d, fmt)`.
    - Property Access: `prop("Property Name")`.
- **Rollup Aggregator Engine**:
  - Traverses `database_relations` for the given row.
  - Retrieves target property cells for all linked rows.
  - Applies calculation: `count_all`, `count_values`, `count_unique`, `sum`, `average`, `median`, `min`, `max`, `percent_empty`, `percent_checked`.
  - Directed Acyclic Graph (DAG) dependency tracker: updates dependent rollups whenever foreign cells change, preventing circular infinite loops.

---

### 4.3 R2: Live Focus Tracking, Pomodoro & Anti-Distraction Mechanics (YPT Core)

#### 4.3.1 Monotonic Background Stopwatch Architecture
- **Zero-Drift Invariant Formula**:
  $$\text{CurrentActiveDuration} = \text{AccumulatedDuration} + \begin{cases}
  \text{CurrentMonotonicTimestamp} - \text{IntervalStartTimestamp} & \text{if } \text{State} == \text{RUNNING} \\
  0 & \text{if } \text{State} \in \{\text{PAUSED}, \text{IDLE}\}
  \end{cases}$$
- **Drift SQLite Storage**:
  ```sql
  CREATE TABLE subjects (
    id TEXT NOT NULL PRIMARY KEY,
    name TEXT NOT NULL,
    color_hex TEXT NOT NULL, -- e.g. '#4CAF50'
    icon TEXT,
    daily_goal_minutes INTEGER NOT NULL DEFAULT 60,
    created_at INTEGER NOT NULL
  );

  CREATE TABLE focus_sessions (
    id TEXT NOT NULL PRIMARY KEY,
    subject_id TEXT NOT NULL,
    linked_entity_type TEXT, -- 'database_row' | 'block' | NULL
    linked_entity_id TEXT, -- row_id or block_id
    session_type TEXT NOT NULL, -- 'stopwatch' | 'pomodoro' | 'exam_countdown'
    start_epoch INTEGER NOT NULL,
    end_epoch INTEGER,
    target_duration_seconds INTEGER NOT NULL DEFAULT 0,
    actual_duration_seconds INTEGER NOT NULL DEFAULT 0,
    pause_count INTEGER NOT NULL DEFAULT 0,
    interruption_count INTEGER NOT NULL DEFAULT 0,
    scratchpad_notes TEXT,
    status TEXT NOT NULL, -- 'running', 'paused', 'completed', 'abandoned'
    created_at INTEGER NOT NULL,
    FOREIGN KEY (subject_id) REFERENCES subjects (id) ON DELETE CASCADE
  );
  CREATE INDEX idx_sessions_subject ON focus_sessions(subject_id);
  CREATE INDEX idx_sessions_start ON focus_sessions(start_epoch);

  CREATE TABLE focus_intervals (
    id TEXT NOT NULL PRIMARY KEY,
    session_id TEXT NOT NULL,
    start_epoch INTEGER NOT NULL,
    end_epoch INTEGER NOT NULL,
    is_break BOOLEAN NOT NULL DEFAULT FALSE,
    FOREIGN KEY (session_id) REFERENCES focus_sessions (id) ON DELETE CASCADE
  );
  CREATE INDEX idx_intervals_session ON focus_intervals(session_id);
  ```
- **Foreground Service Integration (Android)**:
  - Background Service maintains `START_STICKY` with foreground notification showing:
    - Subject name & icon.
    - Live ticking stopwatch `HH:MM:SS`.
    - Quick actions: `Pause`, `Resume`, `Finish`.
- **Pomodoro & Exam Timers**:
  - Pomodoro State Machine:
    $$\text{IDLE} \xrightarrow{\text{Start}} \text{WORK (25m)} \xrightarrow{\text{Finish}} \text{SHORT\_BREAK (5m)} \xrightarrow{\dots} \text{LONG\_BREAK (15m)}$$
  - Exam Countdown: High-stakes mock exam mode with audio chimes at 50% time elapsed, 10 minutes left, and 0 minutes left.

#### 4.3.2 Strict Lock Mode & Anti-Distraction Mechanics
- **Lifecycle Interruption Observer**:
  ```dart
  class StrictLockLifecycleObserver with WidgetsBindingObserver {
    final StrictLockController controller;
    
    @override
    void didChangeAppLifecycleState(AppLifecycleState state) {
      switch (state) {
        case AppLifecycleState.resumed:
          controller.handleAppResumed();
          break;
        case AppLifecycleState.inactive:
        case AppLifecycleState.paused:
        case AppLifecycleState.hidden:
          controller.handleAppBackgrounded();
          break;
        case AppLifecycleState.detached:
          controller.handleAppDetached();
          break;
      }
    }
  }
  ```
- **Grace-Period Countdown Engine**:
  - When the app transitions to `inactive` / `paused` during strict lock:
    1. Starts a monotonic 10-second grace timer.
    2. Records an interruption event log in memory: `{start: epoch, reason: 'app_switch'}`.
    3. If the user returns within 10s: logs minor distraction strike; session continues.
    4. If the user fails to return within 10s:
       - Level 1 (Gentle): Session pauses automatically; interruption flag set.
       - Level 2 (Strict YPT): Emits alarm sound, increments permanent strike count; reduces streak XP.
       - Level 3 (Hardcore): Forfeits current session interval and records as "abandoned".
- **Allowlist System**:
  - Allows in-app navigation only to designated white-listed routes:
    - `InSessionScratchpadDrawer` (slide-out note drawer)
    - `SoundscapeMixerSheet` (ambient audio)
    - `CalculatorModal`
  - System back navigation button and gesture navigation are intercepted via `PopScope(canPop: false)`.
- **Flip-to-Focus Sensor Engine**:
  - Subscribes to `accelerometerEventStream()`:
    - Condition for Face-Down: $Z \le -9.2 \text{ m/s}^2$ and $|X| \le 2.0$ and $|Y| \le 2.0$.
    - When detected: auto-starts session or switches active HUD into ultra-low-power OLED Black mode with a gentle ambient breathing glow.
    - When device is lifted ($Z \ge -5.0 \text{ m/s}^2$): gracefully illuminates display back to interactive HUD.
- **Multi-Track Ambient Soundscape Player**:
  - Independent simultaneous audio channels with volume controls:
    1. White Noise
    2. Gentle Rain & Distant Thunder
    3. Cafe Murmur
    4. Quiet Library
    5. Campfire Crackle
    6. 40Hz Gamma / 10Hz Alpha Binaural Focus Waves

#### 4.3.3 The 24-Hour Visual 10-Minute Timetable Grid (144 Blocks)
- **Mathematical Specification**:
  - Grid covers exactly 24 hours from 05:00:00 AM of Day $D$ to 04:59:59 AM of Day $D+1$.
  - 144 blocks total ($24 \times 6 = 144$).
  - For any given timestamp $T$:
    $$\text{MinutesSinceCutoff}(T) = (T.\text{hour} \times 60 + T.\text{minute} - 300) \pmod{1440}$$
    $$\text{BlockIndex}(T) = \lfloor \text{MinutesSinceCutoff}(T) / 10 \rfloor \in [0, 143]$$
- **Interval Projection Algorithm**:
  - Given a set of focus intervals for study day $D$:
  - For each block $i \in [0, 143]$:
    - $B_{\text{start}} = \text{StudyDayStart}(D) + i \times 10\text{ minutes}$
    - $B_{\text{end}} = B_{\text{start}} + 10\text{ minutes}$
    - For each interval $I_k \in \text{Intervals}$, calculate overlap:
      $$O(k, i) = \max\left(0, \min(I_k.\text{end}, B_{\text{end}}) - \max(I_k.\text{start}, B_{\text{start}})\right)$$
    - Dominant subject is $\operatorname{argmax}_{\text{subject}} \sum_{k \in \text{subject}} O(k, i)$.
    - Fill fraction: $\alpha_i = \min\left(1.0, \frac{\sum_k O(k, i)}{600\text{ seconds}}\right)$.
  - **CustomPainter Implementation**:
    - High-performance Skia/Impeller hardware-accelerated canvas painter rendering 144 rounded rect cells in a $24 \times 6$ or $12 \times 12$ matrix.
    - Animated live pulse on the current active block index.
    - Interactive tap gesture detector displaying popup tooltip with exact minute breakdown and subject label.

#### 4.3.4 Live Study Rooms ("Study With Me") & Social Presence
- **Tri-State Machine**:
  ```
      ┌───────────┐         Start Focus         ┌───────────────┐
      │  OFFLINE  ├────────────────────────────►│   STUDYING    │
      └─────▲─────┘                             └───────┬───────┘
            │                                           │
            │ Disconnect                         Break  │ Resume
            │ Timeout                            Pause  │ Focus
            │                                           ▼
      ┌─────┴─────┐                             ┌───────────────┐
      │   AWAY    │◄────────────────────────────┤    RESTING    │
      └───────────┘         Inactivity          └───────────────┘
  ```
- **Real-Time Signaling Protocol**:
  - Ephemeral Presence Channels via WebSocket / Supabase Realtime:
    ```json
    {
      "event": "presence_heartbeat",
      "userId": "usr_987",
      "roomId": "room_alpha",
      "state": "STUDYING",
      "subject": {"id": "sub_math", "name": "Calculus", "colorHex": "#3B82F6"},
      "sessionElapsedSeconds": 3720,
      "avatarAnimation": "reading_book",
      "hasVideoCamera": false,
      "timestamp": 1729095000000
    }
    ```
  - Presence Heartbeat: Every 15 seconds. If peer heartbeat is missing for 45s, peer is transitioned to `OFFLINE`.
  - Cheering Reactions: Sub-500ms broadcast pub/sub delivering instant peer animations:
    `{"event": "peer_reaction", "type": "FIRE", "fromUser": "Sara", "toUser": "Ali"}`.
  - Desk-Cam Video Streaming: WebRTC Mesh / SFU peer connections rendering low-frame-rate, muted live desk feeds.

---

### 4.4 R3: Hybrid Synergy & Dynamic Linking Engine (HamPA Bridge)

#### 4.4.1 "Focus Now" Dynamic Launcher
- Can be triggered from:
  1. Any `database_rows` record in any of the 6 database views (e.g., Table row action button or Kanban card icon).
  2. Any `checklist` block inside a Notion page.
- Passes a strongly typed `FocusContext`:
  ```dart
  class FocusContext {
    final String entityType; // 'database_row' | 'block'
    final String entityId;
    final String pageId;
    final String title;
    final String? subjectId;
    final int? estimatedDurationSeconds;
  }
  ```
- Launches the Focus HUD, automatically setting the active subject, pre-populating target goals, and linking session telemetry.

#### 4.4.2 Atomic Session Auto-Logging Transaction
When a focus session finishes, the following single atomic Drift SQLite transaction is executed:
```dart
Future<void> completeSessionAndAutoLog({
  required FocusSession session,
  required List<FocusInterval> intervals,
  required bool markTaskCompleted,
}) async {
  await db.transaction(() async {
    // 1. Insert completed session & intervals
    await db.focusSessionsDao.insertSession(session);
    await db.focusIntervalsDao.insertIntervals(intervals);

    // 2. If session is linked to a database row, update properties
    if (session.linkedEntityType == 'database_row' && session.linkedEntityId != null) {
      final rowId = session.linkedEntityId!;
      final row = await db.databaseRowsDao.getRowById(rowId);
      final properties = await db.databasePropertiesDao.getPropertiesForDatabase(row.databaseId);

      for (final prop in properties) {
        // Auto-update 'Total Studied Time' (number property)
        if (prop.name.toLowerCase().contains('studied time') || prop.name.toLowerCase().contains('total time')) {
          final existingCell = await db.databaseCellsDao.getCell(rowId, prop.id);
          final currentSeconds = existingCell?.numberVal ?? 0.0;
          await db.databaseCellsDao.upsertCell(
            rowId: rowId,
            propertyId: prop.id,
            numberVal: currentSeconds + session.actualDurationSeconds,
          );
        }
        // Auto-update 'Sessions Count' (number property)
        if (prop.name.toLowerCase().contains('session count') || prop.name.toLowerCase().contains('sessions')) {
          final existingCell = await db.databaseCellsDao.getCell(rowId, prop.id);
          final currentCount = existingCell?.numberVal ?? 0.0;
          await db.databaseCellsDao.upsertCell(
            rowId: rowId,
            propertyId: prop.id,
            numberVal: currentCount + 1,
          );
        }
        // Auto-update 'Last Studied Date' (date property)
        if (prop.name.toLowerCase().contains('last studied') || prop.name.toLowerCase().contains('last active')) {
          await db.databaseCellsDao.upsertCell(
            rowId: rowId,
            propertyId: prop.id,
            dateVal: session.endEpoch,
          );
        }
        // Auto-update 'Status' if marked complete
        if (markTaskCompleted && prop.type == 'status') {
          await db.databaseCellsDao.upsertCell(
            rowId: rowId,
            propertyId: prop.id,
            textVal: 'Done',
          );
        }
      }
    }

    // 3. If session is linked to a checklist block, mark isCompleted
    if (session.linkedEntityType == 'block' && session.linkedEntityId != null && markTaskCompleted) {
      final block = await db.blocksDao.getBlockById(session.linkedEntityId!);
      final content = jsonDecode(block.contentJson);
      content['isCompleted'] = true;
      content['checkedAt'] = DateTime.now().millisecondsSinceEpoch;
      await db.blocksDao.updateBlockContent(block.id, jsonEncode(content));
    }

    // 4. Invalidate / update today's 144-block timetable cache & streak engine
    await timetableProjectionService.projectAndCacheTodayGrid();
    await streakEngine.recalculateStreak();
  });
}
```

#### 4.4.3 In-Session Distraction-Free Scratchpad
- A slide-out split drawer built with `Drift` reactivity.
- When opened during strict lock:
  - Connects to the linked task's page document via `blocksDao.watchBlocksForPage(linkedPageId)`.
  - Allows taking rapid notes, typing formulas, or checking sub-tasks without triggering `AppLifecycleState.inactive` or exiting the strict lock mode.
  - All keystrokes are debounced and committed directly to SQLite.

#### 4.4.4 D-Day & Exam Countdown Coupling
- Table `d_day_targets`:
  ```sql
  CREATE TABLE d_day_targets (
    id TEXT NOT NULL PRIMARY KEY,
    title TEXT NOT NULL,
    target_date INTEGER NOT NULL, -- Exam date epoch
    subject_id TEXT NOT NULL,
    target_study_hours REAL NOT NULL,
    linked_database_id TEXT, -- Target syllabus database
    created_at INTEGER NOT NULL,
    FOREIGN KEY (subject_id) REFERENCES subjects (id) ON DELETE CASCADE,
    FOREIGN KEY (linked_database_id) REFERENCES databases (id) ON DELETE SET NULL
  );
  ```
- Metric Calculations:
  - $\text{DaysRemaining} = \lceil (\text{target\_date} - \text{now}) / 86400000 \rceil$
  - $\text{HoursCompleted} = \sum \text{actual\_duration\_seconds}(\text{subject}) / 3600$
  - $\text{RequiredDailyPace} = \frac{\max(0, \text{target\_study\_hours} - \text{HoursCompleted})}{\text{DaysRemaining}}$
  - $\text{SyllabusCompletion} = \frac{\text{Count of Done Rows in linked\_database\_id}}{\text{Total Rows in linked\_database\_id}} \times 100\%$

---

### 4.5 R4: Analytics, Heatmaps & Gamification Engine

#### 4.5.1 GitHub-Style Study Heatmap
- **Intensity Calculation**:
  - Total study hours for day $D$: $H_D = \sum \text{duration}(D) / 3600$.
  - Intensity Levels:
    - Level 0: $H_D == 0$ (Default background tint)
    - Level 1: $0 < H_D \le 2.0$ (Light tint)
    - Level 2: $2.0 < H_D \le 4.0$ (Medium tint)
    - Level 3: $4.0 < H_D \le 6.0$ (Vibrant tint)
    - Level 4: $H_D > 6.0$ (Deep intense accent)
- **Visual Matrix**:
  - Horizontal 52-week grid (7 rows $\times$ 52 columns) rendered with `CustomPainter`.
  - Full RTL & LTR support with Persian/Gregorian tooltip localization.

#### 4.5.2 05:00 AM Day-Cutoff Streak Engine
- **Study Day Assignment**:
  $$\text{StudyDay}(T) = \begin{cases}
  \text{Date}(T) - 1\text{ day} & \text{if } T.\text{hour} < 5 \\
  \text{Date}(T) & \text{if } T.\text{hour} \ge 5
  \end{cases}$$
- **Streak Evaluation Algorithm**:
  ```dart
  class StreakEngine {
    final FocusSessionsDao sessionsDao;
    final int minDailyGoalSeconds; // Default 1800 (30 mins)

    Future<StreakResult> calculateStreak() async {
      final now = DateTime.now();
      final currentStudyDay = getStudyDay(now);
      
      int currentStreak = 0;
      int bestStreak = 0;
      int runningStreak = 0;

      // Fetch study days with total active study seconds
      final Map<DateTime, int> dailyStudyTime = await sessionsDao.getAggregatedDailyStudySeconds();

      // Check if current study day has already met the goal
      final todayStudied = dailyStudyTime[currentStudyDay] ?? 0;
      final bool todayCompleted = todayStudied >= minDailyGoalSeconds;

      DateTime checkDay = todayCompleted ? currentStudyDay : currentStudyDay.subtract(const Duration(days: 1));
      
      // Calculate backwards unbroken streak
      while (true) {
        final studied = dailyStudyTime[checkDay] ?? 0;
        if (studied >= minDailyGoalSeconds) {
          currentStreak++;
          checkDay = checkDay.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }

      // Calculate historical best streak
      // (Traverse all sorted recorded study days)
      final sortedDays = dailyStudyTime.keys.toList()..sort();
      DateTime? prevDay;
      for (final day in sortedDays) {
        if ((dailyStudyTime[day] ?? 0) >= minDailyGoalSeconds) {
          if (prevDay != null && day.difference(prevDay).inDays == 1) {
            runningStreak++;
          } else {
            runningStreak = 1;
          }
          if (runningStreak > bestStreak) bestStreak = runningStreak;
          prevDay = day;
        }
      }

      return StreakResult(
        currentStreak: currentStreak,
        bestStreak: bestStreak,
        isTodayGoalMet: todayCompleted,
      );
    }
  }
  ```

#### 4.5.3 Multi-Tier Leaderboards & Privacy
- **Aggregation Dimensions**:
  - Timeframes: Daily (05:00 to 05:00), Weekly (Monday/Saturday cutoff), Monthly, All-time.
  - Scopes: Study Group, Peer Circles, National / Grade Rank.
- **Privacy Engine**:
  - `is_anonymous`: Generates pseudonymous alias (e.g. "Focus Lion #89").
  - `hide_subjects`: Hides subject details, displaying only total aggregate hours.
  - `opt_out_public`: Omits user from national rankings while keeping private group visibility.

---

### 4.6 Module Layout & Clean Architecture File Tree

```
c:\parsa\HamPA\
├── pubspec.yaml
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_constants.dart
│   │   │   └── color_palette.dart
│   │   ├── database/
│   │   │   ├── app_database.dart          # Drift SQLite database definition
│   │   │   ├── app_database.g.dart        # Generated Drift code
│   │   │   ├── daos/
│   │   │   │   ├── pages_dao.dart
│   │   │   │   ├── blocks_dao.dart
│   │   │   │   ├── databases_dao.dart
│   │   │   │   ├── database_properties_dao.dart
│   │   │   │   ├── database_rows_dao.dart
│   │   │   │   ├── database_cells_dao.dart
│   │   │   │   ├── database_views_dao.dart
│   │   │   │   ├── subjects_dao.dart
│   │   │   │   ├── focus_sessions_dao.dart
│   │   │   │   └── d_day_dao.dart
│   │   │   └── tables/                    # Modular Drift table definitions
│   │   ├── error/
│   │   │   └── failures.dart
│   │   ├── platform/
│   │   │   ├── background_service.dart    # Android foreground service & notifications
│   │   │   ├── sensor_manager.dart        # Accelerometer stream wrapper
│   │   │   └── audio_manager.dart         # Multi-track ambient soundscape player
│   │   └── utils/
│   │       ├── fractional_indexer.dart    # LexoRank algorithm for blocks/properties
│   │       ├── time_utils.dart            # 05:00 AM cutoff & study day math
│   │       └── formula_parser.dart        # AST evaluator for formulas
│   │
│   ├── features/
│   │   ├── workspace_editor/              # Notion Block Workspace
│   │   │   ├── domain/
│   │   │   │   ├── models/                # PageEntity, BlockEntity, RichTextSpan
│   │   │   │   └── repositories/          # PageRepository, BlockRepository
│   │   │   └── presentation/
│   │   │       ├── widgets/               # BlockRenderers (Text, Heading, Checklist, Callout, Toggle, Code, Math)
│   │   │       └── controllers/           # BlockEditorNotifier, PageTreeNotifier
│   │   │
│   │   ├── workspace_database/            # Notion Relational Database Engine
│   │   │   ├── domain/
│   │   │   │   ├── models/                # DatabaseEntity, PropertyEntity, RowEntity, CellEntity, ViewEntity
│   │   │   │   └── services/              # RollupCalculationEngine, FormulaEvaluationEngine
│   │   │   └── presentation/
│   │   │       ├── views/
│   │   │       │   ├── table_view.dart    # Table with inline edit & footers
│   │   │       │   ├── kanban_view.dart   # Kanban board with drag-and-drop
│   │   │       │   ├── calendar_view.dart # Monthly/weekly calendar
│   │   │       │   ├── timeline_view.dart # Gantt timeline with dependencies
│   │   │       │   ├── list_view.dart     # Minimalist list
│   │   │       │   └── gallery_view.dart  # Card grid gallery
│   │   │       └── controllers/           # DatabaseViewNotifier
│   │   │
│   │   ├── focus_engine/                  # YPT Focus Core
│   │   │   ├── domain/
│   │   │   │   ├── models/                # FocusSession, FocusInterval, Subject
│   │   │   │   └── services/              # MonotonicTimerService, PomodoroStateMachine
│   │   │   └── presentation/
│   │   │       ├── hud/                   # FocusHUD (Stopwatch, Pomodoro, Exam mode)
│   │   │       └── controllers/           # FocusSessionNotifier
│   │   │
│   │   ├── strict_lock/                   # YPT Anti-Distraction
│   │   │   ├── domain/
│   │   │   │   └── services/              # LifecycleWatcher, GracePeriodEngine, FlipSensorWatcher
│   │   │   └── presentation/
│   │   │       ├── widgets/               # LockOverlay, OLEDBlackHUD, WarningDialog
│   │   │       └── controllers/           # StrictLockNotifier
│   │   │
│   │   ├── timetable_grid/                # YPT 144-Block Visual Timetable
│   │   │   ├── domain/
│   │   │   │   ├── models/                # GridBlockState (0..143)
│   │   │   │   └── services/              # TimetableProjectionEngine
│   │   │   └── presentation/
│   │   │       ├── widgets/               # TimetableGridPainter, BlockTooltip
│   │   │       └── controllers/           # TimetableNotifier
│   │   │
│   │   ├── study_room/                    # YPT Live Study Rooms & Social
│   │   │   ├── domain/
│   │   │   │   ├── models/                # RoomMember, PresenceState, PeerReaction
│   │   │   │   └── services/              # PresenceService, WebRTCService
│   │   │   └── presentation/
│   │   │       ├── widgets/               # RoomGrid, MemberCard, CheeringOverlay
│   │   │       └── controllers/           # StudyRoomNotifier
│   │   │
│   │   ├── hybrid_bridge/                 # HamPA Dynamic Synergy Bridge
│   │   │   ├── domain/
│   │   │   │   ├── models/                # FocusContext, DDayTarget
│   │   │   │   └── services/              # AutoLoggingTransactionService, DDayEngine
│   │   │   └── presentation/
│   │   │       ├── widgets/               # FocusNowButton, InSessionScratchpadDrawer, DDayWidget
│   │   │       └── controllers/           # BridgeNotifier
│   │   │
│   │   └── analytics_gamification/        # Heatmaps & Streaks
│   │       ├── domain/
│   │       │   ├── models/                # HeatmapData, StreakResult, LeaderboardEntry
│   │       │   └── services/              # StreakEngine, LeaderboardService
│   │       └── presentation/
│   │           ├── widgets/               # AnnualHeatmapPainter, StreakBadge, LeaderboardList
│   │           └── controllers/           # AnalyticsNotifier
└── test/
    ├── unit/
    │   ├── monotonic_timer_test.dart
    │   ├── formula_parser_test.dart
    │   ├── rollup_engine_test.dart
    │   ├── timetable_projection_test.dart
    │   ├── streak_engine_test.dart
    │   └── fractional_indexer_test.dart
    ├── widget/
    │   ├── database_views_test.dart
    │   ├── block_editor_test.dart
    │   ├── timetable_grid_painter_test.dart
    │   └── focus_hud_test.dart
    └── integration/
        ├── auto_logging_transaction_test.dart
        ├── strict_lock_interruption_test.dart
        └── scratchpad_sync_test.dart
```

---

### 4.7 Key Domain Interface Contracts

#### 4.7.1 Relational Database Engine Contracts
```dart
abstract class IDatabaseEngineRepository {
  Stream<DatabaseEntity> watchDatabase(String databaseId);
  Stream<List<PropertyEntity>> watchProperties(String databaseId);
  Stream<List<RowEntity>> watchRows(String databaseId);
  Stream<List<CellEntity>> watchCells(String databaseId);
  Stream<List<ViewEntity>> watchViews(String databaseId);

  Future<void> createProperty(String databaseId, PropertyEntity property);
  Future<void> updatePropertyValue({
    required String rowId,
    required String propertyId,
    dynamic value,
  });
  Future<String> createRow(String databaseId); // Automatically creates underlying Page
  Future<void> deleteRow(String rowId);
  Future<void> createRelation({
    required String propertyId,
    required String fromRowId,
    required String toRowId,
  });
}
```

#### 4.7.2 Monotonic Focus Engine Contracts
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

#### 4.7.3 Timetable Projection Engine Contracts
```dart
abstract class ITimetableProjectionEngine {
  /// Projects focus intervals into 144 discrete 10-minute blocks for a study day (05:00 - 05:00)
  List<GridBlockState> projectIntervalsToGrid({
    required DateTime studyDay,
    required List<FocusInterval> intervals,
    required Map<String, SubjectEntity> subjectMap,
  });

  Stream<List<GridBlockState>> watchTodayGrid();
}
```

#### 4.7.4 Hybrid Bridge & Auto-Logging Contracts
```dart
abstract class IHybridBridgeService {
  /// Initiates focus tagged to a database row or block
  Future<void> launchFocusFromTask(FocusContext context);

  /// Executes atomic auto-logging transaction updating database row properties & syllabus
  Future<void> executeAutoLogTransaction({
    required FocusSession session,
    required List<FocusInterval> intervals,
    required bool markTaskCompleted,
  });

  /// In-session scratchpad stream directly bound to linked task page
  Stream<List<BlockEntity>> watchScratchpadBlocks(String pageId);
  Future<void> updateScratchpadBlock(BlockEntity block);
}
```

---

## 5. Verification Method

To independently verify this technical architecture during Phase 1–5:

1. **Drift SQLite Data Schema & Multi-View State Invariance (AC1, AC2, AC3)**:
   - Command: `flutter test test/integration/database_views_test.dart`
   - Invalidation Condition: If modifying a cell in Table View fails to emit a reactive update to Kanban View or Calendar View within 50ms, or if an offline write fails to persist across database disconnect/reconnect.

2. **Monotonic Background Stopwatch Zero-Drift (AC4)**:
   - Command: `flutter test test/unit/monotonic_timer_test.dart`
   - Invalidation Condition: If simulated sleep/pause of 1 hour produces elapsed duration $\ne 3600 \pm 0.05$ seconds.

3. **Strict Lock Interruption Detection (AC5)**:
   - Command: `flutter test test/widget/strict_lock_interruption_test.dart`
   - Invalidation Condition: If emitting `AppLifecycleState.inactive` or `paused` fails to trigger the grace period countdown or fails to increment the interruption counter.

4. **144-Block Timetable 05:00 AM Boundary Projection (AC6)**:
   - Command: `flutter test test/unit/timetable_projection_test.dart`
   - Test Scenario: Study session from 04:30 AM to 05:30 AM.
   - Assertion: Blocks 141, 142, 143 (04:30–05:00) are assigned to Day $D-1$; Blocks 0, 1, 2 (05:00–05:30) are assigned to Day $D$.

5. **Hybrid Auto-Logging & Rollup Integrity (AC8, AC9, AC10)**:
   - Command: `flutter test test/integration/auto_logging_transaction_test.dart`
   - Test Scenario: Launch "Focus Now" on a database task with 0 studied seconds. Run a 1800-second session. Complete session with `markTaskCompleted = true`.
   - Assertions:
     - Row's `Total Studied Time` becomes 1800s.
     - Row's `Sessions Count` becomes 1.
     - Row's `Status` becomes 'Done'.
     - Parent database rollup property updates reactively.
     - Streak counter increments by 1 and today's heatmap cell updates intensity to Level 1.
