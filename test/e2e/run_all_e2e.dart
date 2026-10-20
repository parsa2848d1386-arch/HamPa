// HamPA E2E Standalone Test Runner
// Executes all 403 test cases across Tiers 1-4 and reports detailed summary.

import 'support/test_runner.dart';
import 'tier1_feature_coverage/f01_f07_workspace_blocks_test.dart';
import 'tier1_feature_coverage/f08_f16_relational_database_test.dart';
import 'tier1_feature_coverage/f17_f23_focus_strict_lock_test.dart';
import 'tier1_feature_coverage/f24_f28_timetable_study_rooms_test.dart';
import 'tier1_feature_coverage/f29_f32_hybrid_bridge_test.dart';
import 'tier1_feature_coverage/f33_f35_analytics_gamification_test.dart';

import 'tier2_boundary_corner/f01_f07_workspace_boundary_test.dart';
import 'tier2_boundary_corner/f08_f16_relational_boundary_test.dart';
import 'tier2_boundary_corner/f17_f23_focus_boundary_test.dart';
import 'tier2_boundary_corner/f24_f28_timetable_boundary_test.dart';
import 'tier2_boundary_corner/f29_f32_hybrid_boundary_test.dart';
import 'tier2_boundary_corner/f33_f35_analytics_boundary_test.dart';

import 'tier3_cross_feature/pairwise_interactions_test.dart';
import 'tier4_real_world_scenarios/student_study_journeys_test.dart';

Future<void> main() async {
  print('================================================================');
  print('          HamPA (هم‌پا) Comprehensive E2E Test Suite            ');
  print('================================================================');
  resetTestStats();

  print('\n>>> Running Tier 1: Isolated Feature Coverage (F01–F35)...');
  runWorkspaceBlocksTier1Tests();
  runRelationalDatabaseTier1Tests();
  runFocusStrictLockTier1Tests();
  runTimetableStudyRoomsTier1Tests();
  runHybridBridgeTier1Tests();
  runAnalyticsGamificationTier1Tests();

  print('\n>>> Running Tier 2: Boundary & Corner Cases (F01–F35)...');
  runWorkspaceBlocksTier2Tests();
  runRelationalDatabaseTier2Tests();
  runFocusStrictLockTier2Tests();
  runTimetableStudyRoomsTier2Tests();
  runHybridBridgeTier2Tests();
  runAnalyticsGamificationTier2Tests();

  print('\n>>> Running Tier 3: Cross-Feature Pairwise Combinations...');
  runPairwiseCrossFeatureTier3Tests();

  print('\n>>> Running Tier 4: Real-World Student Study Scenarios...');
  runRealWorldScenariosTier4Tests();

  // Give brief moment for any pending microtasks
  await Future.delayed(const Duration(milliseconds: 100));

  final summary = getTestSummary();
  print('\n================================================================');
  print('                     TEST RUN SUMMARY                           ');
  print('================================================================');
  print('Total Tests Executed: ${summary.total}');
  print('Passed:               ${summary.passed}');
  print('Failed:               ${summary.failed}');
  print('================================================================');

  if (summary.failures.isNotEmpty) {
    print('\nFAILURE DETAILS:');
    for (final f in summary.failures) {
      print('------------------------------------------------');
      print(f);
    }
  }

  if (summary.isSuccess) {
    print('\n[SUCCESS] 100% of HamPA E2E Tests Passed successfully!');
  } else {
    print('\n[FAILURE] Some E2E tests failed.');
  }
}
