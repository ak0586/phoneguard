import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'package:lost_phone_finder/l10n/app_localizations.dart';

class MandatorySetupGuideScreen extends StatelessWidget {
  const MandatorySetupGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text(l10n.setupGuide),
        actions: const [LanguageToggleButton(), SizedBox(width: 8)],
      ),
      body: const SingleChildScrollView(
        child: SetupGuideContent(isFullPage: true),
      ),
    );
  }
}

class LanguageToggleButton extends StatelessWidget {
  const LanguageToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isHi = provider.settings.languageCode == 'hi';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final l10n = AppLocalizations.of(context)!;

    return InkWell(
      onTap: () => provider.setLanguageCode(isHi ? 'en' : 'hi'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(isDark ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: primaryColor.withOpacity(isDark ? 0.4 : 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.translate_rounded,
              size: 14,
              color: isDark ? Colors.white : primaryColor,
            ),
            const SizedBox(width: 6),
            Text(
              isHi ? l10n.english : l10n.hindi.split(' ')[0],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isDark ? Colors.white : primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SetupGuideContent extends StatefulWidget {
  final bool isFullPage;
  const SetupGuideContent({super.key, this.isFullPage = false});

  @override
  State<SetupGuideContent> createState() => _SetupGuideContentState();
}

class _SetupGuideContentState extends State<SetupGuideContent> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.all(widget.isFullPage ? 20 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRequirementItem(
            context,
            index: 0,
            icon: Icons.chat_bubble_rounded,
            title: l10n.chatProtection,
            description: l10n.chatProtectionDesc,
            instruction: l10n.chatProtectionInstr,
            color: Colors.green,
          ),
          _buildRequirementItem(
            context,
            index: 1,
            icon: Icons.admin_panel_settings_rounded,
            title: l10n.deviceAdmin,
            description: l10n.deviceAdminDesc,
            instruction: l10n.deviceAdminInstr,
            color: Colors.blue,
          ),
          _buildRequirementItem(
            context,
            index: 2,
            icon: Icons.location_on_rounded,
            title: l10n.locationAccess,
            description: l10n.locationAccessDesc,
            instruction: l10n.locationAccessInstr,
            color: Colors.red,
          ),
          _buildRequirementItem(
            context,
            index: 3,
            icon: Icons.people_alt_rounded,
            title: l10n.trustedNumbers,
            description: l10n.trustedNumbersDesc,
            instruction: l10n.trustedNumbersInstr,
            color: Colors.orange,
          ),
          _buildRequirementItem(
            context,
            index: 4,
            icon: Icons.admin_panel_settings_rounded,
            title: 'Security Control Hub',
            description: 'Set your trigger word and recovery actions',
            instruction: 'Go to Security Center tab and configure your secret keyword and what happens when it is sent.',
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: primaryColor.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: primaryColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.setupGuideFooter,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 110),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String title,
    required String description,
    required String instruction,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isExpanded = _expandedIndex == index;
    final primaryColor = Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          setState(() {
            _expandedIndex = isExpanded ? null : index;
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isExpanded
                ? (isDark
                      ? primaryColor.withOpacity(0.1)
                      : primaryColor.withOpacity(0.05))
                : (isDark ? Colors.white.withOpacity(0.03) : Colors.white),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isExpanded
                  ? primaryColor.withOpacity(0.3)
                  : (isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.05)),
              width: isExpanded ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isExpanded
                                ? (isDark ? Colors.white : primaryColor)
                                : (isDark
                                      ? Colors.white.withOpacity(0.9)
                                      : Colors.black87),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          description,
                          style: TextStyle(
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 300),
                    turns: isExpanded ? 0.25 : 0,
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: isExpanded
                          ? primaryColor
                          : Colors.grey.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
              if (isExpanded) ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.near_me_rounded, size: 16, color: primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        instruction,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
