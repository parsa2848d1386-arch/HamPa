# Dispatch Assignment: Milestone 1 Database & Persistence Explorer

- **Identity**: teamwork_preview_explorer (Drift DB & Data Architecture Explorer)
- **Working Directory**: c:\parsa\HamPA\.agents\teamwork\explorer_m1_db
- **Parent Conversation ID**: 22d8faaf-eb90-463c-99a6-32a4eb94320e
- **Authoritative Request**: c:\parsa\HamPA\.agents\teamwork\ORIGINAL_REQUEST.md
- **Global Project Specification**: c:\parsa\HamPA\PROJECT.md
- **Environment Findings**: c:\parsa\HamPA\.agents\teamwork\explorer_survey_env\handoff.md
- **Architecture Blueprint**: c:\parsa\HamPA\.agents\teamwork\explorer_survey_arch\handoff.md

## Scope: Milestone 1 (M1) — Local-First Drift SQLite Core
Investigate and design the exact file-by-file implementation plan for:
1. Flutter project configuration (`pubspec.yaml`) with required dependencies: `drift: ^2.24.0`, `drift_flutter: ^0.2.0`, `path_provider`, `path`, `uuid`, etc.
2. Drift database schema and DAOs:
   - `pages` table & `PagesDao` (CRUD, hierarchical queries, watchPageTree, updateParent, sort orders).
   - `blocks` table & `BlocksDao` (CRUD, watchBlocksForPage, fractional order indexing, type-specific JSON content).
   - `subjects` table & `SubjectsDao` (core subject definitions with colors and goals).
3. Local-first transaction management and offline persistence guarantees (AC3).
4. Unit tests in `test/unit/drift_database_test.dart`.
5. Deliver concrete code templates and architectural recommendations in `handoff.md` and notify parent.

## 2026-10-16T16:43:33Z
You are explorer_m1_db.
Working directory: c:\parsa\HamPA\.agents\teamwork\explorer_m1_db
Read instructions in c:\parsa\HamPA\.agents\teamwork\explorer_m1_db\DISPATCH.md.
Read authoritative request in c:\parsa\HamPA\.agents\teamwork\ORIGINAL_REQUEST.md.
Read project specifications in c:\parsa\HamPA\PROJECT.md.
Design file-by-file implementation plan for Milestone 1 Drift SQLite database, DAOs (pages, blocks, subjects), offline persistence, and unit tests.
Write progress.md as you work and deliver handoff.md in your working directory.
When done, send a message to parent orchestrator (Conversation ID: 22d8faaf-eb90-463c-99a6-32a4eb94320e).
