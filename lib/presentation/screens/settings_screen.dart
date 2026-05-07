import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/native_ad_widget.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:lost_phone_finder/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/models/trusted_number.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _keywordController;
  bool _isEditingKeyword = false;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<AppProvider>(context, listen: false);
    _keywordController = TextEditingController(text: provider.settings.triggerKeyword);
  }

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle, style: const TextStyle(fontWeight: FontWeight.w900)),
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer2<AppProvider, AuthProvider>(
        builder: (context, provider, auth, _) {
          final settings = provider.settings;
          final isPremium = auth.profile?.isPremium ?? false;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            children: [
              // ─── Trigger Keyword Section ──────────────────────────────────
              _buildSectionHeader('TRIGGER KEYWORD'),
              _buildSettingCard(
                context,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'This word triggers all security actions via SMS',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _keywordController,
                              enabled: _isEditingKeyword,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.vpn_key_rounded, color: AppTheme.primary),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Theme.of(context).brightness == Brightness.dark 
                                    ? Colors.white.withOpacity(0.05) 
                                    : Colors.grey.withOpacity(0.05),
                              ),
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.5),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            onPressed: () {
                              if (_isEditingKeyword) {
                                provider.setTriggerKeyword(_keywordController.text);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Keyword Updated!'), behavior: SnackBarBehavior.floating),
                                );
                              }
                              setState(() => _isEditingKeyword = !_isEditingKeyword);
                            },
                            icon: Icon(_isEditingKeyword ? Icons.check_rounded : Icons.edit_rounded),
                            style: IconButton.styleFrom(
                              backgroundColor: _isEditingKeyword ? Colors.green : AppTheme.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              // ─── Trusted Contacts Section ──────────────────────────────────
              _buildSectionHeader('TRUSTED CONTACTS'),
              _buildSettingCard(
                context,
                child: Column(
                  children: [
                    if (provider.trustedNumbers.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('No trusted numbers added yet.', style: TextStyle(color: Colors.grey)),
                      )
                    else
                      ...provider.trustedNumbers.take(2).map((n) => ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primary.withOpacity(0.1),
                              child: const Icon(Icons.person_rounded, color: AppTheme.primary, size: 20),
                            ),
                            title: Text(n.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(n.phoneNumber),
                          )),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.people_alt_rounded, color: Colors.green),
                      title: const Text('Manage Trusted Numbers', style: TextStyle(fontWeight: FontWeight.bold)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.pushNamed(context, '/trusted-numbers'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              // ─── Automatic Responses Section ────────────────────────────────
              _buildSectionHeader('AUTOMATIC RESPONSES'),
              _buildSettingCard(
                context,
                child: Column(
                  children: [
                    _buildToggleTile(
                      icon: Icons.location_on_rounded,
                      color: Colors.blue,
                      title: 'Send GPS Location',
                      value: settings.defaultActions.sendLocation,
                      onChanged: (v) => provider.setDefaultActions(settings.defaultActions.copyWith(sendLocation: v)),
                    ),
                    const Divider(indent: 70),
                    _buildToggleTile(
                      icon: Icons.volume_up_rounded,
                      color: AppTheme.primary,
                      title: 'Start Loud Alarm',
                      value: settings.defaultActions.startAlarm,
                      onChanged: (v) => provider.setDefaultActions(settings.defaultActions.copyWith(startAlarm: v)),
                    ),
                    const Divider(indent: 70),
                    _buildToggleTile(
                      icon: Icons.track_changes_rounded,
                      color: Colors.green,
                      title: 'Live Tracking',
                      subtitle: 'Sends GPS every 3 mins',
                      value: settings.defaultActions.enableTracking,
                      onChanged: (v) async {
                        if (v) {
                          final loc = await Permission.location.request();
                          final sms = await Permission.sms.request();
                          if (!loc.isGranted || !sms.isGranted) return;
                        }
                        provider.setDefaultActions(settings.defaultActions.copyWith(enableTracking: v));
                      },
                    ),
                    const Divider(indent: 70),
                    _buildToggleTile(
                      icon: Icons.lock_rounded,
                      color: Colors.orange,
                      title: 'Lock Device Screen',
                      value: settings.defaultActions.lockDevice,
                      onChanged: (v) async {
                        if (v && !provider.isDeviceAdminActive) {
                          await provider.requestDeviceAdmin();
                          if (!provider.isDeviceAdminActive) return;
                        }
                        provider.setDefaultActions(settings.defaultActions.copyWith(lockDevice: v));
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              // ─── Advanced Protection Section ───────────────────────────────
              _buildSectionHeader('ADVANCED PROTECTION'),
              _buildSettingCard(
                context,
                child: Column(
                  children: [
                    _buildToggleTile(
                      icon: Icons.chat_bubble_outline_rounded,
                      color: provider.isNotificationListenerEnabled ? Colors.green : Colors.blueGrey,
                      title: 'RCS / Chat Protection',
                      subtitle: provider.isNotificationListenerEnabled ? 'Active' : 'Enable to process WhatsApp/RCS',
                      value: provider.isNotificationListenerEnabled,
                      onChanged: (val) => provider.openNotificationListenerSettings(),
                    ),
                    const Divider(indent: 70),
                    _buildToggleTile(
                      icon: Icons.camera_front_rounded,
                      color: Colors.indigo,
                      title: l10n.intrusionSelfie,
                      subtitle: l10n.intrusionSelfieDesc,
                      value: settings.intrusionSelfieEnabled,
                      onChanged: (val) async {
                        if (val) {
                          final status = await Permission.camera.request();
                          if (!status.isGranted) return;
                        }
                        provider.updateSettings(settings.copyWith(intrusionSelfieEnabled: val));
                      },
                    ),
                    const Divider(indent: 70),
                    _buildToggleTile(
                      icon: Icons.sd_card_alert_rounded,
                      color: Colors.redAccent,
                      title: l10n.simChangeAlert,
                      value: settings.simChangeAlertEnabled,
                      onChanged: (val) => provider.updateSettings(settings.copyWith(simChangeAlertEnabled: val)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              // ─── Technical & System Section ───────────────────────────────
              _buildSectionHeader('TECHNICAL & SYSTEM'),
              _buildSettingCard(
                context,
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.admin_panel_settings_rounded, 
                        color: provider.isDeviceAdminActive ? Colors.green : Colors.red,
                      ),
                      title: Text(l10n.deviceAdminTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(provider.isDeviceAdminActive ? l10n.deviceAdminActive : l10n.deviceAdminInactive),
                      onTap: () {
                        if (provider.isDeviceAdminActive) {
                          _confirmDeactivation(context, provider);
                        } else {
                          provider.requestDeviceAdmin();
                        }
                      },
                    ),
                    const Divider(indent: 70),
                    ListTile(
                      leading: const Icon(Icons.battery_saver_rounded, color: Colors.amber),
                      title: Text(l10n.batteryOptimizationTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                      onTap: () => provider.openBatteryOptimizationSettings(),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              if (!isPremium) ...[
                const NativeAdWidget(templateType: TemplateType.medium),
                const SizedBox(height: 40),
              ],
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
        style: const TextStyle(
          color: Colors.grey, 
          fontSize: 11, 
          fontWeight: FontWeight.w900, 
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingCard(BuildContext context, {required Widget child}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
        ),
      ),
      child: child,
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
      value: value,
      onChanged: onChanged,
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Future<void> _confirmDeactivation(BuildContext context, AppProvider provider) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deactivateProtection),
        content: Text(l10n.deactivateWarning),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.deactivate, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      provider.deactivateDeviceAdmin();
    }
  }
}
