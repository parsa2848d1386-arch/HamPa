# HamPA (هم‌پا) — Test Infrastructure & E2E Testing Architecture

## 1. Test Philosophy & Principles

The HamPA E2E Test Suite is architected according to three non-negotiable principles:

1. **Opaque-Box Requirement-Driven Verification**:
   Tests are written strictly against user requirements ($R1$–$R4$), acceptance criteria ($AC1$–$AC10$), and public interface contracts. Tests interact with public domain interfaces, repository contracts, and event streams. They never couple to internal private implementation details or framework-specific internals.
   
2. **Zero Facade & Authentic Domain Logic Execution**:
   Every test exercises genuine state transitions, mathematical algorithms, data serialization, schema relationships, and invariant checks. No test is permitted to pass vacuously without asserting deterministic outputs derived from authoritative sources.

3. **Subsystem Isolation & Self-Containment**:
   Each test suite creates, configures, and tears down its own state. Tests do not depend on execution order, network availability, or external persistent side effects.

---

## 2. Test Architecture & Directory Layout

The E2E test suite resides entirely within `test/e2e/`:

```
c:\parsa\HamPA\test\e2e\
├── contracts/                              # Canonical domain models & interfaces per PROJECT.md
│   ├── workspace_contracts.dart            # Page, Block, Tree, IWorkspaceRepository
│   ├── database_contracts.dart             # Database, Property, Row, Cell, View, Formula, Rollup
│   ├── focus_contracts.dart                # Stopwatch, Pomodoro, Exam, Strict Lock, Allowlist, Sensor
│   ├── timetable_contracts.dart            # 144-Slot Grid, 05:00 Cutoff, Subject, Color Mapping
│   ├── study_room_contracts.dart           # Tri-State Presence, Avatars, Cheering Rate Limiter
│   ├── hybrid_bridge_contracts.dart        # "Focus Now", Auto-Logging, In-Session Scratchpad, D-Day
│   └── analytics_contracts.dart            # Heatmaps (365/366d), 05:00 Streak, Leaderboards
│
├── harness/                                # Independent in-memory reference test harness
│   ├── test_workspace_harness.dart         # Reference workspace engine & tree cycle prevention
│   ├── test_database_harness.dart          # Reference database, AST evaluator & rollup calculator
│   ├── test_focus_harness.dart             # Monotonic elapsed calculator & lock lifecycle monitor
│   ├── test_timetable_harness.dart         # 144-slot grid projector & boundary bisector
│   ├── test_study_room_harness.dart        # Tri-state presence coordinator & rate limiter
│   ├── test_hybrid_bridge_harness.dart     # Atomic auto-logger & scratchpad flush controller
│   ├── test_analytics_harness.dart         # Heatmap level generator & streak calculator
│   └── test_oracle_harness.dart            # Unified HamPA E2E System Test Double
│
├── tier1_feature_coverage/                 # Tier 1: Happy-path isolated feature coverage (≥5 per F01–F35)
│   ├── f01_f07_workspace_blocks_test.dart  # F01–F07 (≥35 test cases)
│   ├── f08_f16_relational_database_test.dart# F08–F16 (≥45 test cases)
│   ├── f17_f23_focus_strict_lock_test.dart # F17–F23 (≥35 test cases)
│   ├── f24_f28_timetable_study_rooms_test.dart# F24–F28 (≥25 test cases)
│   ├── f29_f32_hybrid_bridge_test.dart     # F29–F32 (≥20 test cases)
│   └── f33_f35_analytics_gamification_test.dart# F33–F35 (≥15 test cases)
│
├── tier2_boundary_corner/                  # Tier 2: Boundary conditions & error paths (≥5 per F01–F35)
│   ├── f01_f07_workspace_boundary_test.dart# Boundaries & errors for F01–F07 (≥35 test cases)
│   ├── f08_f16_relational_boundary_test.dart# Boundaries & errors for F08–F16 (≥45 test cases)
│   ├── f17_f23_focus_boundary_test.dart    # Boundaries & errors for F17–F23 (≥35 test cases)
│   ├── f24_f28_timetable_boundary_test.dart# Boundaries & errors for F24–F28 (≥25 test cases)
│   ├── f29_f32_hybrid_boundary_test.dart   # Boundaries & errors for F29–F32 (≥20 test cases)
│   └── f33_f35_analytics_boundary_test.dart# Boundaries & errors for F33–F35 (≥15 test cases)
│
├── tier3_cross_feature/                    # Tier 3: Pairwise cross-subsystem integration (≥35 tests)
│   └── pairwise_interactions_test.dart     # Closed-loop data flow tests across subsystems (≥35 tests)
│
├── tier4_real_world_scenarios/             # Tier 4: Realistic user study workflows (≥18 scenarios)
│   └── student_study_journeys_test.dart    # Comprehensive end-to-end user workflows (≥18 scenarios)
│
├── run_all_e2e.dart                        # Standalone runner executable
└── e2e_suite_test.dart                     # Standard Flutter / Dart test runner entrypoint
```

---

## 3. Runner Invocation & Test Execution

### 3.1 Standard Test Runner (Flutter / Dart)
Execute the complete E2E test suite:
```powershell
flutter test test/e2e/e2e_suite_test.dart
```

Execute individual tiers:
```powershell
# Tier 1: Feature Coverage
flutter test test/e2e/tier1_feature_coverage/

# Tier 2: Boundary & Corner Cases
flutter test test/e2e/tier2_boundary_corner/

# Tier 3: Cross-Feature Combinations
flutter test test/e2e/tier3_cross_feature/

# Tier 4: Real-World Scenarios
flutter test test/e2e/tier4_real_world_scenarios/
```

### 3.2 Standalone Dart Harness Runner
In environments where Flutter SDK is being provisioned or running in headless CLI mode:
```powershell
dart run test/e2e/run_all_e2e.dart
```

---

## 4. Feature Inventory to Test Tiers Mapping Matrix

| Feature | Name | Category | Tier 1 (Coverage ≥5) | Tier 2 (Boundary ≥5) | Tier 3 (Cross) | Tier 4 (Scenario) |
|---|---|---|---|---|---|---|
| **F01** | Hierarchical Page Tree | Workspace | 5 tests | 5 tests | Pairwise | S01, S15 |
| **F02** | Drag-and-Drop Page Tree | Workspace | 5 tests | 5 tests | Pairwise | S01, S15 |
| **F03** | Local-First Drift Persistence | Workspace | 5 tests | 5 tests | Pairwise | S02, S18 |
| **F04** | Rich Text & Headings Blocks | Block Editor | 5 tests | 5 tests | Pairwise | S01, S04 |
| **F05** | Interactive Checklist Blocks | Block Editor | 5 tests | 5 tests | Pairwise | S03, S13 |
| **F06** | Callout & Toggle Blocks | Block Editor | 5 tests | 5 tests | Pairwise | S01, S13 |
| **F07** | Code Syntax & LaTeX Math | Block Editor | 5 tests | 5 tests | Pairwise | S04, S17 |
| **F08** | Rich Property Schema Engine | Relational DB | 5 tests | 5 tests | Pairwise | S03, S14 |
| **F09** | Two-Way Database Relations | Relational DB | 5 tests | 5 tests | Pairwise | S03, S14 |
| **F10** | Formula Expression Engine | Relational DB | 5 tests | 5 tests | Pairwise | S03, S14 |
| **F11** | Automatic Rollups & Aggregations | Relational DB | 5 tests | 5 tests | Pairwise | S03, S14 |
| **F12** | Table View with Inline Editing | Relational DB | 5 tests | 5 tests | Pairwise | S03, S14 |
| **F13** | Kanban Board View | Relational DB | 5 tests | 5 tests | Pairwise | S03, S16 |
| **F14** | Calendar View (Month/Week) | Relational DB | 5 tests | 5 tests | Pairwise | S05, S12 |
| **F15** | Timeline / Gantt View | Relational DB | 5 tests | 5 tests | Pairwise | S05, S16 |
| **F16** | List & Gallery Views | Relational DB | 5 tests | 5 tests | Pairwise | S03, S16 |
| **F17** | Monotonic Background Stopwatch | Focus Engine | 5 tests | 5 tests | Pairwise | S06, S07 |
| **F18** | Customizable Pomodoro Cycles | Focus Engine | 5 tests | 5 tests | Pairwise | S07, S11 |
| **F19** | Mock Exam Countdown Timers | Focus Engine | 5 tests | 5 tests | Pairwise | S08, S17 |
| **F20** | Strict Lock & Interruption Log | Anti-Distraction | 5 tests | 5 tests | Pairwise | S06, S10 |
| **F21** | Reference Allowlist | Anti-Distraction | 5 tests | 5 tests | Pairwise | S06, S10 |
| **F22** | Flip-to-Focus Sensor Detection | Anti-Distraction | 5 tests | 5 tests | Pairwise | S09, S11 |
| **F23** | Multi-Track Ambient Soundscapes | Anti-Distraction | 5 tests | 5 tests | Pairwise | S06, S11 |
| **F24** | 24-Hour 10-Minute Timetable Grid | Timetable Grid | 5 tests | 5 tests | Pairwise | S06, S09 |
| **F25** | Real-Time Block Painting & Pulse | Timetable Grid | 5 tests | 5 tests | Pairwise | S06, S09 |
| **F26** | Live Study Rooms Presence | Study Rooms | 5 tests | 5 tests | Pairwise | S10, S11 |
| **F27** | Animated Avatars & Desk Cam | Study Rooms | 5 tests | 5 tests | Pairwise | S10, S11 |
| **F28** | Groups, Quotas, Cheering | Study Rooms | 5 tests | 5 tests | Pairwise | S10, S11 |
| **F29** | "Focus Now" Launcher Action | Hybrid Bridge | 5 tests | 5 tests | Pairwise | S03, S06 |
| **F30** | Session Auto-Logging to DB Rows | Hybrid Bridge | 5 tests | 5 tests | Pairwise | S03, S06 |
| **F31** | In-Session Scratchpad Drawer | Hybrid Bridge | 5 tests | 5 tests | Pairwise | S06, S10 |
| **F32** | D-Day & Exam Syllabus Countdown | Hybrid Bridge | 5 tests | 5 tests | Pairwise | S12, S17 |
| **F33** | GitHub-Style Study Heatmaps | Analytics | 5 tests | 5 tests | Pairwise | S09, S18 |
| **F34** | 05:00 AM Day-Cutoff Streak Engine| Gamification | 5 tests | 5 tests | Pairwise | S09, S18 |
| **F35** | Multi-Tier Leaderboards & Privacy| Gamification | 5 tests | 5 tests | Pairwise | S10, S18 |

**Total Test Targets**:
- **Tier 1 (Feature Coverage)**: 35 features $\times$ 5 tests = **175 test cases**
- **Tier 2 (Boundary & Corner)**: 35 features $\times$ 5 tests = **175 test cases**
- **Tier 3 (Cross-Feature Pairwise)**: **35 test cases**
- **Tier 4 (Real-World Scenarios)**: **18 comprehensive scenarios**
- **Grand Total**: **403 deterministic test cases**

---

## 5. Acceptance Criteria Verification Assertions

Every test suite guarantees explicit validation of Acceptance Criteria $AC1$ through $AC10$:
- **AC1** (Tree & Blocks state preservation): Tested in `f01_f07_workspace_blocks_test.dart` and `student_study_journeys_test.dart` (S01).
- **AC2** (6 Database views parity): Tested in `f08_f16_relational_database_test.dart` and `pairwise_interactions_test.dart`.
- **AC3** (Local-first persistence & offline sync): Tested in `f01_f07_workspace_blocks_test.dart` and `f01_f07_workspace_boundary_test.dart`.
- **AC4** (Monotonic stopwatch zero drift): Tested in `f17_f23_focus_strict_lock_test.dart` and `pairwise_interactions_test.dart`.
- **AC5** (Strict lock interruption detection & allowlist): Tested in `f17_f23_focus_strict_lock_test.dart` and `f17_f23_focus_boundary_test.dart`.
- **AC6** (10-minute grid real-time painting & 05:00 cutoff): Tested in `f24_f28_timetable_study_rooms_test.dart` and `f24_f28_timetable_boundary_test.dart`.
- **AC7** (Live study room <500ms presence & rate-limited cheering): Tested in `f24_f28_timetable_study_rooms_test.dart` and `pairwise_interactions_test.dart`.
- **AC8** ("Focus Now" auto-log to DB task properties & rollup update): Tested in `f29_f32_hybrid_bridge_test.dart` and `pairwise_interactions_test.dart`.
- **AC9** (In-session scratchpad writes to linked page document): Tested in `f29_f32_hybrid_bridge_test.dart` and `student_study_journeys_test.dart` (S06).
- **AC10** (Immediate heatmap intensity & 05:00 streak update): Tested in `f33_f35_analytics_gamification_test.dart` and `pairwise_interactions_test.dart`.
