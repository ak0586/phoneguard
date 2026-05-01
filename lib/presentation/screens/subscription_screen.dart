import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../providers/subscription_provider.dart';
import '../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final subProvider = Provider.of<SubscriptionProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final profile = authProvider.profile;
    final isPremium = profile?.isPremium ?? false;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, isPremium),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isPremium) _buildActiveSubscriptionCard(context, profile!) else _buildPremiumHeader(context),
                  const SizedBox(height: 32),
                  _buildFeaturesList(context),
                  const SizedBox(height: 32),
                  if (!isPremium) ...[
                    _buildPricingSection(context, subProvider),
                    const SizedBox(height: 24),
                    _buildRestoreButton(context, subProvider),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isPremium) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppTheme.primary,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          isPremium ? 'Premium Active' : 'Upgrade to Premium',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              right: -50,
              top: -20,
              child: Icon(
                Icons.stars_rounded,
                size: 250,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildActiveSubscriptionCard(BuildContext context, dynamic profile) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.verified_rounded, color: AppTheme.primary, size: 48),
          const SizedBox(height: 16),
          const Text(
            'You are a Premium Member',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Enjoy all advanced security features without limits.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          if (profile.protectionExpiry != null)
            Text(
              'Expires on: ${profile.protectionExpiry!.day}/${profile.protectionExpiry!.month}/${profile.protectionExpiry!.year}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
            ),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Protect Your Phone with\nUltimate Security',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
        const SizedBox(height: 12),
        Text(
          'Join thousands of users who trust PhoneGuard to recover their stolen devices.',
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildFeaturesList(BuildContext context) {
    final features = [
      {'icon': Icons.security_rounded, 'title': 'Permanent Protection', 'desc': 'Always-on remote security. No more watching ads to extend protection.'},
      {'icon': Icons.camera_front_rounded, 'title': 'Intrusion Detection', 'desc': 'Unlock silent selfie capture when someone tries to unlock your phone.'},
      {'icon': Icons.ads_click_rounded, 'title': 'Ad-Free Experience', 'desc': 'Remove all banner and rewarded advertisements from the app.'},
      {'icon': Icons.history_rounded, 'title': 'Unlimited Logs', 'desc': 'Full history of all security incidents and location updates.'},
    ];

    return Column(
      children: features.map((f) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(f['icon'] as IconData, color: Colors.blue, size: 24),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(f['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(f['desc'] as String, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildPricingSection(BuildContext context, SubscriptionProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.products.isEmpty) {
      return Center(
        child: Text(
          provider.errorMessage ?? 'Products not available. Check your internet or Play Store account.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    return Column(
      children: provider.products.map((product) {
        final isYearly = product.id == SubscriptionProvider.yearlyId;
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isYearly ? AppTheme.primary : Colors.grey.shade300, width: isYearly ? 2 : 1),
          ),
          child: InkWell(
            onTap: () => provider.buySubscription(product),
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isYearly)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(8)),
                            child: const Text('BEST VALUE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        const SizedBox(height: 4),
                        Text(product.title.replaceAll('(PhoneGuard)', ''), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text(isYearly ? 'Billed annually' : 'Billed monthly', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text(
                    product.price,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.primary),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRestoreButton(BuildContext context, SubscriptionProvider provider) {
    return Center(
      child: TextButton(
        onPressed: () => provider.restorePurchases(),
        child: const Text('Restore Purchase', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
