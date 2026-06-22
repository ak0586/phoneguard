import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import 'package:lost_phone_finder/l10n/app_localizations.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _countryName = "detecting";

  @override
  void initState() {
    super.initState();
    _fetchCountry();
  }

  Future<void> _fetchCountry() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastFetchTime = prefs.getInt('last_country_fetch_time') ?? 0;
      final cachedCountry = prefs.getString('cached_country_name');
      final currentTime = DateTime.now().millisecondsSinceEpoch;

      if (cachedCountry != null && (currentTime - lastFetchTime) < 86400000) {
        if (mounted) setState(() => _countryName = cachedCountry);
        return;
      }

      final status = await Permission.locationWhenInUse.request();
      if (status.isGranted) {
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
          ),
        );
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty && mounted) {
          final country = placemarks.first.country ?? "Unknown Country";
          await prefs.setString('cached_country_name', country);
          await prefs.setInt('last_country_fetch_time', currentTime);
          setState(() => _countryName = country);
        }
      } else if (mounted) {
        setState(() => _countryName = cachedCountry ?? "denied");
      }
    } catch (e) {
      if (mounted) {
        final prefs = await SharedPreferences.getInstance();
        setState(
          () => _countryName =
              prefs.getString('cached_country_name') ?? "unavailable",
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final profile = authProvider.profile;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.profileTitle,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showLogoutDialog(context, authProvider, l10n),
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              _buildUserHeader(context, user, authProvider, profile),
              const SizedBox(height: 32),

              // Subscription Status Card
              if (profile != null)
                _buildSubscriptionCard(context, profile, l10n),
              const SizedBox(height: 24),

              _buildInfoSection(context, l10n, authProvider, user),
              const SizedBox(height: 32),

              _buildActionButtons(context, l10n, authProvider),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserHeader(
    BuildContext context,
    dynamic user,
    AuthProvider auth,
    dynamic profile,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Hero(
          tag: 'profile_avatar',
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).scaffoldBackgroundColor,
                width: 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 58,
              backgroundColor: AppTheme.primary,
              backgroundImage: (() {
                final url = profile?.photoUrl;
                if (url == null) return null;
                if (url.startsWith('data:image')) {
                  return MemoryImage(base64Decode(url.split(',').last));
                }
                return NetworkImage(url) as ImageProvider;
              })(),
              child: profile?.photoUrl == null
                  ? Text(
                      user?.displayName?.isNotEmpty == true
                          ? user!.displayName![0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          user?.displayName ?? 'User Name',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_on_rounded,
              color: Colors.red.shade400,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              _countryName == "detecting"
                  ? l10n.detectingLocation
                  : (_countryName == "denied"
                      ? l10n.locationDenied
                      : (_countryName == "unavailable"
                          ? l10n.locationUnavailable
                          : _countryName)),
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubscriptionCard(
    BuildContext context,
    dynamic profile,
    AppLocalizations l10n,
  ) {
    final isPro = profile.isPremium;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPro
              ? [Colors.amber.shade700, Colors.orange.shade900]
              : [Colors.blue.shade700, Colors.indigo.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: (isPro ? Colors.orange : Colors.blue).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isPro ? Icons.verified_user_rounded : Icons.shield_rounded,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPro ? l10n.proProtection : l10n.freeProtection,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      isPro
                          ? l10n.lifetimeActive
                          : l10n.adSupportedDesc,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (isPro)
                const Icon(Icons.star_rounded, color: Colors.white, size: 24),
            ],
          ),
          const SizedBox(height: 20),
          _buildProtectionProgress(context, profile, l10n),
        ],
      ),
    );
  }

  Widget _buildProtectionProgress(
    BuildContext context,
    dynamic profile,
    AppLocalizations l10n,
  ) {
    final now = DateTime.now();
    final createdAt = profile.createdAt;
    final expiry = profile.protectionExpiry;
    final bool isTrial = now.difference(createdAt).inDays < 3;

    DateTime? activeExpiry;
    if (profile.isPremium)
      activeExpiry = expiry;
    else if (isTrial)
      activeExpiry = createdAt.add(const Duration(days: 3));
    else if (expiry != null && expiry.isAfter(now))
      activeExpiry = expiry;

    if (activeExpiry == null || activeExpiry.isBefore(now)) {
      return Text(
        l10n.protectionExpired,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    final diff = activeExpiry.difference(now);
    final days = diff.inDays;

    return Row(
      children: [
        const Icon(Icons.timer_outlined, color: Colors.white70, size: 16),
        const SizedBox(width: 8),
        Text(
          days >= 1
              ? l10n.daysRemaining(days)
              : "${diff.inHours}h ${diff.inMinutes % 60}m ${l10n.leftLabel}",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(
    BuildContext context,
    AppLocalizations l10n,
    AuthProvider auth,
    dynamic user,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.accountInfoSection,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        _infoTile(
          Icons.alternate_email_rounded,
          l10n.emailLabel,
          user?.email ?? 'Not available',
        ),
        _infoTile(
          Icons.phone_iphone_rounded,
          l10n.mobileLabel,
          auth.mobileNumber ?? 'Not provided',
        ),
        _infoTile(
          Icons.calendar_month_rounded,
          l10n.joinedOnLabel,
          user?.metadata.creationTime != null
              ? DateFormat('dd MMM yyyy').format(user!.metadata.creationTime!)
              : 'N/A',
        ),
      ],
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 24),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    AppLocalizations l10n,
    AuthProvider auth,
  ) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/edit-profile'),
          icon: const Icon(Icons.edit_rounded, size: 20),
          label: Text(l10n.editProfile.toUpperCase()),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 60),
            backgroundColor: AppTheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () => _showDeleteAccountDialog(context, auth),
          icon: const Icon(
            Icons.no_accounts_rounded,
            color: Colors.redAccent,
            size: 20,
          ),
          label: Text(l10n.deleteAccount.toUpperCase()),
          style: TextButton.styleFrom(
            minimumSize: const Size(double.infinity, 60),
            foregroundColor: Colors.redAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.redAccent.withOpacity(0.2)),
            ),
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog(
    BuildContext context,
    AuthProvider auth,
    AppLocalizations l10n,
  ) {
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
          ElevatedButton(
            onPressed: () {
              auth.signOut();
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/auth-wrapper', (route) => false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text(l10n.logout.toUpperCase()),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, AuthProvider auth) {
    final passwordController = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          l10n.deleteAccount,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.deleteAccountDesc),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(hintText: l10n.password),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await auth.deleteAccount(passwordController.text);
              if (success && context.mounted) {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/auth-wrapper', (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text(l10n.deleteAccountConfirm),
          ),
        ],
      ),
    );
  }
}
