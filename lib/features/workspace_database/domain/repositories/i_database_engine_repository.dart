import '../models/database_entity.dart';
import '../models/property_entity.dart';
import '../models/property_type.dart';
import '../models/row_entity.dart';
import '../models/cell_entity.dart';
import '../models/view_entity.dart';
import '../models/database_view_type.dart';
import '../models/rollup_function.dart';

abstract class IDatabaseEngineRepository {
  Stream<DatabaseEntity> watchDatabase(String databaseId);
  Stream<List<PropertyEntity>> watchProperties(String databaseId);
  Stream<List<RowEntity>> watchRows(String databaseId);
  Stream<List<CellEntity>> watchCells(String databaseId);
  Stream<List<ViewEntity>> watchViews(String databaseId);

  Future<DatabaseEntity> createDatabase({
    required String title,
    required String pageId,
  });

  Future<PropertyEntity> addProperty({
    required String databaseId,
    required String name,
    required PropertyType type,
    Map<String, dynamic>? config,
  });

  Future<String> createRow(String databaseId); // Automatically creates underlying Page
  Future<void> updatePropertyValue({
    required String rowId,
    required String propertyId,
    dynamic value,
  });
  Future<dynamic> getPropertyValue({
    required String rowId,
    required String propertyId,
  });
  Future<void> deleteRow(String rowId);

  Future<ViewEntity> createView({
    required String databaseId,
    required String name,
    required DatabaseViewType type,
    Map<String, dynamic>? config,
  });

  // Formula evaluation and cycle detection
  Future<dynamic> evaluateFormula({
    required String rowId,
    required String expression,
    Set<String>? visitedProperties,
  });

  // Rollup calculation across related databases
  Future<dynamic> computeRollup({
    required String rowId,
    required String relationPropertyId,
    required String targetPropertyId,
    required RollupFunction function,
  });
}
