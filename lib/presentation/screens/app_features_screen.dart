import 'package:flutter/material.dart';
import 'package:lost_phone_finder/core/theme/app_theme.dart';
import 'package:lost_phone_finder/l10n/app_localizations.dart';

class AppFeaturesScreen extends StatelessWidget {
  const AppFeaturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final features = [
      {
        'icon': Icons.camera_front_rounded,
        'title': l10n.intrusionDetectionTitle,
        'desc': l10n.intrusionDetectionDesc,
        'color': Colors.purple,
        'tag': 'FREE',
      },
      {
        'icon': Icons.sim_card_rounded,
        'title': 'SIM Change Detection',
        'desc':
            'Instantly notifies your trusted numbers if your SIM card is swapped by an intruder.',
        'color': Colors.orange,
        'tag': 'FREE',
      },
      {
        'icon': Icons.location_on_rounded,
        'title': 'Remote SMS Control',
        'desc':
            'Fetch location, trigger siren, or lock your phone by sending secret SMS commands.',
        'color': Colors.blue,
        'tag': 'FREE',
      },
      {
        'icon': Icons.dashboard_customize_rounded,
        'title': l10n.webDashboard,
        'desc':
            'A powerful online portal to track and manage your phone from any browser.',
        'color': Colors.indigo,
        'tag': 'FREE',
      },
      {
        'icon': Icons.security_rounded,
        'title': 'Uninstall Protection',
        'desc':
            'Prevents intruders from uninstalling the app by using Device Admin lock.',
        'color': Colors.green,
        'tag': 'FREE',
      },
      {
        'icon': Icons.ads_click_rounded,
        'title': l10n.adFreeTitle,
        'desc': l10n.adFreeDesc,
        'color': Colors.red,
        'tag': 'PRO',
      },
    ];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'App Features',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  letterSpacing: -0.5,
                ),
              ),
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primary, Colors.blue.shade900],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Opacity(
                  opacity: 0.1,
                  child: Icon(
                    Icons.security_rounded,
                    size: 200,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Why PhoneGuard?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Everything you need to recover your stolen phone and protect your private data.',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 32),
                  ...features
                      .map((f) => _buildFeatureCard(context, f, isDark))
                      .toList(),
                  const SizedBox(height: 40),
                  _buildGetPremiumCard(context, l10n),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    Map<String, dynamic> f,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (f['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                f['icon'] as IconData,
                color: f['color'] as Color,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          f['title'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (f['tag'] == 'PRO' ? Colors.amber : Colors.green)
                                  .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          f['tag'] as String,
                          style: TextStyle(
                            color: f['tag'] == 'PRO'
                                ? Colors.amber.shade800
                                : Colors.green.shade800,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    f['desc'] as String,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGetPremiumCard(BuildContext context, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade700, Colors.orange.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.star_rounded, color: Colors.white, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Unlock Ultimate Protection',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Go Pro to get the Web Dashboard, Thief Selfie, and more.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/subscription'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.orange.shade900,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text(
              'UPGRADE TO PRO',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}
