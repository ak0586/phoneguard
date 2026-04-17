import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:lost_phone_finder/l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/theme/app_theme.dart';
import 'data/datasources/auth_service.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/register_screen.dart';
import 'presentation/screens/auth/forgot_password_screen.dart';
import 'presentation/screens/auth/email_verification_screen.dart';
import 'data/datasources/hive_data_source.dart';
import 'data/datasources/native_service.dart';
import 'data/datasources/permission_service.dart';
import 'data/repositories/app_repository_impl.dart';
import 'presentation/providers/app_provider.dart';
import 'presentation/screens/activity_logs_screen.dart';
import 'presentation/screens/command_guide_screen.dart';
import 'presentation/screens/faq_screen.dart';
import 'presentation/screens/dashboard_screen.dart';
import 'presentation/screens/default_actions_screen.dart';
import 'presentation/screens/privacy_policy_screen.dart';
import 'presentation/screens/profile_screen.dart';
import 'presentation/screens/edit_profile_screen.dart';
import 'presentation/screens/setup_screen.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/trusted_numbers_screen.dart';
import 'data/datasources/ad_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize SharedPreferences first
  final prefs = await SharedPreferences.getInstance();

  // Initialize Hive with prefs for background sync
  final hiveDataSource = await HiveDataSource.init(prefs);
  
  // Handle migration from SharedPreferences to Hive if needed
  await hiveDataSource.migrateIfNeeded();

  final appRepository = AppRepositoryImpl(hiveDataSource);
  final nativeService = NativeService();
  final permissionService = PermissionService();
  final authService = AuthService();
  final adService = AdService();

  // Initialize Ads
  await adService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) {
            final authProvider = AuthProvider(authService);
            return authProvider;
          },
        ),
        ChangeNotifierProvider(
          create: (context) {
            final appProvider = AppProvider(appRepository, nativeService);
            
            // Link App -> Auth
            appProvider.onTrustedNumbersChanged = (numbers) {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              if (authProvider.isAuthenticated) {
                authProvider.updateTrustedNumbers(numbers);
              }
            };
            
            appProvider.onTriggerKeywordChanged = (keyword) {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              if (authProvider.isAuthenticated) {
                authProvider.updateTriggerKeyword(keyword);
              }
            };

            // Link Auth -> App
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            authProvider.onProfileChanged = (profile) {
              if (profile != null) {
                if (profile.trustedNumbers.isNotEmpty) {
                  appProvider.syncTrustedNumbers(profile.trustedNumbers);
                }
                if (profile.triggerKeyword != null && profile.triggerKeyword!.isNotEmpty) {
                  appProvider.syncTriggerKeyword(profile.triggerKeyword!);
                }
              }
            };

            return appProvider..init();
          },
        ),
        Provider.value(value: permissionService),
        Provider.value(value: adService),
      ],
      child: const LostPhoneApp(),
    ),
  );
}

class LostPhoneApp extends StatelessWidget {
  const LostPhoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return MaterialApp(
          title: 'Lost Phone Recovery',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: provider.settings.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          themeAnimationDuration: Duration.zero,
          locale: Locale(provider.settings.languageCode),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('hi')],
          home: const SplashScreen(),
          routes: {
            '/auth-wrapper': (context) => const AuthWrapper(),
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/forgot-password': (context) => const ForgotPasswordScreen(),
            '/verify-email': (context) => const EmailVerificationScreen(),
            '/dashboard': (context) => const DashboardScreen(),
            '/profile': (context) => const ProfileScreen(),
            '/edit-profile': (context) => const EditProfileScreen(),
            '/setup': (context) => const SetupScreen(),
            '/trusted-numbers': (context) => const TrustedNumbersScreen(),
            '/default-actions': (context) => const DefaultActionsScreen(),
            '/command-guide': (context) => const CommandGuideScreen(),
            '/activity-logs': (context) => const ActivityLogsScreen(),
            '/privacy-policy': (context) => const PrivacyPolicyScreen(),
            '/faq': (context) => const FaqScreen(),
          },
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isInitializing) {
          return const Scaffold(
            backgroundColor: Color(0xFF121212),
            body: Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF))),
          );
        }
        if (!auth.isAuthenticated) {
          return const LoginScreen();
        }
        if (!auth.isEmailVerified) {
          return const EmailVerificationScreen();
        }
        return const DashboardScreen();
      },
    );
  }
}
