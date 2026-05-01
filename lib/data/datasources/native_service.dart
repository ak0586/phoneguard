import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';

/// Service that bridges Flutter to native Android via MethodChannel
/// All system-level operations are delegated to Kotlin
class NativeService {
  static const MethodChannel _channel = MethodChannel(AppConstants.channelName);


  // ─── Alarm ───────────────────────────────────────────────────────────────

  Future<void> startAlarm() async {
    try {
      await _channel.invokeMethod<void>(AppConstants.methodStartAlarm);
    } on PlatformException catch (e) {
      throw Exception('Failed to start alarm: ${e.message}');
    }
  }

  Future<void> stopAlarm() async {
    try {
      await _channel.invokeMethod<void>(AppConstants.methodStopAlarm);
    } on PlatformException catch (e) {
      throw Exception('Failed to stop alarm: ${e.message}');
    }
  }

  // ─── Tracking ────────────────────────────────────────────────────────────

  Future<void> startTracking({required String targetNumber}) async {
    try {
      await _channel.invokeMethod<void>(
        AppConstants.methodStartTrackingService,
        {'targetNumber': targetNumber},
      );
    } on PlatformException catch (e) {
      throw Exception('Failed to start tracking: ${e.message}');
    }
  }

  Future<void> stopTracking() async {
    try {
      await _channel.invokeMethod<void>(AppConstants.methodStopTrackingService);
    } on PlatformException catch (e) {
      throw Exception('Failed to stop tracking: ${e.message}');
    }
  }

  // ─── Device Admin ────────────────────────────────────────────────────────

  Future<void> requestDeviceAdmin() async {
    try {
      await _channel.invokeMethod<void>(AppConstants.methodRequestDeviceAdmin);
    } on PlatformException catch (e) {
      throw Exception('Failed to request device admin: ${e.message}');
    }
  }
  Future<void> deactivateDeviceAdmin() async {
    try {
      await _channel.invokeMethod<void>(AppConstants.methodDeactivateDeviceAdmin);
    } on PlatformException catch (e) {
      throw Exception('Failed to deactivate device admin: ${e.message}');
    }
  }

  Future<bool> isDeviceAdminActive() async {
    try {
      final result = await _channel.invokeMethod<bool>(
        AppConstants.methodIsDeviceAdminActive,
      );
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  // ─── Lock Device ─────────────────────────────────────────────────────────

  Future<void> lockDevice() async {
    try {
      await _channel.invokeMethod<void>(AppConstants.methodLockDevice);
    } on PlatformException catch (e) {
      throw Exception('Failed to lock device: ${e.message}');
    }
  }

  // ─── SMS ─────────────────────────────────────────────────────────────────

  Future<void> sendSms({required String to, required String message}) async {
    try {
      await _channel.invokeMethod<void>(AppConstants.methodSendSms, {
        'to': to,
        'message': message,
      });
    } on PlatformException catch (e) {
      throw Exception('Failed to send SMS: ${e.message}');
    }
  }

  Future<bool> isAlarmActive() async {
    try {
      final result = await _channel.invokeMethod<bool>('isAlarmActive');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> isTrackingRunning() async {
    try {
      final result = await _channel.invokeMethod<bool>('isTrackingRunning');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod<void>(
        AppConstants.methodOpenAccessibilitySettings,
      );
    } on PlatformException catch (e) {
      throw Exception('Failed to open accessibility settings: ${e.message}');
    }
  }

  Future<void> captureIntruderPhoto() async {
    try {
      await _channel.invokeMethod<void>('captureIntruderPhoto');
    } on PlatformException catch (e) {
      throw Exception('Failed to capture photo: ${e.message}');
    }
  }

  Future<void> startFirestoreCommandService() async {
    try {
      await _channel.invokeMethod<void>('startFirestoreCommandService');
    } on PlatformException catch (e) {
      debugPrint('Failed to start command service: ${e.message}');
    }
  }

  Future<void> stopFirestoreCommandService() async {
    try {
      await _channel.invokeMethod<void>('stopFirestoreCommandService');
    } on PlatformException catch (e) {
      debugPrint('Failed to stop command service: ${e.message}');
    }
  }
}
