# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Build & Run
```bash
# Run in debug mode
flutter run

# Run on specific device
flutter run -d "iPhone 16"
flutter run -d "android"

# Build for release
flutter build apk --release
flutter build ios --release

# Clean build artifacts
flutter clean
flutter pub get
```

### iOS Development
```bash
# Clean iOS pods and reinstall
cd ios && rm -rf Pods Podfile.lock && pod install --clean-install && cd ..

# Build iOS without code signing (for testing)
flutter build ios --debug --no-codesign
```

### Testing & Quality
```bash
# Run tests (minimal test setup currently)
flutter test

# Analyze code
flutter analyze

# Check outdated dependencies
flutter pub outdated
```

## Architecture Overview

**Certifide Open App** is a vehicle inspection Flutter application using **Riverpod** for state management with an **offline-first architecture**.

### Core Architecture Patterns
- **State Management**: Riverpod — code-generated `Notifier`s (`@riverpod`) plus `FutureProvider`s. (No legacy `package:provider`.)
- **Data Layer**: Repository pattern with Hive (local) + HTTP API (remote)
- **Storage**: Hive NoSQL database for offline capabilities
- **Authentication**: JWT with auto-refresh mechanism stored in flutter_secure_storage

### Key Providers (lib/providers/)
- **`userNotifierProvider`** (`user_provider.dart`, `UserNotifier`/`UserState`) - Authentication, JWT management, role-based access
- **`inspectionNotifierProvider`** (`inspection_provider.dart`, `InspectionNotifier`/`InspectionState`) - Inspection CRUD, offline sync, auto-retry logic
- **`inspectionSessionNotifierProvider`** (`inspection_session_provider.dart`) - Active inspection session snapshot
- **`inspectionStatsProvider` / `monthlyInspectionStatsProvider`** (`stats_provider.dart`) - `@riverpod` async providers for dashboard stats
- Codegen: every provider uses `@riverpod`; regenerate `*.g.dart` part files via `dart run build_runner build --delete-conflicting-outputs`.

### Directory Structure
```
lib/
├── providers/     # State management (Riverpod notifiers + providers)
├── services/      # Business logic and API services
├── screens/       # UI screens by feature (auth/, home/, profile/, etc.)
├── models/        # Data classes and entities
├── data/          # Storage adapters and local database
├── utils/         # Helper utilities (user_role.dart, etc.)
├── widgets/       # Reusable UI components
└── constants/     # App-wide constants
```

## Key Features & Data Flow

### Inspection Workflow
1. **Offline-First**: Inspections saved locally in Hive, synced when online
2. **Image Handling**: Photos compressed and stored locally with UUID naming
3. **Auto-Sync**: Background synchronization with duplicate detection
4. **Multi-Step Forms**: Complex inspection process with state persistence

### Authentication System
- JWT tokens with refresh mechanism
- Role-based access (Admin/Inspector)
- Secure storage for sensitive data
- API base URL: `https://dev.certifide.in/api`

### Local Storage Strategy
- **Primary DB**: Hive NoSQL for inspection data
- **Images**: Device file system with organized naming
- **Secure Data**: flutter_secure_storage for tokens
- **Auto-cleanup**: Successful submissions trigger local data removal

## Platform Configuration

### Android (`android/app/build.gradle`)
- Package ID: `com.certifide.app`
- Java Version: 11 required
- Release signing currently commented out

### iOS
- Bundle display name needs updating from "Testapp"
- CocoaPods integration with proper scheme configuration
- Portrait + Landscape orientations supported

## Development Notes

### Common Issues & Solutions
- **iOS Build Issues**: Run `flutter clean && cd ios && pod install --clean-install`
- **Connectivity**: App handles offline/online transitions automatically
- **Token Refresh**: Automatic JWT refresh prevents auth errors

### State Management Patterns
- Widgets are `ConsumerWidget`/`ConsumerStatefulWidget`; use `ref.read(provider.notifier)` for actions and `ref.watch(provider)` for UI updates
- Prefer `ref.watch(provider.select((s) => s.field))` to rebuild only on the fields that matter
- For purely-local, transient UI state (spinners, highlights, timers), use `ValueNotifier` + `ValueListenableBuilder` so only that widget rebuilds instead of `setState` on the whole screen
- Services layer handles business logic, notifiers manage state
- After editing a `@riverpod` notifier, regenerate with `dart run build_runner build --delete-conflicting-outputs`

### Image & File Handling
- Images auto-compressed before storage
- File paths use UUID naming convention
- Cleanup logic prevents storage bloat

### API Integration
- HTTP service with proper error handling
- Retry logic for network failures
- JWT header injection for authenticated requests

## Testing Setup

Currently minimal test coverage. Test files should follow Flutter conventions:
- Unit tests in `test/`
- Widget tests for UI components
- Integration tests for full workflows