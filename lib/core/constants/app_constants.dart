/// App-wide constants for Lost Phone Finder
class AppConstants {
  AppConstants._();

  // Platform channel name (must match MainActivity.kt)
  static const String channelName = 'lost_phone_finder/channel';

  // SharedPreferences keys
  static const String keyTrustedNumbers = 'trusted_numbers';
  static const String keyTriggerKeyword = 'trigger_keyword';
  static const String keyPin = 'pin';
  static const String keyPinEnabled = 'pin_enabled';
  static const String keyStealthMode = 'stealth_mode';
  static const String keySecretDialCode = 'secret_dial_code';
  static const String keyActivityLogs = 'activity_logs';
  static const String keyDefaultActions = 'default_actions';
  static const String keyOnboardingDone = 'onboarding_done';

  // Default values
  static const String defaultTriggerKeyword = 'miss you phone';
  static const String defaultSecretDialCode = '*#4321#';
  static const int trackingIntervalMinutes = 3;
  static const int maxActivityLogs = 200;

  // Platform channel methods
  static const String methodStartAlarm = 'startAlarm';
  static const String methodStopAlarm = 'stopAlarm';
  static const String methodAddLog = 'addLog';
  static const String methodGetLogs = 'getLogs';
  static const String methodRequestDeviceAdmin = 'requestDeviceAdmin';
  static const String methodDeactivateDeviceAdmin = 'deactivateDeviceAdmin';
  static const String methodIsDeviceAdminActive = 'isDeviceAdminActive';
  static const String methodStartTrackingService = 'startTrackingService';
  static const String methodStopTrackingService = 'stopTrackingService';
  static const String methodSendSms = 'sendSms';
  static const String methodLockDevice = 'lockDevice';
  static const String methodOpenAccessibilitySettings = 'openAccessibilitySettings';
  static const String methodOpenAppInfo = 'openAppInfo';
  static const String methodOpenBatteryOptimizationSettings = 'openBatteryOptimizationSettings';

  // Commands
  static const String cmdLocation = 'location';
  static const String cmdAlarm = 'alarm';
  static const String cmdTrack = 'track';
  static const String cmdStop = 'stop';
  static const String cmdAudio = 'audio';
  static const String cmdLock = 'lock';

  // Notification
  static const String notificationChannelId = 'recovery_service';
  static const String notificationChannelName = 'Recovery Service';
}
