import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dashboard_screen.dart';
import 'activity_logs_screen.dart';
import 'subscription_screen.dart';
import 'command_guide_screen.dart';
import '../widgets/app_drawer.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = '${info.version}+${info.buildNumber}';
      });
    }
  }

  final List<Widget> _screens = [
    const DashboardScreen(),
    const SubscriptionScreen(),
    const CommandGuideScreen(),
    const ActivityLogsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final isHi = context.watch<AppProvider>().settings.languageCode == 'hi';

    return Scaffold(
      drawer: AppDrawer(
        appVersion: _appVersion,
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      extendBody: true,
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 70,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 2),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withOpacity(0.8)
                      : Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.12)
                        : Colors.black.withOpacity(0.08),
                    width: 1,
                  ),
                ),
                child: BottomNavigationBar(
                  currentIndex: _currentIndex,
                  onTap: (index) => setState(() => _currentIndex = index),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  type: BottomNavigationBarType.fixed,
                  selectedItemColor: primaryColor,
                  unselectedItemColor: isDark ? const Color(0xFFCCCCCC) : Colors.black54,
                  selectedFontSize: 12,
                  unselectedFontSize: 11,
                  showUnselectedLabels: true,
                  selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5),
                  iconSize: 22,
                  items: [
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.home_rounded),
                      activeIcon: _GlowIcon(
                        icon: Icons.home_rounded,
                        color: primaryColor,
                      ),
                      label: isHi ? 'होम' : 'Home',
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.stars_rounded),
                      activeIcon: _GlowIcon(
                        icon: Icons.stars_rounded,
                        color: Colors.amber,
                      ),
                      label: isHi ? 'प्रीमियम' : 'Premium',
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.menu_book_rounded),
                      activeIcon: _GlowIcon(
                        icon: Icons.menu_book_rounded,
                        color: primaryColor,
                      ),
                      label: isHi ? 'गाइड' : 'Guide',
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.receipt_long_rounded),
                      activeIcon: _GlowIcon(
                        icon: Icons.receipt_long_rounded,
                        color: primaryColor,
                      ),
                      label: isHi ? 'लॉग्स' : 'Logs',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlowIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _GlowIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }
}
