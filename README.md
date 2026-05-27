# 🛡️ PhoneGuard — Anti-Theft & Remote Recovery Suite

**PhoneGuard** is an enterprise-grade mobile security and remote device recovery solution designed for Android. Built using a decoupled architecture with **Flutter** for the cross-platform presentation layer and **Native Kotlin** for the secure background execution layer, it enables device owners to remotely track, alert, and lock their misplaced or stolen devices. 

Remote control commands can be issued either via secure SMS triggers or through a web-based dashboard utilizing battery-efficient Firebase Cloud Messaging (FCM).

---

## 📖 System Documentation Index

To explore specific modules of the PhoneGuard codebase, refer to the dedicated guides below:

*   **System Architecture & Flow**: [ARCHITECTURE.md](file:///d:/Flutter%20Apps/phoneguard/ARCHITECTURE.md)
*   **Web Dashboard & FCM API specs**: [API_DOCUMENTATION.md](file:///d:/Flutter%20Apps/phoneguard/API_DOCUMENTATION.md)
*   **Database & State Synchronization**: [DATABASE.md](file:///d:/Flutter%20Apps/phoneguard/DATABASE.md)
*   **Build Pipeline & Production Deployment**: [DEPLOYMENT.md](file:///d:/Flutter%20Apps/phoneguard/DEPLOYMENT.md)
*   **Contributing Standards & Branching**: [CONTRIBUTING.md](file:///d:/Flutter%20Apps/phoneguard/CONTRIBUTING.md)
*   **Troubleshooting & Debugging**: [TROUBLESHOOTING.md](file:///d:/Flutter%20Apps/phoneguard/TROUBLESHOOTING.md)
*   **Security Architecture & Hardening**: [SECURITY.md](file:///d:/Flutter%20Apps/phoneguard/SECURITY.md)
*   **Complete System Manual & Journeys**: [COMPLETE_SYSTEM_DOCUMENTATION.md](file:///d:/Flutter%20Apps/phoneguard/COMPLETE_SYSTEM_DOCUMENTATION.md)

---

## 1. Project Overview

### Project Name
*PhoneGuard* (Internal package identifier: `com.kyvronix.phoneguard`, Flutter codebase namespace: `lost_phone_finder`)

### Purpose of the Application
PhoneGuard provides device owners with a robust, tamper-resistant remote control suite to protect personal data and locate physical devices in theft or loss scenarios. Unlike standard operating system recovery tools that depend on a continuous high-speed data connection and open user sessions, PhoneGuard operates in the background with SMS-fallback triggers, booting receivers, and offline-first storage mechanisms.

### Problem It Solves
1.  **Connectivity Deficit**: Standard tracking apps fail if cellular data or Wi-Fi is disabled. PhoneGuard uses SMS triggers to bypass internet dependencies.
2.  **GPS Disabling**: Thieves immediately disable location services. PhoneGuard implements a 3-tier fallback location engine (High-accuracy GPS ➔ Network/Wi-Fi/Cell Triangulation ➔ OS Cached Last Location) to ensure location is reported.
3.  **App Interception**: Many third-party messaging apps intercept and consume SMS broadcasts (`abortBroadcast()`). PhoneGuard implements an OS-level database `ContentObserver` on the inbox to read triggers directly from the device's storage.
4.  **Device Lock Limitations**: Stock Android lock options can be bypassed if the device lacks security rules. PhoneGuard integrates with the Android Device Admin API to lock the screen instantly.
5.  **Evidence Collection Gap**: Owners need visual evidence of unauthorized users. PhoneGuard captures silent selfies of intruders on failed lock screen attempts and uploads them to the cloud.

### Target Users
*   **Individual Smartphone Owners**: Users seeking advanced anti-theft, silent-siren alarms, and remote location services.
*   **Enterprise IT Managers**: Organizations requiring remote locking and device status audits for employee mobile fleets.
*   **Elderly & Family Administrators**: Families managing safety and locations of dependent family members via offline SMS commands.

### Business Use Cases
*   **Remote Asset Retrieval**: Locating corporate devices lost in transit.
*   **Unauthorized Access Auditing**: Tracking physical tampering via intrusion logging.
*   **Loss Prevention**: Reducing company overhead by recovery instead of replacement.

---

## 2. Technical Stack Summary

PhoneGuard utilizes a modern, hybrid tech stack engineered for reliability and visual excellence:

| Tier | Technology | Purpose | Tradeoffs & Benefits |
| :--- | :--- | :--- | :--- |
| **Frontend UI** | Flutter & Dart (`^3.10.4`) | High-performance, reactive UI development with a premium dark-themed aesthetic. | **Benefit**: Single codebase for complex UI workflows; fast prototyping. **Tradeoff**: Increased initial application size. |
| **State Management**| Provider (`^6.1.2`) | Manages settings data, activity logs, and subscription statuses across screens. | **Benefit**: Lightweight, low boilerplate, clean separation of concerns. **Tradeoff**: Not suited for massive, multi-threaded reactive streams. |
| **Local Cache** | Hive (`^2.2.3`) & SharedPrefs | local caching for settings and UI logs. | **Benefit**: Sub-millisecond reads/writes. SharedPreferences acts as the bridge for Kotlin services. |
| **Cloud Database** | Cloud Firestore | Syncs live user document settings, remote command requests, and Base64 intrusion pictures. | **Benefit**: Real-time WebSocket connection. Offline sync out of the box. |
| **Authentication** | Firebase Auth | Email/password sign-up and Google Sign-in. | **Benefit**: Industry-standard secure sessions. |
| **Native Execution**| Kotlin & CameraX | OS-level SMS interception, hidden Camera2 API execution, boot listeners, and Device Admin. | **Benefit**: Accesses raw hardware APIs and runs background tasks even when Dart VM is suspended. |

---

## 3. High-Level System Architecture

```mermaid
graph TD
    %% Presentation Layer
    subgraph Flutter Presentation
        UI[Material Design UI] <--> Prov[Providers: Auth/App/Sub]
        Prov <--> Repo[AppRepository]
    end

    %% Data Layer
    subgraph Data Layer
        Repo <--> HiveDB[(Hive Cache)]
        Repo <--> SP[SharedPreferences]
        Repo <--> FA[Firebase Auth]
    end

    %% Native Layer
    subgraph Native Android Layer (Kotlin)
        SP <.-> StateSync[StateSyncManager]
        MainActivity[MainActivity] <-->|MethodChannel| UI
        
        subgraph Background Services
            RecSvc[RecoveryService] -->|Monitors SMS| ContentObserver
            TrackSvc[TrackingService] -->|Interval Location| SmsSender
            AlarmSvc[AlarmService] -->|Audible Alert| AudioController
            IntrusionSvc[IntrusionCameraService] -->|Silent CameraX Capture| Cam2[Camera API]
        end
        
        subgraph Hardware Receivers
            SmsReceiver[SmsReceiver] -->|Priority 1000| Parser[CommandParser]
            ContentObserver --> Parser
            BootReceiver[BootReceiver] -->|Trigger Boot Startup| RecSvc
            ShutdownReceiver[ShutdownReceiver] -->|Trigger State Sync| StateSync
            SimReceiver[SimChangeReceiver] -->|Verify SIM IMSI| SmsSender
            AdminReceiver[DeviceAdminReceiver] -->|Catch Failed Pattern| IntrusionSvc
        end
    end

    %% Remote Cloud
    subgraph Firebase Cloud
        Firestore[(Firestore DB)] <.->|Snapshot Listener| MainActivity
        Firestore <.->|Snapshot Listener| RecSvc
        Firestore <.->|State Sync| StateSync
        FCM[Firebase Cloud Messaging] -->|Background Dispatch| FcmHandler[FcmCommandHandler]
        FcmHandler --> Parser
    end

    %% User Dashboard Interaction
    WebDashboard[Web Dashboard] -->|Command Update| Firestore
    WebDashboard -->|Push Trigger| FCM
```

---

## 4. Codebase Directory Map

```
phoneguard/
├── android/                         # Native Android Gradle Project
│   └── app/src/main/kotlin/com/kyvronix/phoneguard/
│       ├── MainActivity.kt          # MethodChannel Handler
│       ├── MainApplication.kt       # Application Context Initialization
│       ├── alarm/                   # Media Player Volume Override
│       ├── location/                # 3-Tier GPS Fallback Algorithm
│       ├── receivers/               # Boot, Shutdown, and SIM State Receivers
│       ├── security/                # DeviceAdmin and CameraX Stealth Service
│       ├── services/                # Recovery, Tracking, and FCM Background Services
│       ├── sms/                     # SmsReceiver and CountDownLatch SmsSender
│       └── utils/                   # Shared SharedPreferences / Firestore Sync
├── assets/                          # Static audio cues, Google logos, and app icons
├── lib/                             # Flutter Codebase
│   ├── core/                        # Global Constants, Shared Themes, and Utilities
│   ├── data/                        # Hive & SharedPreferences Data Sources
│   ├── domain/                      # Models and Repository Specifications
│   └── presentation/                # Providers, Widgets, and Screens
├── pubspec.yaml                     # Dependencies and Metadata Config
└── README.md                        # Master Documentation Index
```

---

## 5. Local Setup & Development Onboarding

### Prerequisites
1.  **Flutter SDK**: `>= 3.10.4`
2.  **Java Development Kit (JDK)**: JDK 17 (recommended for Gradle build compatibility)
3.  **Android SDK & NDK**: Command-line tools or Android Studio configuration
4.  **Firebase Console Access**: A Firebase project to host your database

### Project Installation
Clone the repository and install the dependencies:
```bash
git clone https://github.com/kyvronix/phoneguard.git
cd phoneguard
flutter pub get
```

### Firebase Integration
1.  Create an Android application in your Firebase Console using the package name `com.kyvronix.phoneguard`.
2.  Download the generated `google-services.json` file.
3.  Place it in the [android/app/](file:///d:/Flutter%20Apps/phoneguard/android/app/) directory.
4.  Enable **Email/Password** and **Google** sign-in providers in Firebase Authentication.
5.  Enable **Cloud Firestore** and apply security rules.

### Running in Development
Connect an Android device with USB debugging enabled, then execute:
```bash
flutter run
```

*For troubleshooting build, Gradle, or permission issues, refer to [TROUBLESHOOTING.md](file:///d:/Flutter%20Apps/phoneguard/TROUBLESHOOTING.md).*
