import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import '../../data/datasources/ad_service.dart';
import '../../core/theme/app_theme.dart';

class ProtectionStatusCard extends StatefulWidget {
  const ProtectionStatusCard({super.key});

  @override
  State<ProtectionStatusCard> createState() => _ProtectionStatusCardState();
}

class _ProtectionStatusCardState extends State<ProtectionStatusCard> {
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    // Tick every second to update the countdown display
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatCountdown(Duration diff) {
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;

    if (days >= 1) {
      return "$days day${days > 1 ? 's' : ''} remaining";
    } else {
      // Less than 24 hours — show live HH:MM:SS countdown
      final h = hours.toString().padLeft(2, '0');
      final m = minutes.toString().padLeft(2, '0');
      final s = seconds.toString().padLeft(2, '0');
      return "$h:$m:$s remaining";
    }
  }

  @override
  Widget build(BuildContext context) {
    final adService = Provider.of<AdService>(context, listen: false);

    return Consumer2<AppProvider, AuthProvider>(
      builder: (context, appProvider, authProvider, _) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final profile = authProvider.profile;

        bool isBasicActive = appProvider.isProtectionActive;
        bool isPremium = profile?.isPremium ?? false;

        DateTime? expiry = profile?.protectionExpiry;
        DateTime createdAt = profile?.createdAt ?? DateTime.now();
        bool isTrial = DateTime.now().difference(createdAt).inDays < 3;

        bool isProtectionFunctional =
            isPremium || isTrial || (expiry != null && expiry.isAfter(DateTime.now()));
        bool isActuallyActive = isBasicActive && isProtectionFunctional;

        String getRemainingTimeString() {
          final now = DateTime.now();
          DateTime? activeExpiry;

          if (isPremium) {
            activeExpiry = expiry;
          } else if (isTrial) {
            activeExpiry = createdAt.add(const Duration(days: 3));
          } else if (expiry != null && expiry.isAfter(now)) {
            activeExpiry = expiry;
          }

          if (activeExpiry == null || activeExpiry.isBefore(now)) return '';

          final diff = activeExpiry.difference(now);

          if (isPremium) {
            if (profile?.subscriptionType == 'yearly') {
              return _formatCountdown(diff);
            } else {
              return _formatCountdown(diff);
            }
          } else {
            return _formatCountdown(diff);
          }
        }

        Color statusColor = AppTheme.error;
        IconData statusIcon = Icons.shield_outlined;
        String statusTitle = 'Protection Disabled';
        String statusSubtitle = 'Add a trusted number to enable protection';

        if (!isBasicActive) {
          statusColor = AppTheme.error;
          statusIcon = Icons.shield_outlined;
          statusTitle = 'Setup Required';
          statusSubtitle = 'Add a trusted number to enable protection';
        } else if (isPremium) {
          statusColor = AppTheme.success;
          statusIcon = Icons.verified_user_rounded;
          statusTitle = 'Premium Protection';
          statusSubtitle = getRemainingTimeString();
        } else if (isActuallyActive) {
          statusColor = isTrial ? const Color(0xFF00E5FF) : AppTheme.success;
          statusIcon = Icons.shield_rounded;
          statusTitle = 'Protection Active';
          statusSubtitle = isTrial
              ? '3-day free trial active • ${getRemainingTimeString()}'
              : getRemainingTimeString();
        } else {
          statusColor = Colors.orange;
          statusIcon = Icons.gpp_maybe_rounded;
          statusTitle = 'Protection Expired';
          statusSubtitle = 'Watch an ad to re-enable remote protection';
        }

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? statusColor.withOpacity(0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: statusColor.withValues(alpha: isDarkMode ? 0.3 : 0.2),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          statusColor.withValues(alpha: isDarkMode ? 0.2 : 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              statusTitle,
                              style: TextStyle(
                                color:
                                    Theme.of(context).colorScheme.onSurface,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            if (isPremium) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.success.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: AppTheme.success
                                          .withOpacity(0.5)),
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
                        const SizedBox(height: 4),
                        // Show countdown with monospace font when < 24h
                        Builder(builder: (_) {
                          final isLiveCountdown = statusSubtitle
                              .contains(RegExp(r'\d{2}:\d{2}:\d{2}'));
                          return Text(
                            statusSubtitle,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.7),
                              fontSize: isLiveCountdown ? 14 : 13,
                              fontWeight: isLiveCountdown
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                              fontFamily:
                                  isLiveCountdown ? 'monospace' : null,
                              height: 1.3,
                              letterSpacing: isLiveCountdown ? 1.0 : 0,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (isBasicActive && !isPremium) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (!isTrial)
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Loading Ad...'),
                                duration: Duration(seconds: 1)),
                          );

                          adService.loadRewardedAd(
                            onAdLoaded: (ad) {
                              adService.showRewardedAd(
                                ad: ad,
                                onUserEarnedReward: (ad, reward) {
                                  authProvider.extendProtection(8);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('🎉 Protection extended by 8 hours!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                },
                                onAdDismissed: () {},
                              );
                            },
                            onAdFailedToLoad: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Ad failed to load. Try again later.')),
                              );
                            },
                          );
                        },
                        icon: const Icon(Icons.play_circle_fill),
                        label: Text(isActuallyActive ? 'EXTEND' : 'REACTIVE'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00E5FF),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  if (!isTrial) const SizedBox(width: 12),
                  Expanded(
                    flex: 4,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/subscription'),
                      icon: const Icon(Icons.stars_rounded),
                      label: const Text('GO PREMIUM'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}
