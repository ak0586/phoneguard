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
          '${l10n.lastUpdated}: May 2026',
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
          title: 'Google अकाउंट और ऑथेंटिकेशन',
          icon: Icons.account_circle_rounded,
          color: Color(0xFF4285F4),
          content: 'हम आपकी पहचान को सुरक्षित रखने के लिए Google साइन-इन का उपयोग करते हैं।\n\n'
              '• हम केवल आपकी ईमेल आईडी और बुनियादी प्रोफ़ाइल जानकारी एक्सेस करते हैं।\n'
              '• यह सुनिश्चित करता है कि केवल आप ही अपने व्यक्तिगत वेब डैशबोर्ड तक पहुँच सकें।\n'
              '• आपका पासवर्ड कभी भी हमारे द्वारा एक्सेस या स्टोर नहीं किया जाता है।',
        ),
        const _PolicySectionData(
          title: 'क्लाउड सिंक्रोनाइज़ेशन (Firebase)',
          icon: Icons.cloud_done_rounded,
          color: Color(0xFFFFCA28),
          content: 'रिमोट रिकवरी सक्षम करने के लिए, कुछ डेटा Google Firebase पर सुरक्षित रूप से स्टोर किया जाता है।\n\n'
              '• लोकेशन डेटा: मांग पर प्राप्त लोकेशन आपके वेब डैशबोर्ड पर दिखाई देती है।\n'
              '• घुसपैठिए की फोटो: गलत पिन डालने पर ली गई फोटो आपके निजी क्लाउड स्टोरेज पर अपलोड की जाती हैं।\n'
              '• डिवाइस की जानकारी: मॉडल और OS वर्जन को डिवाइस की पहचान के लिए स्टोर किया जाता है।\n'
              '• यह डेटा केवल आपको आपके Google अकाउंट के माध्यम से दिखाई देता है।',
        ),
        const _PolicySectionData(
          title: 'SMS एक्सेस',
          icon: Icons.sms_rounded,
          color: Color(0xFF2196F3),
          content: 'PhoneGuard आपके विश्वसनीय नंबरों से भेजे गए रिकवरी कमांड का पता लगाने के लिए आने वाले SMS संदेशों को सुनता है।\n\n'
              '• SMS केवल आपके डिवाइस पर स्थानीय रूप से प्रोसेस किए जाते हैं।\n'
              '• हम आपके व्यक्तिगत SMS कभी नहीं पढ़ते हैं।\n'
              '• केवल आपके विश्वसनीय नंबरों से भेजे गए ट्रिगर कमांड ही प्रोसेस किए जाते हैं।',
        ),
        const _PolicySectionData(
          title: 'कैमरा और लोकेशन',
          icon: Icons.camera_alt_rounded,
          color: Color(0xFFE91E63),
          content: 'इनका उपयोग केवल सुरक्षा उद्देश्यों के लिए किया जाता है:\n\n'
              '• कैमरा: घुसपैठिए की पहचान के लिए "गलत पिन" या "रिमोट कमांड" पर उपयोग किया जाता है।\n'
              '• लोकेशन: आपके खोए हुए फोन को मैप पर दिखाने के लिए उपयोग किया जाता है।\n'
              '• डेटा ट्रांसफर: यह जानकारी सुरक्षित रूप से आपके निजी डैशबोर्ड पर भेजी जाती है।',
        ),
        const _PolicySectionData(
          title: 'संपर्क और डिवाइस एडमिन',
          icon: Icons.contacts_rounded,
          color: Color(0xFF9C27B0),
          content: 'हम निम्नलिखित डिवाइस एक्सेस का उपयोग करते हैं:\n\n'
              '• संपर्क: केवल आपके फोनबुक से "विश्वसनीय नंबर" चुनने के लिए उपयोग किया जाता है। हम आपके संपर्कों को स्टोर या साझा नहीं करते हैं।\n'
              '• डिवाइस एडमिनिस्ट्रेटर: रिमोटली स्क्रीन लॉक करने की अनुमति देने के लिए आवश्यक है।\n'
              '• फोन स्थिति: सिम कार्ड बदलने का पता लगाने के लिए उपयोग किया जाता है।',
        ),
        const _PolicySectionData(
          title: 'डेटा सुरक्षा और नियंत्रण',
          icon: Icons.lock_rounded,
          color: Color(0xFF43A047),
          content: 'आपका डेटा आपका है और हम इसे कभी बेचते नहीं हैं।\n\n'
              '• कोई तीसरा पक्ष शेयरिंग नहीं: आपका डेटा किसी विज्ञापनदाता या बाहरी कंपनी के साथ साझा नहीं किया जाता है।\n'
              '• डेटा हटाना: आप ऐप के भीतर से अपनी सभी क्लाउड जानकारी साफ़ कर सकते हैं।\n'
              '• एन्क्रिप्शन: सर्वर और ऐप के बीच सभी संचार सुरक्षित रूप से एन्क्रिप्टेड हैं।',
        ),
      ];
    } else {
      return const [
        _PolicySectionData(
          title: 'Google Account & Auth',
          icon: Icons.account_circle_rounded,
          color: Color(0xFF4285F4),
          content: 'We use Google Sign-In to ensure your device security is linked to your identity.\n\n'
              '• We only access your email and basic profile information.\n'
              '• This allows you to securely access your device from any browser via the Web Dashboard.\n'
              '• Your password is never seen or stored by us.',
        ),
        _PolicySectionData(
          title: 'Cloud Synchronization (Firebase)',
          icon: Icons.cloud_done_rounded,
          color: Color(0xFFFFCA28),
          content: 'To enable remote recovery from the web, certain data is stored securely on Google Firebase.\n\n'
              '• Location Data: Current coordinates are uploaded only when requested via dashboard or SMS.\n'
              '• Intrusion Photos: Captured photos of unauthorized users are stored in your private cloud storage.\n'
              '• Device Metadata: Model and OS version are stored to identify your protected devices.\n'
              '• This data is encrypted and accessible only by you.',
        ),
        _PolicySectionData(
          title: 'SMS & Background Processing',
          icon: Icons.sms_rounded,
          color: Color(0xFF2196F3),
          content: 'PhoneGuard listens for recovery commands sent from your trusted numbers.\n\n'
              '• SMS messages are processed locally on your device.\n'
              '• We NEVER read your personal conversations.\n'
              '• Background services are used to ensure recovery commands work even when the app is closed.',
        ),
        _PolicySectionData(
          title: 'Camera & Location Usage',
          icon: Icons.camera_alt_rounded,
          color: Color(0xFFE91E63),
          content: 'Used strictly for security features:\n\n'
              '• Camera: Captures photos during intrusion attempts or via remote command.\n'
              '• Location: Provides GPS coordinates to help you find your lost device.\n'
              '• All captured media and coordinates are sent directly to your private secure dashboard.',
        ),
        _PolicySectionData(
          title: 'Contacts & Hardware Access',
          icon: Icons.contacts_rounded,
          color: Color(0xFF9C27B0),
          content: 'We utilize specific device hardware access:\n\n'
              '• Contacts: Used only to let you pick "Trusted Numbers" from your phonebook. We do not store or share your contact list.\n'
              '• Device Admin: Required to allow remote screen locking functionality.\n'
              '• Phone State: Used to detect SIM card changes and notify your trusted numbers.',
        ),
        _PolicySectionData(
          title: 'Data Control & Privacy',
          icon: Icons.lock_rounded,
          color: Color(0xFF43A047),
          content: 'Your data is private and we have a zero-monetization policy.\n\n'
              '• No Third-Party Sharing: We never sell or share your data with advertisers or third parties.\n'
              '• User Control: You can clear your cloud data and logs at any time from within the app.\n'
              '• Security: All data transfers are encrypted using industry-standard SSL/TLS protocols.',
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
