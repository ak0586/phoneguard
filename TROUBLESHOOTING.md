# 🛠️ PhoneGuard — Build & Runtime Troubleshooting Guide

This guide lists common errors, build failures, runtime issues, and debugging techniques when working on PhoneGuard.

---

## 1. Android Compilation & Build Failures

### A. Android Manifest Merger Failure
*   **Symptom**: Compilation fails with `Manifest merger failed: Attribute meta-data#com.google.android.gms.ads.APPLICATION_ID...`.
*   **Cause**: The application is compiled without specifying a valid AdMob Application ID in the Android Manifest.
*   **Resolution**: 
    1. Open [android/app/src/main/AndroidManifest.xml](file:///d:/Flutter%20Apps/phoneguard/android/app/src/main/AndroidManifest.xml).
    2. Ensure the `<meta-data>` node contains a valid Application ID value:
    ```xml
    <meta-data
        android:name="com.google.android.gms.ads.APPLICATION_ID"
        android:value="ca-app-pub-3940256099942544~3347511713"/> <!-- Test ID -->
    ```

### B. Keystore Configuration & Missing Signing Key
*   **Symptom**: Release compilation fails with `Keystore file not found...` or `key.properties file is missing`.
*   **Cause**: Gradle cannot locate your local release keys or the configuration properties file.
*   **Resolution**:
    1. Verify that `key.properties` exists in your [android/](file:///d:/Flutter%20Apps/phoneguard/android/) directory.
    2. Check that the `storeFile` property contains the correct absolute path to your `.jks` file.
    3. For local debug builds, you can bypass release signing config:
    ```bash
    flutter run --debug
    ```

### C. Gradle Multidex Exception
*   **Symptom**: Build fails with `The number of method references in a .dex file cannot exceed 64K`.
*   **Cause**: Combining Firebase, Google Play Billing, AdMob, and CameraX exceeds standard DX limits.
*   **Resolution**: Enable multidex in [android/app/build.gradle](file:///d:/Flutter%20Apps/phoneguard/android/app/build.gradle):
    ```groovy
    android {
        defaultConfig {
            multiDexEnabled true
        }
    }
    ```

---

## 2. Runtime Platform Exceptions

### A. MethodChannel PlatformException (`NOT_ADMIN`)
*   **Symptom**: Calling `lockDevice` throws `PlatformException(NOT_ADMIN, Device admin not active, null)`.
*   **Cause**: The user has not activated the Device Administrator permission for PhoneGuard in system settings.
*   **Resolution**:
    1. Navigate to Settings ➔ Security ➔ Device Admin Apps.
    2. Toggle **PhoneGuard** to **Active**.
    3. In production, check permission status in code before running locks:
    ```dart
    final isActive = await nativeService.isDeviceAdminActive();
    if (!isActive) {
      await nativeService.requestDeviceAdmin();
    }
    ```

### B. Foreground Service Exception (Android 14+ Constraints)
*   **Symptom**: App crashes with `SecurityException: Starting FGS without type...` or `Foreground service type not allowed`.
*   **Cause**: Android 14 (API 34) requires foreground services to declare specific types and request matching runtime permissions.
*   **Resolution**:
    1. Verify foreground service type attributes in [AndroidManifest.xml](file:///d:/Flutter%20Apps/phoneguard/android/app/src/main/AndroidManifest.xml):
    ```xml
    <service
        android:name=".services.TrackingService"
        android:foregroundServiceType="location" />
    ```
    2. Request foreground permission rules at startup:
    ```xml
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_CAMERA"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE"/>
    ```

---

## 3. ADB Debugging & Test Commands

Utilize the Android Debug Bridge (`adb`) CLI tool to test background receivers and hardware changes:

### A. Triggering Mock Boot Completion
Test the `BootReceiver` startup sequence without restarting the device:
```bash
adb shell am broadcast -a android.intent.action.BOOT_COMPLETED -p com.kyvronix.phoneguard
```

### B. Triggering Mock SIM Card Loaded State
Verify SMS SIM swap detection flows:
```bash
adb shell am broadcast -a android.intent.action.SIM_STATE_CHANGED --es ss LOADED
```

### C. Capturing Native Log Output (Logcat Filter)
Monitor native Kotlin print lines and command execution updates in your terminal:
```bash
adb logcat -s SmsReceiver:D CommandParser:D LocationManager:D IntrusionCameraService:D DeviceAdminReceiver:D
```

### D. Clearing Local Databases & Permissions
Reset the local testing state of your device:
```bash
adb shell pm clear com.kyvronix.phoneguard
```
