// Test Reference Harness: Relational Database Engine & 6 Views
// Grounded in PROJECT.md (F08–F16, AC2, AC8)

import 'dart:async';
import '../contracts/database_contracts.dart';
import 'test_workspace_harness.dart';

class TestDatabaseEngine implements IDatabaseEngineRepository {
  final TestWorkspaceEngine workspaceEngine;

  final Map<String, DatabaseEntity> _databases = {};
  final Map<String, List<PropertyEntity>> _properties = {};
  final Map<String, List<RowEntity>> _rows = {};
  final Map<String, Map<String, CellEntity>> _cells = {}; // rowId -> (propertyId -> Cell)
  final Map<String, List<ViewEntity>> _views = {};

  final Map<String, StreamController<DatabaseEntity>> _dbControllers = {};
  final Map<String, StreamController<List<PropertyEntity>>> _propertyControllers = {};
  final Map<String, StreamController<List<RowEntity>>> _rowControllers = {};
  final Map<String, StreamController<List<CellEntity>>> _cellControllers = {};
  final Map<String, StreamController<List<ViewEntity>>> _viewControllers = {};

  TestDatabaseEngine({required this.workspaceEngine});

  void _notifyDb(String dbId) {
    if (_dbControllers.containsKey(dbId) && _databases.containsKey(dbId)) {
      _dbControllers[dbId]!.add(_databases[dbId]!);
    }
    if (_propertyControllers.containsKey(dbId)) {
      _propertyControllers[dbId]!.add(_properties[dbId] ?? []);
    }
    if (_rowControllers.containsKey(dbId)) {
      _rowControllers[dbId]!.add(_rows[dbId] ?? []);
    }
    if (_cellControllers.containsKey(dbId)) {
      final allCells = <CellEntity>[];
      for (final r in (_rows[dbId] ?? [])) {
        if (_cells.containsKey(r.id)) {
          allCells.addAll(_cells[r.id]!.values);
        }
      }
      _cellControllers[dbId]!.add(allCells);
    }
    if (_viewControllers.containsKey(dbId)) {
      _viewControllers[dbId]!.add(_views[dbId] ?? []);
    }
  }

  @override
  Stream<DatabaseEntity> watchDatabase(String databaseId) {
    _dbControllers.putIfAbsent(databaseId, () => StreamController.broadcast());
    _notifyDb(databaseId);
    return _dbControllers[databaseId]!.stream;
  }

  @override
  Stream<List<PropertyEntity>> watchProperties(String databaseId) {
    _propertyControllers.putIfAbsent(databaseId, () => StreamController.broadcast());
    _notifyDb(databaseId);
    return _propertyControllers[databaseId]!.stream;
  }

  @override
  Stream<List<RowEntity>> watchRows(String databaseId) {
    _rowControllers.putIfAbsent(databaseId, () => StreamController.broadcast());
    _notifyDb(databaseId);
    return _rowControllers[databaseId]!.stream;
  }

  @override
  Stream<List<CellEntity>> watchCells(String databaseId) {
    _cellControllers.putIfAbsent(databaseId, () => StreamController.broadcast());
    _notifyDb(databaseId);
    return _cellControllers[databaseId]!.stream;
  }

  @override
  Stream<List<ViewEntity>> watchViews(String databaseId) {
    _viewControllers.putIfAbsent(databaseId, () => StreamController.broadcast());
    _notifyDb(databaseId);
    return _viewControllers[databaseId]!.stream;
  }

  @override
  Future<DatabaseEntity> createDatabase({
    required String title,
    required String pageId,
  }) async {
    final dbId = 'db_${DateTime.now().microsecondsSinceEpoch}_${_databases.length}';
    final db = DatabaseEntity(id: dbId, title: title, pageId: pageId);
    _databases[dbId] = db;
    _properties[dbId] = [];
    _rows[dbId] = [];
    _views[dbId] = [];

    // Default title property
    await addProperty(
      databaseId: dbId,
      name: 'Name',
      type: PropertyType.title,
    );

    // Default Table view
    await createView(
      databaseId: dbId,
      name: 'Table View',
      type: DatabaseViewType.table,
    );

    _notifyDb(dbId);
    return db;
  }

  @override
  Future<PropertyEntity> addProperty({
    required String databaseId,
    required String name,
    required PropertyType type,
    Map<String, dynamic>? config,
  }) async {
    final list = _properties[databaseId] ?? [];
    if (list.any((p) => p.name.toLowerCase() == name.toLowerCase())) {
      throw ArgumentError('Duplicate property name in database: $name');
    }
    final prop = PropertyEntity(
      id: 'prop_${DateTime.now().microsecondsSinceEpoch}_${list.length}',
      databaseId: databaseId,
      name: name,
      type: type,
      config: config,
    );
    list.add(prop);
    _properties[databaseId] = list;
    _notifyDb(databaseId);
    return prop;
  }

  @override
  Future<String> createRow(String databaseId) async {
    final db = _databases[databaseId];
    if (db == null) throw ArgumentError('Database not found: $databaseId');

    // Dual Identity Paradigm: creates underlying PageEntity with isDatabaseRow = true
    final page = await workspaceEngine.createPage(
      parentPageId: db.pageId,
      title: 'Untitled Row',
      isDatabaseRow: true,
    );

    final rowId = 'row_${DateTime.now().microsecondsSinceEpoch}_${_rows[databaseId]?.length ?? 0}';
    final row = RowEntity(
      id: rowId,
      databaseId: databaseId,
      pageId: page.id,
    );

    _rows.putIfAbsent(databaseId, () => []).add(row);
    _cells[rowId] = {};
    _notifyDb(databaseId);
    return rowId;
  }

  @override
  Future<void> updatePropertyValue({
    required String rowId,
    required String propertyId,
    dynamic value,
  }) async {
    _cells.putIfAbsent(rowId, () => {});
    _cells[rowId]![propertyId] = CellEntity(
      id: 'cell_${rowId}_$propertyId',
      rowId: rowId,
      propertyId: propertyId,
      value: value,
    );

    // Find database ID for row
    for (final dbId in _rows.keys) {
      if (_rows[dbId]!.any((r) => r.id == rowId)) {
        _notifyDb(dbId);
        break;
      }
    }
  }

  @override
  Future<dynamic> getPropertyValue({
    required String rowId,
    required String propertyId,
  }) async {
    return _cells[rowId]?[propertyId]?.value;
  }

  @override
  Future<void> deleteRow(String rowId) async {
    String? foundDbId;
    String? pageIdToDelete;

    for (final dbId in _rows.keys) {
      final index = _rows[dbId]!.indexWhere((r) => r.id == rowId);
      if (index != -1) {
        foundDbId = dbId;
        pageIdToDelete = _rows[dbId]![index].pageId;
        _rows[dbId]!.removeAt(index);
        break;
      }
    }

    _cells.remove(rowId);

    // Referential integrity: clean up references in relation cells
    for (final rCells in _cells.values) {
      for (final cell in rCells.values) {
        if (cell.value is List) {
          final list = List<dynamic>.from(cell.value);
          if (list.remove(rowId)) {
            rCells[cell.propertyId] = cell.copyWith(value: list);
          }
        } else if (cell.value == rowId) {
          rCells[cell.propertyId] = cell.copyWith(value: null);
        }
      }
    }

    if (pageIdToDelete != null) {
      await workspaceEngine.deletePage(pageIdToDelete);
    }
    if (foundDbId != null) {
      _notifyDb(foundDbId);
    }
  }

  @override
  Future<ViewEntity> createView({
    required String databaseId,
    required String name,
    required DatabaseViewType type,
    Map<String, dynamic>? config,
  }) async {
    final list = _views.putIfAbsent(databaseId, () => []);
    final view = ViewEntity(
      id: 'view_${DateTime.now().microsecondsSinceEpoch}_${list.length}',
      databaseId: databaseId,
      name: name,
      type: type,
      config: config,
    );
    list.add(view);
    _notifyDb(databaseId);
    return view;
  }

  @override
  Future<dynamic> evaluateFormula({
    required String rowId,
    required String expression,
    Set<String>? visitedProperties,
  }) async {
    final visited = visitedProperties ?? <String>{};

    // Cycle detection across dependencies
    if (visited.contains(expression)) {
      return '#CYCLE!';
    }
    visited.add(expression);

    // Simple AST evaluator for basic math and property lookups
    try {
      var exp = expression.trim();
      
      // Check for division by zero pattern
      if (exp.contains('/ 0') || exp.contains('/0')) {
        return '#DIV/0!';
      }

      // Prop replacement: prop("Name") -> actual value
      final propRegex = RegExp(r'prop\("([^"]+)"\)');
      final matches = propRegex.allMatches(exp);
      for (final m in matches) {
        final propName = m.group(1)!;
        // Resolve propName to propertyId
        String? targetPropId;
        for (final pList in _properties.values) {
          final match = pList.where((p) => p.name == propName);
          if (match.isNotEmpty) {
            targetPropId = match.first.id;
            break;
          }
        }
        if (targetPropId == null) return null;
        final val = await getPropertyValue(rowId: rowId, propertyId: targetPropId);
        if (val == null) return null;
        exp = exp.replaceAll(m.group(0)!, val.toString());
      }

      // Simple evaluation of basic math expressions: A + B, A * B, A - B, A / B
      if (RegExp(r'^\s*(\d+(\.\d+)?)\s*([\+\-\*\/])\s*(\d+(\.\d+)?)\s*$').hasMatch(exp)) {
        final match = RegExp(r'^\s*(\d+(\.\d+)?)\s*([\+\-\*\/])\s*(\d+(\.\d+)?)\s*$').firstMatch(exp)!;
        final left = double.parse(match.group(1)!);
        final op = match.group(3)!;
        final right = double.parse(match.group(4)!);

        if (op == '/' && right == 0.0) return '#DIV/0!';
        switch (op) {
          case '+':
            return left + right;
          case '-':
            return left - right;
          case '*':
            return left * right;
          case '/':
            return left / right;
        }
      }

      // Number literal
      final numVal = num.tryParse(exp);
      if (numVal != null) return numVal;

      return exp;
    } catch (_) {
      return '#ERROR!';
    }
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
      relatedRowIds = relVal.cast<String>();
    }

    if (relatedRowIds.isEmpty) {
      switch (function) {
        case RollupFunction.count:
        case RollupFunction.sum:
        case RollupFunction.percentChecked:
          return 0;
        case RollupFunction.average:
        case RollupFunction.min:
        case RollupFunction.max:
          return null;
      }
    }

    final targetValues = <dynamic>[];
    for (final rId in relatedRowIds) {
      final v = await getPropertyValue(rowId: rId, propertyId: targetPropertyId);
      if (v != null) targetValues.add(v);
    }

    if (targetValues.isEmpty) {
      switch (function) {
        case RollupFunction.count:
        case RollupFunction.sum:
        case RollupFunction.percentChecked:
          return 0;
        case RollupFunction.average:
        case RollupFunction.min:
        case RollupFunction.max:
          return null;
      }
    }

    switch (function) {
      case RollupFunction.count:
        return targetValues.length;
      case RollupFunction.sum:
        return targetValues.fold<num>(0, (acc, curr) => acc + (curr is num ? curr : 0));
      case RollupFunction.average:
        final nums = targetValues.whereType<num>().toList();
        if (nums.isEmpty) return null;
        return nums.reduce((a, b) => a + b) / nums.length;
      case RollupFunction.min:
        final nums = targetValues.whereType<num>().toList();
        if (nums.isEmpty) return null;
        return nums.reduce((a, b) => a < b ? a : b);
      case RollupFunction.max:
        final nums = targetValues.whereType<num>().toList();
        if (nums.isEmpty) return null;
        return nums.reduce((a, b) => a > b ? a : b);
      case RollupFunction.percentChecked:
        final bools = targetValues.whereType<bool>().toList();
        if (bools.isEmpty) return 0.0;
        final checkedCount = bools.where((b) => b).length;
        return (checkedCount / bools.length) * 100.0;
    }
  }
}
