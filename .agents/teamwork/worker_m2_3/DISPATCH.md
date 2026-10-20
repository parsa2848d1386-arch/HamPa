# Task Assignment: worker_m2_3

## Mission: Milestone 2 Test Authoring, Execution & Verification Pass
You are assigned as the Worker for completing and verifying Milestone 2 (Relational Database Engine & 6 Views).

### Working Directory
`c:\parsa\HamPA\.agents\teamwork\worker_m2_3`

### Mandatory Reading
- `c:\parsa\HamPA\.agents\teamwork\ORIGINAL_REQUEST.md` (Authoritative User Requirements)
- `c:\parsa\HamPA\PROJECT.md` (Project Specification & M2 Feature Inventory F08–F16)
- `c:\parsa\HamPA\CHECKPOINT_STATE.md` (State checkpoint)
- `c:\parsa\HamPA\TEST_INFRA.md` & `c:\parsa\HamPA\TEST_READY.md`

### MANDATORY INTEGRITY WARNING
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

### Your Objectives
1. Inspect the codebase under `lib/core/database/` (tables and daos for databases, properties, rows, cells, views) and `lib/features/workspace_database/` (domain entities, formulas AST engine, rollups, 6 views UI: Table, Kanban, Calendar, Timeline, List, Gallery).
2. Author comprehensive unit and widget tests:
   - `test/unit/database_engine_test.dart`: Test Drift tables, DAOs, dual identity (page creation on database row creation, cascade deletion), 2-way relation synchronization, rollups calculation across relations.
   - `test/unit/formula_engine_test.dart`: Test formula AST engine, lexer, parser, operator precedence, arithmetic, string, logical, date functions, dependency graph, cycle detection returning `#CYCLE!` on direct or indirect circular references.
   - `test/widget/database_views_test.dart`: Test all 6 views UI rendering (Table View with frozen column / footer aggregation, Kanban View with lane grouping / drag & drop, Calendar View with month grid, Timeline/Gantt View with duration bars, List View, Gallery View with card cover/size), view switching toolbar, property visibility, and filter/sort dialogs.
3. Run `C:\flutter\bin\flutter.bat analyze` and fix any lint or type issues until it produces `0 issues found!`.
4. Run `C:\flutter\bin\flutter.bat test test/unit/ test/widget/` and ensure all tests pass (both M1 and M2 tests must pass with 100% success rate).
5. Run the existing E2E tests for M2: `C:\flutter\bin\flutter.bat test test/e2e/tier1_feature_coverage/f08_f16_relational_database_test.dart` and `test/e2e/tier2_boundary_stress/f08_f16_database_boundary_test.dart` (if present).
6. Document full command execution results, pass counts, and architectural verification in `c:\parsa\HamPA\.agents\teamwork\worker_m2_3\handoff.md`.


## 2026-10-17T10:02:26Z
[Message] timestamp=2026-10-17T10:02:26Z sender=ed136aae-8a17-49e6-b0d4-111f343ada43 priority=MESSAGE_PRIORITY_HIGH content=You are worker_m2_3, assigned to finalize the tests and verify Milestone 2 (Relational Database Engine & 6 Views) for HamPA.
Working Directory: c:\parsa\HamPA\.agents\teamwork\worker_m2_3
Project Root: c:\parsa\HamPA
Read your task assignment: c:\parsa\HamPA\.agents\teamwork\worker_m2_3\DISPATCH.md
Read authoritative requirements: c:\parsa\HamPA\.agents\teamwork\ORIGINAL_REQUEST.md
Read project specification: c:\parsa\HamPA\PROJECT.md
Read checkpoint state: c:\parsa\HamPA\CHECKPOINT_STATE.md
