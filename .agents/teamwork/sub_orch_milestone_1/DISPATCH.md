# Dispatch Assignment: Workspace Core Sub-Orchestrator (Milestone 1)

- **Identity**: teamwork_preview_orchestrator (Workspace Core Sub-Orchestrator)
- **Working Directory**: c:\parsa\HamPA\.agents\teamwork\sub_orch_milestone_1
- **Parent Conversation ID**: 22d8faaf-eb90-463c-99a6-32a4eb94320e
- **Authoritative Request**: c:\parsa\HamPA\.agents\teamwork\ORIGINAL_REQUEST.md
- **Global Project Specification**: c:\parsa\HamPA\PROJECT.md
- **Environment Findings**: c:\parsa\HamPA\.agents\teamwork\explorer_survey_env\handoff.md
- **Architecture Blueprint**: c:\parsa\HamPA\.agents\teamwork\explorer_survey_arch\handoff.md

## Scope & Mission
You are the **Workspace Core Sub-Orchestrator** for Milestone 1 of HamPA (هم‌پا).
Your responsibility is to execute Milestone 1:
- **Features**: F01, F02, F03, F04, F05, F06, F07
- **Acceptance Criteria**: AC1, AC3

### Concrete Deliverables
1. **Flutter Scaffolding**:
   - Initialize Flutter application structure (`pubspec.yaml`, `lib/`, `test/`).
   - Configure dependencies as recommended in `PROJECT.md` and `explorer_survey_env/handoff.md`:
     `drift: ^2.24.0`, `drift_flutter: ^0.2.0`, `flutter_bloc: ^9.1.1`, `go_router: ^18.1.0`, `uuid: ^4.6.0`, `intl: ^0.20.3`, `flutter_math_fork: ^0.7.4`, `flutter_highlight: ^0.7.0`, `flutter_markdown: ^0.7.7`, `shared_preferences: ^2.5.6`.
2. **Local-First Drift SQLite Database Core**:
   - `AppDatabase` setup with reactive streams.
   - Tables and DAOs: `pages` (`pages_dao.dart`), `blocks` (`blocks_dao.dart`), `subjects` (`subjects_dao.dart`).
   - Transactional persistence for offline zero-latency edits (AC3).
3. **Hierarchical Page Tree**:
   - Navigation tree supporting arbitrary nesting depth, breadcrumbs, and drag-and-drop reordering/re-parenting without state loss (AC1).
4. **Modular Block Editor**:
   - Rich text, headings (H1, H2, H3), interactive checklists (with toggleable checkbox and strikethrough), callouts (tinted box + icon), toggles (collapsible accordion with nested blocks), code syntax highlighting, and LaTeX math formatting.
5. **Unit & Widget Test Verification**:
   - Comprehensive unit and widget tests for page tree operations, block serialization/deserialization, markdown parsing, and offline persistence.

### Execution Loop
Follow the Project Pattern iteration loop:
1. Initialize `SCOPE.md`, `BRIEFING.md`, `plan.md`, `progress.md`.
2. Spawn **Explorer** (`teamwork_preview_explorer`) to recommend implementation plan.
3. Spawn **Worker** (`teamwork_preview_worker`) with Explorer findings and MANDATORY INTEGRITY WARNING.
4. Spawn 2 **Reviewers** (`teamwork_preview_reviewer`) independently.
5. Spawn 2 **Challengers** (`teamwork_preview_challenger`) to stress-test.
6. Spawn **Forensic Auditor** (`teamwork_preview_auditor`) for integrity verification (binary veto).
7. Evaluate Gate: All pass -> mark M1 DONE, deliver handoff.md, notify parent. Any fail -> loop back.
