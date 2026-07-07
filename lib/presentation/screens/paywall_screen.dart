import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';
import '../../core/theme/app_theme.dart';
import 'package:lost_phone_finder/l10n/app_localizations.dart';

class PaywallScreen extends StatelessWidget {
  final bool showCloseButton;

  const PaywallScreen({super.key, this.showCloseButton = true});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final subProvider = Provider.of<SubscriptionProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final profile = authProvider.profile;
    final isPremium = profile?.isPremium ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF1A1A2E),
                    Color(0xFF16213E),
                    Color(0xFF0F3460),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          // Abstract Shapes
          Positioned(
            top: -100,
            right: -100,
            child: CircleAvatar(
              radius: 150,
              backgroundColor: AppTheme.primary.withOpacity(0.05),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        if (isPremium)
                          _buildActiveStatus(
                            context,
                            authProvider,
                            subProvider,
                            l10n,
                          )
                        else
                          _buildHeroSection(l10n),

                        const SizedBox(height: 40),
                        _buildFeaturesGrid(l10n),

                        if (!isPremium) ...[
                          const SizedBox(height: 40),
                          _buildPricingCards(context, subProvider, l10n),
                          const SizedBox(height: 30),
                          _buildSocialProof(l10n),
                        ],
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
                if (!isPremium)
                  _buildStickyFooter(
                    context,
                    subProvider,
                    l10n,
                    showMaybeLater: showCloseButton,
                  ),
              ],
            ),
          ),

          // Close Button
          if (showCloseButton)
            Positioned(
              top: 50,
              right: 20,
              child: IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white54,
                  size: 30,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActiveStatus(
    BuildContext context,
    AuthProvider auth,
    SubscriptionProvider sub,
    AppLocalizations l10n,
  ) {
    final profile = auth.profile;
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppTheme.success.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.verified_user_rounded,
                color: AppTheme.success,
                size: 64,
              ),
              const SizedBox(height: 24),
              Text(
                l10n.premiumActive.toUpperCase(),
                style: const TextStyle(
                  color: AppTheme.success,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.premiumMemberTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.premiumMemberDesc,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
              if (profile?.protectionExpiry != null) ...[
                const SizedBox(height: 32),
                const Divider(color: Colors.white10),
                const SizedBox(height: 24),
                Text(
                  l10n.expiresOn.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(profile!.protectionExpiry!),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/logo.png', height: 40),
          const SizedBox(width: 12),
          const Text(
            'PhoneGuard',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(AppLocalizations l10n) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.amber.withOpacity(0.3)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded, color: Colors.amber, size: 16),
              SizedBox(width: 8),
              Text(
                'LIFETIME PROTECTION OFFER',
                style: TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Total Security,\nOne-Time Payment',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.w900,
            height: 1.1,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Join 50,000+ users who protected their phones forever. No more ads, no more recurring bills.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 15,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesGrid(AppLocalizations l10n) {
    final features = [
      {
        'icon': Icons.ads_click_rounded,
        'label': 'Ad-Free Protection',
        'desc': 'Zero intrusive ads to distract your security.',
        'color': Colors.orange,
      },
      {
        'icon': Icons.camera_front_rounded,
        'label': 'Thief Selfie',
        'desc': 'Silently capture intruders who try to unlock your phone.',
        'color': Colors.purple,
      },
      {
        'icon': Icons.dashboard_customize_rounded,
        'label': 'Web Dashboard',
        'desc': 'Track and control your phone from any web browser.',
        'color': Colors.blue,
      },
      {
        'icon': Icons.sim_card_alert_rounded,
        'label': 'SIM Swap Alerts',
        'desc': 'Get notified immediately if your SIM card is changed.',
        'color': Colors.redAccent,
      },
      {
        'icon': Icons.settings_remote_rounded,
        'label': 'Remote SMS Control',
        'desc': 'Control your phone via SMS commands from any other device.',
        'color': Colors.green,
      },
      {
        'icon': Icons.security_rounded,
        'label': 'Uninstall Protection',
        'desc': 'Prevents intruders from deleting the app to bypass security.',
        'color': Colors.teal,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PREMIUM BENEFITS',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 20),
        ...features
            .map(
              (f) => _FeatureTile(
                icon: f['icon'] as IconData,
                label: f['label'] as String,
                desc: f['desc'] as String,
                color: f['color'] as Color,
              ),
            )
            .toList(),
      ],
    );
  }
}

class _FeatureTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final String desc;
  final Color color;

  const _FeatureTile({
    required this.icon,
    required this.label,
    required this.desc,
    required this.color,
  });

  @override
  State<_FeatureTile> createState() => _FeatureTileState();
}

class _FeatureTileState extends State<_FeatureTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(_isExpanded ? 0.08 : 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(_isExpanded ? 0.15 : 0.05),
        ),
      ),
      child: InkWell(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: Colors.white24,
                  ),
                ],
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox(width: double.infinity),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 12, left: 56),
                  child: Text(
                    widget.desc,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
                crossFadeState: _isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildPricingCards(
  BuildContext context,
  SubscriptionProvider provider,
  AppLocalizations l10n,
) {
  if (provider.isLoading)
    return const Center(child: CircularProgressIndicator());
  if (provider.products.isEmpty) {
    return Center(
      child: Text(
        l10n.productsNotAvailable,
        style: const TextStyle(color: Colors.white70),
      ),
    );
  }

  // Find products
  Map<String, dynamic>? monthly;
  Map<String, dynamic>? yearly;
  Map<String, dynamic>? lifetime;

  for (var p in provider.products) {
    if (p['id'].contains('monthly'))
      monthly = p;
    else if (p['id'].contains('yearly'))
      yearly = p;
    else if (p['id'].contains('lifetime'))
      lifetime = p;
  }

  // Fallbacks if some aren't found
  lifetime ??= provider.products.first;

  return Column(
    children: [
      // Lifetime Card (Featured)
      _planCard(
        context: context,
        product: lifetime,
        label: 'LIFETIME ACCESS',
        price: lifetime['price'],
        description: 'One-time payment. Best Value.',
        isFeatured: true,
        onBuy: () => provider.buySubscription(lifetime!['id']),
        l10n: l10n,
      ),
      const SizedBox(height: 16),

      Row(
        children: [
          if (yearly != null)
            Expanded(
              child: _planCard(
                context: context,
                product: yearly,
                label: 'YEARLY',
                price: yearly['price'],
                description: 'Full protection',
                isFeatured: false,
                onBuy: () => provider.buySubscription(yearly!['id']),
                l10n: l10n,
              ),
            ),
          if (yearly != null && monthly != null) const SizedBox(width: 12),
          if (monthly != null)
            Expanded(
              child: _planCard(
                context: context,
                product: monthly,
                label: 'MONTHLY',
                price: monthly['price'],
                description: 'Flexible',
                isFeatured: false,
                onBuy: () => provider.buySubscription(monthly!['id']),
                l10n: l10n,
              ),
            ),
        ],
      ),
    ],
  );
}

Widget _planCard({
  required BuildContext context,
  required Map<String, dynamic> product,
  required String label,
  required String price,
  required String description,
  required bool isFeatured,
  required VoidCallback onBuy,
  required AppLocalizations l10n,
}) {
  return Container(
    padding: EdgeInsets.all(isFeatured ? 24 : 16),
    decoration: BoxDecoration(
      gradient: isFeatured
          ? LinearGradient(
              colors: [AppTheme.primary, Colors.indigo.shade900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : null,
      color: isFeatured ? null : Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: isFeatured
            ? Colors.white.withOpacity(0.2)
            : Colors.white.withOpacity(0.1),
      ),
      boxShadow: isFeatured
          ? [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ]
          : [],
    ),
    child: Column(
      crossAxisAlignment: isFeatured
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        if (isFeatured)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'BEST VALUE',
              style: TextStyle(
                color: Colors.black,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        Text(
          label,
          style: TextStyle(
            color: isFeatured ? Colors.white70 : Colors.grey,
            fontWeight: FontWeight.w900,
            fontSize: isFeatured ? 12 : 10,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          price,
          style: TextStyle(
            color: Colors.white,
            fontSize: isFeatured ? 36 : 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (isFeatured)
          const Text(
            'Save 80% compared to monthly',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: onBuy,
          style: ElevatedButton.styleFrom(
            backgroundColor: isFeatured ? Colors.white : AppTheme.primary,
            foregroundColor: isFeatured ? AppTheme.primary : Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: Text(
            isFeatured ? 'SELECT LIFETIME' : 'SELECT',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
          ),
        ),
      ],
    ),
  );
}

Widget _buildSocialProof(AppLocalizations l10n) {
  return Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          5,
          (index) =>
              const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
        ),
      ),
      const SizedBox(height: 12),
      const Text(
        '"Saved my phone from a thief in Delhi. Best investment ever!"',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white54,
          fontStyle: FontStyle.italic,
          fontSize: 13,
        ),
      ),
      const SizedBox(height: 4),
      const Text(
        '- Rahul S.',
        style: TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    ],
  );
}

Widget _buildStickyFooter(
  BuildContext context,
  SubscriptionProvider provider,
  AppLocalizations l10n, {
  required bool showMaybeLater,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
    decoration: BoxDecoration(
      color: const Color(0xFF1E1E2E),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: showMaybeLater
          ? MainAxisAlignment.spaceBetween
          : MainAxisAlignment.center,
      children: [
        if (showMaybeLater)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.later ?? 'Maybe later',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
        TextButton(
          onPressed: () async {
            final scaffoldMessenger = ScaffoldMessenger.of(context);
            final restored = await provider.restorePurchases();
            if (!restored) {
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Text('No previous purchase found for this account.'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            } else {
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Text('Your premium status has been restored!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
          child: Text(
            l10n.restorePurchase,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}
