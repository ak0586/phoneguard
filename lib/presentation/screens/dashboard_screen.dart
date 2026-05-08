import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:lost_phone_finder/presentation/providers/app_provider.dart';
import 'package:lost_phone_finder/presentation/providers/auth_provider.dart';
import 'package:lost_phone_finder/presentation/widgets/protection_status_card.dart';
import 'package:lost_phone_finder/presentation/widgets/intrusion_alerts_card.dart';
import 'package:lost_phone_finder/presentation/widgets/device_admin_status_card.dart';
import 'package:lost_phone_finder/presentation/widgets/permissions_card.dart';
import 'package:lost_phone_finder/presentation/widgets/active_actions_card.dart';
import 'package:lost_phone_finder/presentation/widgets/native_ad_widget.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' hide AppState;
import 'package:lost_phone_finder/l10n/app_localizations.dart';
import 'package:lost_phone_finder/presentation/widgets/onboarding_popup.dart';
import 'package:lost_phone_finder/presentation/screens/paywall_screen.dart';
import 'package:lost_phone_finder/presentation/widgets/rating_dialog.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _appVersion = '1.0.0';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initPackageInfo();
    context.read<AuthProvider>().addListener(_onAuthChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appProvider = context.read<AppProvider>();
      appProvider.checkDeviceAdminStatus();

      // Show onboarding if not done
      if (!appProvider.settings.onboardingDone) {
        OnboardingPopup.show(context);
      } else {
        // Show subscription upsell if non-premium and not shown this session
        final authProvider = context.read<AuthProvider>();
        if (authProvider.profile?.isPremium != true && !appProvider.sessionUpsellShown) {
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const PaywallScreen()),
              );
              appProvider.setSessionUpsellShown(true);
            }
          });
        } else {
          // Check for rating dialog if upsell not shown
          Future.delayed(const Duration(seconds: 8), () {
            if (mounted && appProvider.canShowRatingDialog()) {
              _showRatingDialog(context, appProvider);
            }
          });
        }
      }
    });
  }

  void _onAuthChanged() {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final app = context.read<AppProvider>();
    if (auth.profile != null) {
      if (auth.profile!.trustedNumbers.isNotEmpty)
        app.syncTrustedNumbers(auth.profile!.trustedNumbers);
      if (auth.profile!.triggerKeyword != null)
        app.syncTriggerKeyword(auth.profile!.triggerKeyword!);
    }
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = '${info.version}+${info.buildNumber}';
      });
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
      context.read<AppProvider>().checkDeviceAdminStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Consumer2<AuthProvider, AppProvider>(
        builder: (context, auth, app, _) {
          // 1. Show global loader during initialization
          if (auth.isInitializing || app.state == AppState.loading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // 2. Handle Critical Overlays
          if (app.isUpdateRequired)
            return _buildForceUpdateOverlay(context, app);
          if (auth.hasDeviceConflict)
            return _buildDeviceConflictOverlay(context, auth);

          return SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(context, auth, isDarkMode),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (auth.profile?.isPremium != true) ...[
                        _buildPremiumBanner(context, isDarkMode),
                        const SizedBox(height: 20),
                      ],
                      const ProtectionStatusCard(),
                      const SizedBox(height: 20),
                      const ActiveActionsCard(),
                      const SizedBox(height: 20),
                      const IntrusionAlertsCard(),
                      const SizedBox(height: 20),
                      const DeviceAdminStatusCard(),
                      const SizedBox(height: 24),
                      _buildSecurityHubCard(context, isDarkMode),
                      const SizedBox(height: 20),
                      _buildWebDashboardCard(context, isDarkMode, l10n),
                      const SizedBox(height: 24),
                      const PermissionsCard(),
                      if (auth.profile?.isPremium != true) ...[
                        const SizedBox(height: 20),
                        const NativeAdWidget(),
                      ],
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, AuthProvider auth, bool isDark) {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.menu_rounded),
          ),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PhoneGuard: Lost Phone Finder',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 22,
              letterSpacing: -0.5,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          Text(
            'Anti-Theft Security',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.blue.shade400,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/profile'),
            child: Hero(
              tag: 'profile_avatar',
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  backgroundImage: auth.profile?.photoUrl != null
                      ? (auth.profile!.photoUrl!.startsWith('data:image')
                          ? MemoryImage(base64Decode(auth.profile!.photoUrl!.split(',').last))
                          : NetworkImage(auth.profile!.photoUrl!) as ImageProvider)
                      : null,
                  child: auth.profile?.photoUrl == null
                      ? const Icon(
                          Icons.person_rounded,
                          size: 20,
                          color: Colors.blue,
                        )
                      : null,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWebDashboardCard(BuildContext context, bool isDark, AppLocalizations l10n) {
    return InkWell(
      onTap: () => _launchURL('https://phoneguard-web-dashboard.vercel.app/'),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    Colors.indigo.shade900.withOpacity(0.4),
                    Colors.purple.shade900.withOpacity(0.4),
                  ]
                : [Colors.indigo.shade50, Colors.purple.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.indigo.withOpacity(0.3), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.dashboard_rounded,
                color: Colors.indigo,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.webDashboard,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Remote control your phone from any browser',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new_rounded, color: Colors.indigo, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityHubCard(BuildContext context, bool isDark) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/settings'),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    Colors.blue.shade900.withOpacity(0.4),
                    Colors.indigo.shade900.withOpacity(0.4),
                  ]
                : [Colors.blue.shade50, Colors.indigo.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.admin_panel_settings_rounded,
                color: Colors.blue,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Security Control Center & Settings',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Setup trigger keyword, trusted numbers & default actions',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.blue),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showLogoutDialog(BuildContext context, AuthProvider auth) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          l10n.logout,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(l10n.logoutConfirmMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.cancel.toUpperCase(),
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              auth.signOut();
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/auth-wrapper',
                (route) => false,
              );
            },
            child: Text(
              l10n.logout.toUpperCase(),
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRatingDialog(BuildContext context, AppProvider app) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => RatingDialog(
        onRateNow: () {
          Navigator.pop(context);
          app.requestReview();
        },
        onLater: () {
          Navigator.pop(context);
          app.markRatingRequested();
        },
      ),
    );
  }

  Widget _buildPremiumBanner(BuildContext context, bool isDark) {
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const PaywallScreen()),
      ),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.amber.shade700,
              const Color(0xFF0D1B2A), // Midnight blue
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.stars_rounded, color: Colors.white, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upgrade to Lifetime Protection',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    'Zero Ads • Permanent Security • Web Dashboard',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildForceUpdateOverlay(BuildContext context, AppProvider app) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.update_rounded,
              size: 80,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            l10n.updateRequired,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.updateRequiredDesc,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: () => _launchURL(app.playStoreUrl),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(l10n.updateNow),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.versionUnsupported,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceConflictOverlay(BuildContext context, AuthProvider auth) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              size: 80,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            l10n.accountConflict,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            auth.profile?.deviceModel != null
                ? "Your account is currently protecting another device (${auth.profile!.deviceModel}).\n\nWould you like to switch protection to this device instead?"
                : l10n.accountConflictDesc,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: () => auth.setAsPrimaryDevice(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: auth.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'USE THIS DEVICE',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              auth.signOut();
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/auth-wrapper',
                (route) => false,
              );
            },
            style: TextButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
            ),
            child: Text(
              l10n.logout.toUpperCase(),
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerCardTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _DrawerCardTile({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.05),
            ),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
