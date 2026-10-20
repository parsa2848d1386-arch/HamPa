// E2E Contract Definitions: HamPA Hybrid Synergy Bridge
// Grounded in PROJECT.md and ORIGINAL_REQUEST.md (R3, AC8, AC9)

import 'focus_contracts.dart';
import 'workspace_contracts.dart';

class DDayEntity {
  final String id;
  final String title;
  final DateTime targetDate;
  final String? linkedDatabaseId;
  final String? linkedPropertyId;

  DDayEntity({
    required this.id,
    required this.title,
    required this.targetDate,
    this.linkedDatabaseId,
    this.linkedPropertyId,
  });

  int daysRemaining({DateTime? referenceDate}) {
    final now = referenceDate ?? DateTime.now();
    final cleanTarget = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final cleanNow = DateTime(now.year, now.month, now.day);
    return cleanTarget.difference(cleanNow).inDays;
  }

  String formatDDay({DateTime? referenceDate}) {
    final diff = daysRemaining(referenceDate: referenceDate);
    if (diff == 0) return 'D-Day';
    if (diff > 0) return 'D-$diff';
    return 'D+${diff.abs()}';
  }
}

abstract class IHybridBridgeService {
  Future<void> launchFocusFromTask(FocusContext context);

  Future<void> executeAutoLogTransaction({
    required FocusSession session,
    required List<FocusInterval> intervals,
    required bool markTaskCompleted,
  });

  Stream<List<BlockEntity>> watchScratchpadBlocks(String pageId);
  Future<void> updateScratchpadBlock(BlockEntity block);
  Future<void> flushScratchpadToDocument(String pageId);

  Future<DDayEntity> createDDay({
    required String title,
    required DateTime targetDate,
    String? linkedDatabaseId,
  });
  Future<double> calculateSyllabusProgress(String databaseId);
}
