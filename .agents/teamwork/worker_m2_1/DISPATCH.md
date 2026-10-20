# Task Assignment: Milestone 2 Worker (`worker_m2_1`)

## 1. Assignment
- **Agent**: `worker_m2_1`
- **Role**: Relational Database Engine & 6 Views Implementation Worker
- **Working Directory**: `c:\parsa\HamPA\.agents\teamwork\worker_m2_1`
- **Parent Conversation ID**: `22d8faaf-eb90-463c-99a6-32a4eb94320e`
- **Target**: Milestone 2 (Relational Database Engine & 6 Views: F08–F16, AC2)

---

## 2. Mandatory Integrity Warning
> **DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.**

---

## 3. Required Reading & Authoritative Blueprints
You MUST read:
1. `c:\parsa\HamPA\.agents\teamwork\ORIGINAL_REQUEST.md` (authoritative user requirements R1, AC2)
2. `c:\parsa\HamPA\PROJECT.md` (Milestone 2 scope, F08–F16, Interface Contract 2, Dual Identity Paradigm)
3. `c:\parsa\HamPA\.agents\teamwork\explorer_m2_db_schema\handoff.md` (Drift SQLite schema, 5 tables, DAOs, 2-way relations, Dual Identity, repository)
4. `c:\parsa\HamPA\.agents\teamwork\explorer_m2_formula_engine\handoff.md` (Lexer, Parser, AST, cycle detector `#CYCLE!`, evaluator, rollup calculator)
5. `c:\parsa\HamPA\.agents\teamwork\explorer_m2_views_ui\handoff.md` (DatabaseViewCubit, view switcher, 6 distinct views, cell editors)

---

## 4. Exclusive File Ownership & Deliverables
You own:
- `lib/core/database/tables/databases_table.dart`
- `lib/core/database/tables/database_properties_table.dart`
- `lib/core/database/tables/database_rows_table.dart`
- `lib/core/database/tables/database_cells_table.dart`
- `lib/core/database/tables/database_views_table.dart`
- `lib/core/database/app_database.dart` (tables & DAOs registration)
- `lib/core/database/daos/databases_dao.dart`
- `lib/core/database/daos/database_properties_dao.dart`
- `lib/core/database/daos/database_rows_dao.dart`
- `lib/core/database/daos/database_cells_dao.dart`
- `lib/core/database/daos/database_views_dao.dart`
- `lib/features/workspace_database/` (entire directory: domain, data, presentation)
- `test/unit/database_engine_test.dart`
- `test/unit/formula_engine_test.dart`
- `test/widget/database_views_test.dart`

---

## 5. Execution Steps
1. **Schema & CodeGen**:
   - Create the 5 Drift tables in `lib/core/database/tables/`. Ensure foreign keys use customConstraints with ON DELETE CASCADE and Dual Identity references `pages(id)`.
   - Update `lib/core/database/app_database.dart` to register the new tables and DAOs.
   - Run `C:\flutter\bin\dart.bat run build_runner build --delete-conflicting-outputs`.
2. **DAOs & Repository**:
   - Implement the 5 DAOs in `lib/core/database/daos/`.
   - Implement `DatabaseEngineRepositoryImpl` conforming to `IDatabaseEngineRepository` from `PROJECT.md`.
   - Ensure Dual Identity: creating a row creates an underlying `Page` (`isDatabaseRow: true`), and deleting a row or page cascades cleanly.
   - Ensure Two-Way Relations: creating a relation with 2-way enabled automatically creates reciprocal property in target DB and synchronizes cell arrays.
3. **Formula AST & Rollup Engine**:
   - Implement `Token`, `Lexer`, `ASTNode`, `Parser`, `CycleDetector`, `FormulaEvaluator`, and `RollupEvaluator` in `lib/features/workspace_database/domain/formula/`.
   - Ensure circular dependencies return `#CYCLE!` without crashing or stack overflows.
   - Ensure division by zero returns `#DIV/0!`.
   - Ensure rollups support all required aggregations (`sum`, `average`, `count`, `min`, `max`, `percentChecked`, etc.).
4. **State & 6 Views UI**:
   - Implement `DatabaseViewCubit` and `DatabaseViewState`.
   - Implement top view switcher toolbar.
   - Implement all 6 views:
     - Table View (virtualized grid, cell editing, footer aggregations)
     - Kanban View (lane grouping, drag-and-drop between lanes, lane collapse)
     - Calendar View (month/week grid, multi-day spanning bars, drag-to-reschedule)
     - Timeline/Gantt View (horizontal time axis, draggable duration bars, dependency arrow lines)
     - List View (compact vertical row list with property pills)
     - Gallery View (card grid with cover preview and size toggles)
   - Ensure AC2 invariant: switching between all 6 views preserves identical data state without reloading.
5. **Unit & Widget Tests**:
   - Implement `test/unit/database_engine_test.dart`.
   - Implement `test/unit/formula_engine_test.dart`.
   - Implement `test/widget/database_views_test.dart`.
6. **Verification**:
   - Run `C:\flutter\bin\flutter.bat analyze`. (Must be 100% clean, 0 errors, 0 warnings).
   - Run `C:\flutter\bin\flutter.bat test test/unit/ test/widget/`. (All tests must pass).
7. **Handoff**:
   - Maintain `progress.md` with timestamps as you work.
   - Write comprehensive `handoff.md` with: Observation, Logic Chain, Caveats, Conclusion, and Verification commands and results.
   - Use `send_message` to report back to parent orchestrator (`22d8faaf-eb90-463c-99a6-32a4eb94320e`).
