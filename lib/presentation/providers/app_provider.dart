import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/models/trusted_number.dart';
import '../../domain/models/activity_log.dart';
import '../../domain/repositories/app_repository.dart';
import '../../data/datasources/native_service.dart';
import '../../data/datasources/auth_service.dart';
import '../../core/utils/phone_utils.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:in_app_review/in_app_review.dart';

enum AppState { idle, loading, error }

/// Central provider that manages all app state:
/// settings, trusted numbers, activity logs, and recovery status
class AppProvider extends ChangeNotifier with WidgetsBindingObserver {
  final AppRepository _repository;
  final NativeService _nativeService;
  final AuthService _authService;
  final Uuid _uuid = const Uuid();

  AppSettings _settings = const AppSettings();
  List<ActivityLog> _logs = [];
  AppState _state = AppState.idle;
  String? _errorMessage;
  bool _isAlarmActive = false;
  bool _isTrackingActive = false;
  bool _isDeviceAdminActive = false;
  String _minRequiredVersion = '1.0.0';
  bool _isUpdateRequired = false;
  String _playStoreUrl = 'https://play.google.com/store/apps/details?id=com.kyvronix.phoneguard';
  Timer? _pollingTimer;
  void Function(List<TrustedNumber>)? onTrustedNumbersChanged;
  void Function(String)? onTriggerKeywordChanged;
  bool _isNotificationListenerEnabled = false;
  bool _isIntrusionCardCollapsed = false;
  bool _isPermissionsCardCollapsed = false;
  bool _sessionUpsellShown = false;
  bool _disposed = false;
  bool _isAppInForeground = true; // Lifecycle flag — pauses polling when app is backgrounded
  
  // Rating logic state
  int _sessionCount = 0;
  int _actionCount = 0;
  bool _hasRated = false;
  DateTime? _lastRatingRequest;

  AppProvider(this._repository, this._nativeService, this._authService);

  void setIntrusionCardCollapsed(bool collapsed) {
    _isIntrusionCardCollapsed = collapsed;
    notifyListeners();
  }

  void setSessionUpsellShown(bool shown) {
    _sessionUpsellShown = shown;
    notifyListeners();
  }

  Future<bool> canShowAdPaywallToday() async {
    final prefs = await SharedPreferences.getInstance();
    final lastShown = prefs.getString('last_ad_paywall_date') ?? '';
    final today = DateTime.now().toIso8601String().substring(0, 10); // YYYY-MM-DD
    return lastShown != today;
  }

  Future<void> markAdPaywallShownToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setString('last_ad_paywall_date', today);
    notifyListeners();
  }

  void setPermissionsCardCollapsed(bool collapsed) {
    _isPermissionsCardCollapsed = collapsed;
    notifyListeners();
  }

  // ─── Actions ─────────────────────────────────────────────────────────────

  // ─── Getters ─────────────────────────────────────────────────────────────

  AppSettings get settings => _settings;
  List<TrustedNumber> get trustedNumbers => _settings.trustedNumbers;
  List<ActivityLog> get logs => _logs;
  AppState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isAlarmActive => _isAlarmActive;
  bool get isTrackingActive => _isTrackingActive;
  bool get isDeviceAdminActive => _isDeviceAdminActive;
  bool get isUpdateRequired => _isUpdateRequired;
  String get playStoreUrl => _playStoreUrl;
  bool get isNotificationListenerEnabled => _isNotificationListenerEnabled;
  bool get isIntrusionCardCollapsed => _isIntrusionCardCollapsed;
  bool get isPermissionsCardCollapsed => _isPermissionsCardCollapsed;
  bool get sessionUpsellShown => _sessionUpsellShown;
  bool get isProtectionActive => trustedNumbers.isNotEmpty;
  DefaultActions get defaultActions => _settings.defaultActions;

  // ─── Initialization ──────────────────────────────────────────────────────

  Future<void> init() async {
    _state = AppState.loading;
    notifyListeners();

    // Register for app lifecycle events to pause/resume polling
    WidgetsBinding.instance.addObserver(this);

    try {
      _settings = await _repository.getSettings();
      _logs = await _repository.getLogs();
      _logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      await refreshActiveActions();
      await _checkNativeEvents(); // New: Check for SIM change/Shutdown
      await _checkVersionUpdate(); // New: Force update check
      
      // Sync Remote Logs if authenticated
      await _syncRemoteLogsOnStart();
      
      // Load and increment session count
      await _initRatingLogic();

      _startPolling();
      _state = AppState.idle;
    } catch (e) {
      _state = AppState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  /// Called by Android OS when app lifecycle changes.
  /// Pauses the polling timer when the app is in the background to save battery.
  /// Resumes with an immediate check when the user returns to the foreground.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isAppInForeground = true;
      // Immediately refresh state and restart polling when user returns
      refreshActiveActions();
      _startPolling();
      debugPrint('AppProvider: App foregrounded — polling resumed (30s interval)');
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _isAppInForeground = false;
      // Cancel the timer — no point polling when user can't see the UI
      _pollingTimer?.cancel();
      _pollingTimer = null;
      debugPrint('AppProvider: App backgrounded — polling paused to save battery');
    }
  }

  /// Clears all local state when user logs out
  Future<void> reset() async {
    _state = AppState.loading;
    notifyListeners();
    try {
      _settings = const AppSettings();
      _logs = [];
      await _repository.saveSettings(_settings);
      await _repository.clearLogs();
      _state = AppState.idle;
    } catch (e) {
      _state = AppState.error;
    }
    notifyListeners();
  }

  void _startPolling() {
    // Only poll when the app is in the foreground
    if (!_isAppInForeground) return;
    _pollingTimer?.cancel();
    // Changed from 5s → 30s: reduces MethodChannel calls from 720x/hr to 120x/hr
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => refreshActiveActions(),
    );
  }

  Future<void> _syncRemoteLogsOnStart() async {
    final user = _authService.currentUser;
    if (user == null) return;

    try {
      final remoteLogsData = await _authService.fetchRemoteLogs(user.uid);
      if (remoteLogsData.isNotEmpty) {
        final remoteLogs = remoteLogsData.map((m) => ActivityLog.fromMap(m)).toList();
        
        // Merge with local logs, avoiding duplicates by ID
        final localIds = _logs.map((l) => l.id).toSet();
        bool changed = false;
        
        for (var log in remoteLogs) {
          if (!localIds.contains(log.id)) {
            _logs.add(log);
            await _repository.addLog(log);
            changed = true;
          }
        }
        
        if (changed) {
          _logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error syncing remote logs: $e');
    }
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _pollingTimer?.cancel();
    // Unregister lifecycle observer to prevent memory leaks
    WidgetsBinding.instance.removeObserver(this);
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
    final localNumbers = _settings.trustedNumbers;
    final localIds = localNumbers.map((n) => n.id).toSet();
    final firestoreIds = firestoreNumbers.map((n) => n.id).toSet();
    
    // Sync if counts differ OR any ID mismatch
    if (localNumbers.length != firestoreNumbers.length || !localIds.containsAll(firestoreIds) || !firestoreIds.containsAll(localIds)) {
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
    if (keyword == _settings.triggerKeyword) return;
    _settings = _settings.copyWith(triggerKeyword: keyword);
    await _repository.saveSettings(_settings);
    notifyListeners();
  }

  // PIN feature is now deprecated and disabled to simplify UX
  Future<void> setPinEnabled(bool enabled, {String? pin}) async {
    await updateSettings(
      _settings.copyWith(isPinEnabled: false),
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
    debugPrint('AppProvider: Adding trusted number: $label ($phoneNumber)');
    if (!PhoneUtils.isValid(phoneNumber)) {
      debugPrint('AppProvider: Invalid number format detected: $phoneNumber');
      _errorMessage = 'Invalid format: $phoneNumber';
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
    debugPrint('AppProvider: List size before: ${trustedNumbers.length}, after: ${updated.length}');
    await updateSettings(_settings.copyWith(trustedNumbers: updated));
    debugPrint('AppProvider: Settings updated. Current list size in provider: ${trustedNumbers.length}');
    
    // Increment action count for rating logic
    await incrementActionCount();
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
    
    // Upload to Firestore if authenticated
    final user = _authService.currentUser;
    if (user != null) {
      _authService.uploadLog(user.uid, log.toMap()).catchError((e) => debugPrint('Error uploading log: $e'));
    }

    // Increment action count for rating logic (only for successful security commands)
    if (success && command != 'System') {
      await incrementActionCount();
    }
    
    notifyListeners();
  }

  Future<void> removeLog(String id) async {
    await _repository.removeLog(id);
    _logs = await _repository.getLogs();
    
    // Remove from Firestore if authenticated
    final user = _authService.currentUser;
    if (user != null) {
      _authService.deleteRemoteLog(user.uid, id).catchError((e) => debugPrint('Error deleting remote log: $e'));
    }
    
    notifyListeners();
  }

  Future<void> clearLogs() async {
    await _repository.clearLogs();
    _logs = [];
    
    // Clear from Firestore if authenticated
    final user = _authService.currentUser;
    if (user != null) {
      _authService.clearRemoteLogs(user.uid).catchError((e) => debugPrint('Error clearing remote logs: $e'));
    }
    
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

  Future<void> openAppInfo() async {
    try {
      await _nativeService.openAppInfo();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> openBatteryOptimizationSettings() async {
    try {
      await _nativeService.openBatteryOptimizationSettings();
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
    _isDeviceAdminActive = await _nativeService.isDeviceAdminActive();
    _isNotificationListenerEnabled = await _nativeService.isNotificationListenerEnabled();
    notifyListeners();
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

      final notificationEnabled = await _nativeService.isNotificationListenerEnabled();
      if (_isNotificationListenerEnabled != notificationEnabled) {
        _isNotificationListenerEnabled = notificationEnabled;
        changed = true;
      }
      
      if (_logs.length != logs.length) {
        // Find new logs that aren't uploaded yet
        final oldIds = _logs.map((l) => l.id).toSet();
        final newLogs = logs.where((l) => !oldIds.contains(l.id)).toList();
        
        _logs = logs;
        _logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        changed = true;
        
        // Upload new logs (likely from background service)
        final user = _authService.currentUser;
        if (user != null && newLogs.isNotEmpty) {
          for (var log in newLogs) {
            _authService.uploadLog(user.uid, log.toMap()).catchError((e) => debugPrint('Error uploading auto log: $e'));
          }
        }
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
      final lastSim = prefs.getString('lastSimNumber') ?? '';
      if (lastSim.isNotEmpty) {
        debugPrint('Last SIM detected: $lastSim');
      }
      
      // 2. Check for Shutdown detection
      final wasShutdown = prefs.getBool('last_shutdown_detected') ?? false;
      if (wasShutdown) {
        await addLog(
          sender: 'System', 
          command: 'Power Off', 
          result: 'Device was shut down or restarted.',
          success: true,
        );
        await prefs.remove('last_shutdown_detected');
      }
    } catch (e) {
      debugPrint('Error checking native events: $e');
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> openNotificationListenerSettings() async {
    try {
      await _nativeService.openNotificationListenerSettings();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> _checkVersionUpdate() async {
    try {
      // 1. Fetch from Firestore (system_config/app_version)
      final doc = await FirebaseFirestore.instance.collection('system_config').doc('app_version').get();
      if (doc.exists) {
        _minRequiredVersion = doc.data()?['min_required_version'] ?? '1.0.5';
        _playStoreUrl = doc.data()?['play_store_url'] ?? _playStoreUrl;
      }

      // 2. Get local version
      final info = await PackageInfo.fromPlatform();
      final currentVersion = info.version;

      // 3. Compare
      _isUpdateRequired = _isVersionLower(currentVersion, _minRequiredVersion);
      notifyListeners();
    } catch (e) {
      debugPrint('Error checking version: $e');
    }
  }

  Future<void> _initRatingLogic() async {
    final prefs = await SharedPreferences.getInstance();
    _sessionCount = prefs.getInt('rating_session_count') ?? 0;
    _actionCount = prefs.getInt('rating_action_count') ?? 0;
    _hasRated = prefs.getBool('rating_has_rated') ?? false;
    final lastReq = prefs.getString('rating_last_request_date');
    if (lastReq != null) _lastRatingRequest = DateTime.tryParse(lastReq);

    // Increment session count
    _sessionCount++;
    await prefs.setInt('rating_session_count', _sessionCount);
    notifyListeners();
  }

  Future<void> incrementActionCount() async {
    _actionCount++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('rating_action_count', _actionCount);
    notifyListeners();
  }

  Future<void> markRated() async {
    _hasRated = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rating_has_rated', true);
    notifyListeners();
  }

  Future<void> markRatingRequested() async {
    _lastRatingRequest = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('rating_last_request_date', _lastRatingRequest!.toIso8601String());
    notifyListeners();
  }

  bool canShowRatingDialog() {
    if (_hasRated) return false;
    
    // Cooldown check (7 days)
    if (_lastRatingRequest != null) {
      final daysSinceLast = DateTime.now().difference(_lastRatingRequest!).inDays;
      if (daysSinceLast < 7) return false;
    }

    // Qualification check: 5 sessions AND 3 successful actions
    return _sessionCount >= 5 && _actionCount >= 3;
  }

  Future<void> requestReview() async {
    final InAppReview inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      await inAppReview.requestReview();
      await markRated();
    }
  }

  bool _isVersionLower(String current, String required) {
    try {
      List<int> currentParts = current.split('.').map((s) => int.tryParse(s) ?? 0).toList();
      List<int> requiredParts = required.split('.').map((s) => int.tryParse(s) ?? 0).toList();
      
      for (int i = 0; i < requiredParts.length; i++) {
        if (i >= currentParts.length) return true;
        if (currentParts[i] < requiredParts[i]) return true;
        if (currentParts[i] > requiredParts[i]) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
