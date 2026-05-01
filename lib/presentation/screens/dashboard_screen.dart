import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/protection_status_card.dart';
import '../widgets/permissions_card.dart';
import '../widgets/active_actions_card.dart';
import '../widgets/native_ad_widget.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/theme/app_theme.dart';

import '../../l10n/app_localizations.dart';

/// Main dashboard screen showing protection status and navigation
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Set up listeners for auth profile changes
    context.read<AuthProvider>().addListener(_onAuthChanged);

    // Initial sync and setup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appProvider = context.read<AppProvider>();
      final authProvider = context.read<AuthProvider>();
      
      appProvider.refreshActiveActions();
      
      // Local -> Firestore
      appProvider.onTrustedNumbersChanged = (numbers) {
        authProvider.updateTrustedNumbers(numbers);
      };
      appProvider.onTriggerKeywordChanged = (keyword) {
        authProvider.updateTriggerKeyword(keyword);
      };

      // Firestore -> Local (One-time check on start)
      if (authProvider.profile != null) {
        appProvider.syncTrustedNumbers(authProvider.profile!.trustedNumbers);
        if (authProvider.profile!.triggerKeyword != null) {
          appProvider.syncTriggerKeyword(authProvider.profile!.triggerKeyword!);
        }
      }
    });
  }

  void _onAuthChanged() {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final app = context.read<AppProvider>();
    
    if (auth.profile != null) {
      // Sync incoming profile changes to local
      if (auth.profile!.trustedNumbers.isNotEmpty) {
        app.syncTrustedNumbers(auth.profile!.trustedNumbers);
      }
      if (auth.profile!.triggerKeyword != null) {
        app.syncTriggerKeyword(auth.profile!.triggerKeyword!);
      }
    }
  }

  @override
  void dispose() {
    context.read<AuthProvider>().removeListener(_onAuthChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<AppProvider>().refreshActiveActions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: ValueKey(isDarkMode),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.hasDeviceConflict) {
            return _buildDeviceConflictOverlay(context, auth);
          }
          
          return SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                _buildHeader(context),
                const SizedBox(height: 24),
                const ProtectionStatusCard(),
                const NativeAdWidget(templateType: TemplateType.small),
                const SizedBox(height: 28),
                _buildSectionTitle(l10n.quickActions),
                const SizedBox(height: 16),
                _buildAlarmControls(context, l10n),
                const SizedBox(height: 16),
                _buildSectionTitle(l10n.settings),
                const SizedBox(height: 16),
                _buildFeatureGrid(context, l10n),
                const SizedBox(height: 28),
                const PermissionsCard(),
                const SizedBox(height: 28),
                _buildSectionTitle('More'),
                const SizedBox(height: 12),
                _buildMoreOptions(context, l10n, isDarkMode),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      );
    },
  ),
);
  }

  Widget _buildDeviceConflictOverlay(BuildContext context, AuthProvider auth) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.phonelink_erase_rounded,
              size: 80,
              color: Colors.redAccent,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Primary Device Conflict',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Your account is currently active on another device.\n\nFor security, PhoneGuard only allows one primary device at a time to prevent remote command conflicts.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 16,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: auth.isLoading ? null : () => auth.setAsPrimaryDevice(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: auth.isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'SWITCH TO THIS DEVICE',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => auth.signOut(),
            child: const Text('LOGOUT', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PhoneGuard',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w800,
                fontSize: 28,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Remote SMS Recovery',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade500,
                fontSize: 13,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/profile'),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.grey,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildAlarmControls(BuildContext context, AppLocalizations l10n) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.volume_up_rounded,
                label: provider.isAlarmActive ? l10n.stopAlarm : l10n.testAlarm,
                color: provider.isAlarmActive
                    ? AppTheme.error
                    : AppTheme.primary,
                onTap: () {
                  if (provider.isAlarmActive) {
                    provider.stopAlarm();
                  } else {
                    provider.startAlarm();
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: provider.isTrackingActive
                    ? Icons.location_off_rounded
                    : Icons.my_location_rounded,
                label: provider.isTrackingActive ? 'Stop Track' : 'Test Track',
                color: provider.isTrackingActive
                    ? AppTheme.warning
                    : AppTheme.success,
                onTap: () async {
                  if (provider.isTrackingActive) {
                    provider.stopTracking();
                  } else {
                    // Check permissions before starting
                    final smsStatus = await Permission.sms.request();
                    final locStatus = await Permission.location.request();

                    if (!smsStatus.isGranted || !locStatus.isGranted) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'SMS and Location permissions are required for tracking',
                            ),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                      return;
                    }

                    final numbers = provider.trustedNumbers;
                    if (numbers.isNotEmpty) {
                      provider.startTracking(numbers.first.phoneNumber);
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Add a trusted number first'),
                          ),
                        );
                      }
                    }
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: Icons.run_circle_outlined,
                label: 'Running',
                color: (provider.isAlarmActive || provider.isTrackingActive)
                    ? Colors.orange
                    : Colors.grey,
                hasBadge: provider.isAlarmActive || provider.isTrackingActive,
                onTap: () => _showRunningActionsDialog(context),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showRunningActionsDialog(BuildContext context) {
    // Proactively refresh before showing to ensure accuracy
    context.read<AppProvider>().refreshActiveActions();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.run_circle_outlined, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Running Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const ActiveActionsCard(showEmptyState: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureGrid(BuildContext context, AppLocalizations l10n) {
    final features = [
      _FeatureItem(
        icon: Icons.tune_rounded,
        title: l10n.setupSecurity,
        subtitle: 'Keyword & PIN',
        route: '/setup',
        gradient: const LinearGradient(
          colors: [Color(0xFF7B1FA2), Color(0xFF9C27B0)],
        ),
      ),
      _FeatureItem(
        icon: Icons.contacts_rounded,
        title: l10n.trustedNumbers,
        subtitle: 'Manage contacts',
        route: '/trusted-numbers',
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
        ),
      ),
      _FeatureItem(
        icon: Icons.settings_suggest_rounded,
        title: l10n.defaultActions,
        subtitle: 'Auto-response',
        route: '/default-actions',
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF388E3C)],
        ),
      ),
      _FeatureItem(
        icon: Icons.sms_rounded,
        title: l10n.commandGuide,
        subtitle: 'SMS guide',
        route: '/command-guide',
        gradient: AppTheme.primaryGradient,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio:
            1.2, // Reduced from 1.4 to accommodate longer Hindi strings
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final f = features[index];
        return _FeatureCard(item: f);
      },
    );
  }

  Widget _buildMoreOptions(
    BuildContext context,
    AppLocalizations l10n,
    bool isDarkMode,
  ) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final isDark = provider.settings.isDarkMode;
        final isHi = provider.settings.languageCode == 'hi';
        
        return Column(
          children: [
            _OptionTile(
              icon: Icons.history_rounded,
              label: l10n.activityLogs,
              onTap: () => Navigator.pushNamed(context, '/activity-logs'),
            ),
            const SizedBox(height: 4),
            _OptionTile(
              icon: Icons.privacy_tip_rounded,
              label: l10n.privacyPolicy,
              onTap: () => Navigator.pushNamed(context, '/privacy-policy'),
            ),
            const SizedBox(height: 4),
            _OptionTile(
              icon: Icons.help_outline_rounded,
              label: 'Help & FAQ',
              onTap: () => Navigator.pushNamed(context, '/faq'),
            ),
            const SizedBox(height: 4),
            _OptionTile(
              icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              label: isDark ? 'Light Mode' : 'Dark Mode',
              trailing: Switch(
                key: ValueKey('theme_switch_$isDark'),
                value: isDark,
                onChanged: (val) => provider.setThemeMode(isDark: val),
              ),
            ),
            const SizedBox(height: 4),
            _OptionTile(
              icon: Icons.language_rounded,
              label: isHi ? 'English' : 'हिंदी (Hindi)',
              trailing: const Icon(
                Icons.translate_rounded,
                color: Colors.grey,
              ),
              onTap: () => provider.setLanguageCode(isHi ? 'en' : 'hi'),
            ),
          ],
        );
      },
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool hasBadge;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.hasBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: isDarkMode ? color.withValues(alpha: 0.1) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withValues(alpha: isDarkMode ? 0.3 : 0.15),
                width: 1.5,
              ),
              boxShadow: isDarkMode
                  ? null
                  : [
                      BoxShadow(
                        color: color.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (hasBadge)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final LinearGradient gradient;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.gradient,
  });
}

class _FeatureCard extends StatelessWidget {
  final _FeatureItem item;
  const _FeatureCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, item.route),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: Theme.of(context).brightness == Brightness.light
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: item.gradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: Colors.white, size: 22),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    item.title,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _OptionTile({
    required this.icon,
    required this.label,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: isDarkMode ? 0.1 : 0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.grey.shade600, size: 20),
        ),
        title: Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: trailing ??
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
        onTap: onTap,
        tileColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),
    );
  }
}
