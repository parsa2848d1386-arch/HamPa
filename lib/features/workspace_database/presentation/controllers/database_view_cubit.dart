import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/database_view_type.dart';
import '../../domain/models/view_entity.dart';
import '../../domain/models/cell_entity.dart';
import '../../domain/models/row_entity.dart';
import '../../domain/models/filter_criteria.dart';
import '../../domain/models/sort_criteria.dart';
import '../../domain/models/column_layout.dart';
import '../../domain/models/aggregation_type.dart';
import '../../domain/repositories/i_database_engine_repository.dart';
import 'database_view_state.dart';

class DatabaseViewCubit extends Cubit<DatabaseViewState> {
  final IDatabaseEngineRepository _repository;
  final String _databaseId;

  StreamSubscription? _dbSub;
  StreamSubscription? _propsSub;
  StreamSubscription? _rowsSub;
  StreamSubscription? _cellsSub;
  StreamSubscription? _viewsSub;

  DatabaseViewCubit({
    required IDatabaseEngineRepository repository,
    required String databaseId,
  })  : _repository = repository,
        _databaseId = databaseId,
        super(const DatabaseViewState()) {
    _initStreams();
  }

  void _initStreams() {
    emit(state.copyWith(status: DatabaseViewStatus.loading));

    _dbSub = _repository.watchDatabase(_databaseId).listen(
      (db) {
        emit(state.copyWith(database: db));
      },
      onError: (err) {
        emit(state.copyWith(
          status: DatabaseViewStatus.error,
          errorMessage: err.toString(),
        ));
      },
    );

    _propsSub = _repository.watchProperties(_databaseId).listen((props) {
      final layouts = Map<String, ColumnLayout>.from(state.columnLayouts);
      for (int i = 0; i < props.length; i++) {
        final p = props[i];
        layouts.putIfAbsent(p.id, () => ColumnLayout(propertyId: p.id, orderIndex: i));
      }
      emit(state.copyWith(properties: props, columnLayouts: layouts));
      _recomputeVisibleRows();
    });

    _viewsSub = _repository.watchViews(_databaseId).listen((views) {
      final active = state.activeView ?? (views.isNotEmpty ? views.first : null);
      emit(state.copyWith(views: views, activeView: active));
      _applyActiveViewConfig(active);
    });

    _rowsSub = _repository.watchRows(_databaseId).listen((rows) {
      emit(state.copyWith(rawRows: rows));
      _recomputeVisibleRows();
    });

    _cellsSub = _repository.watchCells(_databaseId).listen((cells) {
      final cellMap = <String, Map<String, CellEntity>>{};
      for (final cell in cells) {
        cellMap.putIfAbsent(cell.rowId, () => {})[cell.propertyId] = cell;
      }
      emit(state.copyWith(cellsByRow: cellMap));
      _recomputeVisibleRows();
    });
  }

  void _applyActiveViewConfig(ViewEntity? view) {
    if (view == null) return;
    final config = view.config;
    emit(state.copyWith(
      calendarDisplayMode: config['displayMode'] as String? ?? state.calendarDisplayMode,
      galleryCardSize: config['cardSize'] as String? ?? state.galleryCardSize,
    ));
    _recomputeVisibleRows();
  }

  void _recomputeVisibleRows() {
    var result = List<RowEntity>.from(state.rawRows);

    // 1. Search Query filter (matches title or any cell string)
    if (state.searchQuery.isNotEmpty) {
      final q = state.searchQuery.toLowerCase();
      result = result.where((r) {
        final rowCells = state.cellsByRow[r.id];
        if (rowCells == null) return false;
        return rowCells.values.any((c) => c.value?.toString().toLowerCase().contains(q) ?? false);
      }).toList();
    }

    // 2. Active Filters
    for (final filter in state.filters) {
      result = result.where((r) {
        final val = state.getCellValue(r.id, filter.propertyId);
        return filter.evaluate(val);
      }).toList();
    }

    // 3. Active Sorts
    if (state.sorts.isNotEmpty) {
      result.sort((a, b) {
        for (final sort in state.sorts) {
          final valA = state.getCellValue(a.id, sort.propertyId);
          final valB = state.getCellValue(b.id, sort.propertyId);
          final cmp = sort.compare(valA, valB);
          if (cmp != 0) return cmp;
        }
        return a.createdAt.compareTo(b.createdAt);
      });
    }

    emit(state.copyWith(
      status: DatabaseViewStatus.loaded,
      visibleRows: result,
    ));
  }

  // --- View Switcher Operations ---
  void selectView(String viewId) {
    final target = state.views.firstWhere((v) => v.id == viewId, orElse: () => state.views.first);
    emit(state.copyWith(activeView: target));
    _applyActiveViewConfig(target);
  }

  Future<void> createView({
    required String name,
    required DatabaseViewType type,
    Map<String, dynamic>? config,
  }) async {
    final newView = await _repository.createView(
      databaseId: _databaseId,
      name: name,
      type: type,
      config: config,
    );
    emit(state.copyWith(activeView: newView));
  }

  // --- Inline Cell & Row Mutations ---
  Future<void> updateCellValue({
    required String rowId,
    required String propertyId,
    required dynamic value,
  }) async {
    await _repository.updatePropertyValue(
      rowId: rowId,
      propertyId: propertyId,
      value: value,
    );
  }

  Future<String> addNewRow() async {
    final newRowId = await _repository.createRow(_databaseId);
    return newRowId;
  }

  Future<void> deleteRow(String rowId) async {
    await _repository.deleteRow(rowId);
  }

  // --- Search, Filter & Sort ---
  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
    _recomputeVisibleRows();
  }

  void addFilter(FilterCriteria filter) {
    final updated = List<FilterCriteria>.from(state.filters)..add(filter);
    emit(state.copyWith(filters: updated));
    _recomputeVisibleRows();
  }

  void removeFilter(String filterId) {
    final updated = state.filters.where((f) => f.id != filterId).toList();
    emit(state.copyWith(filters: updated));
    _recomputeVisibleRows();
  }

  void clearFilters() {
    emit(state.copyWith(filters: []));
    _recomputeVisibleRows();
  }

  void setSorts(List<SortCriteria> sorts) {
    emit(state.copyWith(sorts: sorts));
    _recomputeVisibleRows();
  }

  // --- Layout, Resizing & Aggregation ---
  void updateColumnWidth(String propertyId, double width) {
    final current = state.columnLayouts[propertyId];
    if (current == null) return;
    final updated = Map<String, ColumnLayout>.from(state.columnLayouts);
    updated[propertyId] = current.copyWith(width: width.clamp(80.0, 600.0));
    emit(state.copyWith(columnLayouts: updated));
  }

  void togglePropertyVisibility(String propertyId) {
    final current = state.columnLayouts[propertyId];
    if (current == null) return;
    final updated = Map<String, ColumnLayout>.from(state.columnLayouts);
    updated[propertyId] = current.copyWith(isVisible: !current.isVisible);
    emit(state.copyWith(columnLayouts: updated));
  }

  void reorderColumns(int oldIndex, int newIndex) {
    final sortedLayouts = state.columnLayouts.values.toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    if (oldIndex < newIndex) newIndex -= 1;
    final item = sortedLayouts.removeAt(oldIndex);
    sortedLayouts.insert(newIndex, item);

    final updated = <String, ColumnLayout>{};
    for (int i = 0; i < sortedLayouts.length; i++) {
      updated[sortedLayouts[i].propertyId] = sortedLayouts[i].copyWith(orderIndex: i);
    }
    emit(state.copyWith(columnLayouts: updated));
  }

  void setFooterAggregation(String propertyId, AggregationType type) {
    final map = Map<String, AggregationType>.from(state.footerAggregations);
    map[propertyId] = type;
    emit(state.copyWith(footerAggregations: map));
  }

  // --- Active Cell Editing ---
  void startCellEditing(String rowId, String propertyId) {
    emit(state.copyWith(
      activeEditingRowId: rowId,
      activeEditingPropertyId: propertyId,
    ));
  }

  void stopCellEditing() {
    emit(state.copyWith(clearActiveEditing: true));
  }

  // --- Kanban & Interactive View Mutations ---
  void toggleKanbanLaneCollapse(String laneKey) {
    final set = Set<String>.from(state.collapsedKanbanLanes);
    if (set.contains(laneKey)) {
      set.remove(laneKey);
    } else {
      set.add(laneKey);
    }
    emit(state.copyWith(collapsedKanbanLanes: set));
  }

  Future<void> moveKanbanCard({
    required String rowId,
    required String groupByPropertyId,
    required dynamic newLaneValue,
  }) async {
    await updateCellValue(
      rowId: rowId,
      propertyId: groupByPropertyId,
      value: newLaneValue,
    );
  }

  // --- Calendar & Timeline Rescheduling ---
  void setCalendarDisplayMode(String mode) {
    emit(state.copyWith(calendarDisplayMode: mode));
  }

  Future<void> rescheduleRow({
    required String rowId,
    required String datePropertyId,
    required String newDateIso,
  }) async {
    await updateCellValue(
      rowId: rowId,
      propertyId: datePropertyId,
      value: newDateIso,
    );
  }

  void setGalleryCardSize(String size) {
    emit(state.copyWith(galleryCardSize: size));
  }

  @override
  Future<void> close() {
    _dbSub?.cancel();
    _propsSub?.cancel();
    _rowsSub?.cancel();
    _cellsSub?.cancel();
    _viewsSub?.cancel();
    return super.close();
  }
}
