# Changes Log - worker_r3_hardening

## Summary of Changes

### 1. Synergy Bridge (`lib/features/synergy_bridge/`)
- **`lib/features/synergy_bridge/domain/models/dday_entity.dart`** (New File):
  - Created `DDayEntity` with `id`, `title`, `targetDate`, `linkedDatabaseId`, `linkedPropertyId`.
  - Implemented `daysRemaining({DateTime? referenceDate})` computing clean calendar difference.
  - Implemented `formatDDay({DateTime? referenceDate})` returning `'D-Day'` for 0, `'D-X'` for positive days, and `'D+X'` for past milestones.
  - Implemented `copyWith` helper.

- **`lib/features/synergy_bridge/presentation/widgets/dday_countdown_widget.dart`** (New File):
  - Created `DDayCountdownWidget` displaying milestone title, formatted countdown badge with color coding (urgent red for D-Day, warning orange for <=7 days, primary for regular), and target date.
  - Integrated optional `syllabusProgress` percentage with a themed `LinearProgressIndicator` (green when 100%+).

- **`lib/features/synergy_bridge/services/synergy_bridge_service.dart`** (Updated):
  - Updated `launchFocusForTask` to accept and preserve `taskTitle`, `databaseId`, `rowId`, `subjectId`, `mode`, and `targetSeconds`.
  - Stored active context in fields with public getters: `activeTaskTitle`, `activeDatabaseId`, `activeRowId`, `activeSubjectId`.
  - Refactored `syncSessionToTaskDatabase` into a single atomic SQLite transaction using `appDatabase.transaction(() async { ... })`.
  - Implemented updates for:
    - `Total Studied Time`: finds or creates property, accumulates elapsed seconds numerically.
    - `Sessions Count`: finds or creates property, increments integer count by 1.
    - `Last Studied Date`: finds or creates property, records today's date formatted as `YYYY-MM-DD`.
    - `Status`: updates to `'Done'` when `markTaskCompleted == true`.
  - Implemented `calculateSyllabusProgress(databaseId)` computing percentage of completed/done/checked tasks across database rows (returns 100.0 for empty databases).
  - Implemented `createDDay` helper.

- **`lib/features/synergy_bridge/presentation/widgets/in_session_scratchpad_drawer.dart`** (Updated):
  - Wired to `BlocksDao` for the linked `pageId`.
  - Reads existing blocks for `pageId` on initialization and populates editor without blocking focus.
  - Implemented in-memory buffering and debounced background flushing to SQLite as paragraph/text blocks.
  - Added public `flush()` method for manual commit.
  - Handled `isDisposing` in `dispose()` to persist pending buffer without calling `setState` during teardown.
  - Fixed `Row` layout inside header with `Expanded` and `Flexible` to prevent `RenderFlex` overflow on narrow viewports.

---

### 2. Analytics & Gamification Engine (`lib/features/analytics_gamification/`)
- **`lib/features/analytics_gamification/domain/models/streak_result.dart`** (New File):
  - Created `StreakResult` model containing `currentStreak`, `longestStreak`, `lastStudyDate`, and `isFrozen`.

- **`lib/features/analytics_gamification/domain/models/streak_engine.dart`** (Updated):
  - Fixed the DST bug: replaced `DateTime.subtract(const Duration(days: 1))` with calendar day calculation `DateTime(d.year, d.month, d.day - 1)`.
  - Preserved 05:00 AM day cutoff (sessions before 05:00 AM credited to preceding calendar day).
  - Implemented dual computation for both `currentStreak` and `longestStreak`, returning full `StreakResult`.
  - Added configurable `cutoffHour = 5`.
  - Updated `HeatmapDayEntry.computeIntensity(int minutes)` with 4 discrete levels:
    - Level 0: 0m (empty)
    - Level 1: 1–29m
    - Level 2: 30–59m
    - Level 3: 60–119m
    - Level 4: 120m+

- **`lib/features/analytics_gamification/presentation/widgets/study_heatmap_widget.dart`** (Updated):
  - Refactored away from nested containers to high-performance `CustomPainter` (`HeatmapPainter`).
  - `HeatmapPainter` paints 7-day rows across weeks directly onto canvas with rounded cells and configurable spacing.
  - Added view mode toggle between Annual (52 weeks) and Monthly (5 weeks) view modes via `SegmentedButton`.
  - Added streak counter display, cutoff info, and color legend.

- **`lib/features/analytics_gamification/domain/models/leaderboard_entry.dart`** (New File):
  - Created `LeaderboardTier` enum (`national`, `group`, `peer`).
  - Created `LeaderboardEntry` with `rank`, `userId`, `displayName`, `totalSeconds`, `isAnonymous`, `subjectName`, `tier`, `formattedDuration`.

- **`lib/features/analytics_gamification/services/leaderboard_service.dart`** (New File):
  - Created `LeaderboardService` sorting users descending by `totalSeconds` and generating ranked lists.
  - Implemented Anonymized Mode masking `displayName` to `'Anonymous #<4-digit hash>'` and `subjectName` to `'General Study'`.
  - Supported per-user `isAnonymous` override.

- **`lib/features/analytics_gamification/presentation/widgets/leaderboard_view.dart`** (New File):
  - Created `LeaderboardView` widget with `TabBar` for Multi-Tier support (National, Group, Peer).
  - Added interactive Anonymized Mode switch toggle.
  - Rendered top 3 medal badges (🥇, 🥈, 🥉) and formatted study durations.

---

### 3. Tests (`test/unit/`)
- **`test/unit/synergy_bridge_test.dart`** (New File, 7 tests):
  - Focus launch and context preservation tests.
  - Atomic session auto-logging tests (accumulating total time, sessions count, last date, status).
  - Syllabus progress calculation tests (empty database, partial completion, 100% completion).
  - D-Day entity and countdown widget tests.
  - In-session scratchpad debounced SQLite persistence widget tests.

- **`test/unit/analytics_engine_test.dart`** (New File, 13 tests):
  - Streak calculation for continuous sessions and night-owl sessions (05:00 AM cutoff).
  - DST transition calendar arithmetic verification.
  - Gap day streak breaking and longest streak preservation.
  - Keeping streak alive from yesterday.
  - Custom cutoff hour configuration.
  - 4-level heatmap intensity thresholds.
  - Heatmap widget rendering with `CustomPainter` and Annual/Monthly toggle.
  - Leaderboard sorting, ranking, multi-tier tabs, and anonymized privacy masking.
