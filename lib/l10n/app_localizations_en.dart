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

  @override
  String get setupGuide => 'Setup Guide';

  @override
  String get chatProtection => 'Chat Protection (RCS/WhatsApp)';

  @override
  String get chatProtectionDesc =>
      'Intercepts recovery commands via RCS & WhatsApp notifications.';

  @override
  String get chatProtectionInstr =>
      'Enable this in Settings -> Notifications -> Chat Protection (RCS/WhatsApp).';

  @override
  String get deviceAdmin => 'Device Admin';

  @override
  String get deviceAdminDesc => 'Remote lock or wipe your phone if stolen.';

  @override
  String get deviceAdminInstr =>
      'Activate this in Settings -> Technical -> Device Administrator.';

  @override
  String get locationAccess => 'Location Access';

  @override
  String get locationAccessDesc =>
      'Required to track and find your device on a map even when the app is closed or not in use.';

  @override
  String get locationAccessInstr =>
      'Set this to \"Allow all the time\" in Settings -> Privacy -> App Permissions to ensure recovery works 24/7.';

  @override
  String get trustedNumbersDesc => 'Set numbers that can send commands.';

  @override
  String get trustedNumbersInstr =>
      'Go to Security tab, tap \"Trusted Numbers\" and add at least one emergency contact.';

  @override
  String get defaultActionsDesc =>
      'Decide what happens when a command is received (Alarm, Lock, etc).';

  @override
  String get defaultActionsInstr =>
      'Go to Security tab, tap \"Default Actions\" and select which actions to trigger by default.';

  @override
  String get triggerKeyword => 'Trigger Keyword';

  @override
  String get triggerKeywordDesc =>
      'Set the secret word that activates your phone.';

  @override
  String get triggerKeywordInstr =>
      'Go to Security tab and type your secret trigger keyword.';

  @override
  String get setupGuideFooter =>
      'These settings ensure PhoneGuard can protect you even when the screen is locked.';

  @override
  String get incidentTime => 'Incident Time';

  @override
  String get viewOnMaps => 'VIEW ON GOOGLE MAPS';

  @override
  String get intrusionAlerts => 'Intrusion Alerts';

  @override
  String get clearAll => 'Clear All';

  @override
  String get systemPermissions => 'SYSTEM PERMISSIONS';

  @override
  String get smsAccess => 'SMS Access';

  @override
  String get smsAccessDesc =>
      'Required to receive and process recovery commands even when the device is locked.';

  @override
  String get locationAccessTitle => 'Background Location';

  @override
  String get locationAccessSubtitle =>
      'Collects location data to enable tracking even when the app is closed or not in use.';

  @override
  String get phoneState => 'Phone State';

  @override
  String get phoneStateDesc => 'SIM change detection';

  @override
  String get cameraAccess => 'Security Camera';

  @override
  String get cameraAccessDesc =>
      'Captures photos of intruders even when the screen is off or the app is minimized.';

  @override
  String get contactsAccess => 'Contacts';

  @override
  String get contactsAccessDesc => 'Select trusted recovery contacts';

  @override
  String get checking => 'Checking...';

  @override
  String get allPermsGranted => 'All Permissions Granted';

  @override
  String get checkGrantPerms => 'Check / Grant Permissions';

  @override
  String get permsRequired => 'Permissions Required';

  @override
  String get permsRequiredDesc =>
      'Some permissions were permanently denied.\n\nPlease open App Settings and grant all permissions manually.';

  @override
  String get cancel => 'Cancel';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get noActionsRunning => 'No actions are currently running';

  @override
  String get runningActions => 'RUNNING ACTIONS';

  @override
  String get stopAll => 'STOP ALL';

  @override
  String get sirenActive => 'Siren Alarm is active';

  @override
  String get trackingActive => 'Live Tracking is active';

  @override
  String dayRemaining(Object count) {
    return '$count day remaining';
  }

  @override
  String daysRemaining(Object count) {
    return '$count days remaining';
  }

  @override
  String timeRemaining(Object time) {
    return '$time remaining';
  }

  @override
  String get setupRequired => 'Setup Required';

  @override
  String get addTrustedDesc => 'Add a trusted number to enable protection';

  @override
  String get premiumProtection => 'Premium Protection';

  @override
  String get freeTrialActive => '3-day free trial active';

  @override
  String get protectionExpired => 'Protection Expired';

  @override
  String get watchAdDesc => 'Watch an ad to re-enable remote protection';

  @override
  String get pro => 'PRO';

  @override
  String get limitReachedMsg =>
      '🚫 Daily limit reached (6 ads). Try again tomorrow!';

  @override
  String get loadingAd => 'Loading Ad...';

  @override
  String get protectionExtendedMsg => '🎉 Protection extended by 4 hours!';

  @override
  String get adFailedMsg => 'Ad failed to load. Try again later.';

  @override
  String get limitReached => 'LIMIT REACHED';

  @override
  String get extend => 'EXTEND +4 H';

  @override
  String get reactive => 'REACTIVE +4 H';

  @override
  String get goPremium => 'GO PREMIUM';

  @override
  String get accountConflict => 'Account Conflict';

  @override
  String get accountConflictDesc =>
      'This account is already active on another device. For security, PhoneGuard only allows one active device per account.';

  @override
  String get logout => 'Logout';

  @override
  String get updateRequired => 'Update Required';

  @override
  String get updateRequiredDesc =>
      'A new version of PhoneGuard is available. To maintain security and remote connectivity, you must update to the latest version.';

  @override
  String get updateNow => 'UPDATE NOW';

  @override
  String get versionUnsupported =>
      'Your current version is no longer supported.';

  @override
  String get essentialSetup => 'Essential Setup';

  @override
  String get mandatorySettingsDesc => 'Mandatory settings for recovery';

  @override
  String get later => 'Later';

  @override
  String get completeSetup => 'COMPLETE SETUP';

  @override
  String get activityLogsTitle => 'Activity Logs';

  @override
  String get clearLogsTooltip => 'Clear logs';

  @override
  String get noActivityYet => 'No activity yet';

  @override
  String get recoveryWillAppear =>
      'Recovery commands will appear here\nonce your phone receives them';

  @override
  String get clearLogsConfirm => 'Clear All Logs?';

  @override
  String get clearLogsDesc =>
      'Are you sure you want to delete all activity logs? This action cannot be undone.';

  @override
  String get clear => 'Clear';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get securityIntrusion => 'SECURITY & INTRUSION';

  @override
  String get intrusionSelfie => 'Intrusion Selfie';

  @override
  String get intrusionSelfieDesc => 'Automatically capture photo on wrong PIN';

  @override
  String get intrusionThreshold => 'Intrusion Threshold';

  @override
  String failedAttempts(Object count) {
    return '$count failed attempts';
  }

  @override
  String attemptsCount(Object count) {
    return '$count attempts';
  }

  @override
  String get simChangeAlert => 'SIM Change Alert';

  @override
  String get simChangeAlertDesc => 'Notify trusted numbers if SIM is replaced';

  @override
  String get trustedNumbersSettingsDesc =>
      'Manage contacts who can control your phone';

  @override
  String get notifications => 'NOTIFICATIONS';

  @override
  String get silentBypass => 'Silent Mode Bypass';

  @override
  String get silentBypassDesc => 'Play alarm at full volume even on silent';

  @override
  String get chatProtectionTitle => 'Chat Protection (RCS/WhatsApp)';

  @override
  String get chatActiveDesc => 'Active - Commands work on RCS/WhatsApp';

  @override
  String get chatInactiveDesc => 'Inactive - Tap to enable Chat protection';

  @override
  String get privacyData => 'PRIVACY & DATA';

  @override
  String get appPermissionsTitle => 'App Permissions';

  @override
  String get appPermissionsDesc => 'Manage Android system access';

  @override
  String get clearLocalLogsTitle => 'Clear Local Logs';

  @override
  String get clearLocalLogsDesc => 'Wipe all activity history';

  @override
  String get technical => 'TECHNICAL';

  @override
  String get batteryOptimizationTitle => 'Battery Optimization';

  @override
  String get batteryOptimizationDesc => 'Ensure background service stays alive';

  @override
  String get deviceAdminTitle => 'Device Administrator';

  @override
  String get deviceAdminActive => 'Active (Recommended)';

  @override
  String get deviceAdminInactive => 'Inactive - Tap to Activate';

  @override
  String get logsClearedMsg => 'Logs cleared successfully';

  @override
  String get deactivateProtection => 'Deactivate Protection?';

  @override
  String get deactivateWarning =>
      'Warning: Disabling Device Admin will allow anyone to uninstall the app and stop remote protection.';

  @override
  String get areYouSureProceed => 'Are you sure you want to proceed?';

  @override
  String get deactivate => 'DEACTIVATE';

  @override
  String get remoteAccess => 'REMOTE ACCESS';

  @override
  String get webDashboard => 'Web Dashboard';

  @override
  String get remoteControlUrl => 'REMOTE CONTROL URL';

  @override
  String get supportHelp => 'SUPPORT & HELP';

  @override
  String get contactSupport => 'Contact Support';

  @override
  String get preferences => 'PREFERENCES';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get darkModeLabel => 'Dark Mode';

  @override
  String get english => 'English';

  @override
  String get hindi => 'हिंदी (Hindi)';

  @override
  String get about => 'ABOUT';

  @override
  String get shareApp => 'Share App';

  @override
  String get rateReview => 'Rate & Review';

  @override
  String get shareMsg =>
      'Protect your phone with PhoneGuard! Download now: https://phoneguard-web-dashboard.vercel.app/';

  @override
  String get madeWithLove => 'Made with ❤️ by Kyvronix';

  @override
  String get trustedNumbersTitle => 'Trusted Numbers';

  @override
  String get addFirstNumber => 'Add First Number';

  @override
  String get aboutTrustedNumbers => 'About Trusted Numbers';

  @override
  String get gotIt => 'Got it';

  @override
  String get removeNumberConfirm => 'Remove Number?';

  @override
  String get remove => 'Remove';

  @override
  String get profileTitle => 'Profile';

  @override
  String get editProfile => 'EDIT PROFILE';

  @override
  String get deleteAccount => 'DELETE ACCOUNT';

  @override
  String get deleteAccountDesc =>
      'This action is permanent and will delete all your data including recovery settings and logs.';

  @override
  String get deleteAccountConfirm => 'DELETE';

  @override
  String get logoutConfirmMsg => 'Are you sure you want to logout?';

  @override
  String get setSecurityPin => 'Set Security PIN';

  @override
  String get setPinDesc => 'Enter a 4-8 digit PIN to protect your commands.';

  @override
  String get pinLengthError => 'PIN must be at least 4 digits';

  @override
  String get enable => 'Enable';

  @override
  String get disable => 'Disable';

  @override
  String get settingsSavedMsg => '✓ Settings saved successfully';

  @override
  String get saveChanges => 'SAVE CHANGES';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get leftLabel => 'left';

  @override
  String get trialLabel => 'Trial';

  @override
  String get fromTrustedNumbers => 'from trusted numbers';

  @override
  String get exactLastLocation => 'EXACT LAST LOCATION';

  @override
  String get enterPasswordConfirm => 'Please enter your password to confirm:';

  @override
  String get password => 'Password';

  @override
  String get addNumberTitle => 'ADD NUMBER';

  @override
  String trustedNumberCount(Object count) {
    return '$count Trusted Number';
  }

  @override
  String trustedNumbersCount(Object count) {
    return '$count Trusted Numbers';
  }

  @override
  String get onlyTheseNumbers => 'Only these numbers can send commands';

  @override
  String get noTrustedNumbers => 'No trusted numbers yet';

  @override
  String get aboutTrustedDesc =>
      'Only SMS messages from trusted numbers will be processed as recovery commands.\n\nCountry codes are detected automatically, but you can also enter them manually (e.g. +91...).\n\nMessages from all other numbers are silently ignored.';

  @override
  String get premiumActive => 'Premium Active';

  @override
  String get upgradePremium => 'Upgrade to Premium';

  @override
  String get premiumMemberTitle => 'You are a Premium Member';

  @override
  String get premiumMemberDesc =>
      'Enjoy all advanced security features without limits.';

  @override
  String get expiresOn => 'Expires on';

  @override
  String get protectUltimateTitle =>
      'Protect Your Phone with\nUltimate Security';

  @override
  String get joinThousandsDesc =>
      'Join thousands of users who trust PhoneGuard to recover their stolen devices.';

  @override
  String get permanentProtectionTitle => 'Permanent Protection';

  @override
  String get permanentProtectionDesc =>
      'Always-on remote security. No more watching ads to extend protection.';

  @override
  String get intrusionDetectionTitle => 'Intrusion Detection';

  @override
  String get intrusionDetectionDesc =>
      'Unlock silent selfie capture when someone tries to unlock your phone.';

  @override
  String get adFreeTitle => 'Ad-Free Experience';

  @override
  String get adFreeDesc =>
      'Remove all banner and rewarded advertisements from the app.';

  @override
  String get unlimitedLogsTitle => 'Unlimited Logs';

  @override
  String get unlimitedLogsDesc =>
      'Full history of all security incidents and location updates.';

  @override
  String get bestValue => 'BEST VALUE';

  @override
  String get billedAnnually => 'Billed annually';

  @override
  String get billedMonthly => 'Billed monthly';

  @override
  String get restorePurchase => 'Restore Purchase';

  @override
  String get productsNotAvailable =>
      'Products not available. Check your internet or Play Store account.';

  @override
  String get locationDisclosureTitle => 'Background Location Usage';

  @override
  String get locationDisclosureDesc =>
      'PhoneGuard collects location data to enable device tracking and recovery features even when the app is closed or not in use.\n\nThis data is only used for recovery purposes and is sent securely to your private dashboard.';

  @override
  String get cameraDisclosureTitle => 'Security Camera Usage';

  @override
  String get cameraDisclosureDesc =>
      'PhoneGuard uses the camera to capture photos of unauthorized users attempting to access your device. This feature works even when the screen is off to provide you with evidence of intrusion.';

  @override
  String get iUnderstand => 'I UNDERSTAND';

  @override
  String get paymentReceipt => 'Payment Receipt';

  @override
  String get paymentSuccessful => 'Payment Successful';

  @override
  String get thankYouForUpgrade =>
      'Thank you for upgrading to PhoneGuard Premium. Your device is now fully protected.';

  @override
  String get totalAmount => 'Total Amount';

  @override
  String get orderId => 'Order ID';

  @override
  String get plan => 'Plan';

  @override
  String get date => 'Date';

  @override
  String get account => 'Account';

  @override
  String get validUntil => 'Valid Until';

  @override
  String get lifetime => 'Lifetime';

  @override
  String get receiptSupportInfo =>
      'A confirmation email has been sent by Google Play. Please keep your Order ID for any future support.';

  @override
  String get done => 'Done';

  @override
  String get deletePhotoConfirm => 'Delete Photo?';

  @override
  String get deletePhotoDesc =>
      'Are you sure you want to delete this intrusion alert? This action cannot be undone.';

  @override
  String get delete => 'Delete';
}
