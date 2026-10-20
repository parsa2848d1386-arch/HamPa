# Dispatch Assignment: Workspace Core Worker (Milestone 1)

- **Identity**: teamwork_preview_worker (Workspace Core Worker)
- **Working Directory**: c:\parsa\HamPA\.agents\teamwork\worker_m1_1
- **Parent Conversation ID**: 22d8faaf-eb90-463c-99a6-32a4eb94320e
- **Authoritative Request**: c:\parsa\HamPA\.agents\teamwork\ORIGINAL_REQUEST.md
- **Global Project Specification**: c:\parsa\HamPA\PROJECT.md
- **Drift DB Blueprint**: c:\parsa\HamPA\.agents\teamwork\explorer_m1_db\handoff.md
- **Page Tree Blueprint**: c:\parsa\HamPA\.agents\teamwork\explorer_m1_tree\handoff.md
- **Block Editor Blueprint**: c:\parsa\HamPA\.agents\teamwork\explorer_m1_editor\handoff.md

## MANDATORY INTEGRITY WARNING
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

## Write Ownership
You exclusively own:
- `pubspec.yaml`
- `lib/` (including `lib/main.dart`, `lib/app.dart`, `lib/core/`, `lib/features/workspace_editor/`, `lib/features/focus_engine/domain/models/subject_entity.dart`)
- `test/unit/` (`test/unit/drift_database_test.dart`, `test/unit/fractional_indexer_test.dart`, `test/unit/page_tree_utils_test.dart`)
- `test/widget/` (`test/widget/page_tree_test.dart`, `test/widget/block_editor_test.dart`)
Do NOT touch or overwrite `test/e2e/` (owned by `test_writer_e2e_1`).

## Implementation Instructions
1. **Toolchain Verification**: Check `flutter --version` and `dart --version`. If not in PATH, inspect `C:\flutter\bin` or clone/configure Flutter into `C:\flutter`.
2. **Scaffold & Dependencies**: Ensure `pubspec.yaml` matches the blueprint with `drift: ^2.24.0`, `drift_flutter: ^0.2.0`, `flutter_bloc: ^9.1.1`, `uuid`, `intl`, `flutter_math_fork`, `flutter_highlight`, etc. Run `flutter pub get`.
3. **Drift SQLite Core**: Implement tables (`Pages`, `Blocks`, `Subjects`), DAOs (`PagesDao`, `BlocksDao`, `SubjectsDao`), and `AppDatabase` with WAL mode and foreign keys enabled.
4. **Hierarchical Page Tree**: Implement `PageEntity`, `PageTreeNode`, `PageTreeUtils` (cycle prevention), `FractionalIndexer` (LexoRank), `PageTreeCubit`, and presentation widgets (`PageTreeSidebar`, `PageTreeItem` with 3-zone drop target, `PageBreadcrumbs`).
5. **Modular Block Editor**: Implement `BlockType`, content value objects, `BlockEntity`, `BlockEditorNotifier` (debounced auto-save), slash command menu (`/`), and block renderers (Text, Headings, Checklists with strikethrough, Callout, Toggle, Code highlighting, LaTeX math KaTeX).
6. **Verification**:
   - Run unit and widget tests:
     `flutter test test/unit/drift_database_test.dart`
     `flutter test test/unit/fractional_indexer_test.dart`
     `flutter test test/unit/page_tree_utils_test.dart`
     `flutter test test/widget/page_tree_test.dart`
     `flutter test test/widget/block_editor_test.dart`
   - All tests must pass with 100% genuine assertions.
7. **Handoff**: Document all executed commands, passing test outputs, and file layout compliance in `handoff.md`. Notify parent when complete.


## 2026-10-16T17:02:23Z
You are worker_m1_1.
Working directory: c:\parsa\HamPA\.agents\teamwork\worker_m1_1
Read instructions in c:\parsa\HamPA\.agents\teamwork\worker_m1_1\DISPATCH.md.
Read authoritative request in c:\parsa\HamPA\.agents\teamwork\ORIGINAL_REQUEST.md.
Read project specifications in c:\parsa\HamPA\PROJECT.md.
Read detailed blueprints:
- c:\parsa\HamPA\.agents\teamwork\explorer_m1_db\handoff.md
- c:\parsa\HamPA\.agents\teamwork\explorer_m1_tree\handoff.md
- c:\parsa\HamPA\.agents\teamwork\explorer_m1_editor\handoff.md

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

Implement Milestone 1 (Flutter scaffolding, Drift SQLite local-first database, DAOs, Page Tree with drag-and-drop & cycle prevention, Modular Block Editor with LaTeX math & syntax highlighting).
Run all build and test commands yourself to verify.
Write progress.md as you work and deliver complete handoff.md in your working directory.
When done, send a message to parent orchestrator (Conversation ID: 22d8faaf-eb90-463c-99a6-32a4eb94320e).
