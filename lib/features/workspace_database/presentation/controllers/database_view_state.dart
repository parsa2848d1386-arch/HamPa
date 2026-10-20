import '../../domain/models/database_entity.dart';
import '../../domain/models/property_entity.dart';
import '../../domain/models/row_entity.dart';
import '../../domain/models/cell_entity.dart';
import '../../domain/models/view_entity.dart';
import '../../domain/models/filter_criteria.dart';
import '../../domain/models/sort_criteria.dart';
import '../../domain/models/column_layout.dart';
import '../../domain/models/aggregation_type.dart';

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
