# Technical Exploration & Quality Audit Report: R2 (Milestones 3 & 4)
**HamPA (هم‌پا) Focus Engine, 24-Hour Timetable & Live Study Rooms**

- **Author**: `explorer_r2`
- **Working Directory**: `c:\parsa\HamPA\.agents\teamwork\explorer_r2\`
- **Date**: 2026-10-17T12:15:00Z
- **Target Milestones**: Milestone 3 (YPT Focus Engine & Strict Lock) & Milestone 4 (24-Hour Timetable & Live Study Rooms)
- **Status Summary**: `flutter analyze` passes with 0 issues (304.3s). Unit tests in `test/unit/m2_m3_combined_test.dart` pass 5/5. However, deep architectural inspection reveals significant divergence between production UI/Cubit code and the authoritative requirements in `ORIGINAL_REQUEST.md` and `PROJECT.md`, where critical mechanics (sensor listener, audio playback, CustomPainter pulsing, lifecycle observer) exist only as harness mocks in `test/e2e/harness/` rather than in production features.

---

## 1. Executive Summary

| Subsystem / Feature | Required Specification (`PROJECT.md` F17–F28) | Production State (`lib/features/`) | Quality & Gap Assessment |
|---|---|---|---|
| **F17: Monotonic Background Stopwatch** | Drift-free monotonic delta: `elapsed = (now - start) - total_paused` | Implemented in `FocusTimerCubit` (`focus_timer_cubit.dart:123`) using `DateTime.now()` | ⚠️ **Wall-Clock Vulnerability**: Uses `DateTime.now()` instead of monotonic `Stopwatch`. Pause start is in-memory only and lost on process restart. |
| **F18: Customizable Pomodoro Cycles** | Configurable work/break intervals with audio chimes & cycle tracking | Hardcoded 1500s default in `FocusSessionState` / `FocusTimerCubit:34` | ⚠️ **Missing Break Engine**: Does not alternate work and break intervals; no audio chimes or cycle counter. |
| **F19: Mock Exam Countdown Timers** | Standardized simulation timer with section breakdowns & alert chimes | Generic countdown in `FocusTimerCubit:128-137`; `TimerMode.exam` | ❌ **Missing Sections & Alerts**: No multi-section schema, no section transition chimes, no exam presets. |
| **F20: Strict Lock & Interruption Log** | `WidgetsBindingObserver` detecting background switches, 10s grace, logging | Boolean toggle `isStrictLockActive` in `FocusTimerCubit:73-75` | ❌ **Missing Lifecycle Observer**: No `WidgetsBindingObserver`, no 10s grace period, no interruption duration/count tracking. |
| **F21: Reference Allowlist** | Permitted in-app tools (Scratchpad, Calculator, Ambient sound) | Scratchpad button in `FocusTimerView:65-71` | ⚠️ **Partial**: UI button exists for scratchpad; no allowlist config, package checker, or calculator tool. |
| **F22: Flip-to-Focus Sensor** | Accelerometer sensor detection ($Z \le -9.2\text{ m/s}^2$) with OLED black mode | Black background in `FocusTimerView:34`; `sensors_plus` in `pubspec.yaml` | ❌ **No Hardware Listener**: `sensors_plus` is imported 0 times in `lib/`. Exists only in `test_focus_harness.dart`. |
| **F23: Multi-Track Ambient Soundscapes** | Offline mixer (Rain, White Noise, Cafe, Library, Waves) with volume sliders | Single boolean toggle `toggleAmbientSound` in `FocusTimerCubit:77-83` | ❌ **No Audio Playback**: `audioplayers` is imported 0 times in `lib/`. No multi-track volume slider mixer. |
| **F24: 24-Hour 10-Minute Timetable Grid** | 144 blocks mapping 05:00 AM–05:00 AM study day to color-coded subjects | `TimetableState` with 144 blocks (`timetable_state.dart`) | ⚠️ **Projection Edge-Case**: `start.difference(dayCutoff)` clamps negative pre-05:00 AM times to slot 0; hardcoded 2026-01-01 base date. |
| **F25: Real-Time Block Painting & Pulse** | `CustomPainter` dynamically painting & pulsing active 10-minute block | Rendered via `ListView.builder` of 144 `Container` widgets | ❌ **CustomPainter Missing**: Uses 144 widget boxes; pulsing animation is completely unimplemented. |
| **F26: Live Study Rooms Presence** | Tri-state presence (`STUDYING`, `RESTING`, `OFFLINE`) <500ms sync | `LiveStudyRoomState` & `LiveStudyRoomView` | ⚠️ **In-Memory Mock Only**: `web_socket_channel` imported 0 times in `lib/`. No real-time backend synchronization. |
| **F27: Animated Avatars & Desk Cam** | State-driven vector avatars (Rive/Lottie) or low-latency camera tile | Renders letter avatar `CircleAvatar` (`peer.displayName[0]`) | ❌ **Static Avatar Only**: `lottie` imported 0 times in `lib/`. No animated vector states or camera preview. |
| **F28: Groups, Quotas, Cheering** | Peer study quotas, group leaderboards, instant emoji cheering | `withCheer(peerId)` increments integer counter | ⚠️ **No Rate Limiting / Animation**: No token bucket rate limiter in production; no floating emoji animations. |

---

## 2. In-Depth Component Analysis

### 2.1 Focus Engine (Milestone 3)

#### 2.1.1 Timing Computation & Monotonicity
- **Code Reference**: `lib/features/focus_timer/presentation/controllers/focus_timer_cubit.dart:120-141`
```dart
void _startTicker() {
  _ticker?.cancel();
  _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
    if (state.startTime == null || !state.isRunning) return;

    // Monotonic Delta Formula: elapsed = (now - start) - total_paused
    final now = DateTime.now();
    final totalDelta = now.difference(state.startTime!).inSeconds;
    final currentElapsed = (totalDelta - state.pauseAccumulatedSeconds).clamp(0, 86400 * 7);
...
```
- **Finding**:
  1. The formula `currentElapsed = (totalDelta - state.pauseAccumulatedSeconds)` correctly computes time difference without relying on accumulating ticker ticks.
  2. However, `DateTime.now()` is tied to the system clock. If the system time jumps backward (NTP sync or manual clock adjustment), `totalDelta` decreases or becomes negative. Dart's standard `Stopwatch` uses the OS monotonic high-resolution clock and should back `_ticker` or be sampled alongside `DateTime.now()`.
  3. `_pauseStartTime` is an ephemeral in-memory field (`DateTime? _pauseStartTime;` line 11). If the app process is terminated while paused, resuming on restart cannot compute `now.difference(_pauseStartTime!)`.
  4. In `completeSession()` (`focus_timer_cubit.dart:86-111`), if the user completes a session while in `TimerStatus.paused`, the elapsed time in the ongoing pause is never added to `pauseAccumulatedSeconds` before persisting to SQLite.

#### 2.1.2 Pomodoro & Exam Countdowns
- **Code Reference**: `focus_timer_cubit.dart:128-137`
```dart
if (state.mode == TimerMode.pomodoro || state.mode == TimerMode.exam) {
  if (currentElapsed >= state.targetSeconds) {
    emit(state.copyWith(
      elapsedSeconds: state.targetSeconds,
      status: TimerStatus.completed,
    ));
    completeSession();
    return;
  }
}
```
- **Finding**:
  1. No Pomodoro cycle transition: When work duration (1500s) completes, it unconditionally calls `completeSession()` and stops. There is no automated transition to short break (300s) or long break (900s), nor tracking of completed cycles (e.g. 4 pomodoros).
  2. No exam section breakdown: Mock exams in real life (SAT, GRE, Konkur) require section timing (e.g. Verbal 35m, Quant 35m). The current engine only handles a single scalar `targetSeconds`.

#### 2.1.3 Strict Lock & Hardware Sensors
- **Code Reference**: `lib/features/focus_timer/presentation/widgets/focus_timer_view.dart:34, 49-56`
- **Finding**:
  1. Strict lock is represented solely by `isStrictLockActive: bool`, which toggles the scaffold background to `Colors.black` and shows a red lock icon.
  2. There is no `WidgetsBindingObserver` implementation. When the user leaves HamPA, Android `onPause`/`onStop` or iOS lifecycle changes are undetected.
  3. The 10-second grace period and interruption logging (`interruptionCount`, `interruptionDurationSeconds`) exist solely in `test/e2e/harness/test_focus_harness.dart` and are completely absent from `FocusTimerCubit`.
  4. Accelerometer sensor detection ($Z \le -9.2\text{ m/s}^2$) is not integrated. `sensors_plus` is present in `pubspec.yaml` but never imported in `lib/`.

#### 2.1.4 Multi-Track Ambient Soundscapes
- **Code Reference**: `focus_timer_cubit.dart:77-83`, `focus_timer_view.dart:57-64`
- **Finding**:
  1. The code contains only:
     ```dart
     void toggleAmbientSound(String? trackName) {
       if (state.isAmbientSoundPlaying && state.activeSoundTrack == trackName) {
         emit(state.copyWith(isAmbientSoundPlaying: false, activeSoundTrack: null));
       } else {
         emit(state.copyWith(isAmbientSoundPlaying: true, activeSoundTrack: trackName ?? 'White Noise'));
       }
     }
     ```
  2. `audioplayers` is not imported anywhere in `lib/`.
  3. No multi-track mixing capability: The user cannot play Rain at 70% volume while simultaneously playing Cafe at 30% volume.

---

### 2.2 Timetable & Live Study Rooms (Milestone 4)

#### 2.2.1 24-Hour 10-Minute Timetable Grid & Cutoff Math
- **Code Reference**: `lib/features/timetable/domain/models/timetable_state.dart:18-21, 50-69`
```dart
DateTime get blockStartTime {
  // Base day starts at 05:00 AM
  return DateTime(2026, 1, 1, 5, 0).add(Duration(minutes: index * 10));
}
...
TimetableState withSession({
  required String subjectId,
  required String subjectName,
  required Color color,
  required DateTime start,
  required int durationSeconds,
}) {
  final dayCutoff = DateTime(date.year, date.month, date.day, 5, 0);
  final diffMinutes = start.difference(dayCutoff).inMinutes;
  final startIndex = (diffMinutes ~/ 10).clamp(0, 143);
  final blockSpan = ((durationSeconds / 60) / 10).ceil().clamp(1, 144 - startIndex);
```
- **Finding**:
  1. **Hardcoded Block Date**: `blockStartTime` hardcodes `DateTime(2026, 1, 1, 5, 0)`. It should use the parent `TimetableState.date`.
  2. **Pre-05:00 AM Edge Case**: If a session starts at 02:00 AM on `date`, `start.difference(dayCutoff).inMinutes` is negative (-180 minutes). `(-18).clamp(0, 143)` results in `0`. This mistakenly paints slot 0 (05:00 AM) instead of mapping to the previous study day or wrapping modulo 144.
  3. **Binary Fill & Minute Distortion**: `((durationSeconds / 60) / 10).ceil()` causes any session >= 1 second to occupy a full 10-minute block and records `minutesStudied: 10`.

#### 2.2.2 Timetable UI: Missing CustomPainter & Pulsing
- **Code Reference**: `lib/features/timetable/presentation/widgets/visual_timetable_widget.dart:38-89`
- **Finding**:
  1. Rendered using a `ListView.builder` of 24 rows, with each row containing 6 `Container` widgets inside `Row` and `Expanded`.
  2. This creates 144 widget elements with borders and gesture detectors.
  3. `CustomPainter` is completely missing. Pulsing the active 10-minute block is not implemented (no `AnimationController`, no pulse glow).
  4. Unconstrained height risk: If `VisualTimetableWidget` is placed inside a scrollable column without an explicit height or `SizedBox`, the `Expanded` wrapping `ListView.builder` will throw an unbounded vertical viewport error.

#### 2.2.3 Live Study Rooms & Social Presence
- **Code Reference**: `lib/features/live_rooms/presentation/widgets/live_study_room_view.dart:35-116`
- **Finding**:
  1. `LiveStudyRoomView` renders a static `GridView.builder` of study cards.
  2. Avatar is a static `CircleAvatar` displaying `peer.displayName[0]`. No Rive or Lottie vector animation is rendered for studying/resting states.
  3. No network integration: `web_socket_channel` is not imported. All presence data is local-only.
  4. Peer cheering is an unthrottled integer counter increment without animations or rate-limiting.

---

## 3. Test Suite Audit & Forensic Analysis

### 3.1 Verification Commands and Results
1. **Static Analysis**:
   - Command: `& C:\flutter\bin\flutter.bat analyze`
   - Result: `No issues found! (ran in 304.3s)` (0 errors, 0 warnings, 0 lints).
2. **Unit Tests**:
   - Command: `& C:\flutter\bin\flutter.bat test test/unit/m2_m3_combined_test.dart`
   - Result: `00:00 +5: All tests passed!` (5/5 passing).
3. **E2E Test Runner**:
   - Command: `& C:\flutter\bin\cache\dart-sdk\bin\dart.exe run test/e2e/run_all_e2e.dart`
   - Result: 403 tests executed, with failures identified in async execution.

### 3.2 Forensic Flaws in E2E Test Infrastructure
1. **Async Test Runner Concurrency Bug**:
   In `test/e2e/support/test_runner.dart:20-39`:
   ```dart
   void test(String description, dynamic Function() body) {
     _totalTests++;
     ...
     final result = body();
     if (result is Future) {
       result.then((_) { _passedTests++; }).catchError(...);
     }
   }
   ```
   Because `body()` is not awaited sequentially by the runner, all 403 tests fire concurrently! Tests that share `late` fixture variables (like `late TestLiveStudyRoomEngine rooms;`) suffer from race conditions because subsequent tests invoke `setUp()` and reassign `rooms` while earlier tests are still running.
2. **Broadcast Stream Timing**:
   In `test/e2e/harness/test_study_room_harness.dart:23-27`, `watchRoomMembers` adds events synchronously to a broadcast stream before the caller can listen with `.first`. In concurrent execution, this causes `firstWhere` to receive subsequent test emissions instead of its own, throwing `Bad state: No element`.
3. **Mock vs Production Separation**:
   The E2E tests in `test/e2e/tier1_feature_coverage/` test the classes in `test/e2e/harness/` (`TestFocusEngine`, `TestTimetableEngine`, `TestLiveStudyRoomEngine`), NOT the actual production widgets and cubits in `lib/features/focus_timer/`, `lib/features/timetable/`, and `lib/features/live_rooms/`.

---

## 4. Architectural & Production Action Plan

To bring R2 to global production market standards without regressions:

1. **Focus Engine Hardening**:
   - Implement `Stopwatch` / monotonic ticker backing in `FocusTimerCubit` to prevent wall-clock tampering or daylight saving jumps.
   - Implement `WidgetsBindingObserver` in `FocusTimerView` / service to track app backgrounding, start a 10s grace period timer, and log `interruptionsCount` and `interruptionDurationSeconds`.
   - Wire `sensors_plus` stream (`accelerometerEventStream()`) with debounce window (1500ms) to detect $Z \le -9.2\text{ m/s}^2$ and trigger auto-pause / auto-resume.
   - Wire `audioplayers` with multi-track mixer service allowing simultaneous volume control for Rain, White Noise, Cafe, Library, and Waves.

2. **Timetable CustomPainter**:
   - Replace the 144 `Container` widgets in `VisualTimetableWidget` with a dedicated `TimetableCustomPainter`.
   - Add an `AnimationController` to smoothly pulse the current active 10-minute slot with subject glow.
   - Fix 05:00 AM cutoff math in `TimetableState` to handle pre-cutoff hours (00:00–04:59) mapping to slots 114–143.

3. **Live Study Rooms Real-Time Stream**:
   - Implement WebSocket / SSE presence stream service.
   - Add state-driven animated avatar widget (Lottie/Rive reading vs resting).
   - Add token-bucket rate limiter (5 cheers / 10s) and floating emoji overlay.

4. **Test Harness Concurrency Fix**:
   - Refactor `test_runner.dart` to await async test cases sequentially so fixture states do not contaminate concurrent tests.
