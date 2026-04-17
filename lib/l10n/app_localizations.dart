import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Lost Phone Recovery'**
  String get appName;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @protectionActive.
  ///
  /// In en, this message translates to:
  /// **'Protection Active'**
  String get protectionActive;

  /// No description provided for @protectionActiveDesc.
  ///
  /// In en, this message translates to:
  /// **'Monitoring for incoming SMS commands'**
  String get protectionActiveDesc;

  /// No description provided for @protectionDisabled.
  ///
  /// In en, this message translates to:
  /// **'Protection Disabled'**
  String get protectionDisabled;

  /// No description provided for @protectionDisabledDesc.
  ///
  /// In en, this message translates to:
  /// **'Add a trusted number to enable protection'**
  String get protectionDisabledDesc;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @testAlarm.
  ///
  /// In en, this message translates to:
  /// **'Test Alarm'**
  String get testAlarm;

  /// No description provided for @stopAlarm.
  ///
  /// In en, this message translates to:
  /// **'Stop Alarm'**
  String get stopAlarm;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @setupSecurity.
  ///
  /// In en, this message translates to:
  /// **'Setup & Security'**
  String get setupSecurity;

  /// No description provided for @trustedNumbers.
  ///
  /// In en, this message translates to:
  /// **'Trusted Numbers'**
  String get trustedNumbers;

  /// No description provided for @defaultActions.
  ///
  /// In en, this message translates to:
  /// **'Default Actions'**
  String get defaultActions;

  /// No description provided for @commandGuide.
  ///
  /// In en, this message translates to:
  /// **'Command Guide'**
  String get commandGuide;

  /// No description provided for @activityLogs.
  ///
  /// In en, this message translates to:
  /// **'Activity Logs'**
  String get activityLogs;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @helpFaq.
  ///
  /// In en, this message translates to:
  /// **'Help & FAQ'**
  String get helpFaq;

  /// No description provided for @needMoreHelp.
  ///
  /// In en, this message translates to:
  /// **'Need more help?'**
  String get needMoreHelp;

  /// No description provided for @support247.
  ///
  /// In en, this message translates to:
  /// **'Our support team is available 24/7'**
  String get support247;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'CHAT'**
  String get chat;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated'**
  String get lastUpdated;

  /// No description provided for @privacyCommitmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Our Commitment'**
  String get privacyCommitmentTitle;

  /// No description provided for @privacyCommitmentDesc.
  ///
  /// In en, this message translates to:
  /// **'PhoneGuard does NOT collect, upload, or sell any personal data. All data stays on your device. We have NO servers, NO analytics, and NO third-party data sharing.'**
  String get privacyCommitmentDesc;

  /// No description provided for @privacyIntro.
  ///
  /// In en, this message translates to:
  /// **'PhoneGuard is designed to help you recover your lost or stolen device. We are committed to protecting your privacy and being transparent about how the app works.'**
  String get privacyIntro;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
