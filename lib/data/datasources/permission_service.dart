import 'package:permission_handler/permission_handler.dart';

/// Manages all Android runtime permission requests
/// Requests permissions only when they are actually needed (lazy approach)
class PermissionService {
  /// Requests all permissions needed for the protection service to work
  Future<Map<Permission, PermissionStatus>> requestAllCorePermissions() async {
    final permissions = [
      Permission.sms,
      Permission.location,
      Permission.locationAlways,
      Permission.camera,
      Permission.phone,
      Permission.notification,
    ];
    return await permissions.request();
  }

  /// Check if all core permissions are granted
  Future<bool> areCorePermissionsGranted() async {
    final sms = await Permission.sms.isGranted;
    final location = await Permission.location.isGranted;
    final camera = await Permission.camera.isGranted;
    final phone = await Permission.phone.isGranted;
    return sms && location && camera && phone;
  }

  /// Check individual permission status
  Future<PermissionStatus> checkSms() => Permission.sms.status;
  Future<PermissionStatus> checkLocation() => Permission.location.status;
  Future<PermissionStatus> checkCamera() => Permission.camera.status;
  Future<PermissionStatus> checkPhone() => Permission.phone.status;

  /// Request a specific permission with explanation context
  Future<PermissionStatus> requestSms() => Permission.sms.request();
  Future<PermissionStatus> requestLocation() => Permission.location.request();
  Future<PermissionStatus> requestCamera() => Permission.camera.request();
  Future<PermissionStatus> requestPhone() => Permission.phone.request();
  Future<PermissionStatus> requestNotification() =>
      Permission.notification.request();
  Future<PermissionStatus> requestLocationAlways() =>
      Permission.locationAlways.request();

  /// Opens app settings so user can manually grant permissions
  Future<bool> openSettings() => openAppSettings();
}
