import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull, Column;
import 'core/database/app_database.dart';

import 'features/workspace_editor/data/repositories/workspace_repository_impl.dart';
import 'features/workspace_editor/domain/repositories/i_workspace_repository.dart';
import 'features/workspace_editor/presentation/controllers/page_tree_cubit.dart';
import 'features/workspace_editor/presentation/controllers/page_tree_state.dart';
import 'features/workspace_editor/presentation/controllers/block_editor_notifier.dart';
import 'features/workspace_editor/presentation/widgets/page_tree_sidebar.dart';
import 'features/workspace_editor/presentation/widgets/page_breadcrumbs.dart';
import 'features/workspace_editor/presentation/widgets/block_editor_view.dart';
import 'features/workspace_database/data/repositories/database_engine_repository_impl.dart';
import 'features/workspace_database/presentation/controllers/database_view_cubit.dart';
import 'features/workspace_database/presentation/widgets/database_view_container.dart';
import 'features/focus_timer/presentation/controllers/focus_timer_cubit.dart';
import 'features/focus_timer/presentation/widgets/focus_timer_view.dart';
import 'features/timetable/domain/models/timetable_state.dart';
import 'features/timetable/presentation/widgets/visual_timetable_widget.dart';
import 'features/live_rooms/domain/models/live_study_room_state.dart';
import 'features/live_rooms/presentation/widgets/live_study_room_view.dart';
import 'features/analytics_gamification/domain/models/streak_engine.dart';
import 'features/analytics_gamification/presentation/widgets/study_heatmap_widget.dart';

enum MainNavigationSection {
  workspace,
  database,
  focusTimer,
  timetable,
  liveRoom,
  analytics,
}

class HamPAApp extends StatelessWidget {
  final AppDatabase database;
  final IWorkspaceRepository workspaceRepository;
  final DatabaseEngineRepositoryImpl databaseEngineRepository;
  final FocusTimerCubit focusTimerCubit;

  const HamPAApp({
    super.key,
    required this.database,
    required this.workspaceRepository,
    required this.databaseEngineRepository,
    required this.focusTimerCubit,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AppDatabase>.value(value: database),
        RepositoryProvider<IWorkspaceRepository>.value(value: workspaceRepository),
        RepositoryProvider<DatabaseEngineRepositoryImpl>.value(value: databaseEngineRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<PageTreeCubit>(
            create: (context) => PageTreeCubit(repository: workspaceRepository),
          ),
          BlocProvider<FocusTimerCubit>.value(value: focusTimerCubit),
        ],
        child: MaterialApp(
          title: 'HamPA — Hybrid Notion & YPT Planner',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6366F1), // Modern Indigo
              brightness: Brightness.light,
              surface: const Color(0xFFF8FAFC),
            ),
            scaffoldBackgroundColor: const Color(0xFFFFFFFF),
            useMaterial3: true,
            cardTheme: CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            navigationRailTheme: const NavigationRailThemeData(
              backgroundColor: Color(0xFFF8FAFC),
              indicatorColor: Color(0xFFEEF2FF),
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6366F1),
              brightness: Brightness.dark,
              surface: const Color(0xFF0F172A),
            ),
            scaffoldBackgroundColor: const Color(0xFF020617),
            useMaterial3: true,
            cardTheme: CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFF1E293B)),
              ),
            ),
            navigationRailTheme: const NavigationRailThemeData(
              backgroundColor: Color(0xFF0F172A),
              indicatorColor: Color(0xFF1E1B4B),
            ),
          ),
          home: MainShellScreen(
            database: database,
            databaseEngineRepository: databaseEngineRepository,
          ),
        ),
      ),
    );
  }
}

class MainShellScreen extends StatefulWidget {
  final AppDatabase database;
  final DatabaseEngineRepositoryImpl databaseEngineRepository;

  const MainShellScreen({
    super.key,
    required this.database,
    required this.databaseEngineRepository,
  });

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  MainNavigationSection _currentSection = MainNavigationSection.workspace;
  BlockEditorNotifier? _editorNotifier;
  String? _currentPageId;

  // Active database for Section 2
  String? _activeDatabaseId;
  DatabaseViewCubit? _databaseViewCubit;

  // Timetable state for Section 4
  late TimetableState _timetableState;

  // Live Study Room for Section 5
  LiveStudyRoomState _roomState = const LiveStudyRoomState(
    roomId: 'room_global_study',
    roomName: 'Global Study Hall 📚',
    peers: [],
  );

  // Analytics for Section 6
  Map<DateTime, int> _studyMinutesMap = {};
  int _currentStreak = 0;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _timetableState = TimetableState.empty(today);
    _loadSampleDatabaseIfAvailable();
    _loadAnalyticsData();
  }

  Future<void> _loadSampleDatabaseIfAvailable() async {
    final rootPages = await widget.database.pagesDao.watchSubPages(null).first;
    if (rootPages.isNotEmpty) {
      final databases = await widget.database.databasesDao.watchDatabasesForPage(rootPages.first.id).first;
      if (databases.isNotEmpty) {
        _activeDatabaseId = databases.first.id;
        _databaseViewCubit = DatabaseViewCubit(
          repository: widget.databaseEngineRepository,
          databaseId: _activeDatabaseId!,
        );
        if (mounted) setState(() {});
      }
    }
  }

  Future<void> _loadAnalyticsData() async {
    final now = DateTime.now();
    final monthAgo = now.subtract(const Duration(days: 90));
    final sessions = await widget.database.studySessionsDao.getSessionsInDateRange(monthAgo, now);

    final map = <DateTime, int>{};
    final dates = <DateTime>[];

    for (final s in sessions) {
      if (!s.isDiscarded) {
        final d = DateTime(s.startTime.year, s.startTime.month, s.startTime.day);
        map[d] = (map[d] ?? 0) + (s.durationSeconds ~/ 60);
        dates.add(s.startTime);
      }
    }

    _studyMinutesMap = map;
    final streakResult = StreakEngine.calculateStreak(dates);
    _currentStreak = streakResult.currentStreak;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Row(
        children: [
          // Global App Activity Rail (Leftmost)
          NavigationRail(
            selectedIndex: _currentSection.index,
            onDestinationSelected: (idx) {
              setState(() {
                _currentSection = MainNavigationSection.values[idx];
              });
              if (_currentSection == MainNavigationSection.analytics) {
                _loadAnalyticsData();
              }
            },
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Text('هم‌پا', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.description_outlined),
                selectedIcon: Icon(Icons.description),
                label: Text('Docs'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.table_chart_outlined),
                selectedIcon: Icon(Icons.table_chart),
                label: Text('Database'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.timer_outlined),
                selectedIcon: Icon(Icons.timer),
                label: Text('Focus'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.calendar_view_day_outlined),
                selectedIcon: Icon(Icons.calendar_view_day),
                label: Text('Planner'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.groups_outlined),
                selectedIcon: Icon(Icons.groups),
                label: Text('Rooms'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.insights_outlined),
                selectedIcon: Icon(Icons.insights),
                label: Text('Stats'),
              ),
            ],
          ),
          const VerticalDivider(width: 1, thickness: 1),

          // Main View Section Content
          Expanded(
            child: _buildSectionContent(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContent(ThemeData theme) {
    switch (_currentSection) {
      case MainNavigationSection.workspace:
        return _buildWorkspaceSection();

      case MainNavigationSection.database:
        return _buildDatabaseSection();

      case MainNavigationSection.focusTimer:
        return const FocusTimerView();

      case MainNavigationSection.timetable:
        return Scaffold(
          appBar: AppBar(
            title: const Text('24-Hour 10-Minute Timetable (05:00 AM)'),
          ),
          body: VisualTimetableWidget(timetable: _timetableState),
        );

      case MainNavigationSection.liveRoom:
        return LiveStudyRoomView(
          roomState: _roomState,
          onSendCheer: (peerId) {
            setState(() {
              _roomState = _roomState.withCheer(peerId);
            });
          },
        );

      case MainNavigationSection.analytics:
        return Scaffold(
          appBar: AppBar(
            title: const Text('Study Analytics & Streaks'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StudyHeatmapWidget(
                  minutesByDate: _studyMinutesMap,
                  currentStreak: _currentStreak,
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('Streak', '$_currentStreak Days', Icons.local_fire_department, Colors.orange),
                        _buildStatItem('Total Sessions', '${_studyMinutesMap.length}', Icons.check_circle_outline, Colors.green),
                        _buildStatItem('Cutoff', '05:00 AM', Icons.schedule, Colors.blue),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildWorkspaceSection() {
    return Row(
      children: [
        const PageTreeSidebar(),
        Expanded(
          child: BlocConsumer<PageTreeCubit, PageTreeState>(
            listener: (context, state) {
              if (state.selectedPageId != _currentPageId) {
                _currentPageId = state.selectedPageId;
                _editorNotifier?.dispose();
                if (_currentPageId != null) {
                  final repo = context.read<IWorkspaceRepository>() as WorkspaceRepositoryImpl;
                  _editorNotifier = BlockEditorNotifier(
                    repository: repo,
                    pageId: _currentPageId!,
                  );
                } else {
                  _editorNotifier = null;
                }
                setState(() {});
              }
            },
            builder: (context, state) {
              if (state.selectedPageId == null) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.description_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Select or create a page to begin editing',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  const PageBreadcrumbs(),
                  const Divider(height: 1),
                  Expanded(
                    child: _editorNotifier != null
                        ? BlockEditorView(notifier: _editorNotifier!)
                        : const Center(child: CircularProgressIndicator()),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDatabaseSection() {
    if (_databaseViewCubit == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.table_chart_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No Relational Database found yet'),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Create Study & Task Planner Database'),
              onPressed: () async {
                final rootPages = await widget.database.pagesDao.watchSubPages(null).first;
                String pageId;
                if (rootPages.isNotEmpty) {
                  pageId = rootPages.first.id;
                } else {
                  final now = DateTime.now();
                  final newId = 'page_${now.millisecondsSinceEpoch}';
                  await widget.database.pagesDao.insertPage(
                    PagesCompanion.insert(
                      id: newId,
                      title: const Value('Personal Workspace'),
                      createdAt: now,
                      updatedAt: now,
                    ),
                  );
                  pageId = newId;
                }

                final db = await widget.databaseEngineRepository.createDatabase(
                  title: 'My Study & Task Planner',
                  pageId: pageId,
                );
                _activeDatabaseId = db.id;
                _databaseViewCubit = DatabaseViewCubit(
                  repository: widget.databaseEngineRepository,
                  databaseId: _activeDatabaseId!,
                );
                setState(() {});
              },
            ),
          ],
        ),
      );
    }

    return BlocProvider<DatabaseViewCubit>.value(
      value: _databaseViewCubit!,
      child: const DatabaseViewContainer(),
    );
  }

  @override
  void dispose() {
    _editorNotifier?.dispose();
    _databaseViewCubit?.close();
    super.dispose();
  }
}
