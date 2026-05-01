import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isHi = l10n.localeName == 'hi';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.helpFaq),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSupportCard(context, l10n),
              const SizedBox(height: 32),
              ..._buildFaqSections(context, isHi),
              const SizedBox(height: 40),
              Center(
                child: Text(
                  'PhoneGuard v1.0.0',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFaqSections(BuildContext context, bool isHi) {
    if (isHi) {
      return [
        _buildSectionHeader(context, 'सामान्य प्रश्न'),
        _buildFaqItem(
          context,
          'PhoneGuard मेरा फोन कैसे ढूँढता है?',
          'PhoneGuard आपके विश्वसनीय नंबरों से भेजे गए SMS के माध्यम से विशिष्ट "ट्रिगर कीवर्ड" को सुनता है। प्राप्त होने पर, यह सायरन शुरू करना, लोकेशन भेजना या डिवाइस को लॉक करने जैसी कार्रवाइयां करता है।',
        ),
        _buildFaqItem(
          context,
          'ट्रिगर कीवर्ड क्या है?',
          'यह एक गुप्त वाक्यांश (जैसे, "miss you phone") है जो आपके द्वारा भेजे जाने वाले किसी भी SMS कमांड की शुरुआत में होना चाहिए। आप इसे ऐप सेटिंग्स में बदल सकते हैं।',
        ),
        _buildFaqItem(
          context,
          'अगर चोर मेरा SIM बदल दे तो क्या होगा?',
          'PhoneGuard में "SIM परिवर्तन पहचान" शामिल है। यदि कोई अनधिकृत SIM डाला जाता है, तो ऐप स्वचालित रूप से आपके विश्वसनीय नंबरों पर नए नंबर और लोकेशन के साथ एक अलर्ट SMS भेजता है।',
        ),
        const SizedBox(height: 24),
        _buildSectionHeader(context, 'गोपनीयता और सुरक्षा'),
        _buildFaqItem(
          context,
          'मैं ऐप आइकन कैसे छिपाऊं?',
          'सेटिंग्स में "स्टील्थ मोड" सक्षम करें। चोरों से छिपाए रखने के लिए ऐप आइकन आपके लॉन्चर से गायब हो जाएगा।',
        ),
        _buildFaqItem(
          context,
          'छिपे होने पर मैं ऐप कैसे खोलूं?',
          'अपने फोन के डायलर पर जाएं और अपना गुप्त डायल कोड (जैसे, *#*#1247#*#*) टाइप करें। ऐप तुरंत खुल जाएगा।',
        ),
        _buildFaqItem(
          context,
          'सीक्रेट पिन किसके लिए है?',
          '"डेटा वाइप" या "डिवाइस लॉक" जैसे संवेदनशील कमांड के लिए आपके 4-अंकीय पिन की आवश्यकता होती है ताकि अनधिकृत उपयोग को रोका जा सके।',
        ),
        const SizedBox(height: 24),
        _buildSectionHeader(context, 'कमांड और ट्रिगर'),
        _buildFaqItem(
          context,
          'क्या मैं किसी भी फोन से कार्रवाई ट्रिगर कर सकता हूं?',
          'नहीं। सुरक्षा के लिए, कमांड केवल तभी काम करते हैं जब वे आपके द्वारा ऐप में जोड़े गए "विश्वसनीय नंबरों" में से किसी एक से भेजे गए हों।',
        ),
        _buildFaqItem(
          context,
          'क्या यह बिना इंटरनेट के काम करता है?',
          'हाँ! सभी रिकवरी कमांड (अलार्म, लॉक, SMS के माध्यम से लोकेशन) सेलुलर नेटवर्क के माध्यम से पूरी तरह से ऑफलाइन काम करते हैं।',
        ),
        _buildFaqItem(
          context,
          'मैं चलते हुए अलार्म को कैसे रोकूँ?',
          'आप SMS के माध्यम से "Stop" कमांड भेज सकते हैं (जैसे, "miss you phone | stop") या ऐप खोलें और रनिंग एक्शन पॉपअप में "Stop All" पर टैप करें।',
        ),
        const SizedBox(height: 24),
        _buildSectionHeader(context, 'समस्या निवारण'),
        _buildFaqItem(
          context,
          'लोकेशन लिंक काम क्यों नहीं कर रहा है?',
          'सुनिश्चित करें कि आपके फोन पर "लोकेशन सेवाएं" (GPS) सक्षम हैं और ऐप के पास "हमेशा अनुमति दें" लोकेशन अनुमति है।',
        ),
        _buildFaqItem(
          context,
          'Google Play कहता है "उच्च बैटरी उपयोग"?',
          'PhoneGuard को SMS कमांड सुनने के लिए बैकग्राउंड में सक्रिय रहने की आवश्यकता है। कृपया 100% विश्वसनीयता सुनिश्चित करने के लिए PhoneGuard के लिए "बैटरी ऑप्टिमाइजेशन" अक्षम करें।',
        ),
        _buildFaqItem(
          context,
          'अलार्म क्यों नहीं बजा?',
          'सुनिश्चित करें कि आपकी वॉल्यूम सेटिंग्स "अलार्म" या "रिंगटोन" स्ट्रीम को बजने की अनुमति देती हैं। PhoneGuard स्वचालित रूप से वॉल्यूम को अधिकतम करने का प्रयास करेगा।',
        ),
      ];
    }

    return [
      _buildSectionHeader(context, 'General Questions'),
      _buildFaqItem(
        context,
        'How does PhoneGuard find my phone?',
        'PhoneGuard listens for specific "Trigger Keywords" sent via SMS from your Trusted Numbers. Once received, it executes actions like starting a siren, sending location, or locking the device.',
      ),
      _buildFaqItem(
        context,
        'What is a Trigger Keyword?',
        'It is a secret phrase (e.g., "miss you phone") that must be at the start of any SMS command you send. You can change this in the app settings.',
      ),
      _buildFaqItem(
        context,
        'What if the thief changes my SIM?',
        'PhoneGuard includes "SIM Change Detection". If an unauthorized SIM is inserted, the app automatically sends an alert SMS with the new number and location to your Trusted Numbers.',
      ),
      const SizedBox(height: 24),
      _buildSectionHeader(context, 'Stealth & Security'),
      _buildFaqItem(
        context,
        'How do I hide the app icon?',
        'Enable "Stealth Mode" in Settings. The app icon will disappear from your launcher to keep it hidden from thieves.',
      ),
      _buildFaqItem(
        context,
        'How do I open the app if it\'s hidden?',
        'Go to your phone\'s dialer and type your secret dial code (e.g., *#*#1247#*#*). The app will instantly open.',
      ),
      _buildFaqItem(
        context,
        'What is the Secret PIN for?',
        'Sensitive commands like "Wipe Data" or "Lock Device" require your 4-digit PIN to prevent unauthorized use, even from trusted numbers.',
      ),
      const SizedBox(height: 24),
      _buildSectionHeader(context, 'Commands & Triggers'),
      _buildFaqItem(
        context,
        'Can I trigger actions from any phone?',
        'No. For security, commands only work if sent from one of the "Trusted Numbers" you have added in the app.',
      ),
      _buildFaqItem(
        context,
        'Does it work without internet?',
        'Yes! All recovery commands (Alarm, Lock, Location via SMS) work completely offline via cellular network.',
      ),
      _buildFaqItem(
        context,
        'How do I stop a running alarm?',
        'You can send a "Stop" command via SMS (e.g., "miss you phone | stop") or open the app and tap "Stop All" in the Running Actions popup.',
      ),
      const SizedBox(height: 24),
      _buildSectionHeader(context, 'Troubleshooting'),
      _buildFaqItem(
        context,
        'Why is the location link not working?',
        'Ensure "Location Services" (GPS) is enabled on your phone and the app has "Always Allow" location permissions.',
      ),
      _buildFaqItem(
        context,
        'Google Play says "High Battery Usage"?',
        'PhoneGuard needs to stay active in the background to listen for SMS commands. Please disable "Battery Optimization" for PhoneGuard to ensure 100% reliability.',
      ),
      _buildFaqItem(
        context,
        'Why did the alarm not ring?',
        'Ensure your Volume settings allow "Alarm" or "Ringtone" streams to play. PhoneGuard will try to override volume to maximum automatically.',
      ),
    ];
  }

  Widget _buildSupportCard(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white24,
            radius: 24,
            child: Icon(Icons.support_agent_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.needMoreHelp,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  l10n.support247,
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () {
                // Future: Add contact support logic
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  l10n.chat,
                  style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w900, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: Theme.of(context).colorScheme.secondary,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildFaqItem(BuildContext context, String question, String answer) {
    return ExpansionTile(
      shape: const Border(),
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      children: [
        Text(
          answer,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
