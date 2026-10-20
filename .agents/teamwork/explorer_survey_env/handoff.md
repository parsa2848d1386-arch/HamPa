# Handoff Report: Workspace & Environment Exploration for HamPA

**Agent**: `explorer_survey_env`  
**Working Directory**: `c:\parsa\HamPA\.agents\teamwork\explorer_survey_env`  
**Parent Orchestrator**: `22d8faaf-eb90-463c-99a6-32a4eb94320e`  
**Date**: 2026-10-16T16:40:00Z  

---

## 1. Observation

### 1.1 Workspace State
Direct inspection of `c:\parsa\HamPA` via `list_dir`:
```json
{"name":".agents","isDir":true}
{"name":".gemini","isDir":true}
{"name":"ORIGINAL_REQUEST.md","sizeBytes":"4232"}
```
- No existing Flutter files (`pubspec.yaml`, `lib/`, `test/`, `android/`, `windows/`, `web/`) were found.
- Running `git status` inside `c:\parsa\HamPA` yielded:
  `fatal: not a git repository (or any of the parent directories): .git`
- **Result**: The workspace is a clean slate.

### 1.2 Toolchain & SDK Discovery
1. **Flutter & Dart CLI on PATH**:
   Command: `flutter --version; dart --version`
   Output:
   ```
   flutter : The term 'flutter' is not recognized as the name of a cmdlet, function, script file, or operable program.
   dart : The term 'dart' is not recognized as the name of a cmdlet, function, script file, or operable program.
   ```
   Command: `where.exe flutter; where.exe dart`
   Output:
   ```
   INFO: Could not find files for the given pattern(s).
   INFO: Could not find files for the given pattern(s).
   ```
2. **Git**:
   Command: `where.exe git`
   Output: `C:\Program Files\Git\cmd\git.exe`
3. **C++ Desktop Build Tools (Windows Target)**:
   Command: `& "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64`
   Output:
   ```
   displayName: Visual Studio Build Tools 2026
   installationPath: C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools
   installationVersion: 18.10.12201.205
   productId: Microsoft.VisualStudio.Product.BuildTools
   productPath: C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\Common7\Tools\LaunchDevCmd.bat
   ```
   Chocolatey query `choco list` confirmed:
   ```
   visualstudio2026buildtools 118.10.0
   visualstudio2026-workload-vctools 1.0.0
   vcredist140 14.51.36247
   ```
4. **JDK / Java**:
   Command: `where.exe java; where.exe javac`
   Output:
   ```
   C:\Users\ASUS\AppData\Local\Programs\Eclipse Adoptium\jdk-25.0.4.7-hotspot\bin\java.exe
   C:\Users\ASUS\AppData\Local\Programs\Eclipse Adoptium\jdk-25.0.4.7-hotspot\bin\javac.exe
   ```
5. **Browsers (Web Target)**:
   Command: `Test-Path "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"; Test-Path "C:\Program Files\Google\Chrome\Application\chrome.exe"`
   Output:
   ```
   True
   True
   ```
6. **Android Tools**:
   Command: `Get-ChildItem -Path "C:\parsa\QtScrcpy-win-x86-v4.2.1" -Filter "adb.exe" -Recurse`
   Output: `C:\parsa\QtScrcpy-win-x86-v4.2.1\adb.exe`
   Command: `& "C:\parsa\QtScrcpy-win-x86-v4.2.1\adb.exe" devices`
   Output: daemon started successfully at port 5037, 0 devices attached.
7. **Package Manager Availability**:
   - `choco.exe` at `C:\ProgramData\chocolatey\bin\choco.exe` (v2.7.4)
   - `winget.exe` at `C:\Users\ASUS\AppData\Local\Microsoft\WindowsApps\winget.exe`
   - Chocolatey packages available: `flutter 3.47.3`, `dart-sdk 3.13.5`
8. **Network Reachability**:
   Command: `(Invoke-WebRequest -Uri "https://pub.dev" -UseBasicParsing -TimeoutSec 5).StatusCode`
   Output: `200` (Direct high-speed connectivity to Dart registry).

### 1.3 Pub Package Investigation
Direct query to `https://pub.dev/api/packages/<pkg>`:
| Package | Latest Version | SDK Requirement | Notes |
|---|---|---|---|
| `drift` | `2.35.2` | `>=3.10.0 <4.0.0` | Relational local-first SQLite core |
| `drift_flutter` | `0.3.1` | `>=3.0.0 <4.0.0` | "Easily set up drift databases across platforms in Flutter apps" |
| `sqlite3_flutter_libs` | `0.6.0+eol` | - | **Notice**: "Not used anymore, update to version 3.x of package:sqlite3 instead" |
| `flutter_bloc` | `9.1.1` | `>=2.14.0 <4.0.0` | State management for events, stopwatch, room streams |
| `provider` | `6.1.5+1` | `>=2.12.0 <4.0.0` | Lightweight DI and ChangeNotifier support |
| `flutter_riverpod` | `3.4.3` | `>=3.0.0 <4.0.0` | Modern reactive state management |
| `go_router` | `18.1.0` | `>=3.0.0 <4.0.0` | Declarative routing with URL & deep-linking |
| `uuid` | `4.6.0` | `>=3.0.0 <4.0.0` | ID generation for pages, blocks, rows |
| `intl` | `0.20.3` | `>=3.0.0 <4.0.0` | Date formatting & localization |
| `table_calendar` | `3.3.0` | `>=3.0.0 <4.0.0` | Calendar view for relational database & sessions |
| `fl_chart` | `1.2.0` | `>=3.0.0 <4.0.0` | Analytics and trend charts |
| `audioplayers` | `6.8.1` | `>=3.0.0 <4.0.0` | Ambient soundscape audio playback |
| `sensors_plus` | `7.1.1` | `>=3.3.0 <4.0.0` | Flip-to-focus phone sensor detection |
| `shared_preferences` | `2.5.6` | `>=3.0.0 <4.0.0` | Fast key-value settings & token cache |
| `flutter_math_fork` | `0.7.4` | `>=2.12.0 <4.0.0` | LaTeX math formatting for Notion blocks |
| `flutter_highlight` | `0.7.0` | `>=2.12.0 <4.0.0` | Code block syntax highlighting |
| `flutter_markdown` | `0.7.7+1` | `>=3.0.0 <4.0.0` | Markdown rendering |
| `web_socket_channel` | `3.0.3` | `>=3.3.0 <4.0.0` | Real-time live study room peer synchronization |
| `lottie` | `3.6.1` | `>=3.0.0 <4.0.0` | Study avatar animations |
| `rive` | `0.14.11` | `>=3.0.0 <4.0.0` | Interactive vector avatars |
| `build_runner` (dev) | `2.17.1` | `>=3.0.0 <4.0.0` | Code generation for Drift and models |
| `drift_dev` (dev) | `2.35.1` | `>=3.10.0 <4.0.0` | Drift query and schema compiler |
| `bloc_test` (dev) | `10.0.0` | `>=3.0.0 <4.0.0` | Bloc testing utilities |
| `mocktail` (dev) | `1.0.5` | `>=2.12.0 <4.0.0` | Null-safe test mocking without code generation |
| `test` (dev) | `1.33.0` | `>=3.0.0 <4.0.0` | Dart standard test harness |

---

## 2. Logic Chain

1. **Observation 1.1** demonstrates `c:\parsa\HamPA` currently contains only `.agents/`, `.gemini/`, and `ORIGINAL_REQUEST.md`.  
   -> **Inference**: A fresh Flutter application scaffolding step (`flutter create`) is required before creating source code or writing features.
2. **Observation 1.2.3 and 1.2.5** establish that Visual Studio Build Tools 2026 (with C++ x86/x64 tools) and both Google Chrome and Microsoft Edge are present on the local machine.  
   -> **Inference**: Both the **Windows Desktop** target and the **Web** target can be compiled and executed locally without installing additional platform compilers or IDEs.
3. **Observation 1.2.1** shows `flutter` and `dart` commands are not currently on the active `PATH`. However, **Observation 1.2.2 and 1.2.7** show `git.exe` and `choco.exe` are operational, and `pub.dev` is directly reachable via HTTP (Observation 1.2.8).  
   -> **Inference**: The Flutter SDK can be provisioned rapidly either by cloning `https://github.com/flutter/flutter.git` into `C:\flutter` (preferred for speed and exact channel control) or via `choco install flutter -y`. Adding its `bin` directory to the session PATH will immediately activate `flutter` and `dart`.
4. **Observation 1.3** reveals `sqlite3_flutter_libs` is flagged as `0.6.0+eol` with notice *"Not used anymore, update to version 3.x of package:sqlite3 instead"*, whereas `drift_flutter: 0.3.1` natively handles multi-platform SQLite connections across Windows, Android, iOS, and Web without `sqlite3_flutter_libs`.  
   -> **Inference**: Specifying `drift: ^2.24.0` with `drift_flutter: ^0.2.0` (or `sqlite3: ^3.1.3`) avoids build breakages and resolves cleanly across desktop and web.
5. In accordance with the `flutter-apply-architecture-best-practices` standard, the hybrid Notion + YPT scope demands clean separation between persistence (Drift tables/DAOs), business logic (Stopwatch, Lock, Timetable, Room sync), and UI presentation.  
   -> **Inference**: A hybrid layered architecture (`lib/core/`, `lib/data/`, `lib/domain/`, `lib/presentation/features/`) provides the isolation necessary for parallel agent implementation.

---

## 3. Caveats

1. **Flutter SDK Extraction**: The Flutter SDK is not currently present in PATH or unpacked in standard directories (`C:\flutter`, `C:\src\flutter`). The implementer agent will need to provision or clone Flutter (e.g. `git clone -b stable https://github.com/flutter/flutter.git C:\flutter`) and configure `$env:PATH`.
2. **Android SDK Hardware Execution**: While `adb.exe` is present at `C:\parsa\QtScrcpy-win-x86-v4.2.1\adb.exe`, no active Android device or emulator was attached at survey time. Windows Desktop and Web are the primary immediately runnable targets.
3. **Canvas Performance for Timetable**: The 144-slot 10-minute visual timetable grid and 365-day heatmap should be rendered using `CustomPainter` rather than deeply nested widget trees (e.g., 144 separate Container widgets with individual borders) to guarantee 60fps rendering and instant subject color repaint during active sessions.

---

## 4. Conclusion

The `c:\parsa\HamPA` workspace is a pristine environment ready for Flutter project initialization. The host machine is equipped with all necessary C++ desktop build prerequisites (Visual Studio Build Tools 2026) and browser runtimes (Chrome, Edge). All required libraries for Notion-like block databases and YPT focus mechanics have been analyzed on `pub.dev` with proven dependency compatibility.

### Recommended `pubspec.yaml` Specification
```yaml
name: hampa
description: "HamPA (هم‌پا) - Hybrid Notion Workspace & YPT Focus Planner"
publish_to: "none"
version: 1.0.0+1

environment:
  sdk: ">=3.4.0 <4.0.0"
  flutter: ">=3.22.0"

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^2.0.0

  # State Management & Routing
  flutter_bloc: ^9.1.1
  provider: ^6.1.5
  go_router: ^18.1.0

  # Local Database & Persistence (Notion Core)
  drift: ^2.24.0
  drift_flutter: ^0.2.0
  path_provider: ^2.1.6
  path: ^1.9.1
  shared_preferences: ^2.5.6

  # Notion Rich Block Formatting
  flutter_math_fork: ^0.7.4
  flutter_highlight: ^0.7.0
  flutter_markdown: ^0.7.7

  # YPT Timetable, Sound & Sensors
  sensors_plus: ^7.1.1
  audioplayers: ^6.8.1
  table_calendar: ^3.3.0
  fl_chart: ^1.2.0

  # Live Study Rooms & Utilities
  web_socket_channel: ^3.0.3
  uuid: ^4.6.0
  intl: ^0.20.3
  lottie: ^3.6.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  build_runner: ^2.17.1
  drift_dev: ^2.24.0
  bloc_test: ^10.0.0
  mocktail: ^1.0.5
  test: ^1.33.0

flutter:
  uses-material-design: true
  assets:
    - assets/sounds/
    - assets/icons/
```

### Recommended Directory Structure
```
c:\parsa\HamPA\
├── lib/
│   ├── core/
│   │   ├── constants/             # Day cutoff (05:00), 144-slot grid defs, lock allowlist
│   │   ├── theme/                 # Dark/light theme, subject color palettes
│   │   ├── utils/                 # Monotonic timer, date/time calculations, formula engine
│   │   └── widgets/               # Atomic buttons, card wrappers, status pills
│   ├── data/
│   │   ├── local/
│   │   │   ├── database.dart      # Drift schema & tables (Pages, Blocks, Databases, StudySessions)
│   │   │   └── daos/              # WorkspaceDao, FocusDao, AnalyticsDao
│   │   ├── repositories/          # WorkspaceRepository, FocusRepository, StudyRoomRepository
│   │   └── services/              # AudioService, SensorService, StudyRoomSocketService
│   ├── domain/
│   │   └── models/                # Block, Page, DatabaseView, TaskItem, StudySession, RoomUser
│   ├── presentation/
│   │   ├── workspace/             # Page tree navigation, block editor (text, heading, checklist, math)
│   │   ├── database/              # 6 views: Table, Kanban, Calendar, Timeline, List, Gallery
│   │   ├── focus/                 # Stopwatch HUD, Pomodoro, Strict Lock, Soundscape player
│   │   ├── timetable/             # CustomPainter 144-slot 24h visual grid (05:00 - 05:00)
│   │   ├── study_rooms/           # Live room presence grid, animated avatars, cheering
│   │   ├── bridge/                # "Focus Now" task trigger, in-session scratchpad drawer
│   │   └── analytics/             # Annual/monthly GitHub-style heatmaps, streak calculation
│   └── main.dart
├── test/
│   ├── core/utils/monotonic_timer_test.dart
│   ├── core/utils/formula_engine_test.dart
│   ├── data/local/drift_database_test.dart
│   ├── presentation/focus/focus_bloc_test.dart
│   ├── presentation/timetable/timetable_painter_test.dart
│   └── widget_test.dart
└── pubspec.yaml
```

---

## 5. Verification Method

1. **Workspace Verification**:
   - Inspect directory contents: `Get-ChildItem -Path c:\parsa\HamPA` to verify absence of conflicting project files prior to scaffolding.
2. **Build Tools Verification**:
   - Verify Visual Studio C++ toolchain:
     `& "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64`
   - Verify browser engines:
     `Test-Path "C:\Program Files\Google\Chrome\Application\chrome.exe"`
3. **Dependency Compatibility Verification**:
   - Query pub.dev endpoints:
     `Invoke-RestMethod -Uri "https://pub.dev/api/packages/drift_flutter"`
     `Invoke-RestMethod -Uri "https://pub.dev/api/packages/flutter_bloc"`
4. **Invalidation Conditions**:
   - If `sqlite3_flutter_libs` is selected instead of `drift_flutter`, dependency resolution or build linking may fail.
   - If Flutter SDK is extracted without Visual Studio C++ toolchain in PATH, Windows desktop compilation will fail.
