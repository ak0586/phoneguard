# Phase 1: Stability & Action Monitoring

## Overview
1.  **Fix Activity Logs:** Resolve the serialization bridge between Kotlin and Dart to ensure logs are visible in the app.
2.  **Running Actions Dashboard:** Implement a "Live Monitor" UI to see and stop currently running anti-theft actions (Alarm, Tracking, etc.).
3.  **Firebase Integration:** Initialize Firebase Auth and implement Login/Registration with email verification.
4.  **Activity Log & Cloud Storage:** Log actions to Firestore and upload captured thief photos.

---

## Technical Details

### 1. Fix Activity Logs
- **Issue**: Kotlin writes a raw JSON list string, but Flutter expects a `List<String>` where each string is JSON, or it handles the decoding incorrectly.
- **Solution**:
    - #### [MODIFY] [local_storage_datasource.dart](file:///d:/Flutter%20Apps/lost_phone_finder/lib/data/datasources/local_storage_datasource.dart)
        - Update `loadLogs` to handle raw JSON strings directly.
    - #### [MODIFY] [CommandParser.kt](file:///d:/Flutter%20Apps/lost_phone_finder/android/app/src/main/kotlin/com/example/lost_phone_finder/sms/CommandParser.kt)
        - Ensure Kotlin's field names (`senderNumber`, `command`, `result`, `success`) perfectly match Dart's `ActivityLog` model.

### 2. Running Actions Monitor
- **Background**: Currently, if an alarm or tracking is triggered by SMS, the app UI (AppProvider) doesn't know it's "Active" unless the app was already open.
- **Solution**:
    - #### [MODIFY] [AlarmController.kt](file:///d:/Flutter%20Apps/lost_phone_finder/android/app/src/main/kotlin/com/example/lost_phone_finder/alarm/AlarmController.kt)
        - Update shared prefs flag `isNativeAlarmActive` when alarm starts/stops.
    - #### [MODIFY] [TrackingService.kt](file:///d:/Flutter%20Apps/lost_phone_finder/android/app/src/main/kotlin/com/example/lost_phone_finder/services/TrackingService.kt)
        - Update shared prefs flag `isNativeTrackingActive` when service starts/stops.
    - #### [MODIFY] [AppProvider.dart](file:///d:/Flutter%20Apps/lost_phone_finder/lib/presentation/providers/app_provider.dart)
        - Poll or check these native flags on init/resume to show "Active Actions" banner.
    - #### [NEW] Dashboard "Active Actions" Card
        - Show a pulse animation if actions are running with a "STOP ALL" button.

### 3. Firebase Auth & Authentication
- **Tasks**:
    - Add `firebase_auth` and `firebase_core` to `pubspec.yaml`.
    - Implement `AuthScreen` (Login/Register).
    - Add **Verify Email** banner in Dashboard: `if (user != null && !user.emailVerified) { ... }`.
    - #### [NEW] [auth_service.dart](file:///d:/Flutter%20Apps/lost_phone_finder/lib/data/datasources/auth_service.dart)
    - #### [NEW] [login_screen.dart](file:///d:/Flutter%20Apps/lost_phone_finder/lib/presentation/screens/login_screen.dart)

### 4. Profiles & Monetization (Roadmap)
- **Profile**: Create `ProfileScreen` for editing Name, alternate email, and secondary phone number.
- **ADS**: Add `google_mobile_ads`. Show banner on dashboard and interstitial after a successful action trigger.
- **Revenue**: Integrate `in_app_purchase` for a "Premium Version" to unlock Cloud Backup and remove ads.

---

## Verification Plan

### Automated Tests
- Run `flutter test` for model serialization.

### Manual Verification
1.  **Activity Logs**: Trigger SMS command → verify `Activity Log` screen shows the new entry.
2.  **Running Actions**: Send "ALARM" SMS while app is closed → open app → verify "Alarm is Running" indicator is visible in Dashboard → click "Stop" and verify alarm stops.
3.  **Auth**: Register new account → verify email verification warning appears → verify login works.
