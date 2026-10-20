# Milestone 2 Blueprint: Relational Database 6 Views & UI

## 1. Observation

### 1.1 Direct Repository Evidence
- **PROJECT.md (`c:\parsa\HamPA\PROJECT.md`)**:
  - Lines 29–37: Defines Features F08 through F16:
    - **F08**: Rich Property Schema Engine (text, number, select, multi-select, status, date, tags, relation, formula, rollup).
    - **F12**: Table View with Inline Editing (virtualized tabular grid, inline cell editors, footer aggregations).
    - **F13**: Kanban Board View (drag-and-drop card columns grouped by status or select property).
    - **F14**: Calendar View (Month/Week grid, date-mapped task chips, multi-day spanning).
    - **F15**: Timeline / Gantt View (duration bar chart, milestone markers, drag dependency connector arrows).
    - **F16**: List & Gallery Views (minimalist high-density list and responsive card cover gallery).
  - Lines 41, 65: Acceptance Criteria AC2:
    > "Database views switch between Table, Kanban, Calendar, and Timeline with identical underlying data state."
  - Lines 13–15: Dual Identity Paradigm:
    > "Every row in a relational database has a 1:1 dual identity as an underlying `Page` (`is_database_row = TRUE`). Opening any row presents a complete block-based document workspace with nested blocks, embedded databases, and in-session scratchpads."
  - Lines 90–102: Interface Contract 2 (`IDatabaseEngineRepository`):
    - Streams: `watchDatabase`, `watchProperties`, `watchRows`, `watchCells`, `watchViews`.
    - Mutations: `updatePropertyValue`, `createRow`, `deleteRow`.

- **ORIGINAL_REQUEST.md (`c:\parsa\HamPA\.agents\teamwork\ORIGINAL_REQUEST.md`)**:
  - Lines 12–18 (R1): Notion Core Relational database engine supporting 6 distinct views: Table, Kanban, Calendar, Timeline/Gantt, List, and Gallery.
  - Lines 41: AC2 verification requirement.

- **pubspec.yaml (`c:\parsa\HamPA\pubspec.yaml`)**:
  - `flutter_bloc: ^9.1.1` (bloc state management)
  - `provider: ^6.1.5`
  - `go_router: ^18.1.0`
  - `table_calendar: ^3.3.0` (calendar grid utilities)
  - `fl_chart: ^1.2.0`
  - `intl: ^0.20.2`
  - `bloc_test: ^10.0.0`
  - `mocktail: ^1.0.5`

- **Existing Contracts and Tests (`c:\parsa\HamPA\test\e2e\contracts\database_contracts.dart`)**:
  - Lines 4–34: Enums `PropertyType`, `RollupFunction`, `DatabaseViewType` (`table`, `kanban`, `calendar`, `timeline`, `list`, `gallery`).
  - Lines 36–155: Entities `PropertyEntity`, `DatabaseEntity`, `RowEntity`, `CellEntity`, `ViewEntity`.
  - Lines 157–203: Definition of `IDatabaseEngineRepository`.

- **Existing M1 Precedents**:
  - `lib/features/workspace_editor/domain/models/page_entity.dart`: Line 10 already includes `final bool isDatabaseRow;`.
  - `lib/features/workspace_editor/presentation/controllers/page_tree_cubit.dart`: Implements reactive StreamSubscription pattern with Drift DAOs and immutable state `copyWith`.

---

## 2. Logic Chain

```
[M2 Feature Inventory F12-F16 & AC2]
                  │
                  ▼
[Unified IDatabaseEngineRepository Streams (db, properties, rows, cells, views)]
                  │
                  ▼
[Single Source of Truth: DatabaseViewCubit & DatabaseViewState]
  ├── Active Database & Active View
  ├── Filter Criteria (AND/OR, operators)
  ├── Sort Criteria (Property, Asc/Desc)
  ├── Search Query
  ├── Column Layouts (Widths, Order, Visibility)
  └── Selection State (Active Cell, Selected Rows)
                  │
                  ▼
[Top Toolbar: ViewSwitcherToolbar + Action Controls]
  ├── 6 View Tabs (Table, Kanban, Calendar, Timeline, List, Gallery)
  ├── Filter Popover & Sort Popover
  ├── Column Visibility & Search
  └── "+ New Row" (Dispatches createRow -> creates Page with isDatabaseRow=true)
                  │
                  ▼
       ┌──────────┼──────────┬──────────┬──────────┬──────────┐
       ▼          ▼          ▼          ▼          ▼          ▼
   [View 1]   [View 2]   [View 3]   [View 4]   [View 5]   [View 6]
    Table      Kanban    Calendar   Timeline     List     Gallery
   (F12)      (F13)      (F14)      (F15)      (F16)      (F16)
       │          │          │          │          │          │
       └──────────┴──────────┴──────────┴──────────┴──────────┘
                  │
                  ▼
[Shared Polymorphic Inline Cell Editors (11 Property Types)]
  Title, Text, Number, Select, MultiSelect, Status, Date,
  Checkbox, Relation, Formula, Rollup
                  │
                  ▼
[Zero Data Loss On Switch (AC2 Guaranteed via Shared Underlying State)]
```

1. **State Isolation vs Unified Projection**: If each view maintained its own disconnected state, switching views would cause synchronization lags, inconsistent filter states, and violate AC2. Therefore, `DatabaseViewCubit` acts as the single orchestrator. It manages the underlying database rows and cells directly from `IDatabaseEngineRepository` streams, and computes a projected dataset (`visibleRows`, `groupedLanes`, `calendarDays`, `timelineSpans`) according to the active view's configuration.
2. **AC2 Strict Guarantee**: Switching between views updates only the `activeViewId` in `DatabaseViewState`. The underlying rows and cells remain identical and immediately available in memory. An inline edit in Gallery View immediately modifies the underlying cell in SQLite, and switching back to Table View displays the updated value without reload.
3. **Inline Editing Architecture**: Table cells and cards must support direct in-place editing. By delegating cell editing to a polymorphic `InlineCellEditor` router, every property type (Text, Select, Date, Checkbox, Relation) renders both a display mode and an edit mode with full keyboard accessibility (Enter to commit, Escape to abort, Tab to advance).
4. **Interactive Gestures**:
   - Table: Column drag reordering (`onHorizontalDragUpdate`), edge resize handles (`GestureDetector`).
   - Kanban: Drag-and-drop cards between lanes using Flutter's `Draggable` and `DragTarget`, immediately invoking `updatePropertyValue`.
   - Calendar: Drag-to-reschedule across day cells and dragging from the "Unscheduled Items Drawer".
   - Timeline/Gantt: Duration bar dragging (time translation) and left/right handle dragging (duration resizing), with dependency arrows drawn via `CustomPainter`.
5. **Dual Identity Navigation**: Every row contains `row.pageId`. Tapping the "Open" button on any row or double-clicking the title in any of the 6 views navigates to the row's underlying document workspace (`BlockEditorView`), fulfilling the Dual Identity Paradigm.

---

## 3. Blueprint File-by-File Specification

### 3.1 Directory Tree Structure
```
c:\parsa\HamPA\
├── lib/
│   └── features/
│       └── workspace_database/
│           ├── domain/
│           │   └── models/
│           │       ├── database_entity.dart
│           │       ├── property_entity.dart
│           │       ├── row_entity.dart
│           │       ├── cell_entity.dart
│           │       ├── view_entity.dart
│           │       ├── filter_criteria.dart
│           │       ├── sort_criteria.dart
│           │       ├── column_layout.dart
│           │       └── aggregation_type.dart
│           ├── presentation/
│           │   ├── controllers/
│           │   │   ├── database_view_cubit.dart
│           │   │   └── database_view_state.dart
│           │   └── widgets/
│           │       ├── database_view_container.dart
│           │       ├── view_switcher/
│           │       │   ├── view_switcher_toolbar.dart
│           │       │   ├── filter_popover.dart
│           │       │   ├── sort_popover.dart
│           │       │   └── properties_visibility_sheet.dart
│           │       ├── views/
│           │       │   ├── table/
│           │       │   │   ├── table_view_widget.dart
│           │       │   │   ├── table_header_cell.dart
│           │       │   │   ├── table_cell_widget.dart
│           │       │   │   └── table_footer_aggregation_row.dart
│           │       │   ├── kanban/
│           │       │   │   ├── kanban_view_widget.dart
│           │       │   │   ├── kanban_lane_widget.dart
│           │       │   │   └── kanban_card_widget.dart
│           │       │   ├── calendar/
│           │       │   │   ├── calendar_view_widget.dart
│           │       │   │   ├── calendar_day_cell.dart
│           │       │   │   ├── calendar_event_chip.dart
│           │       │   │   └── unscheduled_items_drawer.dart
│           │       │   ├── timeline/
│           │       │   │   ├── timeline_view_widget.dart
│           │       │   │   ├── timeline_header_ruler.dart
│           │       │   │   ├── timeline_task_bar.dart
│           │       │   │   ├── timeline_milestone_marker.dart
│           │       │   │   └── timeline_dependency_painter.dart
│           │       │   ├── list/
│           │       │   │   ├── list_view_widget.dart
│           │       │   │   └── list_row_item.dart
│           │       │   └── gallery/
│           │       │       ├── gallery_view_widget.dart
│           │       │       └── gallery_card_widget.dart
│           │       └── cell_editors/
│           │           ├── inline_cell_editor.dart
│           │           ├── text_cell_editor.dart
│           │           ├── number_cell_editor.dart
│           │           ├── select_cell_editor.dart
│           │           ├── multi_select_cell_editor.dart
│           │           ├── status_cell_editor.dart
│           │           ├── date_cell_editor.dart
│           │           ├── checkbox_cell_editor.dart
│           │           ├── relation_cell_editor.dart
│           │           ├── formula_cell_display.dart
│           │           └── rollup_cell_display.dart
└── test/
    └── widget/
        ├── database_view_switcher_ac2_test.dart
        ├── table_view_inline_editing_test.dart
        ├── kanban_drag_and_drop_test.dart
        ├── calendar_reschedule_test.dart
        ├── timeline_gantt_test.dart
        ├── list_view_test.dart
        └── gallery_view_test.dart
```

---

### 3.2 Domain Models Specification

#### 1. `lib/features/workspace_database/domain/models/filter_criteria.dart`
```dart
enum FilterOperator {
  equals,
  notEquals,
  contains,
  doesNotContain,
  startsWith,
  endsWith,
  isEmpty,
  isNotEmpty,
  greaterThan,
  lessThan,
  greaterThanOrEqual,
  lessThanOrEqual,
  dateIs,
  dateBefore,
  dateAfter,
  dateToday,
  isChecked,
  isNotChecked,
}

enum Conjunction { and, or }

class FilterCriteria {
  final String id;
  final String propertyId;
  final FilterOperator operator;
  final dynamic value;
  final Conjunction conjunction;

  const FilterCriteria({
    required this.id,
    required this.propertyId,
    required this.operator,
    this.value,
    this.conjunction = Conjunction.and,
  });

  bool evaluate(dynamic cellValue) {
    switch (operator) {
      case FilterOperator.equals:
        return cellValue?.toString().toLowerCase() == value?.toString().toLowerCase();
      case FilterOperator.notEquals:
        return cellValue?.toString().toLowerCase() != value?.toString().toLowerCase();
      case FilterOperator.contains:
        return cellValue?.toString().toLowerCase().contains(value?.toString().toLowerCase() ?? '') ?? false;
      case FilterOperator.doesNotContain:
        return !(cellValue?.toString().toLowerCase().contains(value?.toString().toLowerCase() ?? '') ?? false);
      case FilterOperator.startsWith:
        return cellValue?.toString().toLowerCase().startsWith(value?.toString().toLowerCase() ?? '') ?? false;
      case FilterOperator.endsWith:
        return cellValue?.toString().toLowerCase().endsWith(value?.toString().toLowerCase() ?? '') ?? false;
      case FilterOperator.isEmpty:
        return cellValue == null || cellValue.toString().trim().isEmpty;
      case FilterOperator.isNotEmpty:
        return cellValue != null && cellValue.toString().trim().isNotEmpty;
      case FilterOperator.greaterThan:
        if (cellValue is num && value is num) return cellValue > value;
        return false;
      case FilterOperator.lessThan:
        if (cellValue is num && value is num) return cellValue < value;
        return false;
      case FilterOperator.greaterThanOrEqual:
        if (cellValue is num && value is num) return cellValue >= value;
        return false;
      case FilterOperator.lessThanOrEqual:
        if (cellValue is num && value is num) return cellValue <= value;
        return false;
      case FilterOperator.isChecked:
        return cellValue == true;
      case FilterOperator.isNotChecked:
        return cellValue != true;
      case FilterOperator.dateIs:
      case FilterOperator.dateBefore:
      case FilterOperator.dateAfter:
      case FilterOperator.dateToday:
        if (cellValue == null) return false;
        final cellDate = DateTime.tryParse(cellValue.toString());
        if (cellDate == null) return false;
        if (operator == FilterOperator.dateToday) {
          final now = DateTime.now();
          return cellDate.year == now.year && cellDate.month == now.month && cellDate.day == now.day;
        }
        final targetDate = DateTime.tryParse(value.toString());
        if (targetDate == null) return false;
        if (operator == FilterOperator.dateIs) {
          return cellDate.year == targetDate.year && cellDate.month == targetDate.month && cellDate.day == targetDate.day;
        } else if (operator == FilterOperator.dateBefore) {
          return cellDate.isBefore(targetDate);
        } else {
          return cellDate.isAfter(targetDate);
        }
    }
  }
}
```

#### 2. `lib/features/workspace_database/domain/models/sort_criteria.dart`
```dart
enum SortDirection { ascending, descending }

class SortCriteria {
  final String propertyId;
  final SortDirection direction;

  const SortCriteria({
    required this.propertyId,
    this.direction = SortDirection.ascending,
  });

  int compare(dynamic valA, dynamic valB) {
    if (valA == null && valB == null) return 0;
    if (valA == null) return direction == SortDirection.ascending ? 1 : -1;
    if (valB == null) return direction == SortDirection.ascending ? -1 : 1;

    int result = 0;
    if (valA is num && valB is num) {
      result = valA.compareTo(valB);
    } else if (valA is bool && valB is bool) {
      result = (valA == valB) ? 0 : (valA ? 1 : -1);
    } else {
      result = valA.toString().compareTo(valB.toString());
    }
    return direction == SortDirection.ascending ? result : -result;
  }
}
```

#### 3. `lib/features/workspace_database/domain/models/column_layout.dart`
```dart
class ColumnLayout {
  final String propertyId;
  final double width;
  final bool isVisible;
  final int orderIndex;

  const ColumnLayout({
    required this.propertyId,
    this.width = 160.0,
    this.isVisible = true,
    required this.orderIndex,
  });

  ColumnLayout copyWith({
    String? propertyId,
    double? width,
    bool? isVisible,
    int? orderIndex,
  }) {
    return ColumnLayout(
      propertyId: propertyId ?? this.propertyId,
      width: width ?? this.width,
      isVisible: isVisible ?? this.isVisible,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }
}
```

#### 4. `lib/features/workspace_database/domain/models/aggregation_type.dart`
```dart
enum AggregationType {
  none,
  countAll,
  countValues,
  countUnique,
  countEmpty,
  countNotEmpty,
  percentEmpty,
  percentNotEmpty,
  sum,
  average,
  median,
  min,
  max,
  range,
  percentChecked,
}

extension AggregationCalculation on AggregationType {
  String formatResult(dynamic result) {
    if (result == null) return '';
    if (result is double) {
      return result.toStringAsFixed(result.truncateToDouble() == result ? 0 : 2);
    }
    return result.toString();
  }

  dynamic compute(List<dynamic> values) {
    switch (this) {
      case AggregationType.none:
        return null;
      case AggregationType.countAll:
        return values.length;
      case AggregationType.countValues:
        return values.where((v) => v != null && v.toString().trim().isNotEmpty).length;
      case AggregationType.countUnique:
        return values.where((v) => v != null).toSet().length;
      case AggregationType.countEmpty:
        return values.where((v) => v == null || v.toString().trim().isEmpty).length;
      case AggregationType.countNotEmpty:
        return values.where((v) => v != null && v.toString().trim().isNotEmpty).length;
      case AggregationType.percentEmpty:
        if (values.isEmpty) return 0.0;
        final emptyCount = values.where((v) => v == null || v.toString().trim().isEmpty).length;
        return (emptyCount / values.length) * 100.0;
      case AggregationType.percentNotEmpty:
        if (values.isEmpty) return 0.0;
        final notEmpty = values.where((v) => v != null && v.toString().trim().isNotEmpty).length;
        return (notEmpty / values.length) * 100.0;
      case AggregationType.sum:
        final nums = values.whereType<num>();
        if (nums.isEmpty) return 0;
        return nums.fold<num>(0, (prev, curr) => prev + curr);
      case AggregationType.average:
        final nums = values.whereType<num>().toList();
        if (nums.isEmpty) return 0.0;
        return nums.fold<num>(0, (prev, curr) => prev + curr) / nums.length;
      case AggregationType.median:
        final nums = values.whereType<num>().toList()..sort();
        if (nums.isEmpty) return 0;
        final mid = nums.length ~/ 2;
        if (nums.length % 2 == 1) return nums[mid];
        return (nums[mid - 1] + nums[mid]) / 2.0;
      case AggregationType.min:
        final nums = values.whereType<num>();
        if (nums.isEmpty) return null;
        return nums.reduce((a, b) => a < b ? a : b);
      case AggregationType.max:
        final nums = values.whereType<num>();
        if (nums.isEmpty) return null;
        return nums.reduce((a, b) => a > b ? a : b);
      case AggregationType.range:
        final nums = values.whereType<num>().toList();
        if (nums.isEmpty) return 0;
        final minVal = nums.reduce((a, b) => a < b ? a : b);
        final maxVal = nums.reduce((a, b) => a > b ? a : b);
        return maxVal - minVal;
      case AggregationType.percentChecked:
        if (values.isEmpty) return 0.0;
        final checked = values.where((v) => v == true).length;
        return (checked / values.length) * 100.0;
    }
  }
}
```

---

### 3.3 State Management Blueprint (`DatabaseViewCubit` & `DatabaseViewState`)

#### 1. `lib/features/workspace_database/presentation/controllers/database_view_state.dart`
```dart
enum DatabaseViewStatus { initial, loading, loaded, error }

class DatabaseViewState {
  final DatabaseViewStatus status;
  final String? errorMessage;
  final DatabaseEntity? database;
  final List<PropertyEntity> properties;
  final List<ViewEntity> views;
  final ViewEntity? activeView;
  final List<RowEntity> rawRows;
  // Key: rowId -> (Key: propertyId -> CellEntity)
  final Map<String, Map<String, CellEntity>> cellsByRow;
  final List<RowEntity> visibleRows;
  final List<FilterCriteria> filters;
  final List<SortCriteria> sorts;
  final String searchQuery;
  final Map<String, ColumnLayout> columnLayouts;
  final Map<String, AggregationType> footerAggregations; // propertyId -> AggregationType
  final Set<String> selectedRowIds;
  final String? activeEditingRowId;
  final String? activeEditingPropertyId;
  final Set<String> collapsedKanbanLanes;
  final String calendarDisplayMode; // 'month' or 'week'
  final String galleryCardSize; // 'small', 'medium', 'large'

  const DatabaseViewState({
    this.status = DatabaseViewStatus.initial,
    this.errorMessage,
    this.database,
    this.properties = const [],
    this.views = const [],
    this.activeView,
    this.rawRows = const [],
    this.cellsByRow = const {},
    this.visibleRows = const [],
    this.filters = const [],
    this.sorts = const [],
    this.searchQuery = '',
    this.columnLayouts = const {},
    this.footerAggregations = const {},
    this.selectedRowIds = const {},
    this.activeEditingRowId,
    this.activeEditingPropertyId,
    this.collapsedKanbanLanes = const {},
    this.calendarDisplayMode = 'month',
    this.galleryCardSize = 'medium',
  });

  DatabaseViewState copyWith({
    DatabaseViewStatus? status,
    String? errorMessage,
    DatabaseEntity? database,
    List<PropertyEntity>? properties,
    List<ViewEntity>? views,
    ViewEntity? activeView,
    List<RowEntity>? rawRows,
    Map<String, Map<String, CellEntity>>? cellsByRow,
    List<RowEntity>? visibleRows,
    List<FilterCriteria>? filters,
    List<SortCriteria>? sorts,
    String? searchQuery,
    Map<String, ColumnLayout>? columnLayouts,
    Map<String, AggregationType>? footerAggregations,
    Set<String>? selectedRowIds,
    String? activeEditingRowId,
    bool clearActiveEditing = false,
    String? activeEditingPropertyId,
    Set<String>? collapsedKanbanLanes,
    String? calendarDisplayMode,
    String? galleryCardSize,
  }) {
    return DatabaseViewState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      database: database ?? this.database,
      properties: properties ?? this.properties,
      views: views ?? this.views,
      activeView: activeView ?? this.activeView,
      rawRows: rawRows ?? this.rawRows,
      cellsByRow: cellsByRow ?? this.cellsByRow,
      visibleRows: visibleRows ?? this.visibleRows,
      filters: filters ?? this.filters,
      sorts: sorts ?? this.sorts,
      searchQuery: searchQuery ?? this.searchQuery,
      columnLayouts: columnLayouts ?? this.columnLayouts,
      footerAggregations: footerAggregations ?? this.footerAggregations,
      selectedRowIds: selectedRowIds ?? this.selectedRowIds,
      activeEditingRowId: clearActiveEditing ? null : (activeEditingRowId ?? this.activeEditingRowId),
      activeEditingPropertyId: clearActiveEditing ? null : (activeEditingPropertyId ?? this.activeEditingPropertyId),
      collapsedKanbanLanes: collapsedKanbanLanes ?? this.collapsedKanbanLanes,
      calendarDisplayMode: calendarDisplayMode ?? this.calendarDisplayMode,
      galleryCardSize: galleryCardSize ?? this.galleryCardSize,
    );
  }

  dynamic getCellValue(String rowId, String propertyId) {
    return cellsByRow[rowId]?[propertyId]?.value;
  }
}
```

#### 2. `lib/features/workspace_database/presentation/controllers/database_view_cubit.dart`
```dart
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

    _dbSub = _repository.watchDatabase(_databaseId).listen((db) {
      emit(state.copyWith(database: db));
    });

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

    // 1. Search Query filter (matches title or any text cell)
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

  // --- Layout, Resizing & Aggregation ---
  void updateColumnWidth(String propertyId, double width) {
    final current = state.columnLayouts[propertyId];
    if (current == null) return;
    final updated = Map<String, ColumnLayout>.from(state.columnLayouts);
    updated[propertyId] = current.copyWith(width: width.clamp(80.0, 600.0));
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
```

---

### 3.4 View Switcher & Toolbar Specification (`ViewSwitcherToolbar`)

#### File: `lib/features/workspace_database/presentation/widgets/view_switcher/view_switcher_toolbar.dart`
- **UI Structure**:
  - Horizontal Row at top of database workspace.
  - Left: Scrollable View Tabs.
    - Each tab renders icon corresponding to view type (`Icons.table_chart` for Table, `Icons.view_kanban` for Kanban, `Icons.calendar_month` for Calendar, `Icons.view_timeline` for Timeline, `Icons.format_list_bulleted` for List, `Icons.grid_view` for Gallery).
    - View Name (e.g. "All Tasks", "Sprint Board").
    - Active indicator: Colored underline + semi-transparent primary container background.
    - Context Menu on long-press or trailing three-dots: "Rename", "Duplicate", "Delete View".
    - "+ Add View" button: Opens a lightweight modal with 6 view type tiles, allowing instant creation of a new view.
  - Right: Action Toolbar.
    - Search text field with quick shortcut (`Ctrl+F` / `Cmd+F`).
    - Filter Button: Badged icon showing active filter count; taps open `FilterPopover`.
    - Sort Button: Badged icon showing active sort count; taps open `SortPopover`.
    - Properties Button: Taps open `PropertiesVisibilitySheet`.
    - "+ New" Primary Button: Creates a new row in Drift SQLite, immediately adds it to `rawRows`, and focuses the Title cell.

---

### 3.5 View 1: Table View Specification (`TableViewWidget`)

#### Files:
1. `lib/features/workspace_database/presentation/widgets/views/table/table_view_widget.dart`
2. `lib/features/workspace_database/presentation/widgets/views/table/table_header_cell.dart`
3. `lib/features/workspace_database/presentation/widgets/views/table/table_cell_widget.dart`
4. `lib/features/workspace_database/presentation/widgets/views/table/table_footer_aggregation_row.dart`

- **Layout & Scrolling Architecture**:
  - Pinned Title Column on the left (fixed 220px width), with row numbering/checkbox and page open icon button (`Icons.open_in_new`).
  - Horizontally scrollable viewport for all subsequent property columns (`SingleChildScrollView(scrollDirection: Axis.horizontal)`).
  - Vertically scrollable row list (`ListView.builder`) synchronized between pinned column and horizontal viewport via a linked `ScrollController`.
- **Column Header Features (`TableHeaderCell`)**:
  - Property Type icon + Name.
  - Drag handle on header for column reordering.
  - Hover handle on right edge: `GestureDetector(onHorizontalDragUpdate: (details) => cubit.updateColumnWidth(propId, currentWidth + details.delta.dx))` with smooth resizing and visual guides.
  - Sort icon indicator (Asc/Desc) if active.
  - Filter badge indicator if filtered.
- **Inline Cell Editing (`TableCellWidget`)**:
  - Displays formatted text, pill, or badge in read-only mode.
  - Single-click activates cell selection.
  - Double-click or Enter activates inline editing, swapping read-only text with the corresponding `InlineCellEditor`.
  - Tab commits edit and shifts focus to adjacent right cell; Enter commits and shifts to cell directly below; Escape cancels.
- **Footer Aggregations (`TableFooterAggregationRow`)**:
  - Fixed bottom row matching column widths.
  - For each column, displays calculated aggregation (e.g. `Sum: 100`, `Avg: 85.0`, `Count: 4`, `75% Checked`).
  - Clicking footer opens dropdown to select `AggregationType` (Sum, Average, Min, Max, Count, etc.).

---

### 3.6 View 2: Kanban Board View Specification (`KanbanViewWidget`)

#### Files:
1. `lib/features/workspace_database/presentation/widgets/views/kanban/kanban_view_widget.dart`
2. `lib/features/workspace_database/presentation/widgets/views/kanban/kanban_lane_widget.dart`
3. `lib/features/workspace_database/presentation/widgets/views/kanban/kanban_card_widget.dart`

- **Lane Grouping Logic**:
  - Grouping Property: Driven by `view.config['groupByProperty']` (defaults to the first `status` or `select` property).
  - Lanes generated for all schema options (e.g. `['To Do', 'In Progress', 'Done']`).
  - Default "No Status" / "Unassigned" lane for rows where cell value is null.
- **Lane Collapsing / Expanding**:
  - Each lane header contains a chevron toggle button.
  - Collapsed Lane: Renders a compact vertical bar (width: 44px) with rotated text and card count badge.
  - Expanded Lane: Width: 280px, containing vertically scrollable card list and "+ Add Card" footer.
- **Drag-and-Drop Interaction**:
  - Card wrapped in `Draggable<RowEntity>` with `feedback`: Elevated card (8dp shadow, slight 2-degree tilt, 90% opacity).
  - `DragTarget<RowEntity>` on each lane:
    - Hovering over lane provides visual drop indicator (highlighted border).
    - Dropping calls `cubit.moveKanbanCard(rowId: row.id, groupByPropertyId: propId, newLaneValue: lane.value)`.
    - Instant local optimistic update + background Drift SQLite persistence.
- **Kanban Card Details (`KanbanCardWidget`)**:
  - Page Icon + Title.
  - Visible property chips (due date badge with overdue red highlight, tag chips).
  - Subtask checklist progress bar (`LinearProgressIndicator`).
  - Quick action: "Focus Now" button (F29 bridge trigger).
  - Tapping card opens the row's underlying `PageEntity` document workspace.

---

### 3.7 View 3: Calendar View Specification (`CalendarViewWidget`)

#### Files:
1. `lib/features/workspace_database/presentation/widgets/views/calendar/calendar_view_widget.dart`
2. `lib/features/workspace_database/presentation/widgets/views/calendar/calendar_day_cell.dart`
3. `lib/features/workspace_database/presentation/widgets/views/calendar/calendar_event_chip.dart`
4. `lib/features/workspace_database/presentation/widgets/views/calendar/unscheduled_items_drawer.dart`

- **Calendar Modes**:
  - Month Mode: 7 columns (Mon–Sun) x 5–6 rows.
  - Week Mode: 7 vertical day columns showing current week.
  - Header: Month/Year title, Prev/Next buttons, "Today" jump button, Mode toggle (Month/Week).
- **Day Cell & Spanning Bars**:
  - Each day cell is a `DragTarget<RowEntity>`.
  - Multi-day spanning events: When a row has `startDate` and `endDate`, calculates spanning span across grid columns and renders continuous horizontal bar across adjacent day cells.
  - Single-day events: Compact chip with status color dot and title.
- **Drag-to-Reschedule**:
  - Event chip wrapped in `Draggable<RowEntity>`.
  - Dragging from Day 10 and dropping onto Day 15 triggers `cubit.rescheduleRow(rowId: row.id, datePropertyId: dateProp.id, newDateIso: '2026-10-15')`.
- **Unscheduled Items Drawer (`UnscheduledItemsDrawer`)**:
  - Collapsible drawer at bottom or side showing all rows where the calendar date property is null.
  - Draggable items: Users drag cards directly from drawer onto any calendar day cell to schedule them immediately.

---

### 3.8 View 4: Timeline / Gantt View Specification (`TimelineViewWidget`)

#### Files:
1. `lib/features/workspace_database/presentation/widgets/views/timeline/timeline_view_widget.dart`
2. `lib/features/workspace_database/presentation/widgets/views/timeline/timeline_header_ruler.dart`
3. `lib/features/workspace_database/presentation/widgets/views/timeline/timeline_task_bar.dart`
4. `lib/features/workspace_database/presentation/widgets/views/timeline/timeline_milestone_marker.dart`
5. `lib/features/workspace_database/presentation/widgets/views/timeline/timeline_dependency_painter.dart`

- **Layout Structure**:
  - Split View: Left pane (pinned row titles and status badges, 220px width), Right pane (horizontal time canvas).
  - Synchronized vertical scrolling via shared `ScrollController`.
- **Horizontal Time Ruler (`TimelineHeaderRuler`)**:
  - Timescale zoom levels: Days (40px/day), Weeks (15px/day), Months (5px/day).
  - Ticks for dates, weeks, and month headers.
  - "Today" vertical red line spanning across full canvas height.
- **Draggable Task Bars (`TimelineTaskBar`)**:
  - Position: `x = (startDate - timelineStart).inDays * pixelsPerDay`, `width = (endDate - startDate).inDays * pixelsPerDay`.
  - Middle Drag: Translates task in time (moves both start and end dates by delta days).
  - Left Handle Drag: Extends or shrinks start date.
  - Right Handle Drag: Extends or shrinks end date (duration adjustment).
- **Milestone Marker (`TimelineMilestoneMarker`)**:
  - When `startDate == endDate` or configured as a milestone, renders as a rotated diamond icon (`Transform.rotate(angle: pi / 4)`).
- **Dependency Arrows (`TimelineDependencyPainter`)**:
  - `CustomPainter` rendering Bézier curve connector arrows from predecessor task's right edge to successor task's left edge (based on `BlockedBy` or relation property).
  - Automatic collision / overlap avoidance.
  - Conflict detection: If successor task starts before predecessor ends, the arrow line is drawn in vibrant warning red!

---

### 3.9 View 5: List View Specification (`ListViewWidget`)

#### Files:
1. `lib/features/workspace_database/presentation/widgets/views/list/list_view_widget.dart`
2. `lib/features/workspace_database/presentation/widgets/views/list/list_row_item.dart`

- **Visual Design**:
  - High-density minimalist vertical list.
  - Each row item (height: 40px):
    - Left: Row checkbox (if checkbox property exists or selection mode), Page icon, Title text.
    - Right: Row of compact property pills (Status badge, Date chip, Priority tag).
    - Trailing: Hover action buttons (Open Page, "Focus Now", Delete).
  - Overflow handling: On narrow viewports, trailing property pills collapse into a "+N more" badge.
  - Bottom: "+ New row" quick input field.

---

### 3.10 View 6: Gallery View Specification (`GalleryViewWidget`)

#### Files:
1. `lib/features/workspace_database/presentation/widgets/views/gallery/gallery_view_widget.dart`
2. `lib/features/workspace_database/presentation/widgets/views/gallery/gallery_card_widget.dart`

- **Card Grid Layout**:
  - Responsive grid using `GridView.builder` with `SliverGridDelegateWithMaxCrossAxisExtent`.
  - Card Size Settings:
    - Small: Max width 160px, aspect ratio 1.0.
    - Medium: Max width 240px, aspect ratio 1.2.
    - Large: Max width 340px, aspect ratio 1.4.
- **Gallery Card Component (`GalleryCardWidget`)**:
  - Card Cover Preview (Configurable in view settings):
    - Page Cover image (`page.coverImageUrl`).
    - Page Content text snippet (first 3 lines of page).
    - Specific file/image property or formula preview.
    - None (clean property card).
  - Card Body: Page icon, Bold Title, visible property badges (Status, Priority, Tags).
  - "+ New Card" tile at end of grid.

---

### 3.11 Inline Cell Editors Specification (`cell_editors/`)

#### 1. `lib/features/workspace_database/presentation/widgets/cell_editors/inline_cell_editor.dart`
Router widget that inspects `PropertyType` and instantiates the dedicated editor:
- `PropertyType.title` -> `TitleCellEditor`
- `PropertyType.text` -> `TextCellEditor`
- `PropertyType.number` -> `NumberCellEditor`
- `PropertyType.select` -> `SelectCellEditor`
- `PropertyType.multiSelect` -> `MultiSelectCellEditor`
- `PropertyType.status` -> `StatusCellEditor`
- `PropertyType.date` -> `DateCellEditor`
- `PropertyType.checkbox` -> `CheckboxCellEditor`
- `PropertyType.relation` -> `RelationCellEditor`
- `PropertyType.formula` -> `FormulaCellDisplay` (read-only with `#CYCLE!` badge)
- `PropertyType.rollup` -> `RollupCellDisplay` (read-only with computed metric)

#### Key Editor Implementations:
- **`SelectCellEditor`**: Popover dropdown displaying colored pill options, search field, and "+ Create option" for dynamic addition.
- **`DateCellEditor`**: Material date picker / date range picker popover with "Include time" toggle.
- **`CheckboxCellEditor`**: Custom animated checkbox toggle with instant SQLite save.
- **`RelationCellEditor`**: Searchable popover displaying rows from target database; allows checking/unchecking multiple row links.

---

## 4. Widget Test Suite Specification

### 4.1 Test 1: View Switcher AC2 Verification
- **File**: `test/widget/database_view_switcher_ac2_test.dart`
- **Objective**: Verify seamless switching across all 6 views with identical underlying data state without data loss or re-fetching lag (AC2).
- **Test Steps**:
  1. Seed fake database with 3 rows: `['Alpha Task', 'Beta Task', 'Gamma Task']` and properties (Title, Status, DueDate, Score).
  2. Pump `DatabaseViewContainer`.
  3. Verify Table View renders all 3 rows.
  4. Tap "Kanban" tab in `ViewSwitcherToolbar`. Pump and settle. Verify Kanban lanes render containing the 3 cards.
  5. Tap "Calendar" tab. Verify tasks render on calendar day cells.
  6. Tap "Timeline" tab. Verify timeline task duration bars render.
  7. Tap "List" tab. Verify minimalist list items render.
  8. Tap "Gallery" tab. Verify gallery card tiles render.
  9. In Gallery View, inline-edit 'Alpha Task' title to 'Alpha Task Modified'.
  10. Switch back to Table View tab. Verify Table View immediately renders 'Alpha Task Modified' in the first row.

### 4.2 Test 2: Table View Inline Editing & Aggregations
- **File**: `test/widget/table_view_inline_editing_test.dart`
- **Objective**: Test cell editing across property types and footer aggregation math.
- **Test Steps**:
  1. Pump Table View with 3 rows.
  2. Tap number cell on Row 1, enter '42', press Enter. Verify cell update dispatched.
  3. Tap checkbox cell on Row 2, verify checkbox toggles to true.
  4. Tap footer aggregation cell on number column, select "Sum" from dropdown.
  5. Verify footer displays computed sum (e.g. `Sum: 42`).
  6. Select "Average", verify footer displays computed average.

### 4.3 Test 3: Kanban Drag-and-Drop
- **File**: `test/widget/kanban_drag_and_drop_test.dart`
- **Objective**: Test card drag-and-drop between lanes and lane collapsing.
- **Test Steps**:
  1. Pump Kanban View with lanes: "To Do", "In Progress", "Done". Row 1 has Status "To Do".
  2. Find card for Row 1 in "To Do" column.
  3. Perform drag gesture from "To Do" lane onto "In Progress" lane.
  4. Verify `updatePropertyValue` called with `value: 'In Progress'`.
  5. Verify card now renders under "In Progress".
  6. Tap collapse toggle on "To Do" lane header. Verify lane width shrinks to 44px collapsed state.

### 4.4 Test 4: Calendar Reschedule & Unscheduled Drawer
- **File**: `test/widget/calendar_reschedule_test.dart`
- **Objective**: Test drag-to-reschedule and scheduling from unscheduled items drawer.
- **Test Steps**:
  1. Seed 1 scheduled task (Day 10) and 1 unscheduled task (null date).
  2. Pump Calendar View. Verify scheduled task appears on Day 10.
  3. Drag task from Day 10 to Day 15. Verify date property updated to Day 15.
  4. Open Unscheduled Drawer, drag unscheduled task onto Day 20.
  5. Verify unscheduled task is now scheduled on Day 20.

### 4.5 Test 5: Timeline Gantt Drag & Milestone
- **File**: `test/widget/timeline_gantt_test.dart`
- **Objective**: Test bar duration dragging, milestone markers, and dependency arrows.
- **Test Steps**:
  1. Seed task with `start: '2026-10-01'`, `end: '2026-10-05'`.
  2. Pump Timeline View. Verify task bar rendered with matching width.
  3. Drag right edge handle to extend end date. Verify end date updated.
  4. Seed milestone task where `start == end`. Verify diamond marker renders instead of duration bar.
  5. Seed dependent task `BlockedBy: task1`. Verify `TimelineDependencyPainter` renders arrow connecting tasks.

### 4.6 Test 6: Gallery Card Size Toggle & Cover Preview
- **File**: `test/widget/gallery_view_test.dart`
- **Objective**: Test gallery grid responsiveness and card size toggle.
- **Test Steps**:
  1. Pump Gallery View with 4 cards.
  2. Verify default card size is Medium.
  3. Tap toolbar size toggle, select "Large". Verify card width constraints update to Large.
  4. Tap card, verify navigation to row's Page workspace.

---

## 5. Caveats
1. **Read-Only Investigation**: As an explorer agent, no source code files or tests have been created or modified in the workspace. All architectural specifications and test blueprints are provided for implementers.
2. **`table_calendar` Dependency**: The project has `table_calendar: ^3.3.0` in `pubspec.yaml`. For the monthly and weekly calendar view, implementations can either wrap `table_calendar` or use a custom grid layout. Using a custom grid layout gives tighter control over multi-day spanning event bars and DragTarget integration.
3. **Touch vs Pointer Gestures**: Drag-and-drop on desktop/web should trigger immediately on mouse down (`Draggable`), while on mobile touch screens it should use `LongPressDraggable` to avoid conflicting with vertical page scrolling.
4. **CustomPainter Layout Measurement**: Dependency arrows in Timeline View require mapping task row indices and bar date offsets to screen coordinates (`RenderBox.localToGlobal` or canvas coordinates within the horizontal scroll viewport).

---

## 6. Conclusion
The file-by-file blueprint provides an end-to-end design for Milestone 2 Relational Database 6 Views & UI:
- **State Management**: Centralized in `DatabaseViewCubit` and `DatabaseViewState`, streaming Drift SQLite data and projecting views.
- **6 Views**: Full UI/UX and gesture specifications for Table (F12), Kanban (F13), Calendar (F14), Timeline/Gantt (F15), List (F16), and Gallery (F16).
- **View Switcher Toolbar**: Seamless switching between views with identical underlying data state, directly satisfying Acceptance Criteria AC2.
- **Inline Cell Editors**: Polymorphic editing across 11 property types.
- **Widget Test Suite**: 6 interactive widget test blueprints verifying view switching, inline editing, drag-and-drop, rescheduling, and resizing.

---

## 7. Verification Method
When the implementation is completed by workers, verify the implementation using:
```bash
# 1. Run all Milestone 2 Widget Tests
flutter test test/widget/database_view_switcher_ac2_test.dart
flutter test test/widget/table_view_inline_editing_test.dart
flutter test test/widget/kanban_drag_and_drop_test.dart
flutter test test/widget/calendar_reschedule_test.dart
flutter test test/widget/timeline_gantt_test.dart
flutter test test/widget/list_view_test.dart
flutter test test/widget/gallery_view_test.dart

# 2. Run Tier 1 Relational Database E2E Tests (F08-F16 & AC2)
flutter test test/e2e/tier1_feature_coverage/f08_f16_relational_database_test.dart

# 3. Invalidation Conditions
# - Test failure on switching views resulting in null or lost row state (AC2 failure).
# - Table cell inline edit failing to persist back to SQLite.
# - Kanban drag-and-drop failing to update row status property.
# - Calendar drag-to-reschedule failing to update date property.
# - Missing footer aggregation computations (Sum, Avg, Count).
```
