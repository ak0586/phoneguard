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
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
        );

        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty && mounted) {
          final country = placemarks.first.country ?? "Unknown Country";
          final isoCode = placemarks.first.isoCountryCode;
          
          // Save to cache
          await prefs.setString('cached_country_name', country);
          if (isoCode != null) {
            await prefs.setString('cached_iso_country_code', isoCode);
          }
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
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                authProvider.mobileNumber ?? 'No Mobile Number',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16, 
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
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
                style: TextStyle(
                  fontSize: 14, 
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 16),
              if (profile != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      profile.isPremium ? 'Premium Plan' : 'Free Plan',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF00E5FF),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (profile.isPremium) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.success.withValues(alpha: 0.5)),
                        ),
                        child: const Text(
                          'PRO',
                          style: TextStyle(
                            color: AppTheme.success,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Builder(
                  builder: (context) {
                    final now = DateTime.now();
                    final createdAt = profile.createdAt;
                    final expiry = profile.protectionExpiry;
                    final bool isTrial = now.difference(createdAt).inDays < 3;
                    
                    DateTime? activeExpiry;
                    if (profile.isPremium) {
                      activeExpiry = expiry;
                    } else if (isTrial) {
                      activeExpiry = createdAt.add(const Duration(days: 3));
                    } else if (expiry != null && expiry.isAfter(now)) {
                      activeExpiry = expiry;
                    }

                    if (activeExpiry == null) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text(
                          "Protection Disabled",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.redAccent),
                        ),
                      );
                    }

                    final diff = activeExpiry.difference(now);
                    if (diff.isNegative) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text(
                          "Protection Expired",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.redAccent),
                        ),
                      );
                    }

                    String timeStr = "";
                    Color statusColor = Colors.orange;

                    final days = diff.inDays;
                    if (profile.isPremium) {
                      statusColor = AppTheme.success;
                      if (profile.subscriptionType == 'yearly') {
                        if (days > 30) {
                          final months = (days / 30).floor();
                          timeStr = "$months month${months > 1 ? 's' : ''} remaining";
                        } else if (days >= 1) {
                          timeStr = "$days day${days > 1 ? 's' : ''} remaining";
                        } else {
                          timeStr = "${diff.inHours}h ${diff.inMinutes % 60}m remaining";
                        }
                      } else { // monthly
                        if (days >= 1) {
                          timeStr = "$days day${days > 1 ? 's' : ''} remaining";
                        } else {
                          timeStr = "${diff.inHours}h ${diff.inMinutes % 60}m remaining";
                        }
                      }
                    } else {
                      // Free tier
                      if (isTrial) {
                        statusColor = const Color(0xFF00E5FF);
                        timeStr = "Trial: $days days remaining";
                      } else {
                        statusColor = Colors.orange;
                        if (days >= 30) {
                          final months = (days / 30).floor();
                          timeStr = "$months month${months > 1 ? 's' : ''} remaining";
                        } else if (days >= 1) {
                          timeStr = "$days day${days > 1 ? 's' : ''} remaining";
                        } else {
                          timeStr = "${diff.inHours}h ${diff.inMinutes % 60}m remaining";
                        }
                      }
                    }

                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        timeStr,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }
                ),
              ],
              if (lastSeenStr != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerColor),
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
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lastSeenStr,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), 
                          fontSize: 12,
                        ),
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
                icon: const Icon(Icons.edit),
                label: const Text('EDIT PROFILE'),
              ),
              const SizedBox(height: 16),
              // Logout Button
              ElevatedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(
                        'Logout',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      content: Text(
                        'Are you sure you want to logout?',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('LOGOUT'),
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
                label: const Text('LOGOUT'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
                  foregroundColor: Colors.white,
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
