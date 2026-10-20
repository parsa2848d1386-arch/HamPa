# Forensic Quality Audit & Technical Exploration: R3 Synergy Bridge & Analytics Engine (Milestones 5 & 6)

**Auditor:** explorer_r3  
**Working Directory:** `c:\parsa\HamPA\.agents\teamwork\explorer_r3\`  
**Target Scope:** HamPA Synergy Bridge (M5) & Analytics / Gamification Engine (M6)  
**Date:** 2026-10-17  
**Static Analysis Status:** `flutter analyze` 0 issues (clean)  
**Unit Test Suite Status:** `test/unit/` 100/100 passed (clean)  

---

## 1. Executive Summary

A comprehensive code exploration and forensic quality audit of **Milestone 5 (HamPA Synergy Bridge)** and **Milestone 6 (Analytics, Heatmaps & Gamification Engine)** was conducted across production source code (`lib/features/synergy_bridge/`, `lib/features/analytics_gamification/`), core database layer (`lib/core/database/`), presentation widgets, and test suites (`test/unit/`, `test/widget/`, `test/e2e/`).

### Core Findings Matrix

| Component | Target Requirement | Implementation Status | Quality Assessment & Critical Findings |
|---|---|---|---|
| **"Focus Now" Launcher** | Task-to-timer invocation tagged with row/block context launching HUD | Partial (`SynergyBridgeService`) | **Major Gap:** `taskTitle` accepted but discarded; timer mode hardcoded to 25m Pomodoro; HUD does not render task title/context; `SynergyBridgeService` takes `BuildContext`. |
| **Session Auto-Logging** | Atomic update of `Total Studied Time`, `Sessions Count`, `Last Studied Date`, `Status` | Incomplete (`syncSessionToTaskDatabase`) | **Critical Flaw:** No DB transaction (`db.transaction`); only updates time property (ignores count, last date, status); unit mismatch (writes minutes string instead of seconds); never automatically invoked on session completion. |
| **In-Session Scratchpad** | Distraction-free drawer writing directly to linked page blocks in SQLite | Mock UI Only (`InSessionScratchpadDrawer`) | **Critical Gap:** Pure dummy `TextField` with `onSave` callback; does not write to Drift SQLite page blocks; does not link to `pageId`; no block entity support (checklists, KaTeX, code); no flush buffer. |
| **D-Day & Syllabus Countdown** | Countdown widget coupled with exam targets and syllabus checklist rollups | 100% Missing in `lib/` | **Critical Defect:** `DDayEntity` and syllabus calculation exist ONLY in test harnesses (`test/e2e/`); 0 lines of code in production `lib/features/synergy_bridge/`. |
| **05:00 AM Streak Engine** | Streak calculation preserving night-owl sessions before 05:00 AM | Partial (`StreakEngine`) | **Edge-Case Bugs:** `DateTime.subtract(Duration(days: 1))` suffers from Daylight Saving Time (DST) hour drift; does not compute `longestStreak`; hardcodes cutoff hour (not configurable); disconnected from `StudySessionsDao`. |
| **Study Heatmap Grid** | 4-tier intensity GitHub-style study heatmap with CustomPainter (annual & monthly) | Flawed (`StudyHeatmapWidget`) | **Performance & Spec Violation:** Implemented with 112 nested `Container`/`Row`/`Column` widgets instead of `CustomPainter`; fixed to 16 weeks (no annual or monthly views); threshold mismatch with test contracts. |
| **Multi-Tier Leaderboards** | National, group, and peer leaderboards with Anonymized Mode toggle | 100% Missing in `lib/` | **Critical Defect:** Completely absent from `lib/features/analytics_gamification/`; exists only in `test/e2e/harness/test_analytics_harness.dart`. |
| **Test Coverage & E2E** | Rigorous verification across unit, widget, and E2E suites | Disconnected & Flawed Runner | **Testing Gap:** 0 unit/widget tests for R3 in `test/unit/` or `test/widget/`; E2E tests test in-memory mock harness engines rather than `lib/`; custom `test_runner.dart` has async race conditions causing test collisions in `run_all_e2e.dart`. |

---

## 2. In-Depth Technical Audit: Milestone 5 (Synergy Bridge)

### 2.1 "Focus Now" Launcher Action (`F29`)

#### Code Location
`lib/features/synergy_bridge/services/synergy_bridge_service.dart:24-38`
```dart
  void launchFocusForTask({
    required BuildContext context,
    required String databaseId,
    required String rowId,
    required String subjectId,
    required String taskTitle,
  }) {
    final timerCubit = context.read<FocusTimerCubit>();
    timerCubit.startTimer(
      subjectId: subjectId,
      pageId: rowId,
      mode: TimerMode.pomodoro,
      targetSeconds: 1500, // 25-minute Pomodoro
    );
  }
```

#### Deficiencies & Risks
1. **Discarded Parameter (`taskTitle`):** The method signature takes `required String taskTitle`, but `taskTitle` is never passed to `timerCubit.startTimer(...)`. In fact, `FocusTimerCubit.startTimer` (`lib/features/focus_timer/presentation/controllers/focus_timer_cubit.dart:16-38`) does not even accept a `taskTitle` or `FocusContext` parameter!
2. **Hardcoded Mode and Duration:** The method forces `TimerMode.pomodoro` and `targetSeconds: 1500`. Users initiating focus from a long-duration task, a mock exam row, or a continuous stopwatch task are forced into an unconfigurable 25-minute Pomodoro.
3. **UI Coupling (`BuildContext`):** Service-layer classes in Clean Architecture should not accept `BuildContext` or invoke `context.read<FocusTimerCubit>()`. `FocusTimerCubit` (or a repository/service facade) should be injected via constructor.
4. **Missing HUD Display:** In `lib/features/focus_timer/presentation/widgets/focus_timer_view.dart:38-47`, the app bar title displays only static strings: `'Pomodoro Focus'`, `'Exam Countdown'`, or `'Stopwatch'`. The linked task title or row name is nowhere to be found in the HUD.
5. **No Checklist Block Support:** Requirement R3 and test `F29-3` specify launching focus from an interactive checklist block within a regular document page. `launchFocusForTask` requires `databaseId` and `rowId`, failing to support document block contexts (`pageId` + `blockId`).

---

### 2.2 Atomic Session Auto-Logging to DB Rows (`F30`)

#### Code Location
`lib/features/synergy_bridge/services/synergy_bridge_service.dart:41-62`
```dart
  Future<void> syncSessionToTaskDatabase({
    required String databaseId,
    required String rowId,
    required int addedSeconds,
  }) async {
    final properties = await propertiesDao.getPropertiesForDatabase(databaseId);
    final timeProp = properties.where((p) => p.name.toLowerCase().contains('time') || p.name.toLowerCase().contains('study')).firstOrNull;

    if (timeProp != null) {
      final currentCells = await cellsDao.getCellsForRow(rowId);
      final existingCell = currentCells.where((c) => c.propertyId == timeProp.id).firstOrNull;

      final existingMinutes = existingCell?.valueJson != null ? (double.tryParse(existingCell!.valueJson!) ?? 0.0) : 0.0;
      final newTotalMinutes = existingMinutes + (addedSeconds / 60.0);

      await cellsDao.upsertCell(
        rowId: rowId,
        propertyId: timeProp.id,
        valueJson: newTotalMinutes.toStringAsFixed(1),
      );
    }
  }
```

#### Deficiencies & Risks
1. **Lack of Database Transaction Atomicity:** Despite the specification requiring an *atomic transaction*, the operations (`getPropertiesForDatabase`, `getCellsForRow`, `upsertCell`) are separate async calls without an enclosing SQLite transaction (`db.transaction(...)`).
2. **Missing Properties (Sessions Count, Last Studied Date, Status):** The method only looks for a single property matching `'time'` or `'study'`. It completely ignores:
   - `Sessions Count` (should increment by 1).
   - `Last Studied Date` (should record today's date formatted as `YYYY-MM-DD`).
   - `Status` / `Progress` (marking as `'Done'` when `markTaskCompleted == true`).
3. **Unit Inconsistency:** `addedSeconds` is converted to minutes and stored as a formatted string: `newTotalMinutes.toStringAsFixed(1)`. However, the rest of the database engine (including formulas, rollups, and E2E contracts in `test_hybrid_bridge_harness.dart:66`) expects numeric elapsed seconds (`num`).
4. **Fragile Cell Value Parsing:** `double.tryParse(existingCell!.valueJson!)` assumes raw unescaped number strings. If `valueJson` contains structured JSON (e.g., `{"value": 1800}`) or formatted cell data, `double.tryParse` returns `null` and silently resets the accumulator to `0.0`, destroying historical study time.
5. **No Automatic Event Triggering:** In `FocusTimerCubit.completeSession()` (`lib/features/focus_timer/presentation/controllers/focus_timer_cubit.dart:86-111`), the session is written to `StudySessionsTable`, but `syncSessionToTaskDatabase` is **never called**. `FocusTimerCubit` has no reference to `SynergyBridgeService`. Auto-logging is completely disconnected.

---

### 2.3 In-Session Scratchpad Drawer (`F31`)

#### Code Location
`lib/features/synergy_bridge/presentation/widgets/in_session_scratchpad_drawer.dart:1-80`
```dart
class InSessionScratchpadDrawer extends StatefulWidget {
  final String? initialText;
  final ValueChanged<String>? onSave;
...
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  expands: true,
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(
                    hintText: '- Key formulas to memorize...\n- Questions to ask instructor...',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) => widget.onSave?.call(val),
                ),
              ),
```

#### Deficiencies & Risks
1. **No Block-Based Architecture:** The scratchpad is a simple single-line/multiline `TextField`. It has no support for Notion block entities (checklists, bullet items, KaTeX math equations, code snippets) as required by R3/AC9 and verified in E2E tests (`F31-2`, `F31-B3`, `F31-B4`).
2. **No Persistence to Drift SQLite:** The widget only calls `onSave?.call(val)`. It has no connection to `BlocksDao` or `WorkspaceRepository`.
3. **No Buffer or Flush Mechanism:** Contract `IHybridBridgeService` defines:
   - `Stream<List<BlockEntity>> watchScratchpadBlocks(String pageId);`
   - `Future<void> updateScratchpadBlock(BlockEntity block);`
   - `Future<void> flushScratchpadToDocument(String pageId);`
   None of these methods exist in `lib/features/synergy_bridge/`. Edits in the drawer evaporate if the app is killed or if the focus session finishes without manual copying.
4. **Disconnected from Focus HUD:** In `FocusTimerView` (`lib/features/focus_timer/presentation/widgets/focus_timer_view.dart:65-70`), `onOpenScratchpad` is an optional callback that is nowhere bound to a `Scaffold.endDrawer` in the application tree.

---

### 2.4 D-Day & Exam Syllabus Countdown (`F32`)

#### Code Location
`lib/features/synergy_bridge/` (File missing)

#### Deficiencies & Risks
1. **Completely Absent from Production Code:**
   - No `DDayEntity` in `lib/features/synergy_bridge/domain/models/`.
   - No `DDayWidget` or `CountdownWidget` in `lib/features/synergy_bridge/presentation/widgets/`.
   - No syllabus progress calculation (`calculateSyllabusProgress`) in `lib/features/synergy_bridge/services/`.
2. **Entity Only Exists in Test Directory:** `DDayEntity` is defined in `test/e2e/contracts/hybrid_bridge_contracts.dart:7-35`. In `test_hybrid_bridge_harness.dart:148-151`, `calculateSyllabusProgress` simply returns hardcoded `100.0`.
3. **Missing Rolled-up Calculation:** Syllabus progress should compute the percentage of checklist/task rows marked with `status == 'Done'` or `checked == true` in the linked database.

---

## 3. In-Depth Technical Audit: Milestone 6 (Analytics & Gamification Engine)

### 3.1 05:00 AM Day-Cutoff Streak Engine (`F34`)

#### Code Location
`lib/features/analytics_gamification/domain/models/streak_engine.dart:21-61`
```dart
class StreakEngine {
  static int calculateStreak(List<DateTime> studySessionDates, {DateTime? currentNow}) {
    if (studySessionDates.isEmpty) return 0;

    final now = currentNow ?? DateTime.now();
    final normalizedDates = studySessionDates.map(_normalizeToLogicalDate).toSet().toList()
      ..sort((a, b) => b.compareTo(a));

    if (normalizedDates.isEmpty) return 0;

    final todayNormalized = _normalizeToLogicalDate(now);
    final yesterdayNormalized = todayNormalized.subtract(const Duration(days: 1));

    if (!normalizedDates.contains(todayNormalized) && !normalizedDates.contains(yesterdayNormalized)) {
      return 0;
    }

    int streak = 0;
    DateTime checkDate = normalizedDates.contains(todayNormalized) ? todayNormalized : yesterdayNormalized;

    while (normalizedDates.contains(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  static DateTime _normalizeToLogicalDate(DateTime dt) {
    if (dt.hour < 5) {
      final prev = dt.subtract(const Duration(days: 1));
      return DateTime(prev.year, prev.month, prev.day);
    }
    return DateTime(dt.year, dt.month, dt.day);
  }
}
```

#### Deficiencies & Risks
1. **Daylight Saving Time (DST) Bug:**
   `checkDate = checkDate.subtract(const Duration(days: 1));`
   `Duration(days: 1)` subtracts exactly 24 hours (86,400 seconds). On local `DateTime` instances during DST transitions (e.g., 23-hour or 25-hour days):
   - Subtracting 24 hours shifts the timestamp from `00:00:00` to `23:00:00` or `01:00:00`.
   - `_normalizeToLogicalDate` constructs `DateTime(year, month, day)` which has hour `0`.
   - `normalizedDates.contains(checkDate)` fails because `DateTime(y, m, d, 23, 0) != DateTime(y, m, d, 0, 0)`.
   - **Remedy:** Use calendar arithmetic: `DateTime(checkDate.year, checkDate.month, checkDate.day - 1)`.
2. **Incomplete Output Structure (`StreakResult`):**
   `StreakEngine.calculateStreak` returns a single `int`. It does NOT return `longestStreak`, `lastStudyDate`, or `isFrozen`, violating `PROJECT.md` line 149 and `IStreakEngine`.
3. **Hardcoded Cutoff Hour:**
   `if (dt.hour < 5)` is hardcoded. It does not accept a configurable `int cutoffHour = 5` parameter (tested in boundary test `F34-B1`).
4. **No SQLite DAO Integration:**
   `StreakEngine` does not provide a query or stream connected to `StudySessionsDao` to automatically load timestamps from persisted study sessions.

---

### 3.2 4-Tier Intensity GitHub-Style Study Heatmap (`F33`)

#### Code Location
`lib/features/analytics_gamification/presentation/widgets/study_heatmap_widget.dart:30-97`
```dart
    const weeksCount = 16;
    final totalDays = weeksCount * 7;
    final startDay = today.subtract(Duration(days: totalDays - 1));
...
            SizedBox(
              height: 110,
              child: Row(
                children: List.generate(weeksCount, (weekIdx) {
                  return Expanded(
                    child: Column(
                      children: List.generate(7, (dayIdx) {
                        final currentDay = startDay.add(Duration(days: (weekIdx * 7) + dayIdx));
                        final dateKey = DateTime(currentDay.year, currentDay.month, currentDay.day);
                        final minutes = minutesByDate[dateKey] ?? 0;
                        final level = HeatmapDayEntry.computeIntensity(minutes);

                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.all(1.5),
                            decoration: BoxDecoration(
                              color: _colorForLevel(level, theme),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                }),
              ),
            ),
```

#### Deficiencies & Risks
1. **Violation of Architectural Spec (Missing `CustomPainter`):**
   Requirement F33 explicitly mandates:
   *"GitHub-Style Study Heatmaps: Annual & monthly 4-level contribution heatmaps with CustomPainter."*
   The current implementation uses 16 `Row` columns with 7 `Column` rows of `Container` widgets. For an annual heatmap (52 weeks = 365 cells), rendering 365+ nested layout widgets creates significant layout passes and rebuild overhead. A `CustomPainter` draws directly to the `Canvas` with zero widget tree overhead.
2. **No Annual View / Monthly View Toggle:**
   The widget is hardcoded to `const weeksCount = 16;`. It lacks:
   - Annual View (52 weeks / 365 days).
   - Monthly View (4–5 weeks / 30 days).
   - View switcher toggle tab bar.
3. **Threshold Discrepancy:**
   In `HeatmapDayEntry.computeIntensity` (`streak_engine.dart:12-18`):
   - `< 60m` -> 1
   - `< 180m` (3h) -> 2
   - `< 300m` (5h) -> 3
   - `>= 300m` -> 4
   In `test/e2e/contracts/analytics_contracts.dart:15-21`:
   - `< 3600s` (1h) -> 1
   - `< 7200s` (2h) -> 2
   - `< 14400s` (4h) -> 3
   - `>= 14400s` (4h+) -> 4
   The thresholds differ between 1h/2h/4h and 1h/3h/5h.
4. **Missing UI Affordances:**
   No month labels (Jan, Feb, Mar, etc.) across the top, no weekday abbreviations (M, W, F), and no tap tooltip showing the date and duration.

---

### 3.3 Multi-Tier Leaderboards & Privacy Controls (`F35`)

#### Code Location
`lib/features/analytics_gamification/` (Files missing)

#### Deficiencies & Risks
1. **Completely Absent from Production Code:**
   - No `LeaderboardEntry` model in `lib/features/analytics_gamification/domain/models/`.
   - No `LeaderboardService` in `lib/features/analytics_gamification/services/`.
   - No `LeaderboardWidget` or `LeaderboardView` in `lib/features/analytics_gamification/presentation/widgets/`.
2. **Missing Multi-Tier Scopes:**
   Requirement F35 requires National, Group, and Peer tiers.
3. **Missing Anonymized Mode Toggle:**
   The feature requires masking usernames to `Anonymous #<4-digit hash>` and subject titles to `General Study`. While implemented in test harness `test_analytics_harness.dart:117-140`, it has zero implementation in production code.

---

## 4. Test Suite Audit & Forensic Analysis

### 4.1 Unit & Widget Test Gaps
1. **Zero Unit Tests for R3:**
   Inspecting `test/unit/`:
   - `adversarial_m1_stress_test.dart` (M1 Page Tree)
   - `database_engine_test.dart` (M2 Relational DB)
   - `drift_database_test.dart` (M1/M2 SQLite DAOs)
   - `formula_engine_test.dart` (M2 Formula Engine)
   - `fractional_indexer_test.dart` (M1 LexoRank)
   - `m2_m3_combined_test.dart` (M2/M3 combined)
   - `page_tree_utils_test.dart` (M1 Page Tree)
   There are **zero unit tests** for `SynergyBridgeService`, `InSessionScratchpadDrawer`, `StreakEngine`, or `StudyHeatmapWidget`.
2. **Zero Widget Tests for R3:**
   Inspecting `test/widget/`:
   - `block_editor_adversarial_test.dart`
   - `block_editor_deep_challenge_test.dart`
   - `block_editor_test.dart`
   - `database_views_test.dart`
   - `page_tree_test.dart`
   There are **zero widget tests** for `InSessionScratchpadDrawer`, `StudyHeatmapWidget`, or `FocusTimerView`.

### 4.2 Disconnection Between E2E Suite and Production Code
In `test/e2e/tier1_feature_coverage/f29_f32_hybrid_bridge_test.dart` and `f33_f35_analytics_gamification_test.dart`:
- The tests instantiate `TestHybridBridgeEngine` and `TestAnalyticsStreakEngine` from `test/e2e/harness/`.
- They do **not** instantiate or test `SynergyBridgeService`, `InSessionScratchpadDrawer`, or `StreakEngine` from `lib/`.
- Therefore, even if the E2E harness passes, the actual production code in `lib/` remains unverified by automated tests.

### 4.3 Custom Test Runner Asynchrony Bug
In `test/e2e/support/test_runner.dart:20-40`:
```dart
void test(String description, dynamic Function() body) {
  _totalTests++;
  final testName = _currentGroup.isEmpty ? description : '$_currentGroup > $description';
  try {
    final result = body();
    if (result is Future) {
      // Async test runner handles future synchronously in queue or awaitable
      result.then((_) {
        _passedTests++;
      }).catchError((err, st) {
        _failedTests++;
        _failureMessages.add('FAILED: $testName\nError: $err\nStack: $st');
      });
    } else {
      _passedTests++;
    }
  } catch (err, st) {
...
```
When running `test/e2e/run_all_e2e.dart`:
- All 403 test cases are launched in rapid succession without awaiting `Future` returns.
- Multiple async tests simultaneously mutate singleton/shared test harness instances.
- For example:
  - `F29-1` failed with `Expected equals row_101, but got: null` because another test cleared the active session concurrently.
  - `F29-3` failed with `Expected equals block_todo_42, but got: t_stream` because test `F29-5` ran concurrently.
  - `F30-B3` failed with `Expected equals 100000, but got: 300` because another auto-logging test ran concurrently.
- `run_all_e2e.dart` waits only 100ms before summarizing, resulting in race conditions and false negative failures.

---

## 5. Architectural Remediation Plan (Milestones 5 & 6)

### 5.1 Synergy Bridge Remediation
1. **Refactor `SynergyBridgeService`:**
   - Remove `BuildContext` dependency.
   - Inject `AppDatabase`, `DatabaseRowsDao`, `DatabaseCellsDao`, `DatabasePropertiesDao`, and `FocusTimerCubit`.
   - Implement `launchFocusFromTask({required FocusContext context, TimerMode mode = TimerMode.stopwatch, int? targetSeconds})`.
   - Update `FocusTimerCubit` to accept `FocusContext` in `startTimer`, preserve it in `FocusSessionState`, and display the linked task title in `FocusTimerView`.
2. **Implement True Atomic Auto-Logging:**
   - In `executeAutoLogTransaction`, wrap cell reads and upserts inside `appDatabase.transaction(() async { ... })`.
   - Simultaneously update:
     * `Total Studied Time` (accumulating seconds).
     * `Sessions Count` (incrementing integer).
     * `Last Studied Date` (setting `YYYY-MM-DD`).
     * `Status` / `Progress` (if `markTaskCompleted == true`, set to `'Done'`).
   - Wire `FocusTimerCubit.completeSession` to automatically call `executeAutoLogTransaction` whenever `activePageId` is non-null.
3. **Block-Based In-Session Scratchpad:**
   - Connect `InSessionScratchpadDrawer` to `BlocksDao` via `watchScratchpadBlocks(pageId)` and `updateScratchpadBlock(block)`.
   - Provide an in-memory draft buffer during lock mode and a `flushScratchpadToDocument(pageId)` trigger upon session completion.
4. **Implement D-Day & Exam Syllabus Module:**
   - Create `lib/features/synergy_bridge/domain/models/dday_entity.dart`.
   - Create `lib/features/synergy_bridge/services/syllabus_progress_calculator.dart` that calculates task completion percentage across linked database rows.
   - Create `lib/features/synergy_bridge/presentation/widgets/dday_countdown_widget.dart`.

### 5.2 Analytics & Gamification Engine Remediation
1. **Harden `StreakEngine`:**
   - Fix calendar date arithmetic to `DateTime(dt.year, dt.month, dt.day - 1)` to eliminate DST hour drift.
   - Return structured `StreakResult` with `currentStreak`, `longestStreak`, and `lastStudyDate`.
   - Support configurable `int cutoffHour = 5`.
   - Add reactive stream method `watchStreak(StudySessionsDao dao, {int cutoffHour = 5})`.
2. **Build High-Performance `CustomPainter` Study Heatmap:**
   - Implement `StudyHeatmapPainter extends CustomPainter` rendering cells, grid lines, and level colors directly on the canvas.
   - Add view mode toggle: `HeatmapViewMode.annual` (52 weeks / 365 days) and `HeatmapViewMode.monthly` (5 weeks / 35 days).
   - Add tooltips and month/weekday header rendering.
3. **Implement Multi-Tier Leaderboards:**
   - Create `lib/features/analytics_gamification/domain/models/leaderboard_entry.dart`.
   - Implement `LeaderboardService` supporting National, Group, and Peer tiers with sorting and ranking.
   - Implement Anonymized Mode toggle masking usernames (`Anonymous #<4-digit hash>`) and subject titles (`General Study`).
   - Create `LeaderboardView` widget with tier tabs and privacy switch.

### 5.3 Test Suite Remediation
1. Create `test/unit/synergy_bridge_test.dart` and `test/unit/analytics_gamification_test.dart` to directly test `lib/` implementations.
2. Fix `test/e2e/support/test_runner.dart` to queue async tests sequentially using an async execution queue, ensuring zero race conditions during test runs.

---

## 6. Audit Conclusion
The core workspace (M1) and relational database (M2) remain solid and pass static analysis with 0 issues and 100/100 unit tests passing. However, **Milestones 5 & 6 (R3)** currently contain significant gaps:
- The production implementations in `lib/features/synergy_bridge/` and `lib/features/analytics_gamification/` are skeletal prototypes rather than market-ready production engines.
- D-Day, syllabus countdown, and multi-tier leaderboards are completely missing from `lib/`.
- Auto-logging lacks atomicity, omits essential properties, and is disconnected from session completion.
- The heatmap violates the `CustomPainter` specification and lacks annual/monthly switching.
- E2E tests were testing standalone mock harnesses rather than production code, and the custom E2E runner suffered from async race collisions.

Full remediation of these points will bring R3 to 100% production readiness.
