import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/databases_dao.dart';
import '../../../../core/database/daos/database_properties_dao.dart';
import '../../../../core/database/daos/database_rows_dao.dart';
import '../../../../core/database/daos/database_cells_dao.dart';
import '../../../../core/database/daos/database_views_dao.dart';
import '../../../../core/database/daos/pages_dao.dart';

import '../../domain/formula/formula_evaluator.dart';
import '../../domain/formula/formula_context.dart';
import '../../domain/models/database_entity.dart';
import '../../domain/models/property_entity.dart';
import '../../domain/models/property_type.dart';
import '../../domain/models/row_entity.dart';
import '../../domain/models/cell_entity.dart';
import '../../domain/models/view_entity.dart';
import '../../domain/models/database_view_type.dart';
import '../../domain/models/rollup_function.dart';
import '../../domain/repositories/i_database_engine_repository.dart';
import '../../domain/rollup/rollup_calculator.dart';

class DatabaseEngineRepositoryImpl implements IDatabaseEngineRepository {
  final AppDatabase _db;
  final DatabasesDao _databasesDao;
  final DatabasePropertiesDao _propertiesDao;
  final DatabaseRowsDao _rowsDao;
  final DatabaseCellsDao _cellsDao;
  final DatabaseViewsDao _viewsDao;
  final PagesDao _pagesDao;

  final _uuid = const Uuid();
  static const _formulaEvaluator = FormulaEvaluator();

  DatabaseEngineRepositoryImpl({
    required AppDatabase db,
    required DatabasesDao databasesDao,
    required DatabasePropertiesDao propertiesDao,
    required DatabaseRowsDao rowsDao,
    required DatabaseCellsDao cellsDao,
    required DatabaseViewsDao viewsDao,
    required PagesDao pagesDao,
  })  : _db = db,
        _databasesDao = databasesDao,
        _propertiesDao = propertiesDao,
        _rowsDao = rowsDao,
        _cellsDao = cellsDao,
        _viewsDao = viewsDao,
        _pagesDao = pagesDao;

  @override
  Stream<DatabaseEntity> watchDatabase(String databaseId) {
    return _databasesDao.watchDatabaseById(databaseId).map((entry) {
      if (entry == null) throw ArgumentError('Database not found: $databaseId');
      return DatabaseEntity(
        id: entry.id,
        title: entry.title,
        pageId: entry.pageId,
      );
    });
  }

  @override
  Stream<List<PropertyEntity>> watchProperties(String databaseId) {
    return _propertiesDao.watchPropertiesForDatabase(databaseId).map(
      (entries) => entries.map(_mapPropertyEntryToEntity).toList(),
    );
  }

  @override
  Stream<List<RowEntity>> watchRows(String databaseId) {
    return _rowsDao.watchRowsForDatabase(databaseId).map(
      (entries) => entries.map(_mapRowEntryToEntity).toList(),
    );
  }

  @override
  Stream<List<CellEntity>> watchCells(String databaseId) {
    return _cellsDao.watchCellsForDatabase(databaseId).map(
      (entries) => entries.map(_mapCellEntryToEntity).toList(),
    );
  }

  @override
  Stream<List<ViewEntity>> watchViews(String databaseId) {
    return _viewsDao.watchViewsForDatabase(databaseId).map(
      (entries) => entries.map(_mapViewEntryToEntity).toList(),
    );
  }

  @override
  Future<DatabaseEntity> createDatabase({
    required String title,
    required String pageId,
  }) async {
    final dbId = 'db_${DateTime.now().microsecondsSinceEpoch}_${_uuid.v4().substring(0, 8)}';
    final now = DateTime.now();

    await _db.transaction(() async {
      await _databasesDao.insertDatabase(
        DatabasesTableCompanion.insert(
          id: dbId,
          pageId: pageId,
          title: Value(title),
          createdAt: now,
          updatedAt: now,
        ),
      );

      // Default 'Name' title property
      await addProperty(
        databaseId: dbId,
        name: 'Name',
        type: PropertyType.title,
      );

      // Default Table View
      await createView(
        databaseId: dbId,
        name: 'Table View',
        type: DatabaseViewType.table,
      );
    });

    return DatabaseEntity(id: dbId, title: title, pageId: pageId);
  }

  @override
  Future<PropertyEntity> addProperty({
    required String databaseId,
    required String name,
    required PropertyType type,
    Map<String, dynamic>? config,
  }) async {
    final existing = await _propertiesDao.getPropertiesForDatabase(databaseId);
    if (existing.any((p) => p.name.trim().toLowerCase() == name.trim().toLowerCase())) {
      throw ArgumentError('Duplicate property name in database: $name');
    }

    final propId = 'prop_${DateTime.now().microsecondsSinceEpoch}_${existing.length}';
    final now = DateTime.now();
    final effectiveConfig = Map<String, dynamic>.from(config ?? {});

    // Two-way relation automation
    if (type == PropertyType.relation && effectiveConfig['isTwoWay'] == true) {
      final targetDbId = effectiveConfig['targetDatabaseId'] as String?;
      if (targetDbId == null) {
        throw ArgumentError('Two-way relation requires targetDatabaseId');
      }

      final reciprocalPropId = 'prop_${DateTime.now().microsecondsSinceEpoch}_reciprocal';
      final currentDb = await _databasesDao.getDatabaseById(databaseId);
      final reciprocalName = effectiveConfig['reciprocalPropertyName'] as String? ??
          'Related ${currentDb?.title ?? 'Database'}';

      final targetProps = await _propertiesDao.getPropertiesForDatabase(targetDbId);
      if (targetProps.any((p) => p.name.trim().toLowerCase() == reciprocalName.trim().toLowerCase())) {
        throw ArgumentError('Duplicate property name in target database: $reciprocalName');
      }

      effectiveConfig['targetPropertyId'] = reciprocalPropId;

      final reciprocalConfig = <String, dynamic>{
        'targetDatabaseId': databaseId,
        'targetPropertyId': propId,
        'isTwoWay': true,
        'reciprocalPropertyName': name,
      };

      await _db.transaction(() async {
        await _propertiesDao.insertProperty(
          DatabasePropertiesTableCompanion.insert(
            id: propId,
            databaseId: databaseId,
            name: name,
            propertyType: type.name,
            sortOrder: Value(existing.length.toDouble()),
            configJson: Value(jsonEncode(effectiveConfig)),
            createdAt: now,
            updatedAt: now,
          ),
        );

        await _propertiesDao.insertProperty(
          DatabasePropertiesTableCompanion.insert(
            id: reciprocalPropId,
            databaseId: targetDbId,
            name: reciprocalName,
            propertyType: PropertyType.relation.name,
            sortOrder: Value(targetProps.length.toDouble()),
            configJson: Value(jsonEncode(reciprocalConfig)),
            createdAt: now,
            updatedAt: now,
          ),
        );
      });

      return PropertyEntity(
        id: propId,
        databaseId: databaseId,
        name: name,
        type: type,
        config: effectiveConfig,
      );
    }

    await _propertiesDao.insertProperty(
      DatabasePropertiesTableCompanion.insert(
        id: propId,
        databaseId: databaseId,
        name: name,
        propertyType: type.name,
        sortOrder: Value(existing.length.toDouble()),
        configJson: Value(jsonEncode(effectiveConfig)),
        createdAt: now,
        updatedAt: now,
      ),
    );

    return PropertyEntity(
      id: propId,
      databaseId: databaseId,
      name: name,
      type: type,
      config: effectiveConfig,
    );
  }

  @override
  Future<String> createRow(String databaseId) async {
    final db = await _databasesDao.getDatabaseById(databaseId);
    if (db == null) throw ArgumentError('Database not found: $databaseId');

    final now = DateTime.now();
    final rowId = 'row_${DateTime.now().microsecondsSinceEpoch}_${_uuid.v4().substring(0, 8)}';
    final pageId = _uuid.v4();

    return await _db.transaction(() async {
      // 1. Dual Identity: create underlying page
      await _pagesDao.insertPage(
        PagesCompanion.insert(
          id: pageId,
          parentPageId: Value(db.pageId),
          title: const Value('Untitled Row'),
          isDatabaseRow: const Value(true),
          createdAt: now,
          updatedAt: now,
        ),
      );

      // 2. Insert row record
      final existingRows = await _rowsDao.getRowsForDatabase(databaseId);
      await _rowsDao.insertRow(
        DatabaseRowsTableCompanion.insert(
          id: rowId,
          databaseId: databaseId,
          pageId: pageId,
          sortOrder: Value(existingRows.length.toDouble()),
          createdAt: now,
          updatedAt: now,
        ),
      );

      // 3. Find title property and initialize cell
      final props = await _propertiesDao.getPropertiesForDatabase(databaseId);
      final titleProp = props.where((p) => p.propertyType == PropertyType.title.name).firstOrNull;
      if (titleProp != null) {
        await _cellsDao.upsertCell(
          rowId: rowId,
          propertyId: titleProp.id,
          valueJson: jsonEncode('Untitled Row'),
        );
      }

      return rowId;
    });
  }

  @override
  Future<void> updatePropertyValue({
    required String rowId,
    required String propertyId,
    dynamic value,
  }) async {
    final prop = await _propertiesDao.getPropertyById(propertyId);
    if (prop == null) throw ArgumentError('Property not found: $propertyId');

    final propType = PropertyTypeParsing.fromString(prop.propertyType);

    await _db.transaction(() async {
      // 1. If Title property: keep underlying Page.title synchronized
      if (propType == PropertyType.title) {
        final row = await _rowsDao.getRowById(rowId);
        if (row != null && value is String) {
          await _pagesDao.updatePageTitle(row.pageId, value);
        }
      }

      // 2. If Relation property: handle reciprocal 2-way relation sync
      if (propType == PropertyType.relation) {
        await _handleRelationUpdate(
          sourceRowId: rowId,
          property: prop,
          newValue: value,
        );
        return;
      }

      // 3. Standard cell upsert
      final String? encodedValue = value == null ? null : jsonEncode(value);
      await _cellsDao.upsertCell(
        rowId: rowId,
        propertyId: propertyId,
        valueJson: encodedValue,
      );
    });
  }

  Future<void> _handleRelationUpdate({
    required String sourceRowId,
    required DatabasePropertyEntry property,
    dynamic newValue,
  }) async {
    final config = jsonDecode(property.configJson) as Map<String, dynamic>;
    final isTwoWay = config['isTwoWay'] == true;
    final reciprocalPropId = config['targetPropertyId'] as String?;

    // Parse new target row IDs
    final List<String> newTargetIds = [];
    if (newValue is String && newValue.isNotEmpty) {
      newTargetIds.add(newValue);
    } else if (newValue is List) {
      newTargetIds.addAll(newValue.map((e) => e.toString()));
    }

    // Get current cell value to compute delta
    final currentCell = await _cellsDao.getCell(sourceRowId, property.id);
    final List<String> oldTargetIds = [];
    if (currentCell?.valueJson != null) {
      final decoded = jsonDecode(currentCell!.valueJson!);
      if (decoded is String) {
        oldTargetIds.add(decoded);
      } else if (decoded is List) {
        oldTargetIds.addAll(decoded.map((e) => e.toString()));
      }
    }

    // Upsert source cell preserving exact format (single vs list vs null)
    String? serialized;
    if (newValue == null) {
      serialized = null;
    } else if (newValue is List) {
      serialized = jsonEncode(newTargetIds);
    } else {
      serialized = jsonEncode(newTargetIds.isEmpty ? null : newTargetIds.first);
    }

    await _cellsDao.upsertCell(
      rowId: sourceRowId,
      propertyId: property.id,
      valueJson: serialized,
    );

    // If 2-way relation, update reciprocal cells on target rows
    if (isTwoWay && reciprocalPropId != null) {
      final added = newTargetIds.where((id) => !oldTargetIds.contains(id)).toList();
      final removed = oldTargetIds.where((id) => !newTargetIds.contains(id)).toList();

      for (final targetId in added) {
        await _addReciprocalLink(targetRowId: targetId, reciprocalPropId: reciprocalPropId, sourceRowId: sourceRowId);
      }

      for (final targetId in removed) {
        await _removeReciprocalLink(targetRowId: targetId, reciprocalPropId: reciprocalPropId, sourceRowId: sourceRowId);
      }
    }
  }

  Future<void> _addReciprocalLink({
    required String targetRowId,
    required String reciprocalPropId,
    required String sourceRowId,
  }) async {
    final cell = await _cellsDao.getCell(targetRowId, reciprocalPropId);
    List<String> list = [];
    if (cell?.valueJson != null) {
      final decoded = jsonDecode(cell!.valueJson!);
      if (decoded is List) {
        list = List<String>.from(decoded);
      } else if (decoded is String) {
        list = [decoded];
      }
    }
    if (!list.contains(sourceRowId)) {
      list.add(sourceRowId);
      await _cellsDao.upsertCell(
        rowId: targetRowId,
        propertyId: reciprocalPropId,
        valueJson: jsonEncode(list),
      );
    }
  }

  Future<void> _removeReciprocalLink({
    required String targetRowId,
    required String reciprocalPropId,
    required String sourceRowId,
  }) async {
    final cell = await _cellsDao.getCell(targetRowId, reciprocalPropId);
    if (cell?.valueJson == null) return;
    final decoded = jsonDecode(cell!.valueJson!);
    if (decoded is List) {
      final list = List<String>.from(decoded);
      list.remove(sourceRowId);
      await _cellsDao.upsertCell(
        rowId: targetRowId,
        propertyId: reciprocalPropId,
        valueJson: jsonEncode(list),
      );
    } else if (decoded == sourceRowId) {
      await _cellsDao.upsertCell(
        rowId: targetRowId,
        propertyId: reciprocalPropId,
        valueJson: null,
      );
    }
  }

  @override
  Future<dynamic> getPropertyValue({
    required String rowId,
    required String propertyId,
  }) async {
    final cell = await _cellsDao.getCell(rowId, propertyId);
    if (cell == null || cell.valueJson == null) return null;
    return jsonDecode(cell.valueJson!);
  }

  @override
  Future<void> deleteRow(String rowId) async {
    final row = await _rowsDao.getRowById(rowId);
    if (row == null) return;

    await _db.transaction(() async {
      // 1. Maintain referential integrity across relation cells in other databases
      final referencingCells = await _cellsDao.findRelationCellsContaining(rowId);
      for (final cell in referencingCells) {
        if (cell.valueJson == null) continue;
        final decoded = jsonDecode(cell.valueJson!);
        if (decoded is List) {
          final list = List<dynamic>.from(decoded);
          if (list.remove(rowId)) {
            await _cellsDao.upsertCell(
              rowId: cell.rowId,
              propertyId: cell.propertyId,
              valueJson: jsonEncode(list),
            );
          }
        } else if (decoded == rowId) {
          await _cellsDao.upsertCell(
            rowId: cell.rowId,
            propertyId: cell.propertyId,
            valueJson: null,
          );
        }
      }

      // 2. Delete row from database_rows (cascades to cells)
      await _rowsDao.deleteRow(rowId);

      // 3. Delete underlying page (cascades to blocks)
      await _pagesDao.deletePage(row.pageId);
    });
  }

  @override
  Future<ViewEntity> createView({
    required String databaseId,
    required String name,
    required DatabaseViewType type,
    Map<String, dynamic>? config,
  }) async {
    final views = await _viewsDao.getViewsForDatabase(databaseId);
    final viewId = 'view_${DateTime.now().microsecondsSinceEpoch}_${views.length}';
    final now = DateTime.now();
    final effectiveConfig = config ?? {};

    await _viewsDao.insertView(
      DatabaseViewsTableCompanion.insert(
        id: viewId,
        databaseId: databaseId,
        name: Value(name),
        viewType: type.name,
        sortOrder: Value(views.length.toDouble()),
        configJson: Value(jsonEncode(effectiveConfig)),
        createdAt: now,
        updatedAt: now,
      ),
    );

    return ViewEntity(
      id: viewId,
      databaseId: databaseId,
      name: name,
      type: type,
      config: effectiveConfig,
    );
  }

  @override
  Future<dynamic> evaluateFormula({
    required String rowId,
    required String expression,
    Set<String>? visitedProperties,
  }) async {
    final row = await _rowsDao.getRowById(rowId);
    if (row == null) return null;

    final props = await _propertiesDao.getPropertiesForDatabase(row.databaseId);
    final cells = await _cellsDao.getCellsForRow(rowId);

    final valuesMap = <String, dynamic>{};
    for (final prop in props) {
      final cell = cells.where((c) => c.propertyId == prop.id).firstOrNull;
      if (cell != null && cell.valueJson != null) {
        valuesMap[prop.name] = jsonDecode(cell.valueJson!);
      }
    }

    final context = MapFormulaContext(
      propertyValues: valuesMap,
      activeCallStack: visitedProperties,
    );

    return await _formulaEvaluator.evaluateExpression(expression, context);
  }

  @override
  Future<dynamic> computeRollup({
    required String rowId,
    required String relationPropertyId,
    required String targetPropertyId,
    required RollupFunction function,
  }) async {
    final relVal = await getPropertyValue(rowId: rowId, propertyId: relationPropertyId);
    List<String> relatedRowIds = [];
    if (relVal is String) {
      relatedRowIds = [relVal];
    } else if (relVal is List) {
      relatedRowIds = relVal.map((e) => e.toString()).toList();
    }

    if (relatedRowIds.isEmpty) {
      return RollupCalculator.compute(values: [], function: function);
    }

    final targetValues = <dynamic>[];
    for (final rId in relatedRowIds) {
      final v = await getPropertyValue(rowId: rId, propertyId: targetPropertyId);
      if (v != null) targetValues.add(v);
    }

    return RollupCalculator.compute(values: targetValues, function: function);
  }

  PropertyEntity _mapPropertyEntryToEntity(DatabasePropertyEntry entry) {
    Map<String, dynamic> config = {};
    try {
      config = jsonDecode(entry.configJson) as Map<String, dynamic>;
    } catch (_) {}

    return PropertyEntity(
      id: entry.id,
      databaseId: entry.databaseId,
      name: entry.name,
      type: PropertyTypeParsing.fromString(entry.propertyType),
      config: config,
    );
  }

  RowEntity _mapRowEntryToEntity(DatabaseRowEntry entry) {
    return RowEntity(
      id: entry.id,
      databaseId: entry.databaseId,
      pageId: entry.pageId,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
    );
  }

  CellEntity _mapCellEntryToEntity(DatabaseCellEntry entry) {
    dynamic val;
    if (entry.valueJson != null) {
      try {
        val = jsonDecode(entry.valueJson!);
      } catch (_) {
        val = entry.valueJson;
      }
    }
    return CellEntity(
      id: entry.id,
      rowId: entry.rowId,
      propertyId: entry.propertyId,
      value: val,
    );
  }

  ViewEntity _mapViewEntryToEntity(DatabaseViewEntry entry) {
    Map<String, dynamic> config = {};
    try {
      config = jsonDecode(entry.configJson) as Map<String, dynamic>;
    } catch (_) {}

    final type = DatabaseViewType.values.firstWhere(
      (e) => e.name.toLowerCase() == entry.viewType.toLowerCase(),
      orElse: () => DatabaseViewType.table,
    );

    return ViewEntity(
      id: entry.id,
      databaseId: entry.databaseId,
      name: entry.name,
      type: type,
      config: config,
    );
  }
}
