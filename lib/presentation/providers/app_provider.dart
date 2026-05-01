import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/models/trusted_number.dart';
import '../../domain/models/activity_log.dart';
import '../../domain/repositories/app_repository.dart';
import '../../data/datasources/native_service.dart';
import '../../core/utils/phone_utils.dart';

enum AppState { idle, loading, error }

/// Central provider that manages all app state:
/// settings, trusted numbers, activity logs, and recovery status
class AppProvider extends ChangeNotifier {
  final AppRepository _repository;
  final NativeService _nativeService;
  final Uuid _uuid = const Uuid();

  AppSettings _settings = const AppSettings();
  List<ActivityLog> _logs = [];
  AppState _state = AppState.idle;
  String? _errorMessage;
  bool _isAlarmActive = false;
  bool _isTrackingActive = false;
  bool _isDeviceAdminActive = false;
  Timer? _pollingTimer;
  void Function(List<TrustedNumber>)? onTrustedNumbersChanged;
  void Function(String)? onTriggerKeywordChanged;

  AppProvider(this._repository, this._nativeService);

  // ─── Getters ─────────────────────────────────────────────────────────────

  AppSettings get settings => _settings;
  List<TrustedNumber> get trustedNumbers => _settings.trustedNumbers;
  List<ActivityLog> get logs => _logs;
  AppState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isAlarmActive => _isAlarmActive;
  bool get isTrackingActive => _isTrackingActive;
  bool get isDeviceAdminActive => _isDeviceAdminActive;
  bool get isProtectionActive => trustedNumbers.isNotEmpty;
  DefaultActions get defaultActions => _settings.defaultActions;

  // ─── Initialization ──────────────────────────────────────────────────────

  Future<void> init() async {
    _state = AppState.loading;
    notifyListeners();
    try {
      _settings = await _repository.getSettings();
      _logs = await _repository.getLogs();
      await refreshActiveActions();
      await _checkNativeEvents(); // New: Check for SIM change/Shutdown
      _startPolling();
      _state = AppState.idle;
    } catch (e) {
      _state = AppState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => refreshActiveActions(),
    );
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  // ─── Settings ────────────────────────────────────────────────────────────

  Future<void> updateSettings(AppSettings newSettings) async {
    final oldNumbers = _settings.trustedNumbers;
    final oldKeyword = _settings.triggerKeyword;
    _settings = newSettings;
    await _repository.saveSettings(_settings);
    
    // Notify Firestore if numbers changed
    if (oldNumbers.length != _settings.trustedNumbers.length ||
        oldNumbers.any((n) => !_settings.trustedNumbers.contains(n))) {
      onTrustedNumbersChanged?.call(_settings.trustedNumbers);
    }
    
    // Notify Firestore if keyword changed
    if (oldKeyword != _settings.triggerKeyword) {
      onTriggerKeywordChanged?.call(_settings.triggerKeyword);
    }
    
    notifyListeners();
  }

  Future<void> syncTrustedNumbers(List<TrustedNumber> firestoreNumbers) async {
    if (firestoreNumbers.isEmpty) return;
    
    final localNumbers = _settings.trustedNumbers;
    // Simple check: if local is empty, or there's a mismatch in IDs, sync them
    final localIds = localNumbers.map((n) => n.id).toSet();
    final firestoreIds = firestoreNumbers.map((n) => n.id).toSet();
    
    if (localNumbers.isEmpty || !localIds.containsAll(firestoreIds) || !firestoreIds.containsAll(localIds)) {
      _settings = _settings.copyWith(trustedNumbers: firestoreNumbers);
      await _repository.saveSettings(_settings);
      notifyListeners();
    }
  }

  Future<void> setTriggerKeyword(String keyword) async {
    final cleanKeyword = keyword.trim();
    if (cleanKeyword != _settings.triggerKeyword) {
      await updateSettings(_settings.copyWith(triggerKeyword: cleanKeyword));
      onTriggerKeywordChanged?.call(cleanKeyword);
    }
  }

  Future<void> syncTriggerKeyword(String keyword) async {
    if (keyword.isEmpty || keyword == _settings.triggerKeyword) return;
    _settings = _settings.copyWith(triggerKeyword: keyword);
    await _repository.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> setPinEnabled(bool enabled, {String? pin}) async {
    await updateSettings(
      _settings.copyWith(isPinEnabled: enabled, pin: pin ?? _settings.pin),
    );
  }


  Future<void> setDefaultActions(DefaultActions actions) async {
    await updateSettings(_settings.copyWith(defaultActions: actions));
  }

  Future<void> markOnboardingDone() async {
    await updateSettings(_settings.copyWith(onboardingDone: true));
  }

  Future<void> setThemeMode({required bool isDark}) async {
    await updateSettings(_settings.copyWith(isDarkMode: isDark));
  }

  Future<void> setLanguageCode(String code) async {
    await updateSettings(_settings.copyWith(languageCode: code));
  }

  // ─── Trusted Numbers ─────────────────────────────────────────────────────

  Future<void> addTrustedNumber(String label, String phoneNumber) async {
    if (!PhoneUtils.isValid(phoneNumber)) {
      _errorMessage = 'Invalid phone number format';
      notifyListeners();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final isoCode = prefs.getString('cached_iso_country_code');
    final formattedMobile = PhoneUtils.formatWithCountryCode(phoneNumber, isoCode);

    final number = TrustedNumber(
      id: _uuid.v4(),
      label: label.trim(),
      phoneNumber: formattedMobile,
      addedAt: DateTime.now(),
    );
    final updated = List<TrustedNumber>.from(trustedNumbers)..add(number);
    await updateSettings(_settings.copyWith(trustedNumbers: updated));
  }

  Future<void> updateTrustedNumber(TrustedNumber updated) async {
    final prefs = await SharedPreferences.getInstance();
    final isoCode = prefs.getString('cached_iso_country_code');
    final formattedMobile = PhoneUtils.formatWithCountryCode(updated.phoneNumber, isoCode);
    
    final finalUpdated = updated.copyWith(phoneNumber: formattedMobile);

    final list = trustedNumbers
        .map((n) => n.id == finalUpdated.id ? finalUpdated : n)
        .toList();
    await updateSettings(_settings.copyWith(trustedNumbers: list));
  }

  Future<void> removeTrustedNumber(String id) async {
    final updated = trustedNumbers.where((n) => n.id != id).toList();
    await updateSettings(_settings.copyWith(trustedNumbers: updated));
  }

  // ─── Activity Logs ───────────────────────────────────────────────────────

  Future<void> addLog({
    required String sender,
    required String command,
    required String result,
    bool success = true,
  }) async {
    final log = ActivityLog(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      senderNumber: sender,
      command: command,
      result: result,
      success: success,
    );
    await _repository.addLog(log);
    _logs = await _repository.getLogs();
    notifyListeners();
  }

  Future<void> removeLog(String id) async {
    await _repository.removeLog(id);
    _logs = await _repository.getLogs();
    notifyListeners();
  }

  Future<void> clearLogs() async {
    await _repository.clearLogs();
    _logs = [];
    notifyListeners();
  }

  // ─── Alarm Control ───────────────────────────────────────────────────────

  Future<void> startAlarm() async {
    try {
      await _nativeService.startAlarm();
      _isAlarmActive = true;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> stopAlarm() async {
    try {
      await _nativeService.stopAlarm();
      _isAlarmActive = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> lockDevice() async {
    try {
      await _nativeService.lockDevice();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> openAccessibilitySettings() async {
    try {
      await _nativeService.openAccessibilitySettings();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // ─── Tracking Control ────────────────────────────────────────────────────

  Future<void> startTracking(String targetNumber) async {
    try {
      await _nativeService.startTracking(targetNumber: targetNumber);
      _isTrackingActive = true;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> stopTracking() async {
    try {
      await _nativeService.stopTracking();
      _isTrackingActive = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> checkDeviceAdminStatus() async {
    final active = await _nativeService.isDeviceAdminActive();
    if (_isDeviceAdminActive != active) {
      _isDeviceAdminActive = active;
      notifyListeners();
    }
  }

  Future<void> requestDeviceAdmin() async {
    try {
      await _nativeService.requestDeviceAdmin();
      // Re-check after request
      await Future.delayed(const Duration(seconds: 1));
      await checkDeviceAdminStatus();
    } catch (e) {
      _errorMessage = 'Device admin request failed: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> deactivateDeviceAdmin() async {
    try {
      await _nativeService.deactivateDeviceAdmin();
      // Re-check after request
      await Future.delayed(const Duration(seconds: 1));
      await checkDeviceAdminStatus();
    } catch (e) {
      _errorMessage = 'Device admin deactivation failed: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> refreshActiveActions() async {
    try {
      final alarm = await _nativeService.isAlarmActive();
      final tracking = await _nativeService.isTrackingRunning();
      final admin = await _nativeService.isDeviceAdminActive();

      final logs = await _repository.getLogs();

      bool changed = false;
      if (_isAlarmActive != alarm) {
        _isAlarmActive = alarm;
        changed = true;
      }
      if (_isTrackingActive != tracking) {
        _isTrackingActive = tracking;
        changed = true;
      }
      if (_isDeviceAdminActive != admin) {
        _isDeviceAdminActive = admin;
        changed = true;
      }
      
      if (_logs.length != logs.length) {
        _logs = logs;
        changed = true;
      }

      if (changed) {
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error refreshing actions: $e');
    }
  }

  Future<void> _checkNativeEvents() async {
    try {
      final prefs = await _repository.getPrefs(); // Need to ensure repository has getPrefs or use SharedPreferences directly
      
      // 1. Check for Detecting SIM Change
      final lastSim = prefs.getString('flutter.lastSimNumber') ?? '';
      if (lastSim.isNotEmpty) {
        debugPrint('Last SIM detected: $lastSim');
      }
      
      // 2. Check for Shutdown detection
      final wasShutdown = prefs.getBool('flutter.last_shutdown_detected') ?? false;
      if (wasShutdown) {
        await addLog(
          sender: 'System', 
          command: 'Power Off', 
          result: 'Device was shut down or restarted.',
          success: true,
        );
        await prefs.remove('flutter.last_shutdown_detected');
      }
    } catch (e) {
      debugPrint('Error checking native events: $e');
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
