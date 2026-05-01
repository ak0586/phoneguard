import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _countryName = "Detecting Location...";

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
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
        );
        List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty && mounted) {
          final country = placemarks.first.country ?? "Unknown Country";
          await prefs.setString('cached_country_name', country);
          await prefs.setInt('last_country_fetch_time', currentTime);
          setState(() => _countryName = country);
        }
      } else if (mounted) {
        setState(() => _countryName = cachedCountry ?? "Location Denied");
      }
    } catch (e) {
      if (mounted) {
        final prefs = await SharedPreferences.getInstance();
        setState(() => _countryName = prefs.getString('cached_country_name') ?? "Location Unavailable");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final profile = authProvider.profile;

    String? lastSeenStr;
    if (profile?.lastLatitude != null && profile?.lastLongitude != null) {
      if (profile!.locationUpdatedAt != null) {
        lastSeenStr = "Last Seen: ${DateFormat('dd MMM, hh:mm a').format(profile.locationUpdatedAt!)}";
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                      child: const Text('LOGOUT'),
                    ),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                await authProvider.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                }
              }
            },
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.primaryGradient,
                    boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.4), blurRadius: 15, spreadRadius: 5)],
                  ),
                  child: Center(
                    child: Text(
                      user?.displayName?.isNotEmpty == true ? user!.displayName![0].toUpperCase() : 'U',
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                user?.displayName ?? 'No Name',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
              ),
              const SizedBox(height: 8),
              Text(
                authProvider.mobileNumber ?? 'No Mobile Number',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on, color: Colors.redAccent, size: 16),
                  const SizedBox(width: 4),
                  Text(_countryName, style: const TextStyle(fontSize: 14, color: Colors.redAccent, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                user?.email ?? 'Unknown User',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
              ),
              const SizedBox(height: 16),
              if (profile != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      profile.isPremium ? 'Premium Plan' : 'Free Plan',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Color(0xFF00E5FF), fontWeight: FontWeight.bold),
                    ),
                    if (profile.isPremium) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.2), borderRadius: BorderRadius.circular(6), border: Border.all(color: AppTheme.success.withOpacity(0.5))),
                        child: const Text('PRO', style: TextStyle(color: AppTheme.success, fontSize: 10, fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ],
                ),
                _buildProtectionStatus(profile),
              ],
              if (lastSeenStr != null) ...[
                const SizedBox(height: 16),
                _buildLocationCard(context, profile, lastSeenStr),
              ],
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/edit-profile'),
                icon: const Icon(Icons.edit),
                label: const Text('EDIT PROFILE'),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => _showDeleteAccountDialog(context, authProvider),
                icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                label: const Text('DELETE ACCOUNT', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.redAccent.withOpacity(0.2))),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProtectionStatus(dynamic profile) {
    final now = DateTime.now();
    final createdAt = profile.createdAt;
    final expiry = profile.protectionExpiry;
    final bool isTrial = now.difference(createdAt).inDays < 3;
    DateTime? activeExpiry;
    if (profile.isPremium) activeExpiry = expiry;
    else if (isTrial) activeExpiry = createdAt.add(const Duration(days: 3));
    else if (expiry != null && expiry.isAfter(now)) activeExpiry = expiry;

    if (activeExpiry == null) return const Padding(padding: EdgeInsets.only(top: 8.0), child: Text("Protection Disabled", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.redAccent)));
    
    final diff = activeExpiry.difference(now);
    if (diff.isNegative) return const Padding(padding: EdgeInsets.only(top: 8.0), child: Text("Protection Expired", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.redAccent)));

    String timeStr = "";
    Color statusColor = Colors.orange;
    final days = diff.inDays;
    if (profile.isPremium) {
      statusColor = AppTheme.success;
      timeStr = days >= 1 ? "$days days remaining" : "${diff.inHours}h ${diff.inMinutes % 60}m remaining";
    } else {
      statusColor = isTrial ? const Color(0xFF00E5FF) : Colors.orange;
      timeStr = isTrial ? "Trial: $days days remaining" : "$days days remaining";
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(timeStr, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildLocationCard(BuildContext context, dynamic profile, String lastSeenStr) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).dividerColor)),
      child: Column(
        children: [
          const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.gps_fixed, color: Color(0xFF00E5FF), size: 16), SizedBox(width: 8), Text('EXACT LAST LOCATION', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1))]),
          const SizedBox(height: 8),
          Text('${profile?.lastLatitude?.toStringAsFixed(6)}, ${profile?.lastLongitude?.toStringAsFixed(6)}', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontFamily: 'monospace', fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(lastSeenStr, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12)),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, AuthProvider auth) {
    final passwordController = TextEditingController();
    bool isObscured = true;

    showDialog(
      context: context,
      barrierDismissible: !auth.isLoading,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              SizedBox(width: 12),
              Text('Delete Account', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('This action is permanent and will delete all your data including recovery settings and logs.'),
              const SizedBox(height: 20),
              const Text('Please enter your password to confirm:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                obscureText: isObscured,
                decoration: InputDecoration(
                  hintText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(isObscured ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setDialogState(() => isObscured = !isObscured),
                  ),
                ),
              ),
              if (auth.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(auth.errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: auth.isLoading ? null : () => Navigator.pop(context),
              child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: auth.isLoading ? null : () async {
                if (passwordController.text.isEmpty) return;
                final success = await auth.deleteAccount(passwordController.text);
                if (success && context.mounted) {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                } else {
                  setDialogState(() {}); // Refresh for error message
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
              child: auth.isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('DELETE'),
            ),
          ],
        ),
      ),
    );
  }
}
