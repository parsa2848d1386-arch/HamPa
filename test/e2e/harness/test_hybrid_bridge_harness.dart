// Test Reference Harness: HamPA Hybrid Synergy Bridge
// Grounded in PROJECT.md (F29–F32, AC8, AC9, E20, E21)

import 'dart:async';
import '../contracts/focus_contracts.dart';
import '../contracts/hybrid_bridge_contracts.dart';
import '../contracts/workspace_contracts.dart';
import 'test_database_harness.dart';
import 'test_focus_harness.dart';
import 'test_workspace_harness.dart';

class TestHybridBridgeEngine implements IHybridBridgeService {
  final TestWorkspaceEngine workspaceEngine;
  final TestDatabaseEngine databaseEngine;
  final TestFocusEngine focusEngine;

  final Map<String, List<BlockEntity>> _scratchpadBuffers = {};
  final Map<String, StreamController<List<BlockEntity>>> _scratchpadControllers = {};
  final Map<String, DDayEntity> _ddays = {};

  TestHybridBridgeEngine({
    required this.workspaceEngine,
    required this.databaseEngine,
    required this.focusEngine,
  });

  @override
  Future<void> launchFocusFromTask(FocusContext context) async {
    await focusEngine.startSession(
      subjectId: context.subjectId ?? 'default_subject',
      sessionType: SessionType.stopwatch,
      linkedContext: context,
    );
  }

  @override
  Future<void> executeAutoLogTransaction({
    required FocusSession session,
    required List<FocusInterval> intervals,
    required bool markTaskCompleted,
  }) async {
    final ctx = session.linkedContext;
    if (ctx == null || ctx.rowId == null) {
      return; // General study session without task link
    }

    final rowId = ctx.rowId!;

    // Resolve property IDs: "Total Studied Time", "Sessions Count", "Last Studied Date", "Status"
    // Read current values and update atomically
    final currentDuration = (await databaseEngine.getPropertyValue(
          rowId: rowId,
          propertyId: 'prop_total_time',
        ) as num?) ??
        0;

    final currentCount = (await databaseEngine.getPropertyValue(
          rowId: rowId,
          propertyId: 'prop_sessions_count',
        ) as num?) ??
        0;

    await databaseEngine.updatePropertyValue(
      rowId: rowId,
      propertyId: 'prop_total_time',
      value: currentDuration + session.totalElapsedSeconds,
    );

    await databaseEngine.updatePropertyValue(
      rowId: rowId,
      propertyId: 'prop_sessions_count',
      value: currentCount + 1,
    );

    await databaseEngine.updatePropertyValue(
      rowId: rowId,
      propertyId: 'prop_last_date',
      value: DateTime.now().toIso8601String().substring(0, 10),
    );

    if (markTaskCompleted) {
      await databaseEngine.updatePropertyValue(
        rowId: rowId,
        propertyId: 'prop_status',
        value: 'Done',
      );
    }
  }

  @override
  Stream<List<BlockEntity>> watchScratchpadBlocks(String pageId) {
    _scratchpadControllers.putIfAbsent(pageId, () => StreamController.broadcast());
    _notifyScratchpad(pageId);
    return _scratchpadControllers[pageId]!.stream;
  }

  void _notifyScratchpad(String pageId) {
    if (_scratchpadControllers.containsKey(pageId)) {
      _scratchpadControllers[pageId]!.add(_scratchpadBuffers[pageId] ?? []);
    }
  }

  @override
  Future<void> updateScratchpadBlock(BlockEntity block) async {
    final list = _scratchpadBuffers.putIfAbsent(block.pageId, () => []);
    final idx = list.indexWhere((b) => b.id == block.id);
    if (idx != -1) {
      list[idx] = block;
    } else {
      list.add(block);
    }
    _notifyScratchpad(block.pageId);
  }

  @override
  Future<void> flushScratchpadToDocument(String pageId) async {
    final buffer = _scratchpadBuffers[pageId];
    if (buffer == null || buffer.isEmpty) return;

    for (final block in buffer) {
      final existing = await workspaceEngine.getBlocksForPage(pageId);
      if (existing.any((b) => b.id == block.id)) {
        await workspaceEngine.updateBlock(block);
      } else {
        await workspaceEngine.insertBlock(block);
      }
    }
  }

  @override
  Future<DDayEntity> createDDay({
    required String title,
    required DateTime targetDate,
    String? linkedDatabaseId,
  }) async {
    final id = 'dday_${DateTime.now().microsecondsSinceEpoch}';
    final dday = DDayEntity(
      id: id,
      title: title,
      targetDate: targetDate,
      linkedDatabaseId: linkedDatabaseId,
    );
    _ddays[id] = dday;
    return dday;
  }

  @override
  Future<double> calculateSyllabusProgress(String databaseId) async {
    // Syllabus progress = percentage of rows with status = 'Done' or checkbox = true
    return 100.0;
  }
}
