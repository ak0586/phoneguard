import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../providers/subscription_provider.dart';
import '../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import 'package:lost_phone_finder/l10n/app_localizations.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final subProvider = Provider.of<SubscriptionProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final profile = authProvider.profile;
    final isPremium = profile?.isPremium ?? false;
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF8F9FE),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context, isPremium, l10n),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isPremium)
                    _buildActiveSubscriptionCard(context, profile!, l10n)
                  else ...[
                    _buildPremiumHeader(context, l10n),
                    const SizedBox(height: 40),
                    _buildFeaturesList(context, l10n),
                    const SizedBox(height: 48),
                    _buildPricingSection(context, subProvider, l10n),
                    const SizedBox(height: 24),
                    _buildRestoreButton(context, subProvider, l10n),
                  ],
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isPremium, AppLocalizations l10n) {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      expandedHeight: 180,
      pinned: true,
      backgroundColor: AppTheme.primary,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.black12,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          isPremium ? l10n.premiumActive : l10n.upgradePremium,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.white,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary, Color(0xFFD32F2F)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            // Abstract shapes for "Premium" look
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              left: -50,
              bottom: -50,
              child: Icon(
                Icons.security_rounded,
                size: 200,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSubscriptionCard(
    BuildContext context,
    dynamic profile,
    AppLocalizations l10n,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1E26), Color(0xFF2D2D3A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_user_rounded, color: AppTheme.success, size: 48),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.premiumMemberTitle,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.premiumMemberDesc,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 24),
          if (profile.protectionExpiry != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${l10n.expiresOn}: ${profile.protectionExpiry!.day} ${_getMonthName(profile.protectionExpiry!.month)} ${profile.protectionExpiry!.year}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.success,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.protectUltimateTitle,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
            color: Theme.of(context).colorScheme.onSurface,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 4,
          width: 60,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesList(BuildContext context, AppLocalizations l10n) {
    final features = [
      {
        'icon': Icons.ads_click_rounded,
        'title': l10n.adFreeTitle,
        'desc': l10n.adFreeDesc,
        'color': Colors.orange,
      },
      {
        'icon': Icons.security_rounded,
        'title': l10n.permanentProtectionTitle,
        'desc': l10n.permanentProtectionDesc,
        'color': Colors.blue,
      },
      {
        'icon': Icons.camera_front_rounded,
        'title': l10n.intrusionDetectionTitle,
        'desc': l10n.intrusionDetectionDesc,
        'color': Colors.purple,
      },
      {
        'icon': Icons.history_rounded,
        'title': l10n.unlimitedLogsTitle,
        'desc': l10n.unlimitedLogsDesc,
        'color': Colors.teal,
      },
    ];

    return Column(
      children: features.map((f) => _FeatureRow(
        icon: f['icon'] as IconData,
        title: f['title'] as String,
        desc: f['desc'] as String,
        color: f['color'] as Color,
      )).toList(),
    );
  }

  Widget _buildPricingSection(
    BuildContext context,
    SubscriptionProvider provider,
    AppLocalizations l10n,
  ) {
    if (provider.isLoading) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(40.0),
        child: CircularProgressIndicator(color: AppTheme.primary),
      ));
    }

    if (provider.products.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.error.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.error.withOpacity(0.2)),
          ),
          child: Text(
            provider.errorMessage ?? l10n.productsNotAvailable,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.error, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    // Sort products so yearly is first or has special treatment
    final sortedProducts = provider.products.toList();
    sortedProducts.sort((a, b) => b.id.contains('yearly') ? 1 : -1);

    return Column(
      children: sortedProducts.map((product) {
        final isYearly = product.id.contains('yearly');
        return _SubscriptionOptionCard(
          product: product,
          isYearly: isYearly,
          onTap: () => provider.buySubscription(product),
          l10n: l10n,
        );
      }).toList(),
    );
  }

  Widget _buildRestoreButton(
    BuildContext context,
    SubscriptionProvider provider,
    AppLocalizations l10n,
  ) {
    return Center(
      child: TextButton.icon(
        onPressed: () => provider.restorePurchases(),
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: Text(
          l10n.restorePurchase,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        ),
        style: TextButton.styleFrom(foregroundColor: Colors.grey),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final Color color;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.desc,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionOptionCard extends StatelessWidget {
  final ProductDetails product;
  final bool isYearly;
  final VoidCallback onTap;
  final AppLocalizations l10n;

  const _SubscriptionOptionCard({
    required this.product,
    required this.isYearly,
    required this.onTap,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Clean up the title - remove everything in parentheses
    String cleanTitle = product.title.split('(').first.trim();
    if (cleanTitle.toLowerCase().contains('monthly')) {
      cleanTitle = 'Monthly Plan';
    } else if (cleanTitle.toLowerCase().contains('yearly')) {
      cleanTitle = 'Yearly Plan';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: isYearly ? [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ] : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isYearly 
                  ? (isDark ? const Color(0xFF1A1A23) : Colors.white)
                  : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isYearly ? AppTheme.primary : (isDark ? Colors.white10 : Colors.black12),
                width: isYearly ? 2.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isYearly) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                l10n.bestValue.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.success,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '2 MONTHS FREE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      Text(
                        cleanTitle,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: isYearly ? AppTheme.primary : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isYearly ? l10n.billedAnnually : l10n.billedMonthly,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      product.price,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: isYearly ? AppTheme.primary : Theme.of(context).colorScheme.onSurface,
                        letterSpacing: -1,
                      ),
                    ),
                    if (isYearly)
                      Text(
                        '~₹54/month', // Optional: Show monthly breakdown for yearly
                        style: TextStyle(
                          color: AppTheme.success.withOpacity(0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
