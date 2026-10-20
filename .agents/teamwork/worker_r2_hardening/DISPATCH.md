## 2026-10-17T12:35:33Z
You are worker_r2_hardening. Your assigned working directory is:
c:\parsa\HamPA\.agents\teamwork\worker_r2_hardening\

Your parent orchestrator conversation ID is: ff24b38c-9d77-46b1-966c-5c422adeaa83
Communicate your completion back to your parent using send_message.

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

MANDATORY: You MUST read the following authoritative requirements and context files first:
- c:\parsa\HamPA\ORIGINAL_REQUEST.md
- c:\parsa\HamPA\PROJECT.md
- c:\parsa\HamPA\.agents\teamwork\explorer_r2\report_r2.md
- c:\parsa\HamPA\.agents\teamwork\explorer_r2\handoff.md
- test/e2e/harness/test_focus_harness.dart
- test/e2e/harness/test_timetable_harness.dart

FILE WRITE OWNERSHIP:
You EXCLUSIVELY own:
- lib/features/focus_timer/ (all files)
- lib/features/timetable/ (all files)
- lib/features/live_rooms/ (all files)
Do NOT modify any files outside this ownership!

Tasks:
1. Harden Focus Timer (`lib/features/focus_timer/`):
   - In `FocusTimerCubit` / `FocusSessionState`:
     - Implement monotonic delta timing (`Stopwatch` / epoch difference with robust pause accumulation).
     - Implement `WidgetsBindingObserver` for Strict Anti-Distraction Lock: detect when the app lifecycle transitions away from `resumed` (to `paused`/`inactive`/`hidden`), manage a 10-second grace timer. If the grace period expires while strict lock is active, log an interruption event and increment `interruptionCount`.
     - Update `startTimer` and `FocusSessionState` to support `taskTitle`, `databaseId`, `rowId`, `subjectName`. Display the task title and subject in `FocusTimerView` when present.
   - Implement `AmbientSoundscapePlayer` in `lib/features/focus_timer/presentation/controllers/ambient_soundscape_player.dart` supporting multi-track volume mixing (Rain, White Noise, Cafe, Library, Waves).
   - Implement `FlipToFocusDetector` with an accelerometer listener / fallback ($Z \le -9.2\text{ m/s}^2$).
2. Refactor Timetable Grid (`lib/features/timetable/`):
   - Replace the 144 `Container` widget tree in `VisualTimetableWidget` with a high-performance `CustomPainter` (`TimetablePainter`) that paints the 144 10-minute slots (05:00 AM to 05:00 AM next day) with subject color coding, border grid, and an active pulsing slot animation using `AnimationController`.
3. Verify:
   - Run `flutter analyze` to ensure 0 errors, 0 warnings, 0 lints.
   - Run `flutter test test/unit/m2_m3_combined_test.dart`.
4. Document all changes in `changes.md` and write `handoff.md` in your working directory.
When complete, notify your parent via send_message.
