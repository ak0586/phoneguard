import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lost_phone_finder/l10n/app_localizations.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
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
    });
  }

  void _onAuthChanged() {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final app = context.read<AppProvider>();
    if (auth.profile != null) {
      if (auth.profile!.trustedNumbers.isNotEmpty) app.syncTrustedNumbers(auth.profile!.trustedNumbers);
      if (auth.profile!.triggerKeyword != null) app.syncTriggerKeyword(auth.profile!.triggerKeyword!);
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

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: _buildDrawer(context, l10n, isDarkMode),
      body: Consumer2<AuthProvider, AppProvider>(
        builder: (context, auth, app, _) {
          if (app.isUpdateRequired) return _buildForceUpdateOverlay(context, app);
          if (auth.hasDeviceConflict) return _buildDeviceConflictOverlay(context, auth);
          
          return SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(context, auth, isDarkMode),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const ProtectionStatusCard(),
                      const SizedBox(height: 20),
                      const ActiveActionsCard(),
                      const SizedBox(height: 20),
                      const IntrusionAlertsCard(),
                      const SizedBox(height: 20),
                      const DeviceAdminStatusCard(),
                      const SizedBox(height: 20),
                      const PermissionsCard(),
                      const SizedBox(height: 24),
                      _buildQuickActionsGrid(context, l10n, isDarkMode),
                      const SizedBox(height: 32),
                      const NativeAdWidget(),
                      const SizedBox(height: 24),
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
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.menu_rounded),
        ),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
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
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.blue.shade400),
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
                  border: Border.all(color: Colors.blue.withOpacity(0.3), width: 2),
                ),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  backgroundImage: auth.profile?.photoUrl != null ? NetworkImage(auth.profile!.photoUrl!) : null,
                  child: auth.profile?.photoUrl == null ? const Icon(Icons.person_rounded, size: 20, color: Colors.blue) : null,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context, AppLocalizations l10n, bool isDark) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _buildActionCard(
          context,
          l10n.setupSecurity,
          Icons.security_rounded,
          Colors.blue,
          () => Navigator.pushNamed(context, '/setup'),
          isDark,
        ),
        _buildActionCard(
          context,
          l10n.trustedNumbers,
          Icons.contacts_rounded,
          Colors.green,
          () => Navigator.pushNamed(context, '/trusted-numbers'),
          isDark,
        ),
        _buildActionCard(
          context,
          l10n.defaultActions,
          Icons.settings_suggest_rounded,
          Colors.orange,
          () => Navigator.pushNamed(context, '/default-actions'),
          isDark,
        ),
        _buildActionCard(
          context,
          l10n.commandGuide,
          Icons.menu_book_rounded,
          Colors.purple,
          () => Navigator.pushNamed(context, '/command-guide'),
          isDark,
        ),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
          boxShadow: isDark ? [] : [BoxShadow(color: color.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AppLocalizations l10n, bool isDarkMode) {
    final auth = context.read<AuthProvider>();
    final provider = context.read<AppProvider>();
    final isDark = provider.settings.isDarkMode;
    final isHi = provider.settings.languageCode == 'hi';

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.8,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.05),
                    border: Border(bottom: BorderSide(color: Colors.blue.withOpacity(0.1))),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, spreadRadius: 2),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'PhoneGuard: Finder',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.5),
                      ),
                      const Text(
                        'Premium Security Suite',
                        style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // 1. MAIN FEATURES
                _buildDrawerSectionTitle('MAIN CONTROL'),
                _DrawerCardTile(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  color: Colors.blueGrey,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/settings');
                  },
                ),
                _DrawerCardTile(
                  icon: Icons.history_rounded,
                  label: l10n.activityLogs,
                  color: const Color(0xFFFF9800),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/activity-logs');
                  },
                ),
                _DrawerCardTile(
                  icon: Icons.stars_rounded,
                  label: auth.profile?.isPremium == true ? 'Premium Active' : 'Upgrade to Premium',
                  color: Colors.amber,
                  trailing: auth.profile?.isPremium == true ? const Icon(Icons.verified_rounded, color: Colors.amber, size: 18) : null,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/subscription');
                  },
                ),
                
                const SizedBox(height: 20),
                
                // 2. REMOTE ACCESS
                _buildDrawerSectionTitle('REMOTE ACCESS'),
                _DrawerCardTile(
                  icon: Icons.dashboard_rounded,
                  label: 'Web Dashboard',
                  color: Colors.indigo,
                  onTap: () => _launchURL('https://phoneguard-web-dashboard.vercel.app/'),
                  trailing: const Icon(Icons.open_in_new_rounded, size: 16, color: Colors.grey),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.indigo.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'REMOTE CONTROL URL',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.indigo, letterSpacing: 1),
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          'phoneguard-web-dashboard.vercel.app',
                          style: TextStyle(fontSize: 11, color: isDarkMode ? Colors.white70 : Colors.black87, fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                
                // 3. SUPPORT
                _buildDrawerSectionTitle('SUPPORT & HELP'),
                _DrawerCardTile(
                  icon: Icons.help_outline_rounded,
                  label: 'Help & FAQ',
                  color: const Color(0xFF4CAF50),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/faq');
                  },
                ),
                _DrawerCardTile(
                  icon: Icons.email_rounded,
                  label: 'Contact Support',
                  color: Colors.teal,
                  onTap: () => _launchURL('mailto:support@kyvronix.com'),
                ),

                const SizedBox(height: 20),
                
                // 4. PREFERENCES
                _buildDrawerSectionTitle('PREFERENCES'),
                _DrawerCardTile(
                  icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  label: isDark ? 'Light Mode' : 'Dark Mode',
                  color: Colors.orange,
                  trailing: Switch(
                    value: isDark,
                    activeColor: Colors.orange,
                    onChanged: (val) => provider.setThemeMode(isDark: val),
                  ),
                ),
                _DrawerCardTile(
                  icon: Icons.language_rounded,
                  label: isHi ? 'English' : 'हिंदी (Hindi)',
                  color: Colors.blueGrey,
                  onTap: () => provider.setLanguageCode(isHi ? 'en' : 'hi'),
                  trailing: const Icon(Icons.translate_rounded, size: 18, color: Colors.grey),
                ),

                const SizedBox(height: 20),
                
                // 5. LEGAL & ABOUT
                _buildDrawerSectionTitle('ABOUT'),
                _DrawerCardTile(
                  icon: Icons.privacy_tip_rounded,
                  label: l10n.privacyPolicy,
                  color: const Color(0xFF2196F3),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/privacy-policy');
                  },
                ),
                _DrawerCardTile(
                  icon: Icons.share_rounded,
                  label: 'Share App',
                  color: Colors.pink,
                  onTap: () => Share.share('Protect your phone with PhoneGuard! Download now: https://phoneguard-web-dashboard.vercel.app/'),
                ),
                _DrawerCardTile(
                  icon: Icons.star_rounded,
                  label: 'Rate & Review',
                  color: Colors.amber,
                  onTap: () => _launchURL('https://play.google.com/store/apps/details?id=com.kyvronix.phoneguard'),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: _DrawerCardTile(
              icon: Icons.logout_rounded,
              label: 'Logout',
              color: Colors.redAccent,
              onTap: () {
                Navigator.pop(context);
                _showLogoutDialog(context, auth);
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                children: [
                  Text(
                    'PhoneGuard v$_appVersion (Stable)',
                    style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Made with ❤️ by Kyvronix',
                    style: TextStyle(color: Colors.grey.withOpacity(0.5), fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 8),
      child: Text(
        title,
        style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () {
              auth.signOut();
              Navigator.pushNamedAndRemoveUntil(context, '/auth-wrapper', (route) => false);
            },
            child: const Text('LOGOUT', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildForceUpdateOverlay(BuildContext context, AppProvider app) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.update_rounded, size: 80, color: Colors.blue),
          ),
          const SizedBox(height: 32),
          Text('Update Required', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(
            'A new version of PhoneGuard is available. To maintain security and remote connectivity, you must update to the latest version.',
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('UPDATE NOW'),
          ),
          const SizedBox(height: 24),
          const Text('Your current version is no longer supported.', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildDeviceConflictOverlay(BuildContext context, AuthProvider auth) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.warning_amber_rounded, size: 80, color: Colors.red),
          ),
          const SizedBox(height: 32),
          const Text('Account Conflict', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text(
            'This account is already active on another device. For security, PhoneGuard only allows one active device per account.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: () {
              auth.signOut();
              Navigator.pushNamedAndRemoveUntil(context, '/auth-wrapper', (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('LOGOUT'),
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
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
            boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
