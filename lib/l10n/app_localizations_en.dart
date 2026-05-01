// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Lost Phone Recovery';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get protectionActive => 'Protection Active';

  @override
  String get protectionActiveDesc => 'Monitoring for incoming SMS commands';

  @override
  String get protectionDisabled => 'Protection Disabled';

  @override
  String get protectionDisabledDesc =>
      'Add a trusted number to enable protection';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get testAlarm => 'Test Alarm';

  @override
  String get stopAlarm => 'Stop Alarm';

  @override
  String get settings => 'Settings';

  @override
  String get setupSecurity => 'Setup & Security';

  @override
  String get trustedNumbers => 'Trusted Numbers';

  @override
  String get defaultActions => 'Default Actions';

  @override
  String get commandGuide => 'Command Guide';

  @override
  String get activityLogs => 'Activity Logs';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get language => 'Language';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get helpFaq => 'Help & FAQ';

  @override
  String get needMoreHelp => 'Need more help?';

  @override
  String get support247 => 'Our support team is available 24/7';

  @override
  String get chat => 'CHAT';

  @override
  String get lastUpdated => 'Last updated';

  @override
  String get privacyCommitmentTitle => 'Our Commitment';

  @override
  String get privacyCommitmentDesc =>
      'PhoneGuard only collects the data necessary to recover your device (location, model, and security photos). This data is stored securely on your private Cloud Dashboard (Firebase) and is NEVER shared with third parties. You have full control over your data.';

  @override
  String get privacyIntro =>
      'PhoneGuard is designed to help you recover your lost or stolen device. We are committed to protecting your privacy and being transparent about how the app works.';

  @override
  String get faqSearchHint => 'Search questions...';

  @override
  String get faqNoResults => 'No results found';

  @override
  String get faqBasics => 'Basics';

  @override
  String get faqGeneral => 'General';

  @override
  String get faqSecurity => 'Security';

  @override
  String get faqTechnical => 'Technical';

  @override
  String get faqAccount => 'Account';

  @override
  String get supportGuideDesc => 'Check guides on dashboard';
}
