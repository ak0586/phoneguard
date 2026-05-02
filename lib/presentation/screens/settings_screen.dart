import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/native_ad_widget.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lost_phone_finder/l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text(l10n.settingsTitle),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final settings = provider.settings;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
            children: [
              _buildSectionHeader(l10n.securityIntrusion),
              _buildSettingCard(
                context,
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(l10n.intrusionSelfie),
                      subtitle: Text(l10n.intrusionSelfieDesc),
                      value: settings.intrusionSelfieEnabled,
                      onChanged: (val) => provider.updateSettings(settings.copyWith(intrusionSelfieEnabled: val)),
                      secondary: const Icon(Icons.camera_front_rounded, color: Colors.blue),
                    ),
                    const Divider(indent: 70),
                    ListTile(
                      leading: const Icon(Icons.pin_rounded, color: Colors.orange),
                      title: Text(l10n.intrusionThreshold),
                      subtitle: Text(l10n.failedAttempts(settings.intrusionThreshold)),
                      trailing: DropdownButton<int>(
                        value: settings.intrusionThreshold,
                        underline: const SizedBox(),
                        items: [1, 2, 3, 5].map((i) => DropdownMenuItem(value: i, child: Text(l10n.attemptsCount(i)))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            provider.updateSettings(settings.copyWith(intrusionThreshold: val));
                          }
                        },
                      ),
                    ),
                    const Divider(indent: 70),
                    SwitchListTile(
                      title: Text(l10n.simChangeAlert),
                      subtitle: Text(l10n.simChangeAlertDesc),
                      value: settings.simChangeAlertEnabled,
                      onChanged: (val) => provider.updateSettings(settings.copyWith(simChangeAlertEnabled: val)),
                      secondary: const Icon(Icons.sd_card_alert_rounded, color: Colors.redAccent),
                    ),
                    const Divider(indent: 70),
                    ListTile(
                      leading: const Icon(Icons.people_alt_rounded, color: Colors.green),
                      title: const Text('Trusted Numbers'),
                      subtitle: Text(l10n.trustedNumbersSettingsDesc),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.pushNamed(context, '/trusted-numbers'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(l10n.notifications),
              _buildSettingCard(
                context,
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(l10n.silentBypass),
                      subtitle: Text(l10n.silentBypassDesc),
                      value: settings.silentBypassEnabled,
                      onChanged: (val) => provider.updateSettings(settings.copyWith(silentBypassEnabled: val)),
                      secondary: const Icon(Icons.volume_up_rounded, color: Colors.green),
                    ),
                    const Divider(indent: 70),
                    ListTile(
                      leading: Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: provider.isNotificationListenerEnabled ? Colors.green : Colors.red,
                      ),
                      title: Text(l10n.chatProtectionTitle),
                      subtitle: Text(
                        provider.isNotificationListenerEnabled 
                          ? l10n.chatActiveDesc
                          : l10n.chatInactiveDesc,
                      ),
                      trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                      onTap: () => provider.openNotificationListenerSettings(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(l10n.privacyData),
              _buildSettingCard(
                context,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.security_rounded, color: Colors.teal),
                      title: Text(l10n.appPermissionsTitle),
                      subtitle: Text(l10n.appPermissionsDesc),
                      trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                      onTap: () => provider.openAppInfo(),
                    ),
                    const Divider(indent: 70),
                    ListTile(
                      leading: const Icon(Icons.delete_sweep_rounded, color: Colors.grey),
                      title: Text(l10n.clearLocalLogsTitle),
                      subtitle: Text(l10n.clearLocalLogsDesc),
                      onTap: () => _confirmClearLogs(context, provider),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(l10n.technical),
              _buildSettingCard(
                context,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.battery_saver_rounded, color: Colors.amber),
                      title: Text(l10n.batteryOptimizationTitle),
                      subtitle: Text(l10n.batteryOptimizationDesc),
                      trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                      onTap: () => provider.openBatteryOptimizationSettings(),
                    ),
                    const Divider(indent: 70),
                    ListTile(
                      leading: Icon(Icons.admin_panel_settings_rounded, color: provider.isDeviceAdminActive ? Colors.green : Colors.red),
                      title: Text(l10n.deviceAdminTitle),
                      subtitle: Text(provider.isDeviceAdminActive ? l10n.deviceAdminActive : l10n.deviceAdminInactive),
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
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.clearLogsConfirm),
        content: Text(l10n.clearLocalLogsDesc),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel.toUpperCase())),
          TextButton(
            onPressed: () {
              provider.clearLogs();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.logsClearedMsg)));
            },
            child: Text(l10n.clear.toUpperCase(), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmDeactivation(BuildContext context, AppProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deactivateProtection, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.deactivateWarning,
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(l10n.areYouSureProceed),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel.toUpperCase(), style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              provider.deactivateDeviceAdmin();
              Navigator.pop(context);
            },
            child: Text(l10n.deactivate.toUpperCase(), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
