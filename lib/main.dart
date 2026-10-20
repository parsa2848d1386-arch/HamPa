import 'package:flutter/material.dart';
import 'core/database/app_database.dart';
import 'features/workspace_editor/data/repositories/workspace_repository_impl.dart';
import 'features/workspace_database/data/repositories/database_engine_repository_impl.dart';
import 'features/focus_timer/presentation/controllers/focus_timer_cubit.dart';
import 'core/services/firebase_service.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HamPAAppBootstrapper());
}

class HamPAAppBootstrapper extends StatefulWidget {
  const HamPAAppBootstrapper({super.key});

  @override
  State<HamPAAppBootstrapper> createState() => _HamPAAppBootstrapperState();
}

class _HamPAAppBootstrapperState extends State<HamPAAppBootstrapper> {
  Widget? _app;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      // 1. Initialize Firebase gracefully in background
      await FirebaseService.initialize().catchError((e) {
        debugPrint('Firebase init non-fatal fallback: $e');
      });

      // 2. Initialize Database & DAOs
      final database = AppDatabase();
      
      // Seed subjects asynchronously without blocking UI
      database.subjectsDao.seedDefaultSubjects().catchError((e) {
        debugPrint('Seed subjects error: $e');
      });

      final workspaceRepository = WorkspaceRepositoryImpl(
        pagesDao: database.pagesDao,
        blocksDao: database.blocksDao,
      );

      final databaseEngineRepository = DatabaseEngineRepositoryImpl(
        db: database,
        databasesDao: database.databasesDao,
        propertiesDao: database.databasePropertiesDao,
        rowsDao: database.databaseRowsDao,
        cellsDao: database.databaseCellsDao,
        viewsDao: database.databaseViewsDao,
        pagesDao: database.pagesDao,
      );

      final focusTimerCubit = FocusTimerCubit(
        studySessionsDao: database.studySessionsDao,
      );

      if (mounted) {
        setState(() {
          _app = HamPAApp(
            database: database,
            workspaceRepository: workspaceRepository,
            databaseEngineRepository: databaseEngineRepository,
            focusTimerCubit: focusTimerCubit,
          );
        });
      }
    } catch (e, st) {
      debugPrint('Bootstrap error: $e\n$st');
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_app != null) {
      return _app!;
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(
          child: _error != null
              ? Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.amber, size: 48),
                      const SizedBox(height: 16),
                      const Text(
                        'خطا در بارگذاری اولیه',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x666366F1),
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.layers_outlined, color: Colors.white, size: 36),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'هم‌پا | HamPA',
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
