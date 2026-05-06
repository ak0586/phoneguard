import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../widgets/native_ad_widget.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = Provider.of<AuthProvider>(context);
    final isPremium = auth.profile?.isPremium ?? false;
    final isHi = l10n.localeName == 'hi';

    final allFaqs = _getFaqs(context, isHi);
    final filteredFaqs = allFaqs.where((faq) {
      final query = _searchQuery.toLowerCase();
      return faq.question.toLowerCase().contains(query) || 
             faq.answer.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.helpFaq),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildSearchBar(context, l10n),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_searchQuery.isEmpty) _buildSupportCard(context, l10n),
                    if (_searchQuery.isEmpty && !isPremium) const NativeAdWidget(templateType: TemplateType.medium),
                    if (_searchQuery.isEmpty) const SizedBox(height: 32),
                    
                    if (filteredFaqs.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.withOpacity(0.5)),
                              const SizedBox(height: 16),
                              Text(
                                l10n.faqNoResults,
                                style: const TextStyle(color: Colors.grey, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._buildFilteredFaqs(context, filteredFaqs),
                    
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
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: l10n.faqSearchHint,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty 
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              )
            : null,
          filled: true,
          fillColor: Theme.of(context).cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  List<Widget> _buildFilteredFaqs(BuildContext context, List<FaqItemData> faqs) {
    String? currentCategory;
    List<Widget> widgets = [];

    for (var faq in faqs) {
      if (faq.category != currentCategory) {
        currentCategory = faq.category;
        widgets.add(_buildSectionHeader(context, currentCategory!));
      }
      widgets.add(_buildFaqItem(context, faq.question, faq.answer));
    }

    return widgets;
  }

  List<FaqItemData> _getFaqs(BuildContext context, bool isHi) {
    final l10n = AppLocalizations.of(context)!;
    
    if (isHi) {
      return [
        FaqItemData(l10n.faqBasics, 'PhoneGuard क्या है?', 'यह एक सुरक्षा ऐप है जो आपके फोन के चोरी होने पर उसे वापस पाने में मदद करता है। आप इसे दूसरे फोन से SMS भेजकर कंट्रोल कर सकते हैं।'),
        FaqItemData(l10n.faqBasics, 'मुझे क्या करना चाहिए?', 'सबसे पहले Google से लॉग इन करें, फिर कम से कम 2 विश्वसनीय मोबाइल नंबर (Trusted Numbers) जोड़ें। बस, आपका फोन सुरक्षित है!'),
        FaqItemData(l10n.faqBasics, 'क्या ऐप को हमेशा खुला रखना होगा?', 'नहीं, एक बार सेटअप करने के बाद आप ऐप बंद कर सकते हैं। यह बैकग्राउंड में अपना काम करता रहेगा।'),
        FaqItemData(l10n.faqGeneral, 'PhoneGuard मेरा फोन कैसे ढूँढता है?', 'PhoneGuard दो तरह से काम करता है: SMS कमांड (ऑफलाइन) और वेब डैशबोर्ड (ऑनलाइन)। आप दुनिया में कहीं से भी अपने फोन को ट्रैक, लॉक या सायरन बजा सकते हैं।'),
        FaqItemData(l10n.faqGeneral, 'वेब डैशबोर्ड क्या है?', 'आप browser में phoneguard-dashboard पर लॉग इन करके अपने फोन की लाइव लोकेशन देख सकते हैं और कमांड भेज सकते हैं।'),
        FaqItemData(l10n.faqGeneral, 'क्या सिम में बैलेंस होना चाहिए?', 'हाँ, क्योंकि ऐप लोकेशन भेजने के लिए SMS का उपयोग करता है, इसलिए आपके सिम में SMS भेजने के लिए बैलेंस या पैक होना चाहिए।'),
        FaqItemData(l10n.faqSecurity, 'घुसपैठिए की फोटो कैसे काम करती है?', 'यदि कोई आपके फोन पर गलत पिन डालने की कोशिश करता है, तो PhoneGuard चुपके से उसकी फोटो खींच लेता है और उसे आपके क्लाउड डैशबोर्ड पर अपलोड कर देता है।'),
        FaqItemData(l10n.faqSecurity, 'विश्वसनीय नंबर (Trusted Numbers) क्या हैं?', 'ये वे मोबाइल नंबर हैं जिन्हें आप ऐप में जोड़ते हैं। केवल इन नंबरों से भेजे गए SMS कमांड ही आपके फोन पर काम करेंगे।'),
        FaqItemData(l10n.faqTechnical, 'क्या फोन बंद होने पर यह काम करेगा?', 'अगर फोन पूरी तरह बंद है, तो यह कमांड नहीं ले पाएगा। लेकिन जैसे ही कोई फोन चालू करेगा, यह तुरंत आपको अलर्ट भेज देगा।'),
        FaqItemData(l10n.faqTechnical, 'क्या यह बिना इंटरनेट के काम करता है?', 'हाँ! रिकवरी के लिए मुख्य कमांड (सायरन, लोकेशन SMS, लॉक) बिना इंटरनेट के सेलुलर नेटवर्क पर काम करते हैं।'),
        FaqItemData(l10n.faqTechnical, 'बैटरी ऑप्टिमाइजेशन क्यों बंद करें?', 'Android बैटरी बचाने के लिए बैकग्राउंड ऐप्स को बंद कर देता है। 100% सुरक्षा सुनिश्चित करने के लिए PhoneGuard के लिए बैटरी ऑप्टिमाइजेशन को "Don\'t Optimize" पर सेट करना जरूरी है।'),
        FaqItemData(l10n.faqTechnical, 'क्या मेरा डेटा सुरक्षित है?', 'हाँ, आपका डेटा Firebase के सुरक्षित सर्वर पर एन्क्रिप्टेड है। केवल आप ही अपने डैशबोर्ड के माध्यम से अपनी जानकारी देख सकते हैं।'),
      ];
    }

    return [
      FaqItemData(l10n.faqBasics, 'What is PhoneGuard?', 'It is a security app designed to help you recover your phone if it is lost or stolen. It lets you control your device remotely using simple SMS messages from another phone.'),
      FaqItemData(l10n.faqBasics, 'How do I get started?', 'Simply sign in with Google, then add at least 2 "Trusted Numbers" (like your spouse or parent\'s number). That\'s it! Your phone is now protected.'),
      FaqItemData(l10n.faqBasics, 'Does the app need to stay open?', 'No. Once you have finished the setup, you can close the app. PhoneGuard runs quietly in the background to keep you safe.'),
      FaqItemData(l10n.faqGeneral, 'How does PhoneGuard find my phone?', 'PhoneGuard works in two ways: via SMS commands (Offline) and via the Web Dashboard (Online). You can track, lock, or sound a siren from anywhere in the world.'),
      FaqItemData(l10n.faqGeneral, 'What is the Web Dashboard?', 'You can log in to the PhoneGuard web portal from any browser to see live location, capture history, and send remote commands to your device.'),
      FaqItemData(l10n.faqGeneral, 'Do I need balance/recharge for SMS?', 'Yes. Since the app sends location details back to you via SMS, your SIM card must have an active SMS pack or balance to reply to your commands.'),
      FaqItemData(l10n.faqSecurity, 'How does Intrusion Detection work?', 'If someone tries to unlock your phone with a wrong PIN, PhoneGuard silently captures their photo using the front camera and uploads it to your secure dashboard.'),
      FaqItemData(l10n.faqSecurity, 'What are Trusted Numbers?', 'These are the mobile numbers of your friends or family that you add in the app. Only SMS commands sent from these numbers will be accepted by your phone.'),
      FaqItemData(l10n.faqTechnical, 'Will it work if the phone is switched off?', 'If the phone is completely OFF, it cannot receive commands. However, the moment someone turns the phone ON, PhoneGuard will activate and can send you an alert.'),
      FaqItemData(l10n.faqTechnical, 'Does it work without internet?', 'Yes! Core recovery features like the Siren, Location via SMS, and Remote Lock work completely offline via the cellular network.'),
      FaqItemData(l10n.faqTechnical, 'Why disable Battery Optimization?', 'Android often kills background apps to save battery. To ensure PhoneGuard is always ready to receive commands, you must set its battery usage to "Unrestricted" or "Don\'t Optimize".'),
      FaqItemData(l10n.faqTechnical, 'Is my data secure?', 'Absolutely. Your location and intrusion photos are stored securely on Firebase. Only you can access this data using your private Google account login.'),
      FaqItemData(l10n.faqAccount, 'How do I recover my account?', 'You can sign in with your Google account on any phone or the web dashboard to instantly regain control of your registered device.'),
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
            child: Icon(Icons.security_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.localeName == 'hi' ? 'मदद चाहिए?' : 'Need more help?',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  l10n.localeName == 'hi' ? 'डैशबोर्ड पर गाइड देखें' : 'Check guides on dashboard',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 16, left: 4),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.05),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
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
        ),
      ),
    );
  }
}

class FaqItemData {
  final String category;
  final String question;
  final String answer;

  FaqItemData(this.category, this.question, this.answer);
}
