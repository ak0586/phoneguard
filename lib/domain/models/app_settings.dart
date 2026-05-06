import 'dart:convert';
import 'trusted_number.dart';

/// Holds all default recovery actions configuration
class DefaultActions {
  final bool sendLocation;
  final bool startAlarm;
  final bool enableTracking;
  final bool stopAlarmOnTrigger;
  final bool lockDevice;

  const DefaultActions({
    this.sendLocation = true,
    this.startAlarm = false,
    this.enableTracking = true,
    this.stopAlarmOnTrigger = false,
    this.lockDevice = true,
  });

  DefaultActions copyWith({
    bool? sendLocation,
    bool? startAlarm,
    bool? enableTracking,
    bool? stopAlarmOnTrigger,
    bool? lockDevice,
  }) {
    return DefaultActions(
      sendLocation: sendLocation ?? this.sendLocation,
      startAlarm: startAlarm ?? this.startAlarm,
      enableTracking: enableTracking ?? this.enableTracking,
      stopAlarmOnTrigger: stopAlarmOnTrigger ?? this.stopAlarmOnTrigger,
      lockDevice: lockDevice ?? this.lockDevice,
    );
  }

  Map<String, dynamic> toMap() => {
    'sendLocation': sendLocation,
    'startAlarm': startAlarm,
    'enableTracking': enableTracking,
    'stopAlarmOnTrigger': stopAlarmOnTrigger,
    'lockDevice': lockDevice,
  };

  factory DefaultActions.fromMap(Map<String, dynamic> map) => DefaultActions(
    sendLocation: map['sendLocation'] as bool? ?? true,
    startAlarm: map['startAlarm'] as bool? ?? false,
    enableTracking: map['enableTracking'] as bool? ?? true,
    stopAlarmOnTrigger: map['stopAlarmOnTrigger'] as bool? ?? false,
    lockDevice: map['lockDevice'] as bool? ?? true,
  );
}

/// Central app settings model
class AppSettings {
  final String triggerKeyword;
  final String pin;
  final bool isPinEnabled;
  final DefaultActions defaultActions;
  final List<TrustedNumber> trustedNumbers;
  final bool isInitialized;
  final bool onboardingDone;
  final bool isDarkMode;
  final String languageCode;
  
  // New Settings
  final bool intrusionSelfieEnabled;
  final int intrusionThreshold;
  final bool silentBypassEnabled;
  final bool simChangeAlertEnabled;

  const AppSettings({
    this.triggerKeyword = 'miss you phone',
    this.pin = '',
    this.isPinEnabled = false,
    this.defaultActions = const DefaultActions(),
    this.trustedNumbers = const [],
    this.isInitialized = false,
    this.onboardingDone = false,
    this.isDarkMode = true,
    this.languageCode = 'en',
    this.intrusionSelfieEnabled = true,
    this.intrusionThreshold = 2,
    this.silentBypassEnabled = true,
    this.simChangeAlertEnabled = true,
  });

  AppSettings copyWith({
    bool? isInitialized,
    List<TrustedNumber>? trustedNumbers,
    String? triggerKeyword,
    String? pin,
    bool? isPinEnabled,
    DefaultActions? defaultActions,
    bool? onboardingDone,
    bool? isDarkMode,
    String? languageCode,
    bool? intrusionSelfieEnabled,
    int? intrusionThreshold,
    bool? silentBypassEnabled,
    bool? simChangeAlertEnabled,
  }) {
    return AppSettings(
      isInitialized: isInitialized ?? this.isInitialized,
      trustedNumbers: trustedNumbers ?? this.trustedNumbers,
      triggerKeyword: triggerKeyword ?? this.triggerKeyword,
      pin: pin ?? this.pin,
      isPinEnabled: isPinEnabled ?? this.isPinEnabled,
      defaultActions: defaultActions ?? this.defaultActions,
      onboardingDone: onboardingDone ?? this.onboardingDone,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      languageCode: languageCode ?? this.languageCode,
      intrusionSelfieEnabled: intrusionSelfieEnabled ?? this.intrusionSelfieEnabled,
      intrusionThreshold: intrusionThreshold ?? this.intrusionThreshold,
      silentBypassEnabled: silentBypassEnabled ?? this.silentBypassEnabled,
      simChangeAlertEnabled: simChangeAlertEnabled ?? this.simChangeAlertEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'triggerKeyword': triggerKeyword,
      'pin': pin,
      'isPinEnabled': isPinEnabled,
      'trustedNumbers': trustedNumbers.map((n) => n.toMap()).toList(),
      'defaultActions': defaultActions.toMap(),
      'onboardingDone': onboardingDone,
      'is_dark_mode': isDarkMode,
      'language_code': languageCode,
      'intrusionSelfieEnabled': intrusionSelfieEnabled,
      'intrusionThreshold': intrusionThreshold,
      'silentBypassEnabled': silentBypassEnabled,
      'simChangeAlertEnabled': simChangeAlertEnabled,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      triggerKeyword: map['triggerKeyword'] as String? ?? 'miss you phone',
      pin: map['pin'] as String? ?? '',
      isPinEnabled: map['isPinEnabled'] as bool? ?? false,
      trustedNumbers: (map['trustedNumbers'] as List?)
          ?.map((e) => TrustedNumber.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      defaultActions: map['defaultActions'] != null
          ? DefaultActions.fromMap(map['defaultActions'] as Map<String, dynamic>)
          : const DefaultActions(),
      isInitialized: true,
      onboardingDone: map['onboardingDone'] as bool? ?? false,
      isDarkMode: map['is_dark_mode'] as bool? ?? true,
      languageCode: map['language_code'] as String? ?? 'en',
      intrusionSelfieEnabled: map['intrusionSelfieEnabled'] as bool? ?? true,
      intrusionThreshold: map['intrusionThreshold'] as int? ?? 2,
      silentBypassEnabled: map['silentBypassEnabled'] as bool? ?? true,
      simChangeAlertEnabled: map['simChangeAlertEnabled'] as bool? ?? true,
    );
  }

  String toJson() => jsonEncode(toMap());
  factory AppSettings.fromJson(String source) =>
      AppSettings.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
