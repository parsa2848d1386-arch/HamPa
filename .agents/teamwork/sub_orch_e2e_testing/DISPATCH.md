# Dispatch Assignment: E2E Testing Track Orchestrator

- **Identity**: teamwork_preview_orchestrator (E2E Testing Track Orchestrator)
- **Working Directory**: c:\parsa\HamPA\.agents\teamwork\sub_orch_e2e_testing
- **Parent Conversation ID**: 22d8faaf-eb90-463c-99a6-32a4eb94320e
- **Authoritative Request**: c:\parsa\HamPA\.agents\teamwork\ORIGINAL_REQUEST.md
- **Global Project Specification**: c:\parsa\HamPA\PROJECT.md

## Scope & Mission
You are the **E2E Testing Track Orchestrator** for HamPA (هم‌پا).
Your responsibility is to design and implement the comprehensive, opaque-box, requirement-driven E2E test suite covering all 35 features (F01–F35) and all 10 acceptance criteria (AC1–AC10) from `ORIGINAL_REQUEST.md` and `PROJECT.md`.

### Methodology & Structure
Follow the Project Pattern Dual Track methodology:
1. **Test Infrastructure**:
   - Create `TEST_INFRA.md` at `c:\parsa\HamPA\TEST_INFRA.md`.
   - Setup test runners, harnesses, mocks, and execution commands.
2. **Tier 1 — Feature Coverage (≥5 tests per feature)**:
   - Happy-path tests for each of the 35 features in isolation using simplest verification channel.
   - Target: ≥175 test cases.
3. **Tier 2 — Boundary & Corner Cases (≥5 tests per feature)**:
   - Limits, empty inputs, max-size inputs, zero/negative durations, 05:00 AM cutoff boundary crossing, formula division by zero / cycles, sensor disconnects, OOM resume.
   - Target: ≥175 test cases.
4. **Tier 3 — Cross-Feature Combinations (Pairwise Coverage)**:
   - Feature interactions sharing state (e.g. Focus Now from DB row -> session completes -> auto-log -> rollup update -> 144 grid repaint -> streak calculation).
   - Target: ≥35 test cases.
5. **Tier 4 — Real-World Application Scenarios**:
   - Realistic multi-hour student study workflows: full mock exam session, midnight study session across 05:00 AM, study room session with peer cheering, database project planning with Gantt dependencies and checklist milestones.
   - Target: ≥18 application-level scenarios.
6. **Publication of Readiness**:
   - When the test suite across all 4 tiers is fully designed, implemented, and runnable, publish `TEST_READY.md` at `c:\parsa\HamPA\TEST_READY.md` following the template in the instructions.
7. **Execution**:
   - As an orchestrator, delegate test writing to `teamwork_preview_test_writer` or `teamwork_preview_worker`, review via `teamwork_preview_reviewer`, and verify integrity via `teamwork_preview_auditor`.
   - Deliver regular progress updates and report back to your parent when `TEST_READY.md` is published.
