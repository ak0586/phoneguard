import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import 'package:lost_phone_finder/l10n/app_localizations.dart';

class AppDrawer extends StatelessWidget {
  final String appVersion;
  const AppDrawer({super.key, required this.appVersion});

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
        title: Text(l10n.logout),
        content: Text(l10n.logoutConfirmMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              auth.signOut();
              Navigator.pop(context);
            },
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final auth = context.watch<AuthProvider>();
    final isDark = provider.settings.isDarkMode;
    final isHi = provider.settings.languageCode == 'hi';
    final l10n = AppLocalizations.of(context)!;

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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.05),
                    border: Border(
                      bottom: BorderSide(color: Colors.blue.withOpacity(0.1)),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.blue.withOpacity(0.3), width: 2),
                            ),
                            child: CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.blue.withOpacity(0.1),
                              backgroundImage: auth.profile?.photoUrl != null
                                  ? (auth.profile!.photoUrl!.startsWith('data:image')
                                      ? MemoryImage(base64Decode(auth.profile!.photoUrl!.split(',').last))
                                      : NetworkImage(auth.profile!.photoUrl!) as ImageProvider)
                                  : null,
                              child: auth.profile?.photoUrl == null
                                  ? Text(
                                      auth.user?.displayName?.isNotEmpty == true
                                          ? auth.user!.displayName![0].toUpperCase()
                                          : 'U',
                                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  auth.user?.displayName ?? 'User Name',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                    letterSpacing: -0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  auth.user?.email ?? 'user@example.com',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: auth.profile?.isPremium == true 
                              ? Colors.amber.withOpacity(0.15)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: auth.profile?.isPremium == true 
                                ? Colors.amber.withOpacity(0.4)
                                : Colors.grey.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              auth.profile?.isPremium == true ? Icons.stars_rounded : Icons.person_outline_rounded,
                              size: 14,
                              color: auth.profile?.isPremium == true ? Colors.amber.shade700 : Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              auth.profile?.isPremium == true 
                                  ? (auth.profile?.subscriptionType?.toUpperCase() ?? 'PREMIUM MEMBER')
                                  : 'FREE MEMBER',
                              style: TextStyle(
                                fontSize: 10,
                                color: auth.profile?.isPremium == true ? Colors.amber.shade800 : Colors.grey,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _DrawerCardTile(
                  icon: Icons.auto_awesome_rounded,
                  label: isHi ? 'ऐप फीचर्स' : 'App Features',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/features');
                  },
                ),
                const SizedBox(height: 20),

                const SizedBox(height: 12),

                // SUPPORT
                _buildDrawerSectionTitle(l10n.supportHelp),
                _DrawerCardTile(
                  icon: Icons.help_outline_rounded,
                  label: l10n.helpFaq,
                  color: const Color(0xFF4CAF50),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/faq');
                  },
                ),
                _DrawerCardTile(
                  icon: Icons.email_rounded,
                  label: l10n.contactSupport,
                  color: Colors.teal,
                  onTap: () => _launchURL('mailto:support@kyvronix.com'),
                ),

                const SizedBox(height: 20),

                // PREFERENCES
                _buildDrawerSectionTitle(l10n.preferences),
                _DrawerCardTile(
                  icon: isDark
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                  label: isDark ? l10n.lightMode : l10n.darkModeLabel,
                  color: Colors.orange,
                  onTap: () => provider.setThemeMode(isDark: !isDark),
                  trailing: Switch(
                    value: isDark,
                    activeColor: Colors.orange,
                    onChanged: (val) => provider.setThemeMode(isDark: val),
                  ),
                ),
                _DrawerCardTile(
                  icon: Icons.language_rounded,
                  label: isHi ? l10n.english : l10n.hindi,
                  color: Colors.blueGrey,
                  onTap: () => provider.setLanguageCode(isHi ? 'en' : 'hi'),
                  trailing: const Icon(
                    Icons.translate_rounded,
                    size: 18,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 20),

                // ABOUT
                _buildDrawerSectionTitle(l10n.about),
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
                  label: l10n.shareApp,
                  color: Colors.pink,
                  onTap: () => Share.share(l10n.shareMsg),
                ),
                _DrawerCardTile(
                  icon: Icons.star_rounded,
                  label: l10n.rateReview,
                  color: Colors.amber,
                  onTap: () => _launchURL(
                    'https://play.google.com/store/apps/details?id=com.kyvronix.phoneguard',
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            child: _DrawerCardTile(
              icon: Icons.logout_rounded,
              label: l10n.logout,
              color: Colors.redAccent,
              onTap: () {
                Navigator.pop(context);
                _showLogoutDialog(context, auth);
              },
            ),
          ),
          SafeArea(
            top: false,
            bottom: true,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                children: [
                  Text(
                    'PhoneGuard v$appVersion (Stable)',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.madeWithLove,
                    style: TextStyle(
                      color: Colors.grey.withOpacity(0.5),
                      fontSize: 10,
                    ),
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
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _DrawerCardTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final Widget? trailing;

  const _DrawerCardTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.03),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
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
