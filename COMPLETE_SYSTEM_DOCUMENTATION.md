# 🛡️ PhoneGuard — Comprehensive System Documentation & Developer Manual

Welcome to the master technical manual for **PhoneGuard** (package: `com.kyvronix.phoneguard`). This document serves as the official enterprise reference for developers, security auditors, systems operators, and QA engineers.

---

## 📋 Comprehensive Directory of Guides

*   **Quick Start & Setup**: [README.md](file:///d:/Flutter%20Apps/phoneguard/README.md)
*   **System Architecture & Flow**: [ARCHITECTURE.md](file:///d:/Flutter%20Apps/phoneguard/ARCHITECTURE.md)
*   **FCM Data & Dashboard Spec**: [API_DOCUMENTATION.md](file:///d:/Flutter%20Apps/phoneguard/API_DOCUMENTATION.md)
*   **Local & Cloud Database schemas**: [DATABASE.md](file:///d:/Flutter%20Apps/phoneguard/DATABASE.md)
*   **Production Deployment Manual**: [DEPLOYMENT.md](file:///d:/Flutter%20Apps/phoneguard/DEPLOYMENT.md)
*   **Code Quality & Standard Operating Procedures**: [CONTRIBUTING.md](file:///d:/Flutter%20Apps/phoneguard/CONTRIBUTING.md)
*   **Troubleshooting Guide**: [TROUBLESHOOTING.md](file:///d:/Flutter%20Apps/phoneguard/TROUBLESHOOTING.md)
*   **Security & Hardening Spec**: [SECURITY.md](file:///d:/Flutter%20Apps/phoneguard/SECURITY.md)

---

## 1. Project Overview

### High-Level Summary
PhoneGuard is an advanced anti-theft and remote recovery solution. It provides a secure, reliable communication bridge between the device owner and their hardware. If a device is lost or stolen, the owner can remotely locate it, sound an alarm, lock the screen, and capture photos of unauthorized users.

### Purpose & Business Value
*   **Loss Prevention**: Reduces device replacement costs.
*   **Data Integrity**: Prevents unauthorized access to sensitive local storage.
*   **Evidence Collection**: Captures intruder photos, network IP addresses, and GPS locations to aid recovery efforts.

---

## 2. System Architecture

For a detailed architectural overview and flowcharts, refer to [ARCHITECTURE.md](file:///d:/Flutter%20Apps/phoneguard/ARCHITECTURE.md).

### Communication Protocol
PhoneGuard uses a dual-channel remote control model:
1.  **Direct SMS Line (Data Connection Independent)**: Allows trusted numbers to trigger recovery actions using a customizable keyword, bypassing internet dependencies.
2.  **Web Dashboard (IP Connection Dependent)**: Pushes remote commands to the device in real time via Cloud Firestore WebSockets and Firebase Cloud Messaging (FCM).

---

## 3. Tech Stack Deep-Dive

For build configurations and deployment details, refer to [DEPLOYMENT.md](file:///d:/Flutter%20Apps/phoneguard/DEPLOYMENT.md).

*   **Dart & Flutter**: Cross-platform presentation layer.
*   **Native Kotlin**: System-level integration (broadcast receivers, background tasks, device administration policies).
*   **Firebase Authentication**: User accounts and secure login sessions.
*   **Cloud Firestore**: Real-time database and command queue.
*   **Hive**: Local key-value database for quick UI state access.
*   **SharedPreferences**: Cross-process data bridge between Flutter and Kotlin.

---

## 4. Codebase Directory Map

For formatting guidelines and code standards, refer to [CONTRIBUTING.md](file:///d:/Flutter%20Apps/phoneguard/CONTRIBUTING.md).

*   `lib/domain/`: Domain entities and repository definitions.
*   `lib/data/`: Concrete implementations of data repositories, Hive boxes, and local storage.
*   `lib/presentation/`: UI screens, custom widgets, and Provider state wrappers.
*   `android/app/src/main/kotlin/com/kyvronix/phoneguard/`:
    *   `alarm/`: Volume overrides and media players.
    *   `location/`: 3-tier GPS fallback logic.
    *   `receivers/`: System-level broadcast receivers (Boot, Shutdown, SIM state).
    *   `security/`: Device administration and camera capture.
    *   `services/`: Foreground recovery and tracking tasks.
    *   `sms/`: Incoming SMS parsers and dual-SIM outbound managers.

---

## 5. System Execution Workflows

### A. Device Setup Workflow
1.  **Installation**: User downloads the app, creates an account, and completes email verification.
2.  **Permission Request**: App requests critical permissions: SMS, Location, Background Location, Camera, Contacts, Notification.
3.  **Admin Provisioning**: Prompts the user to activate the **Device Policy Manager** to enable screen-locking features.
4.  **Configuration**: User sets a custom SMS keyword trigger (default: `miss you phone`) and registers trusted contacts.
5.  **Initialization**: Active configuration variables are written to local Hive storage and synced with SharedPreferences and Firestore.

### B. Remote Recovery Workflow
```
[User on Web Dashboard] ➔ Issues Lock Command ➔ Written to Firestore & Sent via FCM
                                                               │
                                                               ▼
[PhoneGuard Service] ➔ Intercepts Event ➔ Checks Sub Expiry ➔ Executes Lock via DeviceAdmin
```

---

## 6. Module-by-Module Technical Reference

### A. Location Manager
*   **File**: [LocationManager.kt](file:///d:/Flutter%20Apps/phoneguard/android/app/src/main/kotlin/com/kyvronix/phoneguard/location/LocationManager.kt)
*   **Logic**: Falls back gracefully: GPS (High Accuracy, 10s timeout) ➔ Network/Wi-Fi Triangulation (8s timeout) ➔ Last Known OS Location Cache.

### B. Silent Camera Service
*   **File**: [IntrusionCameraService.kt](file:///d:/Flutter%20Apps/phoneguard/android/app/src/main/kotlin/com/kyvronix/phoneguard/security/IntrusionCameraService.kt)
*   **Logic**: Uses Android CameraX to capture a front-camera selfie silently on failed unlock attempts. The photo is rotated, scaled down to 640px, compressed to WebP, and uploaded to Firestore as a Base64 string.

### C. Outbound SMS Manager
*   **File**: [SmsSender.kt](file:///d:/Flutter%20Apps/phoneguard/android/app/src/main/kotlin/com/kyvronix/phoneguard/sms/SmsSender.kt)
*   **Logic**: Loops through active SIM subscriptions using a `CountDownLatch` and temporary broadcast receivers to support dual-SIM devices.

---

## 7. Web Dashboard API Specifications

For endpoint payloads and JSON schemas, refer to [API_DOCUMENTATION.md](file:///d:/Flutter%20Apps/phoneguard/API_DOCUMENTATION.md).

---

## 8. Database Architecture

For entity relationships and cross-process data bridge specifications, refer to [DATABASE.md](file:///d:/Flutter%20Apps/phoneguard/DATABASE.md).

---

## 9. Security & Access Control

For security policies and deduplication rules, refer to [SECURITY.md](file:///d:/Flutter%20Apps/phoneguard/SECURITY.md).

*   **Device Admin Protection**: Requires screen-lock verification (PIN, pattern) before the permission can be removed.
*   **Fuzzy Number Matching**: Handles country codes and formatting differences to verify SMS sender identity.
*   **Deduplication**: Drops duplicate commands received within 60 seconds.

---

## 10. Development Sandbox Setup

For environment setup and installation steps, refer to [README.md](file:///d:/Flutter%20Apps/phoneguard/README.md).

---

## 11. Production Release Instructions

For building signed binaries (`.aab`) and configuring keystores, refer to [DEPLOYMENT.md](file:///d:/Flutter%20Apps/phoneguard/DEPLOYMENT.md).

---

## 12. Code Quality & Formatting Standards

For clean architecture rules and design patterns, refer to [CONTRIBUTING.md](file:///d:/Flutter%20Apps/phoneguard/CONTRIBUTING.md).

---

## 13. System Logs & Auditing

PhoneGuard logs security events to monitor device activity:
*   **Local History**: Saves activity logs to `SharedPreferences` (`flutter.activity_logs`). The list is capped at 200 entries to prevent memory bloat.
*   **Cloud Auditing**: Logs are synced to the `users/{uid}/activity_logs` Firestore collection, enabling remote monitoring of recovery actions.

---

## 14. Attack Vector Protections

*   **Brute-Force Lock bypass**: Screen lock failures are monitored via the Device Admin API, triggering silent photo captures if the failure threshold is reached.
*   **SMS Broadcast Hijacking**: Intercepts SMS commands using a maximum priority `SmsReceiver` (1000) and an OS-level `ContentObserver` fallback, bypassing third-party messaging apps that attempt to block notifications.

---

## 15. Testing Protocols

Before deploying updates, run these quality assurance steps:

### A. Static Code Analysis
Run static analysis to check formatting and identify syntax issues:
```bash
flutter analyze
```

### B. Automated Testing
Run unit and widget tests:
```bash
flutter test
```

### C. Manual Verification Steps
1.  Verify SMS command processing under mock settings.
2.  Test SIM change detection by executing a mock broadcast update using `adb`.
3.  Verify Device Admin lock activation and deactivation flows.

---

## 16. Performance Hardening

*   **Reduced MethodChannel Polling**: Polling intervals are adjusted from 5 seconds to 30 seconds when the app is in the foreground, reducing unnecessary background processing.
*   **Lifecycle-Aware Background Tasks**: Polling timers are automatically suspended when the app is in the background.
*   **Memory Management**: Photo sizes are scaled down to 640px and capped at a maximum of 5 images on Firestore, preventing document bloat.

---

## 17. Current Technical Limitations

1.  **Direct Boot Restrictions**: If a device is rebooted, native receivers cannot access encrypted user SharedPreferences until the user enters their PIN/Pattern for the first time.
2.  **OS Background Limits**: Aggressive battery-saving policies on certain Android forks (such as Xiaomi's MIUI or Samsung's One UI) may terminate background services. Users must be guided to disable battery optimization for PhoneGuard.

---

## 18. Developer Onboarding Instructions

For git workflows and coding rules, refer to [CONTRIBUTING.md](file:///d:/Flutter%20Apps/phoneguard/CONTRIBUTING.md).

---

## 19. Common Troubleshooting Rules

For Gradle issues and runtime error handling, refer to [TROUBLESHOOTING.md](file:///d:/Flutter%20Apps/phoneguard/TROUBLESHOOTING.md).

---

## 20. Future Product Roadmap

*   **Mock Shut-down Screens**: Display a fake shutdown dialog when a thief attempts to turn off the phone, allowing the app to keep tracking the device in the background.
*   **Intruder Voice Captures**: Record ambient audio via the microphone on failed unlock attempts and save the clips to Firestore.
*   **WhatsApp Command Support**: Extend command verification to incoming WhatsApp messages using notification listeners.
