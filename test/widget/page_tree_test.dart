import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hampa/features/workspace_editor/domain/models/block_entity.dart';
import 'package:hampa/features/workspace_editor/domain/models/page_entity.dart';
import 'package:hampa/features/workspace_editor/domain/repositories/i_workspace_repository.dart';
import 'package:hampa/features/workspace_editor/presentation/controllers/page_tree_cubit.dart';
import 'package:hampa/features/workspace_editor/presentation/widgets/page_tree_sidebar.dart';
import 'package:hampa/features/workspace_editor/presentation/widgets/page_tree_item.dart';

class FakeWorkspaceRepository implements IWorkspaceRepository {
  final List<PageEntity> _pages = [];
  final StreamController<List<PageEntity>> _streamController =
      StreamController<List<PageEntity>>.broadcast();

  int createPageCallCount = 0;
  String? lastCreatedParentId;
  String? lastUpdatedPageId;
  String? lastNewParentId;
  double? lastNewSortOrder;

  FakeWorkspaceRepository([List<PageEntity>? initial]) {
    if (initial != null) {
      _pages.addAll(initial);
    }
  }

  void seedPages(List<PageEntity> newPages) {
    _pages.clear();
    _pages.addAll(newPages);
    _streamController.add(List.unmodifiable(_pages));
  }

  @override
  Stream<List<PageEntity>> watchPageTree() async* {
    yield List.unmodifiable(_pages);
    yield* _streamController.stream;
  }

  @override
  Future<PageEntity> createPage({
    String? parentPageId,
    required String title,
    String? icon,
    bool isDatabaseRow = false,
    double? sortOrder,
  }) async {
    createPageCallCount++;
    lastCreatedParentId = parentPageId;
    final page = PageEntity(
      id: 'page_${DateTime.now().microsecondsSinceEpoch}',
      parentPageId: parentPageId,
      title: title,
      icon: icon ?? '📄',
      isDatabaseRow: isDatabaseRow,
      sortOrder: sortOrder ?? 1.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _pages.add(page);
    _streamController.add(List.unmodifiable(_pages));
    return page;
  }

  @override
  Future<void> updatePageParent({
    required String pageId,
    String? newParentPageId,
    required double newSortOrder,
  }) async {
    lastUpdatedPageId = pageId;
    lastNewParentId = newParentPageId;
    lastNewSortOrder = newSortOrder;

    final idx = _pages.indexWhere((p) => p.id == pageId);
    if (idx != -1) {
      _pages[idx] = _pages[idx].copyWith(
        parentPageId: newParentPageId,
        clearParentPageId: newParentPageId == null,
        sortOrder: newSortOrder,
      );
      _streamController.add(List.unmodifiable(_pages));
    }
  }

  @override
  Future<void> updatePageTitle({
    required String pageId,
    required String title,
  }) async {
    final idx = _pages.indexWhere((p) => p.id == pageId);
    if (idx != -1) {
      _pages[idx] = _pages[idx].copyWith(title: title);
      _streamController.add(List.unmodifiable(_pages));
    }
  }

  @override
  Future<void> updatePageIcon({
    required String pageId,
    String? icon,
  }) async {
    final idx = _pages.indexWhere((p) => p.id == pageId);
    if (idx != -1) {
      _pages[idx] = _pages[idx].copyWith(icon: icon, clearIcon: icon == null);
      _streamController.add(List.unmodifiable(_pages));
    }
  }

  @override
  Future<void> archivePage({required String pageId}) async {
    final idx = _pages.indexWhere((p) => p.id == pageId);
    if (idx != -1) {
      _pages[idx] = _pages[idx].copyWith(isArchived: true);
      _streamController.add(List.unmodifiable(_pages));
    }
  }

  @override
  Future<void> batchUpdateSortOrders(Map<String, double> pageSortOrders) async {}

  @override
  Stream<List<BlockEntity>> watchBlocksForPage(String pageId) => const Stream.empty();

  @override
  Future<void> insertBlock(BlockEntity block) async {}

  @override
  Future<void> updateBlock(BlockEntity block) async {}

  @override
  Future<void> deleteBlock(String blockId) async {}

  void dispose() {
    _streamController.close();
  }
}

void main() {
  late FakeWorkspaceRepository repository;
  late PageTreeCubit cubit;

  setUp(() {
    repository = FakeWorkspaceRepository();
    cubit = PageTreeCubit(repository: repository);
  });

  tearDown(() {
    cubit.close();
    repository.dispose();
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: Scaffold(
        body: BlocProvider<PageTreeCubit>.value(
          value: cubit,
          child: const PageTreeSidebar(),
        ),
      ),
    );
  }

  testWidgets('Renders empty workspace sidebar with header, search bar, and empty placeholder', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('HamPA Workspace'), findsOneWidget);
    expect(find.text('هم‌پا'), findsOneWidget);
    expect(find.text('Search pages...'), findsOneWidget);
    expect(find.text('No pages yet'), findsOneWidget);
    expect(find.text('Create a page'), findsOneWidget);
  });

  testWidgets('Tapping Create a page or + icon creates root page', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create a page'));
    await tester.pumpAndSettle();

    expect(repository.createPageCallCount, equals(1));
    expect(repository.lastCreatedParentId, isNull);
  });

  testWidgets('Renders populated page tree with titles, icons, and database row badge', (tester) async {
    final now = DateTime.now();
    repository.seedPages([
      PageEntity(
        id: 'p1',
        title: 'Project Notes',
        icon: '📝',
        sortOrder: 1.0,
        createdAt: now,
        updatedAt: now,
      ),
      PageEntity(
        id: 'p2',
        title: 'Task Item #101',
        icon: '🎯',
        isDatabaseRow: true,
        sortOrder: 2.0,
        createdAt: now,
        updatedAt: now,
      ),
    ]);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Project Notes'), findsOneWidget);
    expect(find.text('📝'), findsOneWidget);
    expect(find.text('Task Item #101'), findsOneWidget);
    expect(find.text('🎯'), findsOneWidget);
    expect(find.text('ROW'), findsOneWidget);
  });

  testWidgets('Expand/Collapse chevron toggles child visibility', (tester) async {
    final now = DateTime.now();
    repository.seedPages([
      PageEntity(
        id: 'parent_1',
        title: 'Parent Folder',
        sortOrder: 1.0,
        createdAt: now,
        updatedAt: now,
      ),
      PageEntity(
        id: 'child_1',
        parentPageId: 'parent_1',
        title: 'Child Document',
        sortOrder: 1.0,
        createdAt: now,
        updatedAt: now,
      ),
    ]);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Initially collapsed: Parent visible, Child hidden
    expect(find.text('Parent Folder'), findsOneWidget);
    expect(find.text('Child Document'), findsNothing);

    // Tap chevron to expand
    final chevronFinder = find.byIcon(Icons.chevron_right);
    expect(chevronFinder, findsOneWidget);
    await tester.tap(chevronFinder);
    await tester.pumpAndSettle();

    // Now expanded: Child visible
    expect(find.text('Child Document'), findsOneWidget);

    // Tap chevron to collapse again
    await tester.tap(chevronFinder);
    await tester.pumpAndSettle();

    // Child hidden again
    expect(find.text('Child Document'), findsNothing);
  });

  testWidgets('Search query filters page tree and displays no-match message', (tester) async {
    final now = DateTime.now();
    repository.seedPages([
      PageEntity(
        id: 'p1',
        title: 'Physics Mechanics',
        sortOrder: 1.0,
        createdAt: now,
        updatedAt: now,
      ),
      PageEntity(
        id: 'p2',
        title: 'Chemistry Organic',
        sortOrder: 2.0,
        createdAt: now,
        updatedAt: now,
      ),
    ]);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Physics Mechanics'), findsOneWidget);
    expect(find.text('Chemistry Organic'), findsOneWidget);

    // Enter search query
    await tester.enterText(find.byType(TextField), 'physics');
    await tester.pumpAndSettle();

    expect(find.text('Physics Mechanics'), findsOneWidget);
    expect(find.text('Chemistry Organic'), findsNothing);

    // Enter non-matching query
    await tester.enterText(find.byType(TextField), 'calculus');
    await tester.pumpAndSettle();

    expect(find.text('No pages match "calculus"'), findsOneWidget);
  });

  testWidgets('Tapping page item selects it in PageTreeState', (tester) async {
    final now = DateTime.now();
    repository.seedPages([
      PageEntity(id: 'page_a', title: 'Page A', createdAt: now, updatedAt: now),
    ]);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(cubit.state.selectedPageId, isNull);

    await tester.tap(find.text('Page A'));
    await tester.pumpAndSettle();

    expect(cubit.state.selectedPageId, equals('page_a'));
  });

  testWidgets('Cycle prevention UI: dropping onto self or descendant is rejected by DragTarget', (tester) async {
    final now = DateTime.now();
    repository.seedPages([
      PageEntity(id: 'root_node', title: 'Root Node', createdAt: now, updatedAt: now),
      PageEntity(id: 'sub_node', parentPageId: 'root_node', title: 'Sub Node', createdAt: now, updatedAt: now),
    ]);

    // Expand root_node so sub_node is in the widget tree
    cubit.toggleNodeExpanded('root_node');

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Root Node'), findsOneWidget);
    expect(find.text('Sub Node'), findsOneWidget);

    // Find the DragTarget for Sub Node
    final subDragTargets = tester.widgetList<DragTarget<PageDragData>>(
      find.byType(typeOf<DragTarget<PageDragData>>()),
    ).toList();

    // Verify DragTarget on sub_node rejects dragged root_node (preventing cycle)
    final subTarget = subDragTargets.firstWhere(
      (target) => find.descendant(of: find.byWidget(target), matching: find.text('Sub Node')).evaluate().isNotEmpty,
    );

    final details = DragTargetDetails<PageDragData>(
      data: const PageDragData('root_node'),
      offset: Offset.zero,
    );

    final willAccept = subTarget.onWillAcceptWithDetails!(details);
    expect(willAccept, isFalse, reason: 'DragTarget must reject descendant as drop destination to prevent cycles');
  });

  testWidgets('Cycle prevention UI: invalid drop sets error message and displays SnackBar', (tester) async {
    final now = DateTime.now();
    repository.seedPages([
      PageEntity(id: 'node_a', title: 'Node A', createdAt: now, updatedAt: now),
      PageEntity(id: 'node_b', parentPageId: 'node_a', title: 'Node B', createdAt: now, updatedAt: now),
    ]);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Directly invoke handleDrop attempting to place node_a inside node_b
    await cubit.handleDrop(
      movingPageId: 'node_a',
      targetPageId: 'node_b',
      position: DropPosition.inside,
    );
    await tester.pumpAndSettle();

    // Verify error state & snackbar
    expect(cubit.state.errorMessage, equals('Cannot move a page into its own descendant!'));
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Cannot move a page into its own descendant!'), findsOneWidget);
  });

  testWidgets('Valid drop re-parents page via repository', (tester) async {
    final now = DateTime.now();
    repository.seedPages([
      PageEntity(id: 'folder_1', title: 'Folder 1', createdAt: now, updatedAt: now),
      PageEntity(id: 'doc_1', title: 'Doc 1', createdAt: now, updatedAt: now),
    ]);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await cubit.handleDrop(
      movingPageId: 'doc_1',
      targetPageId: 'folder_1',
      position: DropPosition.inside,
    );
    await tester.pumpAndSettle();

    expect(repository.lastUpdatedPageId, equals('doc_1'));
    expect(repository.lastNewParentId, equals('folder_1'));
  });
}

Type typeOf<T>() => T;
