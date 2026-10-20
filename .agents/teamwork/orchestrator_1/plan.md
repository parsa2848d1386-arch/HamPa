# Project Plan: HamPA (هم‌پا)

## Mission
Build 'HamPA' (هم‌پا), a hybrid productivity and planner Flutter application unifying Notion's block-based workspace and relational databases with YeolPumTa's (YPT) real-time focus tracking, live study rooms, strict anti-distraction lock, 10-minute visual timetable, and gamified analytics.

## Phase 0: Survey & Environment Assessment (Parallel Swarm)
- **Explorer 1 (`explorer_survey_env`)**: Inspect workspace, Flutter/Dart SDK, toolchain capabilities, dependencies, desktop/mobile/web platform targets, and build/test runner viability.
- **Explorer 2 (`explorer_survey_arch`)**: Investigate architectural patterns for Flutter local-first SQLite/Drift, hierarchical block editors, multi-view relational databases, monotonic background timers, and lock mode.
- **Spec Miner (`spec_miner_survey_reqs`)**: Extract exhaustive feature inventory from `ORIGINAL_REQUEST.md`, cataloging R1, R2, R3, R4, acceptance criteria, and edge cases into structured items.

## Phase 1: Global Architecture & Scope Formulation (`PROJECT.md`)
- Merge survey reports into `PROJECT.md` at project root.
- Document Feature Inventory with explicit milestone mappings.
- Define cross-module Interface Contracts (Workspace DB, Focus Engine, Hybrid Bridge, Analytics).
- Define Code Layout following Flutter clean architecture.

## Phase 2: Dual Track Launch
- **Track 1: E2E Testing Track**:
  - Test harness, runners, and mocks.
  - Tier 1: Feature coverage (≥5 tests per feature).
  - Tier 2: Boundary & corner cases.
  - Tier 3: Cross-feature combinations.
  - Tier 4: Real-world application scenarios.
  - Publish `TEST_READY.md`.
- **Track 2: Implementation Track**:
  - Milestone 1: Local-first Drift SQLite storage, Data Models & Notion Block Workspace Core.
  - Milestone 2: Relational Database Engine with 6 Views (Table, Kanban, Calendar, Timeline, List, Gallery) & Property Schema.
  - Milestone 3: YPT Focus Engine, Monotonic Background Stopwatch, Pomodoro, Exam Timer & Strict Lock.
  - Milestone 4: 24-hour Visual 10-minute Timetable Grid & Real-time Live Study Rooms.
  - Milestone 5: HamPA Hybrid Bridge ("Focus Now" from DB row/block, Session auto-logging, In-session Scratchpad, D-Day Countdown).
  - Milestone 6: Analytics, Annual/Monthly Heatmaps, 05:00 AM Streak Engine & Group Leaderboards.

## Phase 3: Milestone Execution Loop (Strict Gating)
- Each milestone executes:
  1. Explorer(s) recommend implementation plan.
  2. Worker implements and runs tests.
  3. Reviewers (2) review code and verify test execution.
  4. Challengers (2) empirically stress-test.
  5. Forensic Auditor verifies authentic implementation (binary veto).
  6. Gate evaluation: Pass -> Next milestone; Fail -> Loop back with audit report.

## Phase 4: Final Milestone & Adversarial Hardening
- Pass 100% of E2E Test Suite (Tiers 1-4).
- Phase 2: Adversarial Coverage Hardening (Tier 5 white-box challenger loop).

## Phase 5: Project Sign-Off
- Full verification against all 10 Acceptance Criteria.
- Human-facing summary report and Sentinel handoff.
