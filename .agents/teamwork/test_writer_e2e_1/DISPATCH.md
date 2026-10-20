# Dispatch Assignment: E2E Test Suite Writer

- **Identity**: teamwork_preview_test_writer (E2E Test Writer)
- **Working Directory**: c:\parsa\HamPA\.agents\teamwork\test_writer_e2e_1
- **Parent Conversation ID**: 22d8faaf-eb90-463c-99a6-32a4eb94320e
- **Authoritative Request**: c:\parsa\HamPA\.agents\teamwork\ORIGINAL_REQUEST.md
- **Global Project Specification**: c:\parsa\HamPA\PROJECT.md
- **Feature Inventory & AC Mapping**: c:\parsa\HamPA\.agents\teamwork\spec_miner_survey_reqs\handoff.md

## Objective
Design and implement the E2E Testing Track for HamPA (هم‌پا):
1. Read `c:\parsa\HamPA\.agents\teamwork\ORIGINAL_REQUEST.md`, `c:\parsa\HamPA\PROJECT.md`, and `spec_miner_survey_reqs/handoff.md`.
2. Author `c:\parsa\HamPA\TEST_INFRA.md` following the template in the instructions:
   - Test philosophy (opaque-box, requirement-driven, zero coupling to internal implementation details).
   - Test architecture and runner invocation (`flutter test test/e2e/...`).
   - Feature inventory mapping to test tiers.
3. Implement test cases in `test/e2e/`:
   - **Tier 1 — Feature Coverage (≥5 per feature)**: Happy-path isolated tests for all 35 features (F01–F35) using simplest verification channels.
   - **Tier 2 — Boundary & Corner Cases (≥5 per feature)**: Limits, empty states, 05:00 AM cutoff boundary crossing, formula errors (`#CYCLE!`), OOM recovery, sensor unavailability.
   - **Tier 3 — Cross-Feature Combinations (Pairwise)**: Database task -> Focus Now -> auto-log -> rollup update -> timetable repaint -> streak update.
   - **Tier 4 — Real-World Application Scenarios (≥18 scenarios)**: Multi-hour study routines, student exam prep workflows, live room peer interactions.
4. When the test suites and infrastructure are in place, publish `c:\parsa\HamPA\TEST_READY.md`.
5. Write your complete progress into `progress.md` and deliver `handoff.md` in your working directory. Notify the parent orchestrator when complete.


## 2026-10-16T16:43:33Z
You are test_writer_e2e_1.
Working directory: c:\parsa\HamPA\.agents\teamwork\test_writer_e2e_1
Read instructions in c:\parsa\HamPA\.agents\teamwork\test_writer_e2e_1\DISPATCH.md.
Read authoritative request in c:\parsa\HamPA\.agents\teamwork\ORIGINAL_REQUEST.md.
Read project specifications in c:\parsa\HamPA\PROJECT.md.
Design test architecture in TEST_INFRA.md and author comprehensive E2E tests across Tiers 1-4.
Publish TEST_READY.md when complete.
Write progress.md as you work and deliver handoff.md in your working directory.
When done, send a message to parent orchestrator (Conversation ID: 22d8faaf-eb90-463c-99a6-32a4eb94320e).
