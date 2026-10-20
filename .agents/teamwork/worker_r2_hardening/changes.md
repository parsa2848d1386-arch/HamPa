# Changes Document: R2 Focus Engine & Timetable Hardening

**Author**: `worker_r2_hardening`
**Date**: 2026-10-17T12:48:00Z
**Milestone**: R2 Hardening (Focus Engine, Anti-Distraction, Timetable CustomPainter)

---

## 1. Summary of Changes

### 1.1 `lib/features/focus_timer/domain/models/focus_session_state.dart`
- **Fields Added**:
  - `taskTitle` (`String?`): Name of the associated database task.
  - `databaseId` (`String?`): ID of parent database.
  - `rowId` (`String?`): ID of database row representing this study task.
  - `subjectName` (`String?`): Human-readable subject title.
  - `interruptionCount` (`int`, default: 0): Total count of distractions logged.
  - `interruptionDurationSeconds` (`int`, default: 0): Total cumulative seconds spent outside the application after grace expiry.
  - `isGracePeriodActive` (`bool`, default: false): Indicates whether the 10-second countdown is actively ticking.
  - `graceRemainingSeconds` (`int`, default: 0): Remaining seconds before an interruption is formally logged.
- **Methods Updated**:
  - Updated constructor with default values preserving backwards compatibility.
  - Updated `copyWith` with all new fields.

### 1.2 `lib/features/focus_timer/presentation/controllers/focus_timer_cubit.dart`
- **Monotonic Delta Timing**:
  - Incorporated high-resolution `Stopwatch` (`_stopwatch`) running alongside epoch timestamps.
  - Accurate pause accumulation in `resumeTimer` and during `completeSession` if session ends while paused.
- **Strict Anti-Distraction Lock & Lifecycle Observer**:
  - Added `WidgetsBindingObserver` integration.
  - Implemented `didChangeAppLifecycleState` and `handleLifecycleTransition`.
  - On transition away from `resumed` (`paused`/`inactive`/`hidden`), launches a 10-second countdown grace timer.
  - If user fails to return before grace timer expires, increments `interruptionCount` and begins tracking `interruptionDurationSeconds`.
  - On returning to `resumed`, cancels grace timer (avoiding penalty if returned within 10s) or records outage duration.
- **Task Metadata Support**:
  - Updated `startTimer()` signature with optional `taskTitle`, `databaseId`, `rowId`, `subjectName`.
  - Automatically resolves subject names from IDs if not provided.

### 1.3 `lib/features/focus_timer/presentation/widgets/focus_timer_view.dart`
- Added dynamic task title display and subject badge above the circular timer.
- Added active 10-second grace countdown alert banner when user is in warning state.
- Added interruption badge displaying distraction counts and total distraction duration.
- Wrapped content in `SingleChildScrollView` to prevent layout overflow constraints.

### 1.4 `lib/features/focus_timer/presentation/controllers/ambient_soundscape_player.dart` (New File)
- Implemented multi-track volume mixer supporting 5 ambient tracks: Rain, White Noise, Cafe, Library, and Waves.
- Supports individual track volume adjustment (0.0 to 1.0), simultaneous concurrent playback, looping, and master `stopAll`.
- Includes graceful platform exception handling for test/desktop headless runners.

### 1.5 `lib/features/focus_timer/presentation/controllers/flip_to_focus_detector.dart` (New File)
- Implemented accelerometer sensor listener using `sensors_plus`.
- Detects face-down orientation ($Z \le -9.2\text{ m/s}^2$).
- Enforces 1500ms debounce window to eliminate jitter.
- Provides `handleSensorValues` for headless testing and programmatic simulation.

### 1.6 `lib/features/timetable/domain/models/timetable_state.dart`
- Refactored `withSession` and added `timeToSlotIndex` helper to handle the 05:00 AM cutoff accurately, preventing negative clamp errors for sessions between 00:00 and 04:59.
- Added `fillRatio`, `isPulsing`, and `copyWith` to `TimetableBlock`.

### 1.7 `lib/features/timetable/presentation/widgets/visual_timetable_widget.dart`
- Replaced the 144 `Container` widget tree with `TimetablePainter` (`CustomPainter`).
- Efficiently renders the 24 hour rows and 6 10-minute columns (144 blocks total).
- Added `AnimationController` with repeating reverse pulse animation for active slot glow.
- Added precise coordinate mapping in `GestureDetector.onTapUp` to trigger `onBlockTap(block)`.

---

## 2. Verification Results
- `flutter analyze`: **0 errors, 0 warnings, 0 lints** (ran in 11.2s).
- `flutter test test/unit/m2_m3_combined_test.dart`: **5/5 tests passed** (00:00 +5).
- `flutter test test/unit/`: **100/100 tests passed** (00:08 +100).
