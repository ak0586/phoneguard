import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:lost_phone_finder/l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'dart:ui';

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
import 'presentation/screens/privacy_policy_screen.dart';
import 'presentation/screens/profile_screen.dart';
import 'presentation/screens/edit_profile_screen.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/trusted_numbers_screen.dart';
import 'presentation/screens/settings_screen.dart';
import 'presentation/screens/mandatory_setup_guide_screen.dart';
import 'presentation/widgets/app_lock_wrapper.dart';
import 'data/datasources/ad_service.dart';
import 'presentation/providers/subscription_provider.dart';
import 'presentation/screens/subscription_screen.dart';
import 'presentation/screens/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Pass all uncaught "fatal" errors from the framework to Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Initialize SharedPreferences first
  final prefs = await SharedPreferences.getInstance();

  // Initialize Hive with prefs for background sync
  final hiveDataSource = await HiveDataSource.init(prefs);
  await hiveDataSource.migrateIfNeeded();

  final appRepository = AppRepositoryImpl(hiveDataSource);
  final nativeService = NativeService();
  final permissionService = PermissionService();
  final authService = AuthService();
  final adService = AdService();

  adService.init().catchError((e) => debugPrint('AdService init error: $e'));

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService),
        ),
        ChangeNotifierProxyProvider<AuthProvider, AppProvider>(
          create: (_) => AppProvider(appRepository, nativeService, authService)..init(),
          update: (_, auth, app) {
            if (app == null) return AppProvider(appRepository, nativeService, authService);
            
            // Reset if user logged out
            if (!auth.isAuthenticated && app.trustedNumbers.isNotEmpty) {
              app.reset();
            }

            // Sync App -> Auth
            app.onTrustedNumbersChanged = (numbers) {
              if (auth.isAuthenticated) auth.updateTrustedNumbers(numbers);
            };
            app.onTriggerKeywordChanged = (keyword) {
              if (auth.isAuthenticated) auth.updateTriggerKeyword(keyword);
            };

            // Sync Auth -> App
            auth.onProfileChanged = (profile) {
              if (profile != null) {
                app.syncTrustedNumbers(profile.trustedNumbers);
                if (profile.triggerKeyword != null) {
                  app.syncTriggerKeyword(profile.triggerKeyword!);
                }
              }
            };
            
            return app;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, SubscriptionProvider>(
          create: (context) => SubscriptionProvider(Provider.of<AuthProvider>(context, listen: false)),
          update: (context, auth, sub) => sub ?? SubscriptionProvider(auth),
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

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return MaterialApp(
          title: 'PhoneGuard: Lost Phone Finder',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: provider.settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          themeAnimationDuration: Duration.zero,
          locale: Locale(provider.settings.languageCode),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('hi')],
          navigatorObservers: [
            FirebaseAnalyticsObserver(analytics: analytics),
          ],
          home: const SplashScreen(),
          routes: {
            '/auth-wrapper': (context) => const AuthWrapper(),
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/forgot-password': (context) => const ForgotPasswordScreen(),
            '/verify-email': (context) => const EmailVerificationScreen(),
            '/dashboard': (context) => const MainNavigationScreen(),
            '/profile': (context) => const ProfileScreen(),
            '/edit-profile': (context) => const EditProfileScreen(),
            '/trusted-numbers': (context) => const TrustedNumbersScreen(),
            '/command-guide': (context) => const CommandGuideScreen(),
            '/activity-logs': (context) => const ActivityLogsScreen(),
            '/privacy-policy': (context) => const PrivacyPolicyScreen(),
            '/faq': (context) => const FaqScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/subscription': (context) => const SubscriptionScreen(),
            '/setup-guide': (context) => const MandatorySetupGuideScreen(),
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
        debugPrint('AuthWrapper: isInit=${auth.isInitializing}, auth=${auth.isAuthenticated}, verified=${auth.isEmailVerified}');
        if (auth.isInitializing) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!auth.isAuthenticated) return const LoginScreen();
        if (!auth.isEmailVerified) return const EmailVerificationScreen();
        return const AppLockWrapper(child: MainNavigationScreen());
      },
    );
  }
}
