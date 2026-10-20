import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hampa/core/database/app_database.dart';
import 'package:hampa/core/database/daos/database_rows_dao.dart';
import 'package:hampa/core/database/daos/database_cells_dao.dart';
import 'package:hampa/core/database/daos/database_properties_dao.dart';
import 'package:hampa/core/database/daos/study_sessions_dao.dart';
import 'package:hampa/features/focus_timer/domain/models/focus_session_state.dart';
import 'package:hampa/features/focus_timer/presentation/controllers/focus_timer_cubit.dart';
import '../domain/models/dday_entity.dart';

class SynergyBridgeService {
  final StudySessionsDao studySessionsDao;
  final DatabaseRowsDao rowsDao;
  final DatabaseCellsDao cellsDao;
  final DatabasePropertiesDao propertiesDao;
  final AppDatabase appDatabase;

  String? _activeTaskTitle;
  String? _activeDatabaseId;
  String? _activeRowId;
  String? _activeSubjectId;

  SynergyBridgeService({
    required this.studySessionsDao,
    required this.rowsDao,
    required this.cellsDao,
    required this.propertiesDao,
    AppDatabase? appDatabase,
  }) : appDatabase = appDatabase ?? (rowsDao.attachedDatabase);

  String? get activeTaskTitle => _activeTaskTitle;
  String? get activeDatabaseId => _activeDatabaseId;
  String? get activeRowId => _activeRowId;
  String? get activeSubjectId => _activeSubjectId;

  /// Launch focus tagged to a specific database task/row
  void launchFocusForTask({
    BuildContext? context,
    FocusTimerCubit? timerCubit,
    required String databaseId,
    required String rowId,
    required String subjectId,
    required String taskTitle,
    TimerMode mode = TimerMode.pomodoro,
    int? targetSeconds,
  }) {
    final cubit = timerCubit ?? context?.read<FocusTimerCubit>();
    if (cubit == null) {
      throw ArgumentError('Either context or timerCubit must be provided');
    }

    _activeTaskTitle = taskTitle;
    _activeDatabaseId = databaseId;
    _activeRowId = rowId;
    _activeSubjectId = subjectId;

    cubit.startTimer(
      subjectId: subjectId,
      pageId: rowId,
      taskTitle: taskTitle,
      databaseId: databaseId,
      rowId: rowId,
      mode: mode,
      targetSeconds: targetSeconds ?? (mode == TimerMode.pomodoro ? 1500 : 3600),
    );
  }

  /// Automatically roll up completed study time into the linked task's database properties
  /// using an atomic SQLite transaction.
  Future<void> syncSessionToTaskDatabase({
    required String databaseId,
    required String rowId,
    required int addedSeconds,
    bool markTaskCompleted = false,
  }) async {
    await appDatabase.transaction(() async {
      final properties = await propertiesDao.getPropertiesForDatabase(databaseId);
      final currentCells = await cellsDao.getCellsForRow(rowId);

      // 1. Total Studied Time (adds studied seconds)
      var timeProp = properties.where((p) {
        final name = p.name.toLowerCase();
        return p.id == 'prop_total_time' ||
            name.contains('total studied time') ||
            name.contains('total study time') ||
            name.contains('study') ||
            name.contains('time');
      }).firstOrNull;

      if (timeProp == null) {
        final propId = 'prop_total_time_${DateTime.now().millisecondsSinceEpoch}';
        await propertiesDao.insertProperty(DatabasePropertiesTableCompanion.insert(
          id: propId,
          databaseId: databaseId,
          name: 'Total Studied Time',
          propertyType: 'number',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
        timeProp = await propertiesDao.getPropertyById(propId);
      }

      if (timeProp != null) {
        final existingCell = currentCells.where((c) => c.propertyId == timeProp!.id).firstOrNull;
        num existingSeconds = 0;
        if (existingCell?.valueJson != null) {
          existingSeconds = num.tryParse(existingCell!.valueJson!) ?? 0;
        }
        final newTotalSeconds = existingSeconds + addedSeconds;
        await cellsDao.upsertCell(
          rowId: rowId,
          propertyId: timeProp.id,
          valueJson: newTotalSeconds.toString(),
        );
      }

      // 2. Sessions Count (increments count by 1)
      var countProp = properties.where((p) {
        final name = p.name.toLowerCase();
        return p.id == 'prop_sessions_count' ||
            name.contains('sessions count') ||
            name.contains('session count') ||
            name.contains('session');
      }).firstOrNull;

      if (countProp == null) {
        final propId = 'prop_sessions_count_${DateTime.now().millisecondsSinceEpoch}';
        await propertiesDao.insertProperty(DatabasePropertiesTableCompanion.insert(
          id: propId,
          databaseId: databaseId,
          name: 'Sessions Count',
          propertyType: 'number',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
        countProp = await propertiesDao.getPropertyById(propId);
      }

      if (countProp != null) {
        final existingCell = currentCells.where((c) => c.propertyId == countProp!.id).firstOrNull;
        int existingCount = 0;
        if (existingCell?.valueJson != null) {
          existingCount = int.tryParse(existingCell!.valueJson!) ?? 0;
        }
        final newCount = existingCount + 1;
        await cellsDao.upsertCell(
          rowId: rowId,
          propertyId: countProp.id,
          valueJson: newCount.toString(),
        );
      }

      // 3. Last Studied Date (formatted as YYYY-MM-DD)
      var dateProp = properties.where((p) {
        final name = p.name.toLowerCase();
        return p.id == 'prop_last_date' ||
            name.contains('last studied date') ||
            name.contains('last date');
      }).firstOrNull;

      if (dateProp == null) {
        final propId = 'prop_last_date_${DateTime.now().millisecondsSinceEpoch}';
        await propertiesDao.insertProperty(DatabasePropertiesTableCompanion.insert(
          id: propId,
          databaseId: databaseId,
          name: 'Last Studied Date',
          propertyType: 'date',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
        dateProp = await propertiesDao.getPropertyById(propId);
      }

      if (dateProp != null) {
        final now = DateTime.now();
        final formattedDate =
            "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
        await cellsDao.upsertCell(
          rowId: rowId,
          propertyId: dateProp.id,
          valueJson: formattedDate,
        );
      }

      // 4. Status (updates to 'Done' if applicable)
      if (markTaskCompleted) {
        var statusProp = properties.where((p) {
          final name = p.name.toLowerCase();
          return p.id == 'prop_status' || name.contains('status') || name.contains('progress');
        }).firstOrNull;

        if (statusProp == null) {
          final propId = 'prop_status_${DateTime.now().millisecondsSinceEpoch}';
          await propertiesDao.insertProperty(DatabasePropertiesTableCompanion.insert(
            id: propId,
            databaseId: databaseId,
            name: 'Status',
            propertyType: 'status',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
          statusProp = await propertiesDao.getPropertyById(propId);
        }

        if (statusProp != null) {
          await cellsDao.upsertCell(
            rowId: rowId,
            propertyId: statusProp.id,
            valueJson: 'Done',
          );
        }
      }
    });
  }

  /// Calculates the syllabus completion percentage across tasks in the database.
  Future<double> calculateSyllabusProgress(String databaseId) async {
    final rows = await rowsDao.getRowsForDatabase(databaseId);
    if (rows.isEmpty) return 100.0;

    final properties = await propertiesDao.getPropertiesForDatabase(databaseId);
    final statusOrCheckboxProps = properties.where((p) {
      final name = p.name.toLowerCase();
      final type = p.propertyType.toLowerCase();
      return name.contains('status') ||
          name.contains('done') ||
          name.contains('progress') ||
          name.contains('check') ||
          type == 'checkbox' ||
          type == 'status';
    }).toList();

    if (statusOrCheckboxProps.isEmpty) return 100.0;

    int completedCount = 0;
    for (final row in rows) {
      final cells = await cellsDao.getCellsForRow(row.id);
      bool isRowCompleted = false;
      for (final prop in statusOrCheckboxProps) {
        final cell = cells.where((c) => c.propertyId == prop.id).firstOrNull;
        if (cell?.valueJson != null) {
          final val = cell!.valueJson!.trim().toLowerCase();
          if (val == 'done' || val == 'completed' || val == 'true' || val == '{"checked":true}') {
            isRowCompleted = true;
            break;
          }
        }
      }
      if (isRowCompleted) {
        completedCount++;
      }
    }

    return (completedCount / rows.length) * 100.0;
  }

  /// Create a D-Day countdown milestone
  Future<DDayEntity> createDDay({
    required String title,
    required DateTime targetDate,
    String? linkedDatabaseId,
    String? linkedPropertyId,
  }) async {
    final id = 'dday_${DateTime.now().microsecondsSinceEpoch}';
    return DDayEntity(
      id: id,
      title: title,
      targetDate: targetDate,
      linkedDatabaseId: linkedDatabaseId,
      linkedPropertyId: linkedPropertyId,
    );
  }
}
