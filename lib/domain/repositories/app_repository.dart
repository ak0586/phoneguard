import '../../domain/models/app_settings.dart';
import '../../domain/models/activity_log.dart';

/// Abstract repository contract for settings and logs
abstract class AppRepository {
  Future<AppSettings> getSettings();
  Future<void> saveSettings(AppSettings settings);
  Future<List<ActivityLog>> getLogs();
  Future<void> addLog(ActivityLog log);
  Future<void> removeLog(String id);
  Future<void> clearLogs();
  Future<dynamic> getPrefs(); // For checking native flags
}
