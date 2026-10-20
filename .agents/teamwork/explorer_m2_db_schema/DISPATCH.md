## 2026-10-16T21:43:49Z
You are explorer_m2_db_schema.
Your working directory is c:\parsa\HamPA\.agents\teamwork\explorer_m2_db_schema.
You MUST read:
1. c:\parsa\HamPA\.agents\teamwork\ORIGINAL_REQUEST.md
2. c:\parsa\HamPA\PROJECT.md (Milestone 2, F08, F09, F11, Interface Contract 2)

Your task is to design the file-by-file blueprint for Milestone 2 Relational Database Schema & Persistence:
- Drift SQLite schema & tables: `DatabasesTable`, `DatabasePropertiesTable`, `DatabaseRowsTable`, `DatabaseCellsTable`, `DatabaseViewsTable`.
- Dual Identity Paradigm: Enforce that every database row references an underlying Page (`pages.id`), ensuring that clicking any row opens its page and modular block document.
- Property types: Title, Text, Number, Select, MultiSelect, Date, Checkbox, URL, Email, Phone, CreatedTime, LastEditedTime, Relation (with 2-way target database and target property), Rollup, Formula.
- 2-way Relations: When a Relation property is created with 2-way linking enabled, automatically create and synchronize the reciprocal relation property in the target database.
- DAOs: `DatabasesDao`, `DatabasePropertiesDao`, `DatabaseRowsDao`, `DatabaseCellsDao`, `DatabaseViewsDao` with reactive streams and atomic transactions.
- Clean Architecture repository: `DatabaseEngineRepositoryImpl` implementing `IDatabaseEngineRepository`.

Write your complete blueprint in c:\parsa\HamPA\.agents\teamwork\explorer_m2_db_schema\handoff.md.
Do NOT write or edit source code directly.
When done, use send_message to report back to parent orchestrator (Conversation ID: 22d8faaf-eb90-463c-99a6-32a4eb94320e).
