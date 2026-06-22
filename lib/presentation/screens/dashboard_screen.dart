import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:lost_phone_finder/presentation/providers/app_provider.dart';
import 'package:lost_phone_finder/presentation/providers/auth_provider.dart';
import 'package:lost_phone_finder/presentation/widgets/protection_status_card.dart';
import 'package:lost_phone_finder/presentation/widgets/intrusion_alerts_card.dart';
import 'package:lost_phone_finder/presentation/widgets/device_admin_status_card.dart';
import 'package:lost_phone_finder/presentation/widgets/permissions_card.dart';
import 'package:lost_phone_finder/presentation/widgets/active_actions_card.dart';
import 'package:lost_phone_finder/presentation/widgets/native_ad_widget.dart';
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
  late AuthProvider _authProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authProvider = Provider.of<AuthProvider>(context, listen: false);
    _authProvider.addListener(_onAuthChanged);
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
    final auth = _authProvider;
    final app = context.read<AppProvider>();
    if (auth.profile != null) {
      if (auth.profile!.trustedNumbers.isNotEmpty)
        app.syncTrustedNumbers(auth.profile!.trustedNumbers);
      if (auth.profile!.triggerKeyword != null)
        app.syncTriggerKeyword(auth.profile!.triggerKeyword!);
    }
  }



  @override
  void dispose() {
    _authProvider.removeListener(_onAuthChanged);
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
                      _buildVulnerableBanner(context, app, isDarkMode),
                      const ProtectionStatusCard(),
                      const SizedBox(height: 20),
                      const ActiveActionsCard(),
                      const SizedBox(height: 20),
                      _buildShortcutsGrid(context, isDarkMode, l10n),
                      const SizedBox(height: 24),
                      const IntrusionAlertsCard(),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
                        child: Text(
                          'SECURITY SETUP CHECKLIST',
                          style: TextStyle(
                            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const DeviceAdminStatusCard(),
                      const SizedBox(height: 16),
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

  Widget _buildShortcutsGrid(BuildContext context, bool isDark, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => Navigator.pushNamed(context, '/settings'),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 120,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.settings_suggest_rounded, color: Colors.blue, size: 20),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.settingsTitle,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Control & Setup',
                        style: TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: InkWell(
            onTap: () => _launchURL('https://phoneguard-web-dashboard.vercel.app/'),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 120,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.dashboard_rounded, color: Colors.indigo, size: 20),
                      ),
                      const Icon(Icons.open_in_new_rounded, color: Colors.indigo, size: 14),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.webDashboard,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Browser Portal',
                        style: TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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

  Widget _buildVulnerableBanner(BuildContext context, AppProvider app, bool isDark) {
    final missingAdmin = !app.isDeviceAdminActive;
    final missingNotif = !app.isNotificationListenerEnabled;

    if (!missingAdmin && !missingNotif) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade900.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade900.withOpacity(0.25), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red.shade400, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.deviceVulnerable,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.deviceVulnerableDesc,
            style: TextStyle(
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          if (missingAdmin)
            _vulnerableItem(l10n.adminDisabled),
          if (missingNotif)
            _vulnerableItem(l10n.chatDisabled),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/setup-guide');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade800,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(l10n.fixSecurityIssues, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _vulnerableItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 6, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

