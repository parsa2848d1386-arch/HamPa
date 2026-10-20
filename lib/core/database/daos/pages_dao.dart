import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/pages_table.dart';

part 'pages_dao.g.dart';

@DriftAccessor(tables: [Pages])
class PagesDao extends DatabaseAccessor<AppDatabase> with _$PagesDaoMixin {
  PagesDao(super.db);

  /// Watches all non-archived pages for reactive tree construction in UI
  Stream<List<PageEntry>> watchPageTree() {
    return (select(pages)
          ..where((tbl) => tbl.isArchived.equals(false))
          ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.sortOrder, mode: OrderingMode.asc),
            (tbl) => OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  /// Watches sub-pages of a parent or root pages if parentId is null
  Stream<List<PageEntry>> watchSubPages(String? parentId) {
    return (select(pages)
          ..where((tbl) =>
              tbl.isArchived.equals(false) &
              (parentId == null ? tbl.parentPageId.isNull() : tbl.parentPageId.equals(parentId)))
          ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.sortOrder, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  /// Watches a single page
  Stream<PageEntry?> watchPageById(String id) {
    return (select(pages)..where((tbl) => tbl.id.equals(id))).watchSingleOrNull();
  }

  /// One-shot page retrieval
  Future<PageEntry?> getPageById(String id) {
    return (select(pages)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// Insert page
  Future<int> insertPage(PagesCompanion entry) {
    return into(pages).insert(entry);
  }

  /// Update page entry
  Future<bool> updatePageEntry(PagesCompanion entry) {
    return update(pages).replace(entry);
  }

  /// Update title
  Future<int> updatePageTitle(String id, String newTitle) {
    return (update(pages)..where((tbl) => tbl.id.equals(id))).write(
      PagesCompanion(
        title: Value(newTitle),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Update icon
  Future<int> updatePageIcon(String id, String? newIcon) {
    return (update(pages)..where((tbl) => tbl.id.equals(id))).write(
      PagesCompanion(
        icon: Value(newIcon),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Re-parents a page and updates sort order with cycle prevention
  Future<void> updatePageParent({
    required String pageId,
    String? newParentPageId,
    required double newSortOrder,
  }) async {
    if (pageId == newParentPageId) {
      throw ArgumentError('A page cannot be its own parent.');
    }

    if (newParentPageId != null) {
      final isDescendant = await _isDescendantOf(
        possibleChildId: newParentPageId,
        ancestorId: pageId,
      );
      if (isDescendant) {
        throw ArgumentError('Cannot move a page under its own descendant.');
      }
    }

    await (update(pages)..where((tbl) => tbl.id.equals(pageId))).write(
      PagesCompanion(
        parentPageId: Value(newParentPageId),
        sortOrder: Value(newSortOrder),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Batch update sort orders for siblings
  Future<void> batchUpdateSortOrders(Map<String, double> pageSortOrders) async {
    await batch((b) {
      for (final entry in pageSortOrders.entries) {
        b.update(
          pages,
          PagesCompanion(
            sortOrder: Value(entry.value),
            updatedAt: Value(DateTime.now()),
          ),
          where: (tbl) => tbl.id.equals(entry.key),
        );
      }
    });
  }

  /// Checks if possibleChildId is a descendant of ancestorId
  Future<bool> _isDescendantOf({
    required String possibleChildId,
    required String ancestorId,
  }) async {
    String? currentParent = possibleChildId;
    final Set<String> visited = {possibleChildId};
    while (currentParent != null) {
      if (currentParent == ancestorId) return true;
      final page = await getPageById(currentParent);
      currentParent = page?.parentPageId;
      if (currentParent != null) {
        if (visited.contains(currentParent)) break;
        visited.add(currentParent);
      }
    }
    return false;
  }

  /// Resolves the ancestor breadcrumb trail from root to current page
  Future<List<PageEntry>> getBreadcrumbs(String pageId) async {
    final breadcrumbs = <PageEntry>[];
    String? currentId = pageId;
    final Set<String> visited = {};

    while (currentId != null && !visited.contains(currentId)) {
      visited.add(currentId);
      final page = await getPageById(currentId);
      if (page == null) break;
      breadcrumbs.insert(0, page);
      currentId = page.parentPageId;
    }
    return breadcrumbs;
  }

  /// Soft delete
  Future<int> archivePage(String id) {
    return (update(pages)..where((tbl) => tbl.id.equals(id))).write(
      PagesCompanion(
        isArchived: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Hard delete (cascades to blocks and subpages)
  Future<int> deletePage(String id) {
    return (delete(pages)..where((tbl) => tbl.id.equals(id))).go();
  }
}
