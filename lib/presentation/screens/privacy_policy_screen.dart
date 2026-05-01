import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

/// In-app privacy policy screen explaining data usage
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isHi = l10n.localeName == 'hi';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.privacyPolicy),
        leading: const BackButton(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildHeader(context, l10n),
          const SizedBox(height: 24),
          ..._getSections(isHi).map((s) => _PolicySection(section: s)),
          const SizedBox(height: 24),
          _buildFooter(l10n),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.privacy_tip_rounded,
            color: Colors.white,
            size: 30,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.privacyPolicy,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${l10n.lastUpdated}: March 2026',
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.privacyIntro,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.success.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.success.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_rounded, color: AppTheme.success, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.privacyCommitmentTitle,
                style: const TextStyle(
                  color: AppTheme.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.privacyCommitmentDesc,
            style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  List<_PolicySectionData> _getSections(bool isHi) {
    if (isHi) {
      return [
        const _PolicySectionData(
          title: 'SMS एक्सेस',
          icon: Icons.sms_rounded,
          color: Color(0xFF2196F3),
          content: 'PhoneGuard आपके विश्वसनीय नंबरों से भेजे गए रिकवरी कमांड का पता लगाने के लिए आने वाले SMS संदेशों को सुनता है।\n\n'
              '• SMS केवल आपके डिवाइस पर स्थानीय रूप से प्रोसेस किए जाते हैं\n'
              '• कोई भी SMS डेटा स्थायी रूप से स्टोर या कहीं अपलोड नहीं किया जाता है\n'
              '• केवल आपके विश्वसनीय नंबरों से आपके ट्रिगर कीवर्ड से मेल खाने वाले संदेश ही किसी कार्रवाई को ट्रिगर करते हैं\n'
              '• अन्य सभी संदेश तुरंत हटा दिए जाते हैं\n'
              '• ऐप कभी भी आपके व्यक्तिगत SMS नहीं पढ़ता है',
        ),
        const _PolicySectionData(
          title: 'लोकेशन एक्सेस',
          icon: Icons.location_on_rounded,
          color: Color(0xFF43A047),
          content: 'लोकेशन केवल तभी एक्सेस की जाती है जब रिकवरी कमांड (location या track) प्राप्त होता है।\n\n'
              '• लोकेशन कमांड के लिए GPS कोऑर्डिनेट मांग पर प्राप्त किए जाते हैं\n'
              '• लोकेशन डेटा SMS के माध्यम से उस विश्वसनीय नंबर को भेजा जाता है जिसने कमांड ट्रिगर किया था\n'
              '• लोकेशन कभी भी किसी सर्वर पर अपलोड नहीं की जाती है\n'
              '• बैकग्राउंड लोकेशन का उपयोग केवल सक्रिय ट्रैकिंग मोड के दौरान किया जाता है, जिसे आप कभी भी रोक सकते हैं',
        ),
        const _PolicySectionData(
          title: 'कैमरा एक्सेस',
          icon: Icons.camera_alt_rounded,
          color: Color(0xFF9C27B0),
          content: 'कैमरा केवल तभी एक्सेस किया जाता है जब किसी विश्वसनीय नंबर से "camera" कमांड प्राप्त होता है।\n\n'
              '• फ्रंट कैमरे का उपयोग करके चुपचाप फोटो ली जाती हैं\n'
              '• ली गई फोटो केवल ऐप की प्राइवेट डायरेक्टरी में स्टोर की जाती हैं\n'
              '• फोटो किसी भी सर्वर या क्लाउड स्टोरेज पर अपलोड नहीं की जाती हैं\n'
              '• फोटो कैप्चर केवल आपके अपने विश्वसनीय नंबरों द्वारा ट्रिगर किया जाता है\n'
              '• फोटो को डिवाइस फाइल मैनेजर में देखा जा सकता है',
        ),
        const _PolicySectionData(
          title: 'फोन स्टेट एक्सेस',
          icon: Icons.phone_android_rounded,
          color: Color(0xFFFFA726),
          content: 'SIM कार्ड परिवर्तन का पता लगाने के लिए READ_PHONE_STATE अनुमति का उपयोग किया जाता है।\n\n'
              '• यदि आपका SIM बदला जाता है, तो ऐप आपके विश्वसनीय नंबरों पर अलर्ट भेजता है\n'
              '• फोन नंबर की जानकारी केवल SMS के माध्यम से भेजी जाती है, कभी सर्वर पर नहीं\n'
              '• कभी भी कॉल लॉग या कॉन्टैक्ट डेटा एक्सेस नहीं किया जाता है',
        ),
        const _PolicySectionData(
          title: 'डेटा स्टोरेज',
          icon: Icons.storage_rounded,
          color: Color(0xFF607D8B),
          content: 'सभी ऐप सेटिंग्स और लॉग एंड्रॉइड SharedPreferences का उपयोग करके आपके डिवाइस पर स्थानीय रूप से स्टोर किए जाते हैं।\n\n'
              '• विश्वसनीय नंबर, ट्रिगर कीवर्ड, पिन और सेटिंग्स केवल स्थानीय रूप से स्टोर किए जाते हैं\n'
              '• गतिविधि लॉग स्थानीय रूप से स्टोर होते हैं और 200 प्रविष्टियों तक सीमित होते हैं\n'
              '• कोई भी डेटा बाहरी सर्वर पर बैकअप नहीं लिया जाता है\n'
              '• आप ऐप को अनइंस्टॉल करके सभी डेटा साफ़ कर सकते हैं',
        ),
        const _PolicySectionData(
          title: 'अनुमति औचित्य',
          icon: Icons.security_rounded,
          color: Color(0xFFE53935),
          content: 'सभी अनुमतियां केवल आवश्यकता पड़ने पर मांगी जाती हैं और रिकवरी के लिए उपयोग की जाती हैं:\n\n'
              '• RECEIVE_SMS / READ_SMS — रिकवरी कमांड का पता लगाएं\n'
              '• SEND_SMS — विश्वसनीय नंबरों को जवाब भेजें\n'
              '• ACCESS_FINE_LOCATION — लोकेशन कमांड के लिए GPS\n'
              '• CAMERA — कैमरा कमांड के लिए फोटो कैप्चर करें\n'
              '• FOREGROUND_SERVICE — रिकवरी सेवा चालू रखें\n'
              '• WAKE_LOCK — स्क्रीन बंद होने पर कमांड प्रोसेस करें\n'
              '• RECEIVE_BOOT_COMPLETED — रीबूट के बाद सेवा शुरू करें\n'
              '• READ_PHONE_STATE — SIM कार्ड परिवर्तन का पता लगाएं',
        ),
      ];
    } else {
      return const [
        _PolicySectionData(
          title: 'SMS Access',
          icon: Icons.sms_rounded,
          color: Color(0xFF2196F3),
          content: 'PhoneGuard listens for incoming SMS messages to detect recovery commands sent from your trusted numbers.\n\n'
              '• SMS messages are processed locally on your device only\n'
              '• No SMS content is stored permanently or uploaded anywhere\n'
              '• Only messages matching your trigger keyword from trusted numbers trigger any action\n'
              '• All other messages are immediately discarded\n'
              '• The app NEVER reads personal SMS conversations',
        ),
        _PolicySectionData(
          title: 'Location Access',
          icon: Icons.location_on_rounded,
          color: Color(0xFF43A047),
          content: 'Location is accessed ONLY when a recovery command (location or track) is received.\n\n'
              '• GPS coordinates are obtained on-demand for the location command\n'
              '• Location data is sent via SMS to the trusted number that triggered the command\n'
              '• Location is never uploaded to any server\n'
              '• Background location is used only during active tracking mode, which you can stop at any time',
        ),
        _PolicySectionData(
          title: 'Camera Access',
          icon: Icons.camera_alt_rounded,
          color: Color(0xFF9C27B0),
          content: 'Camera is accessed ONLY when the "camera" command is received from a trusted number.\n\n'
              '• Photos are captured silently using the front camera\n'
              '• Captured photos are stored in the app private directory only\n'
              '• Photos are NOT uploaded to any server or cloud storage\n'
              '• The photo capture is only triggered by your own trusted numbers\n'
              '• Photos can be reviewed in the device file manager',
        ),
        _PolicySectionData(
          title: 'Phone State Access',
          icon: Icons.phone_android_rounded,
          color: Color(0xFFFFA726),
          content: 'READ_PHONE_STATE permission is used to detect SIM card changes.\n\n'
              '• If your SIM is replaced, the app sends an alert to your configured trusted numbers\n'
              '• Phone number information is only sent via SMS, never to a server\n'
              '• No call logs or contact data are ever accessed',
        ),
        _PolicySectionData(
          title: 'Data Storage',
          icon: Icons.storage_rounded,
          color: Color(0xFF607D8B),
          content: 'All app settings and logs are stored locally on your device using Android SharedPreferences.\n\n'
              '• Trusted numbers, trigger keyword, PIN, and settings are stored locally only\n'
              '• Activity logs are stored locally and capped at 200 entries\n'
              '• No data is backed up to external servers\n'
              '• You can clear all data by uninstalling the app',
        ),
        _PolicySectionData(
          title: 'Permissions Justification',
          icon: Icons.security_rounded,
          color: Color(0xFFE53935),
          content: 'All permissions are requested only when needed and used strictly for recovery purposes:\n\n'
              '• RECEIVE_SMS / READ_SMS — detect recovery commands\n'
              '• SEND_SMS — send location/status replies to trusted numbers\n'
              '• ACCESS_FINE_LOCATION — GPS for location command\n'
              '• CAMERA — capture photo for camera command\n'
              '• FOREGROUND_SERVICE — keep recovery service running\n'
              '• WAKE_LOCK — process commands when screen is off\n'
              '• RECEIVE_BOOT_COMPLETED — restart service after device reboot\n'
              '• READ_PHONE_STATE — detect SIM card changes',
        ),
      ];
    }
  }
}

// ─── Data & Widgets ───────────────────────────────────────────────────────────

class _PolicySectionData {
  final String title;
  final IconData icon;
  final Color color;
  final String content;
  const _PolicySectionData({
    required this.title,
    required this.icon,
    required this.color,
    required this.content,
  });
}

class _PolicySection extends StatelessWidget {
  final _PolicySectionData section;
  const _PolicySection({required this.section});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: ExpansionTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: section.color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(section.icon, color: section.color, size: 20),
        ),
        title: Text(
          section.title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        iconColor: Colors.grey,
        collapsedIconColor: Colors.grey,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              section.content,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
