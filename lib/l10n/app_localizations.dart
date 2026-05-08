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
  /// **'PhoneGuard only collects the data necessary to recover your device (location, model, and security photos). This data is stored securely on your private Cloud Dashboard (Firebase) and is NEVER shared with third parties. You have full control over your data.'**
  String get privacyCommitmentDesc;

  /// No description provided for @privacyIntro.
  ///
  /// In en, this message translates to:
  /// **'PhoneGuard is designed to help you recover your lost or stolen device. We are committed to protecting your privacy and being transparent about how the app works.'**
  String get privacyIntro;

  /// No description provided for @faqSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search questions...'**
  String get faqSearchHint;

  /// No description provided for @faqNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get faqNoResults;

  /// No description provided for @faqBasics.
  ///
  /// In en, this message translates to:
  /// **'Basics'**
  String get faqBasics;

  /// No description provided for @faqGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get faqGeneral;

  /// No description provided for @faqSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get faqSecurity;

  /// No description provided for @faqTechnical.
  ///
  /// In en, this message translates to:
  /// **'Technical'**
  String get faqTechnical;

  /// No description provided for @faqAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get faqAccount;

  /// No description provided for @supportGuideDesc.
  ///
  /// In en, this message translates to:
  /// **'Check guides on dashboard'**
  String get supportGuideDesc;

  /// No description provided for @setupGuide.
  ///
  /// In en, this message translates to:
  /// **'Setup Guide'**
  String get setupGuide;

  /// No description provided for @chatProtection.
  ///
  /// In en, this message translates to:
  /// **'Chat Protection (RCS/WhatsApp)'**
  String get chatProtection;

  /// No description provided for @chatProtectionDesc.
  ///
  /// In en, this message translates to:
  /// **'Intercepts recovery commands via RCS & WhatsApp notifications.'**
  String get chatProtectionDesc;

  /// No description provided for @chatProtectionInstr.
  ///
  /// In en, this message translates to:
  /// **'Enable this in Settings -> Notifications -> Chat Protection (RCS/WhatsApp).'**
  String get chatProtectionInstr;

  /// No description provided for @deviceAdmin.
  ///
  /// In en, this message translates to:
  /// **'Device Admin'**
  String get deviceAdmin;

  /// No description provided for @deviceAdminDesc.
  ///
  /// In en, this message translates to:
  /// **'Remote lock or wipe your phone if stolen.'**
  String get deviceAdminDesc;

  /// No description provided for @deviceAdminInstr.
  ///
  /// In en, this message translates to:
  /// **'Activate this in Settings -> Technical -> Device Administrator.'**
  String get deviceAdminInstr;

  /// No description provided for @locationAccess.
  ///
  /// In en, this message translates to:
  /// **'Location Access'**
  String get locationAccess;

  /// No description provided for @locationAccessDesc.
  ///
  /// In en, this message translates to:
  /// **'Required to track and find your device on a map even when the app is closed or not in use.'**
  String get locationAccessDesc;

  /// No description provided for @locationAccessInstr.
  ///
  /// In en, this message translates to:
  /// **'Set this to \"Allow all the time\" in Settings -> Privacy -> App Permissions to ensure recovery works 24/7.'**
  String get locationAccessInstr;

  /// No description provided for @trustedNumbersDesc.
  ///
  /// In en, this message translates to:
  /// **'Set numbers that can send commands.'**
  String get trustedNumbersDesc;

  /// No description provided for @trustedNumbersInstr.
  ///
  /// In en, this message translates to:
  /// **'Go to Security tab, tap \"Trusted Numbers\" and add at least one emergency contact.'**
  String get trustedNumbersInstr;

  /// No description provided for @defaultActionsDesc.
  ///
  /// In en, this message translates to:
  /// **'Decide what happens when a command is received (Alarm, Lock, etc).'**
  String get defaultActionsDesc;

  /// No description provided for @defaultActionsInstr.
  ///
  /// In en, this message translates to:
  /// **'Go to Security tab, tap \"Default Actions\" and select which actions to trigger by default.'**
  String get defaultActionsInstr;

  /// No description provided for @triggerKeyword.
  ///
  /// In en, this message translates to:
  /// **'Trigger Keyword'**
  String get triggerKeyword;

  /// No description provided for @triggerKeywordDesc.
  ///
  /// In en, this message translates to:
  /// **'Set the secret word that activates your phone.'**
  String get triggerKeywordDesc;

  /// No description provided for @triggerKeywordInstr.
  ///
  /// In en, this message translates to:
  /// **'Go to Security tab and type your secret trigger keyword.'**
  String get triggerKeywordInstr;

  /// No description provided for @setupGuideFooter.
  ///
  /// In en, this message translates to:
  /// **'These settings ensure PhoneGuard can protect you even when the screen is locked.'**
  String get setupGuideFooter;

  /// No description provided for @incidentTime.
  ///
  /// In en, this message translates to:
  /// **'Incident Time'**
  String get incidentTime;

  /// No description provided for @viewOnMaps.
  ///
  /// In en, this message translates to:
  /// **'VIEW ON GOOGLE MAPS'**
  String get viewOnMaps;

  /// No description provided for @intrusionAlerts.
  ///
  /// In en, this message translates to:
  /// **'Intrusion Alerts'**
  String get intrusionAlerts;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @systemPermissions.
  ///
  /// In en, this message translates to:
  /// **'SYSTEM PERMISSIONS'**
  String get systemPermissions;

  /// No description provided for @smsAccess.
  ///
  /// In en, this message translates to:
  /// **'SMS Access'**
  String get smsAccess;

  /// No description provided for @smsAccessDesc.
  ///
  /// In en, this message translates to:
  /// **'Required to receive and process recovery commands even when the device is locked.'**
  String get smsAccessDesc;

  /// No description provided for @locationAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Background Location'**
  String get locationAccessTitle;

  /// No description provided for @locationAccessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Collects location data to enable tracking even when the app is closed or not in use.'**
  String get locationAccessSubtitle;

  /// No description provided for @phoneState.
  ///
  /// In en, this message translates to:
  /// **'Phone State'**
  String get phoneState;

  /// No description provided for @phoneStateDesc.
  ///
  /// In en, this message translates to:
  /// **'SIM change detection'**
  String get phoneStateDesc;

  /// No description provided for @cameraAccess.
  ///
  /// In en, this message translates to:
  /// **'Security Camera'**
  String get cameraAccess;

  /// No description provided for @cameraAccessDesc.
  ///
  /// In en, this message translates to:
  /// **'Captures photos of intruders on failed unlock attempts, even when the app is minimized.'**
  String get cameraAccessDesc;

  /// No description provided for @contactsAccess.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get contactsAccess;

  /// No description provided for @contactsAccessDesc.
  ///
  /// In en, this message translates to:
  /// **'Select trusted recovery contacts'**
  String get contactsAccessDesc;

  /// No description provided for @checking.
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get checking;

  /// No description provided for @allPermsGranted.
  ///
  /// In en, this message translates to:
  /// **'All Permissions Granted'**
  String get allPermsGranted;

  /// No description provided for @checkGrantPerms.
  ///
  /// In en, this message translates to:
  /// **'Check / Grant Permissions'**
  String get checkGrantPerms;

  /// No description provided for @permsRequired.
  ///
  /// In en, this message translates to:
  /// **'Permissions Required'**
  String get permsRequired;

  /// No description provided for @permsRequiredDesc.
  ///
  /// In en, this message translates to:
  /// **'Some permissions were permanently denied.\n\nPlease open App Settings and grant all permissions manually.'**
  String get permsRequiredDesc;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @noActionsRunning.
  ///
  /// In en, this message translates to:
  /// **'No actions are currently running'**
  String get noActionsRunning;

  /// No description provided for @runningActions.
  ///
  /// In en, this message translates to:
  /// **'RUNNING ACTIONS'**
  String get runningActions;

  /// No description provided for @stopAll.
  ///
  /// In en, this message translates to:
  /// **'STOP ALL'**
  String get stopAll;

  /// No description provided for @sirenActive.
  ///
  /// In en, this message translates to:
  /// **'Siren Alarm is active'**
  String get sirenActive;

  /// No description provided for @trackingActive.
  ///
  /// In en, this message translates to:
  /// **'Live Tracking is active'**
  String get trackingActive;

  /// No description provided for @dayRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} day remaining'**
  String dayRemaining(Object count);

  /// No description provided for @daysRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} days remaining'**
  String daysRemaining(Object count);

  /// No description provided for @timeRemaining.
  ///
  /// In en, this message translates to:
  /// **'{time} remaining'**
  String timeRemaining(Object time);

  /// No description provided for @setupRequired.
  ///
  /// In en, this message translates to:
  /// **'Setup Required'**
  String get setupRequired;

  /// No description provided for @addTrustedDesc.
  ///
  /// In en, this message translates to:
  /// **'Add a trusted number to enable protection'**
  String get addTrustedDesc;

  /// No description provided for @premiumProtection.
  ///
  /// In en, this message translates to:
  /// **'Premium Protection'**
  String get premiumProtection;

  /// No description provided for @freeTrialActive.
  ///
  /// In en, this message translates to:
  /// **'3-day free trial active'**
  String get freeTrialActive;

  /// No description provided for @protectionExpired.
  ///
  /// In en, this message translates to:
  /// **'Protection Expired'**
  String get protectionExpired;

  /// No description provided for @watchAdDesc.
  ///
  /// In en, this message translates to:
  /// **'Watch an ad to re-enable remote protection'**
  String get watchAdDesc;

  /// No description provided for @pro.
  ///
  /// In en, this message translates to:
  /// **'PRO'**
  String get pro;

  /// No description provided for @limitReachedMsg.
  ///
  /// In en, this message translates to:
  /// **'🚫 Daily limit reached (6 ads). Try again tomorrow!'**
  String get limitReachedMsg;

  /// No description provided for @loadingAd.
  ///
  /// In en, this message translates to:
  /// **'Loading Ad...'**
  String get loadingAd;

  /// No description provided for @protectionExtendedMsg.
  ///
  /// In en, this message translates to:
  /// **'🎉 Protection extended by 4 hours!'**
  String get protectionExtendedMsg;

  /// No description provided for @adFailedMsg.
  ///
  /// In en, this message translates to:
  /// **'Ad failed to load. Try again later.'**
  String get adFailedMsg;

  /// No description provided for @limitReached.
  ///
  /// In en, this message translates to:
  /// **'LIMIT REACHED'**
  String get limitReached;

  /// No description provided for @extend.
  ///
  /// In en, this message translates to:
  /// **'EXTEND +4 H'**
  String get extend;

  /// No description provided for @reactive.
  ///
  /// In en, this message translates to:
  /// **'REACTIVE +4 H'**
  String get reactive;

  /// No description provided for @goPremium.
  ///
  /// In en, this message translates to:
  /// **'GO PREMIUM'**
  String get goPremium;

  /// No description provided for @accountConflict.
  ///
  /// In en, this message translates to:
  /// **'Account Conflict'**
  String get accountConflict;

  /// No description provided for @accountConflictDesc.
  ///
  /// In en, this message translates to:
  /// **'This account is already active on another device. For security, PhoneGuard only allows one active device per account.'**
  String get accountConflictDesc;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @updateRequired.
  ///
  /// In en, this message translates to:
  /// **'Update Required'**
  String get updateRequired;

  /// No description provided for @updateRequiredDesc.
  ///
  /// In en, this message translates to:
  /// **'A new version of PhoneGuard is available. To maintain security and remote connectivity, you must update to the latest version.'**
  String get updateRequiredDesc;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'UPDATE NOW'**
  String get updateNow;

  /// No description provided for @versionUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Your current version is no longer supported.'**
  String get versionUnsupported;

  /// No description provided for @essentialSetup.
  ///
  /// In en, this message translates to:
  /// **'Essential Setup'**
  String get essentialSetup;

  /// No description provided for @mandatorySettingsDesc.
  ///
  /// In en, this message translates to:
  /// **'Mandatory settings for recovery'**
  String get mandatorySettingsDesc;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @completeSetup.
  ///
  /// In en, this message translates to:
  /// **'COMPLETE SETUP'**
  String get completeSetup;

  /// No description provided for @activityLogsTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity Logs'**
  String get activityLogsTitle;

  /// No description provided for @clearLogsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear logs'**
  String get clearLogsTooltip;

  /// No description provided for @noActivityYet.
  ///
  /// In en, this message translates to:
  /// **'No activity yet'**
  String get noActivityYet;

  /// No description provided for @recoveryWillAppear.
  ///
  /// In en, this message translates to:
  /// **'Recovery commands will appear here\nonce your phone receives them'**
  String get recoveryWillAppear;

  /// No description provided for @clearLogsConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear All Logs?'**
  String get clearLogsConfirm;

  /// No description provided for @clearLogsDesc.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete all activity logs? This action cannot be undone.'**
  String get clearLogsDesc;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @securityIntrusion.
  ///
  /// In en, this message translates to:
  /// **'SECURITY & INTRUSION'**
  String get securityIntrusion;

  /// No description provided for @intrusionSelfie.
  ///
  /// In en, this message translates to:
  /// **'Intrusion Selfie'**
  String get intrusionSelfie;

  /// No description provided for @intrusionSelfieDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatically capture photo on wrong PIN'**
  String get intrusionSelfieDesc;

  /// No description provided for @intrusionThreshold.
  ///
  /// In en, this message translates to:
  /// **'Intrusion Threshold'**
  String get intrusionThreshold;

  /// No description provided for @failedAttempts.
  ///
  /// In en, this message translates to:
  /// **'{count} failed attempts'**
  String failedAttempts(Object count);

  /// No description provided for @attemptsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} attempts'**
  String attemptsCount(Object count);

  /// No description provided for @simChangeAlert.
  ///
  /// In en, this message translates to:
  /// **'SIM Change Alert'**
  String get simChangeAlert;

  /// No description provided for @simChangeAlertDesc.
  ///
  /// In en, this message translates to:
  /// **'Notify trusted numbers if SIM is replaced'**
  String get simChangeAlertDesc;

  /// No description provided for @trustedNumbersSettingsDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage contacts who can control your phone'**
  String get trustedNumbersSettingsDesc;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'NOTIFICATIONS'**
  String get notifications;

  /// No description provided for @silentBypass.
  ///
  /// In en, this message translates to:
  /// **'Silent Mode Bypass'**
  String get silentBypass;

  /// No description provided for @silentBypassDesc.
  ///
  /// In en, this message translates to:
  /// **'Play alarm at full volume even on silent'**
  String get silentBypassDesc;

  /// No description provided for @chatProtectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat Protection (RCS/WhatsApp)'**
  String get chatProtectionTitle;

  /// No description provided for @chatActiveDesc.
  ///
  /// In en, this message translates to:
  /// **'Active - Commands work on RCS/WhatsApp'**
  String get chatActiveDesc;

  /// No description provided for @chatInactiveDesc.
  ///
  /// In en, this message translates to:
  /// **'Inactive - Tap to enable Chat protection'**
  String get chatInactiveDesc;

  /// No description provided for @privacyData.
  ///
  /// In en, this message translates to:
  /// **'PRIVACY & DATA'**
  String get privacyData;

  /// No description provided for @appPermissionsTitle.
  ///
  /// In en, this message translates to:
  /// **'App Permissions'**
  String get appPermissionsTitle;

  /// No description provided for @appPermissionsDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage Android system access'**
  String get appPermissionsDesc;

  /// No description provided for @clearLocalLogsTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear Local Logs'**
  String get clearLocalLogsTitle;

  /// No description provided for @clearLocalLogsDesc.
  ///
  /// In en, this message translates to:
  /// **'Wipe all activity history'**
  String get clearLocalLogsDesc;

  /// No description provided for @technical.
  ///
  /// In en, this message translates to:
  /// **'TECHNICAL'**
  String get technical;

  /// No description provided for @batteryOptimizationTitle.
  ///
  /// In en, this message translates to:
  /// **'Battery Optimization'**
  String get batteryOptimizationTitle;

  /// No description provided for @batteryOptimizationDesc.
  ///
  /// In en, this message translates to:
  /// **'Ensure background service stays alive'**
  String get batteryOptimizationDesc;

  /// No description provided for @deviceAdminTitle.
  ///
  /// In en, this message translates to:
  /// **'Device Administrator'**
  String get deviceAdminTitle;

  /// No description provided for @deviceAdminActive.
  ///
  /// In en, this message translates to:
  /// **'Active (Recommended)'**
  String get deviceAdminActive;

  /// No description provided for @deviceAdminInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive - Tap to Activate'**
  String get deviceAdminInactive;

  /// No description provided for @logsClearedMsg.
  ///
  /// In en, this message translates to:
  /// **'Logs cleared successfully'**
  String get logsClearedMsg;

  /// No description provided for @deactivateProtection.
  ///
  /// In en, this message translates to:
  /// **'Deactivate Protection?'**
  String get deactivateProtection;

  /// No description provided for @deactivateWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning: Disabling Device Admin will allow anyone to uninstall the app and stop remote protection.'**
  String get deactivateWarning;

  /// No description provided for @areYouSureProceed.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to proceed?'**
  String get areYouSureProceed;

  /// No description provided for @deactivate.
  ///
  /// In en, this message translates to:
  /// **'DEACTIVATE'**
  String get deactivate;

  /// No description provided for @remoteAccess.
  ///
  /// In en, this message translates to:
  /// **'REMOTE ACCESS'**
  String get remoteAccess;

  /// No description provided for @webDashboard.
  ///
  /// In en, this message translates to:
  /// **'Web Dashboard'**
  String get webDashboard;

  /// No description provided for @remoteControlUrl.
  ///
  /// In en, this message translates to:
  /// **'REMOTE CONTROL URL'**
  String get remoteControlUrl;

  /// No description provided for @supportHelp.
  ///
  /// In en, this message translates to:
  /// **'SUPPORT & HELP'**
  String get supportHelp;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'PREFERENCES'**
  String get preferences;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @darkModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkModeLabel;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'हिंदी (Hindi)'**
  String get hindi;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'ABOUT'**
  String get about;

  /// No description provided for @shareApp.
  ///
  /// In en, this message translates to:
  /// **'Share App'**
  String get shareApp;

  /// No description provided for @rateReview.
  ///
  /// In en, this message translates to:
  /// **'Rate & Review'**
  String get rateReview;

  /// No description provided for @shareMsg.
  ///
  /// In en, this message translates to:
  /// **'Protect your phone with PhoneGuard! Download now: https://phoneguard-web-dashboard.vercel.app/'**
  String get shareMsg;

  /// No description provided for @madeWithLove.
  ///
  /// In en, this message translates to:
  /// **'Made with ❤️ by Kyvronix'**
  String get madeWithLove;

  /// No description provided for @trustedNumbersTitle.
  ///
  /// In en, this message translates to:
  /// **'Trusted Numbers'**
  String get trustedNumbersTitle;

  /// No description provided for @addFirstNumber.
  ///
  /// In en, this message translates to:
  /// **'Add First Number'**
  String get addFirstNumber;

  /// No description provided for @aboutTrustedNumbers.
  ///
  /// In en, this message translates to:
  /// **'About Trusted Numbers'**
  String get aboutTrustedNumbers;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @removeNumberConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove Number?'**
  String get removeNumberConfirm;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'EDIT PROFILE'**
  String get editProfile;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'DELETE ACCOUNT'**
  String get deleteAccount;

  /// No description provided for @deleteAccountDesc.
  ///
  /// In en, this message translates to:
  /// **'This action is permanent and will delete all your data including recovery settings and logs.'**
  String get deleteAccountDesc;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get deleteAccountConfirm;

  /// No description provided for @logoutConfirmMsg.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmMsg;

  /// No description provided for @setSecurityPin.
  ///
  /// In en, this message translates to:
  /// **'Set Security PIN'**
  String get setSecurityPin;

  /// No description provided for @setPinDesc.
  ///
  /// In en, this message translates to:
  /// **'Enter a 4-8 digit PIN to protect your commands.'**
  String get setPinDesc;

  /// No description provided for @pinLengthError.
  ///
  /// In en, this message translates to:
  /// **'PIN must be at least 4 digits'**
  String get pinLengthError;

  /// No description provided for @enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enable;

  /// No description provided for @disable.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get disable;

  /// No description provided for @settingsSavedMsg.
  ///
  /// In en, this message translates to:
  /// **'✓ Settings saved successfully'**
  String get settingsSavedMsg;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'SAVE CHANGES'**
  String get saveChanges;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @leftLabel.
  ///
  /// In en, this message translates to:
  /// **'left'**
  String get leftLabel;

  /// No description provided for @trialLabel.
  ///
  /// In en, this message translates to:
  /// **'Trial'**
  String get trialLabel;

  /// No description provided for @fromTrustedNumbers.
  ///
  /// In en, this message translates to:
  /// **'from trusted numbers'**
  String get fromTrustedNumbers;

  /// No description provided for @exactLastLocation.
  ///
  /// In en, this message translates to:
  /// **'EXACT LAST LOCATION'**
  String get exactLastLocation;

  /// No description provided for @enterPasswordConfirm.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password to confirm:'**
  String get enterPasswordConfirm;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @addNumberTitle.
  ///
  /// In en, this message translates to:
  /// **'ADD NUMBER'**
  String get addNumberTitle;

  /// No description provided for @trustedNumberCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Trusted Number'**
  String trustedNumberCount(Object count);

  /// No description provided for @trustedNumbersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Trusted Numbers'**
  String trustedNumbersCount(Object count);

  /// No description provided for @onlyTheseNumbers.
  ///
  /// In en, this message translates to:
  /// **'Only these numbers can send commands'**
  String get onlyTheseNumbers;

  /// No description provided for @noTrustedNumbers.
  ///
  /// In en, this message translates to:
  /// **'No trusted numbers yet'**
  String get noTrustedNumbers;

  /// No description provided for @aboutTrustedDesc.
  ///
  /// In en, this message translates to:
  /// **'Only SMS messages from trusted numbers will be processed as recovery commands.\n\nCountry codes are detected automatically, but you can also enter them manually (e.g. +91...).\n\nMessages from all other numbers are silently ignored.'**
  String get aboutTrustedDesc;

  /// No description provided for @premiumActive.
  ///
  /// In en, this message translates to:
  /// **'Premium Active'**
  String get premiumActive;

  /// No description provided for @upgradePremium.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium'**
  String get upgradePremium;

  /// No description provided for @premiumMemberTitle.
  ///
  /// In en, this message translates to:
  /// **'You are a Premium Member'**
  String get premiumMemberTitle;

  /// No description provided for @premiumMemberDesc.
  ///
  /// In en, this message translates to:
  /// **'Enjoy all advanced security features without limits.'**
  String get premiumMemberDesc;

  /// No description provided for @expiresOn.
  ///
  /// In en, this message translates to:
  /// **'Expires on'**
  String get expiresOn;

  /// No description provided for @protectUltimateTitle.
  ///
  /// In en, this message translates to:
  /// **'Protect Your Phone with\nUltimate Security'**
  String get protectUltimateTitle;

  /// No description provided for @joinThousandsDesc.
  ///
  /// In en, this message translates to:
  /// **'Join thousands of users who trust PhoneGuard to recover their stolen devices.'**
  String get joinThousandsDesc;

  /// No description provided for @permanentProtectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Permanent Protection'**
  String get permanentProtectionTitle;

  /// No description provided for @permanentProtectionDesc.
  ///
  /// In en, this message translates to:
  /// **'Always-on remote security. No more watching ads to extend protection.'**
  String get permanentProtectionDesc;

  /// No description provided for @intrusionDetectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Intrusion Detection'**
  String get intrusionDetectionTitle;

  /// No description provided for @intrusionDetectionDesc.
  ///
  /// In en, this message translates to:
  /// **'Unlock silent selfie capture when someone tries to unlock your phone.'**
  String get intrusionDetectionDesc;

  /// No description provided for @adFreeTitle.
  ///
  /// In en, this message translates to:
  /// **'Ad-Free Experience'**
  String get adFreeTitle;

  /// No description provided for @adFreeDesc.
  ///
  /// In en, this message translates to:
  /// **'Remove all banner and rewarded advertisements from the app.'**
  String get adFreeDesc;

  /// No description provided for @unlimitedLogsTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlimited Logs'**
  String get unlimitedLogsTitle;

  /// No description provided for @unlimitedLogsDesc.
  ///
  /// In en, this message translates to:
  /// **'Full history of all security incidents and location updates.'**
  String get unlimitedLogsDesc;

  /// No description provided for @bestValue.
  ///
  /// In en, this message translates to:
  /// **'BEST VALUE'**
  String get bestValue;

  /// No description provided for @billedAnnually.
  ///
  /// In en, this message translates to:
  /// **'Billed annually'**
  String get billedAnnually;

  /// No description provided for @billedMonthly.
  ///
  /// In en, this message translates to:
  /// **'Billed monthly'**
  String get billedMonthly;

  /// No description provided for @restorePurchase.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchase'**
  String get restorePurchase;

  /// No description provided for @productsNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Products not available. Check your internet or Play Store account.'**
  String get productsNotAvailable;

  /// No description provided for @locationDisclosureTitle.
  ///
  /// In en, this message translates to:
  /// **'Background Location Usage'**
  String get locationDisclosureTitle;

  /// No description provided for @locationDisclosureDesc.
  ///
  /// In en, this message translates to:
  /// **'PhoneGuard collects location data to enable device tracking and recovery features even when the app is closed or not in use.\n\nThis data is only used for recovery purposes and is sent securely to your private dashboard.'**
  String get locationDisclosureDesc;

  /// No description provided for @cameraDisclosureTitle.
  ///
  /// In en, this message translates to:
  /// **'Security Camera Usage'**
  String get cameraDisclosureTitle;

  /// No description provided for @cameraDisclosureDesc.
  ///
  /// In en, this message translates to:
  /// **'PhoneGuard uses the camera to capture photos of unauthorized users attempting to access your device. This feature works during failed unlock attempts to provide you with evidence of intrusion even when the app is minimized.'**
  String get cameraDisclosureDesc;

  /// No description provided for @iUnderstand.
  ///
  /// In en, this message translates to:
  /// **'I UNDERSTAND'**
  String get iUnderstand;

  /// No description provided for @paymentReceipt.
  ///
  /// In en, this message translates to:
  /// **'Payment Receipt'**
  String get paymentReceipt;

  /// No description provided for @paymentSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Payment Successful'**
  String get paymentSuccessful;

  /// No description provided for @thankYouForUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Thank you for upgrading to PhoneGuard Premium. Your device is now fully protected.'**
  String get thankYouForUpgrade;

  /// No description provided for @totalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get totalAmount;

  /// No description provided for @orderId.
  ///
  /// In en, this message translates to:
  /// **'Order ID'**
  String get orderId;

  /// No description provided for @plan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get plan;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @validUntil.
  ///
  /// In en, this message translates to:
  /// **'Valid Until'**
  String get validUntil;

  /// No description provided for @lifetime.
  ///
  /// In en, this message translates to:
  /// **'Lifetime'**
  String get lifetime;

  /// No description provided for @receiptSupportInfo.
  ///
  /// In en, this message translates to:
  /// **'A confirmation email has been sent by Google Play. Please keep your Order ID for any future support.'**
  String get receiptSupportInfo;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @deletePhotoConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete Photo?'**
  String get deletePhotoConfirm;

  /// No description provided for @deletePhotoDesc.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this intrusion alert? This action cannot be undone.'**
  String get deletePhotoDesc;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;
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
