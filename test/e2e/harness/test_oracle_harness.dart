// Unified HamPA Reference Test Double (Oracle Harness)
// Coordinates all 7 subsystems for end-to-end testing across Tiers 1-4.

import 'test_workspace_harness.dart';
import 'test_database_harness.dart';
import 'test_focus_harness.dart';
import 'test_timetable_harness.dart';
import 'test_study_room_harness.dart';
import 'test_hybrid_bridge_harness.dart';
import 'test_analytics_harness.dart';

class HamPATestHarness {
  late final TestWorkspaceEngine workspace;
  late final TestDatabaseEngine database;
  late final TestFocusEngine focus;
  late final TestTimetableEngine timetable;
  late final TestLiveStudyRoomEngine studyRooms;
  late final TestHybridBridgeEngine bridge;
  late final TestAnalyticsStreakEngine analytics;

  HamPATestHarness() {
    workspace = TestWorkspaceEngine();
    database = TestDatabaseEngine(workspaceEngine: workspace);
    focus = TestFocusEngine();
    timetable = TestTimetableEngine();
    studyRooms = TestLiveStudyRoomEngine();
    bridge = TestHybridBridgeEngine(
      workspaceEngine: workspace,
      databaseEngine: database,
      focusEngine: focus,
    );
    analytics = TestAnalyticsStreakEngine();
  }
}
