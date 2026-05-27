# 🤝 PhoneGuard — Developer Contribution Guidelines

This document outlines the coding standards, clean architecture principles, state management conventions, and branching strategies required when contributing to the PhoneGuard repository.

---

## 1. Developer Onboarding Checklist

When joining the engineering team, complete these steps:

1.  **Environment Setup**: Verify Flutter SDK `3.10.4` and Java JDK `17` are configured correctly by running `flutter doctor`.
2.  **IDE Hardening**: Enable "Format on Save" in VS Code (`editor.formatOnSave`) or Android Studio. This ensures all files conform to the standard dart formatter rules.
3.  **Firebase Stub**: Download the private development sandbox `google-services.json` from the Slack workspace and place it under `android/app/`.
4.  **Local Build Check**: Execute `flutter run` on a connected developer device (API level 26+).
5.  **Verify Analysis Integrity**: Run `flutter analyze` locally to ensure there are no pre-existing syntax or linter warnings.

---

## 2. Git Branching & Lifecycle Strategy

PhoneGuard utilizes a structured **Git Flow** strategy to prevent main trunk destabilization.

```
                  ┌──────────────┐ (Hotfix)
                  │   hotfix/*   ├─────────┐
                  └──────▲───────┘         │
                         │ Merges          │
                         │ Critical        ▼
┌──────────────┐         │ Fixes    ┌──────────────┐
│    main      ├─────────┴─────────➔│    main      │ (Production Release)
└──────┬───────┘                    └──────▲───────┘
       │                                   │
       │ Branch                            │ Merge Release
       ▼                                   │
┌──────────────┐                    ┌──────┴───────┐
│   develop    ├───────────────────➔│  release/*   │ (QA & Staging)
└──────┬───────┘                    └──────▲───────┘
       │                                   │
       │ Feature Branch                    │ Merge Feature
       ▼                                   │
┌──────────────┐                           │
│  feature/*   ├───────────────────────────┘
└──────────────┘
```

*   **`main` Branch**: Contains the exact version running in production. Only release tags and hotfix branches can be merged directly into `main`.
*   **`develop` Branch**: Main consolidation space for feature integrations. 
*   **`feature/*` Branches**: Feature implementations (e.g. `feature/fcm-command-sync`). Branch off `develop`, submit PR back to `develop`.
*   **`release/*` Branches**: Temporary branches built for staging/QA validation. Merge to `main` and `develop` when approved.
*   **`hotfix/*` Branches**: Address production bugs directly. Branch off `main`, merge to `main` and `develop`.

---

## 3. Architecture & SOLID Implementation

The PhoneGuard codebase adheres to **Clean Architecture** boundaries separated into three distinct layers:

### A. Presentation Layer (`lib/presentation`)
Responsible for rendering the user interface and mapping interactions.
*   **Widgets**: UI components (buttons, dialogs, charts) should be stateless. They rely on the layout tree context to retrieve themes and localized assets.
*   **Providers**: Control presentation logic and screen states. They emit update triggers to listeners via `notifyListeners()` when data changes.

### B. Domain Layer (`lib/domain`)
Houses the business rules, data entities, and repository specifications.
*   **Entities**: Pure Dart objects representing settings data, active logs, and profile info without any dependencies on persistence frameworks.
*   **Repositories (Interfaces)**: Declarative interfaces specifying access methods. They are implemented in the data layer.

### C. Data Layer (`lib/data`)
Coordinates database interactions, device settings caches, and networking.
*   **Data Sources**: Interact directly with external drivers (Hive, SharedPreferences, Firestore, MethodChannel APIs).
*   **Repositories (Implementations)**: Implement domain interfaces. They retrieve data from data sources and format them into domain models.

---

## 4. Coding Standards & Naming Rules

### Dart Style Guide
We follow the official [Dart Style Guide rules](https://dart.dev/effective-dart/style).

*   **Classes & Types**: `UpperCamelCase` (e.g., `IntrusionCameraService`).
*   **Variables, Parameters & Methods**: `lowerCamelCase` (e.g., `fusedLocationClient`).
*   **Files & Directories**: `snake_case` (e.g., `native_service.dart`).
*   **Async Operations**: Always await Futures explicitly. Avoid `.then()` chaining.
*   **Null Safety**: Use assertive null checks (`!`) sparingly. Prefer defensive checks or default fallbacks (`??`).

### Kotlin Style Guide
*   **Classes**: `PascalCase` (e.g., `SmsReceiver`).
*   **Variables**: `lowerCamelCase` (e.g., `lastProcessedSmsId`).
*   **Constants**: `UPPER_SNAKE_CASE` (e.g., `DEDUPE_WINDOW_MS`).
*   **Scope Protection**: Mark variables and methods as `private` or `internal` by default. Expose public functions only when necessary.

---

## 5. Design Patterns in Use

1.  **Repository Pattern**: Exposes data interfaces in the domain layer, abstracting local Hive boxes and SharedPreferences synchronization from the UI widgets.
2.  **Observer Pattern (Provider)**: Coordinates UI widget updates when background tasks complete.
3.  **Bypass/Bridge Pattern**: Implemented on the native Android layer to intercept SMS triggers via receivers or observers and dispatch them to the command parser.
4.  **Worker/Task Pattern (WorkManager)**: Defers state syncs to background workers (`SyncWorker`) to satisfy system-level background execution constraints.
