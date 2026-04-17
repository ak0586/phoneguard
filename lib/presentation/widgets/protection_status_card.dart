import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import '../../data/datasources/ad_service.dart';
import '../../core/theme/app_theme.dart';

class ProtectionStatusCard extends StatelessWidget {
  const ProtectionStatusCard({super.key});

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
        
        bool isProtectionFunctional = isPremium || isTrial || (expiry != null && expiry.isAfter(DateTime.now()));
        bool isActuallyActive = isBasicActive && isProtectionFunctional;

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
          statusSubtitle = 'All features unlocked permanently';
        } else if (isActuallyActive) {
          statusColor = isTrial ? const Color(0xFF00E5FF) : AppTheme.success;
          statusIcon = Icons.shield_rounded;
          statusTitle = 'Protection Active';
          statusSubtitle = isTrial 
            ? '3-day free trial active' 
            : 'Expires in: ${expiry!.difference(DateTime.now()).inHours}h ${expiry.difference(DateTime.now()).inMinutes % 60}m';
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
                color: isDarkMode ? statusColor.withValues(alpha: 0.1) : Colors.white,
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
                      color: statusColor.withValues(alpha: isDarkMode ? 0.2 : 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          statusTitle,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          statusSubtitle,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                            fontSize: 13,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (isBasicActive && !isPremium) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Show Loading Snackbar
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Loading Ad...'), duration: Duration(seconds: 1)),
                    );
                    
                    adService.loadRewardedAd(
                      onAdLoaded: (ad) {
                        adService.showRewardedAd(
                          ad: ad,
                          onUserEarnedReward: (ad, reward) {
                            authProvider.extendProtection(12);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('🎉 Protection extended by 12 hours!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          onAdDismissed: () {},
                        );
                      },
                      onAdFailedToLoad: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ad failed to load. Try again later.')),
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.play_circle_fill),
                  label: Text(isActuallyActive ? 'EXTEND PROTECTION (12h)' : 'REACTIVATE PROTECTION (12h)'),
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
            ],
          ],
        );
      },
    );
  }
}
