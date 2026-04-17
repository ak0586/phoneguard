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

      // Check if 24 hours (86,400,000 ms) have passed
      if (cachedCountry != null && (currentTime - lastFetchTime) < 86400000) {
        if (mounted) {
          setState(() {
            _countryName = cachedCountry;
          });
        }
        return;
      }

      final status = await Permission.locationWhenInUse.request();
      if (status.isGranted) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        );

        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty && mounted) {
          final country = placemarks.first.country ?? "Unknown Country";
          
          // Save to cache
          await prefs.setString('cached_country_name', country);
          await prefs.setInt('last_country_fetch_time', currentTime);

          setState(() {
            _countryName = country;
          });
        }
      } else {
        if (mounted) {
          setState(() => _countryName = cachedCountry ?? "Location Denied");
        }
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
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              // Avatar
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.4),
                        blurRadius: 15,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      user?.displayName?.isNotEmpty == true
                          ? user!.displayName![0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // User Info
              Text(
                user?.displayName ?? 'No Name',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                authProvider.mobileNumber ?? 'No Mobile Number',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.location_on,
                    color: Colors.redAccent,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _countryName,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                user?.email ?? 'Unknown User',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              if (profile?.subscriptionType != null)
                Text(
                  profile!.isPremium ? 'Premium Plan' : 'Free Plan',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF00E5FF),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (profile != null && !profile.isPremium)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    profile.protectionExpiry != null && profile.protectionExpiry!.isAfter(DateTime.now())
                        ? "Protection expires in: ${profile.protectionExpiry!.difference(DateTime.now()).inHours}h"
                        : "Protection Expired",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: profile.protectionExpiry != null && profile.protectionExpiry!.isAfter(DateTime.now())
                          ? Colors.orange
                          : Colors.redAccent,
                    ),
                  ),
                ),
              if (lastSeenStr != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.gps_fixed, color: Color(0xFF00E5FF), size: 16),
                          SizedBox(width: 8),
                          Text(
                            'EXACT LAST LOCATION',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${profile?.lastLatitude?.toStringAsFixed(6)}, ${profile?.lastLongitude?.toStringAsFixed(6)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lastSeenStr,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              // Edit Profile Button
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/edit-profile');
                },
                icon: const Icon(Icons.edit, color: Color(0xFF00E5FF)),
                label: const Text(
                  'EDIT PROFILE',
                  style: TextStyle(
                    color: Color(0xFF00E5FF),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF00E5FF)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Logout Button
              ElevatedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF1E1E1E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      content: const Text(
                        'Are you sure you want to logout?',
                        style: TextStyle(color: Colors.grey),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text(
                            'CANCEL',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent.withValues(
                              alpha: 0.9,
                            ),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'LOGOUT',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && context.mounted) {
                    await context.read<AuthProvider>().signOut();
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text(
                  'LOGOUT',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1.2,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
