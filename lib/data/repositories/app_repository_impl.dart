import '../../domain/models/app_settings.dart';
import '../../domain/models/activity_log.dart';
import '../../domain/repositories/app_repository.dart';
import '../datasources/hive_data_source.dart';

/// Concrete implementation of [AppRepository] using Hive storage
class AppRepositoryImpl implements AppRepository {
  final HiveDataSource _dataSource;

  AppRepositoryImpl(this._dataSource);

  @override
  Future<AppSettings> getSettings() => _dataSource.loadSettings();

  @override
  Future<void> saveSettings(AppSettings settings) =>
      _dataSource.saveSettings(settings);

  @override
  Future<List<ActivityLog>> getLogs() async => _dataSource.loadLogs();

  @override
  Future<void> addLog(ActivityLog log) async {
    final logs = _dataSource.loadLogs();
    logs.insert(0, log); // newest first
    await _dataSource.saveLogs(logs);
  }

  @override
  Future<void> removeLog(String id) async {
    final logs = _dataSource.loadLogs();
    logs.removeWhere((log) => log.id == id);
    await _dataSource.saveLogs(logs);
  }

  @override
  Future<void> clearLogs() => _dataSource.clearLogs();
}
