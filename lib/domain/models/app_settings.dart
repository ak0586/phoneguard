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
    this.sendLocation = false,
    this.startAlarm = false,
    this.enableTracking = false,
    this.stopAlarmOnTrigger = false,
    this.lockDevice = false,
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
    startAlarm: map['startAlarm'] as bool? ?? true,
    enableTracking: map['enableTracking'] as bool? ?? false,
    stopAlarmOnTrigger: map['stopAlarmOnTrigger'] as bool? ?? false,
    lockDevice: map['lockDevice'] as bool? ?? false,
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

  const AppSettings({
    this.triggerKeyword = 'miss you phone', // Assuming AppConstants.defaultTriggerKeyword is 'miss you phone'
    this.pin = '',
    this.isPinEnabled = false,
    this.defaultActions = const DefaultActions(),
    this.trustedNumbers = const [],
    this.isInitialized = false,
    this.onboardingDone = false,
    this.isDarkMode = true,
    this.languageCode = 'en',
  });

  // Assuming AppSettings does not extend Equatable, so adding props getter as is.
  List<Object?> get props => [
        isInitialized,
        trustedNumbers,
        triggerKeyword,
      ];

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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'triggerKeyword': triggerKeyword, // Assuming AppConstants.keyTriggerKeyword is 'triggerKeyword'
      'pin': pin, // Assuming AppConstants.keyPin is 'pin'
      'isPinEnabled': isPinEnabled, // Assuming AppConstants.keyPinEnabled is 'isPinEnabled'
      'trustedNumbers': trustedNumbers.map((n) => n.toMap()).toList(), // Assuming AppConstants.keyTrustedNumbers is 'trustedNumbers'
      'defaultActions': defaultActions.toMap(), // Assuming AppConstants.keyDefaultActions is 'defaultActions'
      'onboardingDone': onboardingDone, // Assuming AppConstants.keyOnboardingDone is 'onboardingDone'
      'is_dark_mode': isDarkMode,
      'language_code': languageCode,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      triggerKeyword: map['triggerKeyword'] as String? ?? 'miss you phone', // Assuming AppConstants.keyTriggerKeyword and default
      pin: map['pin'] as String? ?? '', // Assuming AppConstants.keyPin
      isPinEnabled: map['isPinEnabled'] as bool? ?? false, // Assuming AppConstants.keyPinEnabled
      trustedNumbers: (map['trustedNumbers'] as List?) // Assuming AppConstants.keyTrustedNumbers
          ?.map((e) => TrustedNumber.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      defaultActions: map['defaultActions'] != null // Assuming AppConstants.keyDefaultActions
          ? DefaultActions.fromMap(map['defaultActions'] as Map<String, dynamic>)
          : const DefaultActions(),
      isInitialized: true,
      onboardingDone: map['onboardingDone'] as bool? ?? false, // Assuming AppConstants.keyOnboardingDone
      isDarkMode: map['is_dark_mode'] as bool? ?? true,
      languageCode: map['language_code'] as String? ?? 'en',
    );
  }

  String toJson() => jsonEncode(toMap());
  factory AppSettings.fromJson(String source) =>
      AppSettings.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
