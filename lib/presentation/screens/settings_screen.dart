import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../widgets/native_ad_widget.dart';
import '../../core/theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final settings = provider.settings;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionHeader('SECURITY & INTRUSION'),
              _buildSettingCard(
                context,
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Intrusion Selfie'),
                      subtitle: const Text('Automatically capture photo on wrong PIN'),
                      value: settings.intrusionSelfieEnabled,
                      onChanged: (val) => provider.updateSettings(settings.copyWith(intrusionSelfieEnabled: val)),
                      secondary: const Icon(Icons.camera_front_rounded, color: Colors.blue),
                    ),
                    const Divider(indent: 70),
                    ListTile(
                      leading: const Icon(Icons.pin_rounded, color: Colors.orange),
                      title: const Text('Intrusion Threshold'),
                      subtitle: Text('${settings.intrusionThreshold} failed attempts'),
                      trailing: DropdownButton<int>(
                        value: settings.intrusionThreshold,
                        underline: const SizedBox(),
                        items: [1, 2, 3, 5].map((i) => DropdownMenuItem(value: i, child: Text('$i attempts'))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            provider.updateSettings(settings.copyWith(intrusionThreshold: val));
                          }
                        },
                      ),
                    ),
                    const Divider(indent: 70),
                    SwitchListTile(
                      title: const Text('SIM Change Alert'),
                      subtitle: const Text('Notify trusted numbers if SIM is replaced'),
                      value: settings.simChangeAlertEnabled,
                      onChanged: (val) => provider.updateSettings(settings.copyWith(simChangeAlertEnabled: val)),
                      secondary: const Icon(Icons.sd_card_alert_rounded, color: Colors.redAccent),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('NOTIFICATIONS'),
              _buildSettingCard(
                context,
                child: SwitchListTile(
                  title: const Text('Silent Mode Bypass'),
                  subtitle: const Text('Play alarm at full volume even on silent'),
                  value: settings.silentBypassEnabled,
                  onChanged: (val) => provider.updateSettings(settings.copyWith(silentBypassEnabled: val)),
                  secondary: const Icon(Icons.volume_up_rounded, color: Colors.green),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('PRIVACY & DATA'),
              _buildSettingCard(
                context,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.security_rounded, color: Colors.teal),
                      title: const Text('App Permissions'),
                      subtitle: const Text('Manage Android system access'),
                      trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                      onTap: () => provider.openAppInfo(),
                    ),
                    const Divider(indent: 70),
                    ListTile(
                      leading: const Icon(Icons.delete_sweep_rounded, color: Colors.grey),
                      title: const Text('Clear Local Logs'),
                      subtitle: const Text('Wipe all activity history'),
                      onTap: () => _confirmClearLogs(context, provider),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('TECHNICAL'),
              _buildSettingCard(
                context,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.battery_saver_rounded, color: Colors.amber),
                      title: const Text('Battery Optimization'),
                      subtitle: const Text('Ensure background service stays alive'),
                      trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                      onTap: () => provider.openBatteryOptimizationSettings(),
                    ),
                    const Divider(indent: 70),
                    ListTile(
                      leading: Icon(Icons.admin_panel_settings_rounded, color: provider.isDeviceAdminActive ? Colors.green : Colors.red),
                      title: const Text('Device Administrator'),
                      subtitle: Text(provider.isDeviceAdminActive ? 'Active (Recommended)' : 'Inactive - Tap to Activate'),
                      onTap: () {
                        if (provider.isDeviceAdminActive) {
                          _confirmDeactivation(context, provider);
                        } else {
                          provider.requestDeviceAdmin();
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const NativeAdWidget(templateType: TemplateType.medium),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildSettingCard(BuildContext context, {required Widget child}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDarkMode ? null : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
      ),
      child: child,
    );
  }

  void _confirmClearLogs(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Logs?'),
        content: const Text('This will permanently delete all local activity history.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              provider.clearLogs();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logs cleared successfully')));
            },
            child: const Text('CLEAR', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmDeactivation(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate Protection?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Warning: Disabling Device Admin will allow anyone to uninstall the app and stop remote protection.',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            Text('Are you sure you want to proceed?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              provider.deactivateDeviceAdmin();
              Navigator.pop(context);
            },
            child: const Text('DEACTIVATE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
