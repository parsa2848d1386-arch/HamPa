# Dispatch Assignment: Architecture & Technical Stack Explorer

- **Identity**: teamwork_preview_explorer (Architecture & Technical Stack Explorer)
- **Working Directory**: c:\parsa\HamPA\.agents\teamwork\explorer_survey_arch
- **Orchestrator Conversation ID**: 22d8faaf-eb90-463c-99a6-32a4eb94320e
- **Authoritative Request**: c:\parsa\HamPA\.agents\teamwork\ORIGINAL_REQUEST.md

## Objective
Investigate and design the technical architecture for HamPA (هم‌پا) unifying Notion + YPT:
1. Read `c:\parsa\HamPA\.agents\teamwork\ORIGINAL_REQUEST.md`.
2. Propose data architecture for R1:
   - Page tree & nested block models (text, heading, checklist, callout, toggle, code, math).
   - Relational database schema: tables, columns/properties (status, select/multi-select, date, tags, relations, formulas, rollups), rows, cells.
   - Support for 6 views (Table, Kanban, Calendar, Timeline/Gantt, List, Gallery) sharing the same underlying data models.
   - Drift SQLite local-first storage & reactivity (streams).
3. Propose architecture for R2:
   - Monotonic background stopwatch (`elapsed = now - start_epoch - paused_duration`), Pomodoro cycles, countdown timer.
   - Strict Lock Mode & lifecycle observer (AppLifecycleListener, app switches detection, allowlist).
   - 24-hour visual 10-minute timetable grid (144 blocks, 05:00 AM - 05:00 AM mapping to color-coded subjects).
   - Live Study Rooms real-time state machine (`STUDYING`, `RESTING`, `OFFLINE`), peer updates, cheering.
4. Propose architecture for R3 (Hybrid Bridge):
   - "Focus Now" action on database rows and checklist blocks linking active session to entity.
   - Auto-logging session completion into database properties (`Total Studied Time`, `Sessions Count`, `Last Studied Date`, `Progress`).
   - In-session scratchpad split drawer reading/writing to linked page block without breaking lock.
   - D-Day & exam countdown linked to subjects & syllabus.
5. Propose architecture for R4 (Analytics & Gamification):
   - GitHub-style annual & monthly heatmaps with intensity levels.
   - 05:00 AM day-cutoff streak calculation engine.
   - Leaderboards (group, peer, national) with privacy controls.
6. Define recommended clean module layout and interfaces across these domains.
7. Deliver your architectural proposal in `handoff.md` in your working directory and notify the orchestrator.


## 2026-10-16T16:18:22Z
[Message] timestamp=2026-10-16T16:18:22Z sender=22d8faaf-eb90-463c-99a6-32a4eb94320e priority=MESSAGE_PRIORITY_HIGH content=You are explorer_survey_arch.
Your working directory is c:\parsa\HamPA\.agents\teamwork\explorer_survey_arch.
Read your instructions in c:\parsa\HamPA\.agents\teamwork\explorer_survey_arch\DISPATCH.md.
Read the authoritative user request in c:\parsa\HamPA\.agents\teamwork\ORIGINAL_REQUEST.md.
Investigate and design the technical architecture for HamPA unifying Notion (blocks & 6-view relational DB) and YPT (timer, strict lock, 144-block grid, study rooms), plus the hybrid bridge and analytics/gamification.
Write your progress into progress.md in your working directory as you work.
Deliver your complete findings in handoff.md in your working directory.
When done, use send_message to report back to your parent orchestrator (Conversation ID: 22d8faaf-eb90-463c-99a6-32a4eb94320e).
