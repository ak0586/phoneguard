import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/models/activity_log.dart';
import '../../core/constants/app_constants.dart';

/// Local data source backed by Hive
/// Handles all persistence for settings and activity logs with migration from SharedPreferences
class HiveDataSource {
  static const String boxSettings = 'settings_box';
  static const String boxLogs = 'logs_box';
  static const String keySettings = 'app_settings';
  static const String keyLogs = 'activity_logs';

  final Box _settingsBox;
  final Box _logsBox;
  final SharedPreferences _prefs;

  HiveDataSource(this._settingsBox, this._logsBox, this._prefs);

  /// Initializes Hive and opens necessary boxes
  static Future<HiveDataSource> init(SharedPreferences prefs) async {
    await Hive.initFlutter();
    final settingsBox = await Hive.openBox(boxSettings);
    final logsBox = await Hive.openBox(boxLogs);
    return HiveDataSource(settingsBox, logsBox, prefs);
  }

  /// Migrates data from SharedPreferences if Hive boxes are empty
  Future<void> migrateIfNeeded() async {
    // Migrate Settings
    if (_settingsBox.isEmpty) {
      final rawSettings = _prefs.getString('app_settings');
      if (rawSettings != null) {
        await _settingsBox.put(keySettings, rawSettings);
      }
    }

    // Migrate Logs
    if (_logsBox.isEmpty) {
      final rawLogs = _prefs.getString(AppConstants.keyActivityLogs);
      if (rawLogs != null) {
        await _logsBox.put(keyLogs, rawLogs);
      } else {
        // Check for legacy StringList format (though SharedPreferences handles prefixes)
        final legacyList = _prefs.getStringList(AppConstants.keyActivityLogs);
        if (legacyList != null && legacyList.isNotEmpty) {
          await _logsBox.put(keyLogs, jsonEncode(legacyList));
        }
      }
    }
  }

  // ─── Settings ────────────────────────────────────────────────────────────

  Future<AppSettings> loadSettings() async {
    final raw = _settingsBox.get(keySettings);
    if (raw == null) return const AppSettings();
    try {
      if (raw is String) return AppSettings.fromJson(raw);
      if (raw is Map) {
        return AppSettings.fromMap(Map<String, dynamic>.from(raw));
      }
      return const AppSettings();
    } catch (_) {
      return const AppSettings();
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    final json = settings.toJson();
    await _settingsBox.put(keySettings, json);
    
    // Sync with SharedPreferences for background service compatibility
    await _prefs.setString('app_settings', json);
  }

  // ─── Activity Logs ───────────────────────────────────────────────────────

  List<ActivityLog> loadLogs() {
    // We read logs from SharedPreferences as the source of truth
    // because the Android background service appends to them directly.
    final raw = _prefs.getString(AppConstants.keyActivityLogs);
    if (raw == null) return [];

    try {
      List<dynamic> list;
      if (raw.startsWith('[')) {
        list = jsonDecode(raw);
      } else {
        // Handle legacy format if SharedPreferences doesn't auto-handle it
        final legacyList = _prefs.getStringList(AppConstants.keyActivityLogs);
        if (legacyList != null) {
          list = legacyList;
        } else {
          return [];
        }
      }

      return list
          .map((e) {
            try {
              if (e is String) return ActivityLog.fromJson(e);
              if (e is Map) return ActivityLog.fromMap(Map<String, dynamic>.from(e));
              return null;
            } catch (_) {
              return null;
            }
          })
          .whereType<ActivityLog>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveLogs(List<ActivityLog> logs) async {
    // Keep only the latest [maxActivityLogs] entries
    final trimmed = logs.length > AppConstants.maxActivityLogs
        ? logs.sublist(0, AppConstants.maxActivityLogs)
        : logs;
    
    final list = trimmed.map((e) => e.toMap()).toList();
    final json = jsonEncode(list);
    
    // We save to both for consistency, though SP is the primary for logs
    await _logsBox.put(keyLogs, json);
    await _prefs.setString(AppConstants.keyActivityLogs, json);
  }

  Future<void> clearLogs() async {
    await _logsBox.delete(keyLogs);
    await _prefs.remove(AppConstants.keyActivityLogs);
  }
}
