# Plan — Orchestrator Gen 3 (HamPA Verification & Forensic Audit)

## Objective
Execute comprehensive quality assurance, stress testing, and forensic audit of "HamPA" (هم‌پا) across all 6 core milestones using Flutter, ensuring global market production standards (zero analyzer issues, 100% test pass rate across unit, widget, and E2E suites).

## Phases & Steps
- [ ] **Phase 1: Exploratory Audit & Baseline Verification**
  - Explorer 1: Workspace & Relational Database Quality Audit (R1: M1 & M2, Base-36 LexoRank, cyclic protection, Block Editor renderers, 6 views, formula AST parser & cycle/div0 resilience).
  - Explorer 2: Focus Engine, Timetable & Study Rooms Audit (R2: M3 & M4, monotonic stopwatch, Pomodoro, anti-distraction strict lock, ambient audio, 144-block timetable with 05:00 AM cutoff, live study rooms tri-state presence & cheering).
  - Explorer 3: Synergy Bridge & Analytics Engine Audit (R3: M5 & M6, task-to-timer focus invocation, session auto-log to DB rows, in-session scratchpad drawer, 05:00 AM streak engine, 4-tier heatmap).
  - Worker 1: Run baseline static analysis (`flutter analyze`), unit test suite (`flutter test test/unit/`), widget test suite (`flutter test test/widget/`), and E2E suite (`flutter test test/e2e/e2e_suite_test.dart`), reporting exact counts, exit codes, and any failures.

- [ ] **Phase 2: Remediation & Hardening (if any defects found)**
  - Worker: Apply fixes to any failing tests, analyzer lints, or unhandled exceptions.
  - Reviewer: Verify that fixes adhere strictly to clean architecture and do not break existing milestones.

- [ ] **Phase 3: Adversarial Review & Challenger Stress Testing**
  - Reviewer 1 & 2: Review all 6 milestones against AC1–AC10, verifying data integrity and transition consistency.
  - Challenger 1 & 2: Generate stress tests and empirical edge-case verification for concurrency, rapid view switching, 05:00 AM day boundary bisection, sensor noise, and offline sync.

- [ ] **Phase 4: Forensic Audit & Integrity Verification**
  - Forensic Auditor (`teamwork_preview_auditor`): Static analysis, runtime tracing, and logic validation to confirm 100% authentic implementations with zero cheating, dummy facades, or hardcoded test returns.

- [ ] **Phase 5: Final Synthesis & Project Completion Sign-Off**
  - Synthesize all reports and test logs into comprehensive documentation.
  - Confirm acceptance criteria:
    - `flutter analyze` passes with 0 errors, 0 warnings, 0 lints.
    - 100% pass rate on test/unit/.
    - 100% pass rate on test/widget/.
    - 100% pass rate on test/e2e/.
    - World-class market readiness.
  - Report project completion to Sentinel.
