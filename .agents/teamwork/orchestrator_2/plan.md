# Master Orchestration Plan: HamPA Gen 2

## Phase 1: Milestone 2 Finalization & Gate Sign-off
- [ ] 1.1 Dispatch `worker_m2_2` to author comprehensive unit & widget tests for M2 (`database_engine_test.dart`, `formula_engine_test.dart`, `database_views_test.dart`), run `flutter analyze` and `flutter test`, and confirm all pass.
- [ ] 1.2 Dispatch Verification Swarm for Milestone 2:
  - `reviewer_m2_1`: Schema, DAOs, Relations, Rollups, Dual Identity.
  - `reviewer_m2_2`: 6 Views UI, Formula AST & `#CYCLE!` detection.
  - `challenger_m2_1`: Formula engine adversarial testing, cyclic dependencies, formula stress.
  - `challenger_m2_2`: 6 Views interaction, drag-and-drop, filter/sort edge cases.
  - `auditor_m2_1`: Forensic integrity verification (no cheating, real SQLite).
- [ ] 1.3 Gate Evaluation in `GATE_STATUS.md` and sign-off M2.

## Phase 2: Milestone 3 — YPT Focus Engine, Stopwatch & Strict Lock
- [ ] 2.1 Dispatch `worker_m3_1` to implement monotonic stopwatch, Pomodoro, Flip-to-Focus accelerometer sensor, strict app lock with white/blacklist, and session storage.
- [ ] 2.2 Dispatch Verification Swarm (`reviewer_m3_1`, `reviewer_m3_2`, `challenger_m3_1`, `challenger_m3_2`, `auditor_m3_1`).
- [ ] 2.3 Gate Evaluation and sign-off M3.

## Phase 3: Milestone 4 — 10-Minute Timetable Grid & Live Study Rooms
- [ ] 3.1 Dispatch `worker_m4_1` to implement 24-hour visual 10-minute timetable grid (144 blocks, 05:00 AM - 05:00 AM boundary) and Live Study Rooms ("Study With Me") with tri-state presence (Studying, Rest, Idle), live avatars, and real-time reactions.
- [ ] 3.2 Dispatch Verification Swarm (`reviewer_m4_1`, `reviewer_m4_2`, `challenger_m4_1`, `challenger_m4_2`, `auditor_m4_1`).
- [ ] 3.3 Gate Evaluation and sign-off M4.

## Phase 4: Milestone 5 — HamPA Synergy Bridge: Focus-to-Task & Scratchpad
- [ ] 4.1 Dispatch `worker_m5_1` to implement "Focus Now" button on any database row / checklist block, Session auto-logging directly into database cells, In-session scratchpad drawer, and D-Day target countdown widget.
- [ ] 4.2 Dispatch Verification Swarm (`reviewer_m5_1`, `reviewer_m5_2`, `challenger_m5_1`, `challenger_m5_2`, `auditor_m5_1`).
- [ ] 4.3 Gate Evaluation and sign-off M5.

## Phase 5: Milestone 6 — Analytics, Heatmap & Streak Engine
- [ ] 6.1 Dispatch `worker_m6_1` to implement GitHub-style yearly/monthly activity heatmap, streak calculation with strict 05:00 AM cutoff, distribution charts, and leaderboards.
- [ ] 6.2 Dispatch Verification Swarm (`reviewer_m6_1`, `reviewer_m6_2`, `challenger_m6_1`, `challenger_m6_2`, `auditor_m6_1`).
- [ ] 6.3 Gate Evaluation and sign-off M6.

## Phase 6: Milestone 7 — E2E Suite Certification (403 Tests) & Adversarial Hardening
- [ ] 7.1 Dispatch worker to execute and pass all 403 E2E tests in `test/e2e/` (Tiers 1–4).
- [ ] 7.2 Dispatch challengers for Tier 5 adversarial hardening and stress tests.
- [ ] 7.3 Final forensic audit across entire codebase.
- [ ] 7.4 Compile final project handoff report to Sentinel.
