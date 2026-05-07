import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../widgets/native_ad_widget.dart';
import '../../core/theme/app_theme.dart';

/// Reference guide for all SMS commands
class CommandGuideScreen extends StatelessWidget {
  const CommandGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppProvider, AuthProvider>(
      builder: (context, provider, auth, _) {
        final keyword = provider.settings.triggerKeyword.isEmpty
            ? 'trigger'
            : provider.settings.triggerKeyword;
        final isPremium = auth.profile?.isPremium ?? false;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Command Guide'),
            leading: const BackButton(),
          ),
          body: ListView(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              20 + MediaQuery.of(context).padding.bottom,
            ),
            children: [
              _buildIntro(context),
              if (!isPremium) ...[
                const NativeAdWidget(templateType: TemplateType.small),
                const SizedBox(height: 24),
              ],
              _buildFormatCard(context, keyword),
              const SizedBox(height: 24),
              const Text(
                'COMMAND REFERENCE',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              ..._commands.map((cmd) => _CommandCard(cmd: cmd)),
              if (!isPremium) ...[
                const SizedBox(height: 24),
                const NativeAdWidget(templateType: TemplateType.medium),
              ],
              const SizedBox(height: 24),
              const Text(
                'EXAMPLE SMS MESSAGES',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              ..._buildExamples(keyword).map((ex) => _ExampleCard(example: ex)),
              const SizedBox(height: 24),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIntro(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.sms_rounded, color: Colors.white, size: 28),
          SizedBox(height: 12),
          Text(
            'SMS Recovery Commands',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Send these commands from any trusted number to recover your device remotely — even without internet.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatCard(BuildContext context, String keyword) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF13131A) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Command Format',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          _CodeBlock(text: '$keyword'),
          const SizedBox(height: 8),
          _CodeBlock(text: '$keyword command'),
          const SizedBox(height: 8),
          const Text(
            'Simply send your trigger keyword followed by a command.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }


  static final _commands = [
    _Cmd(
      cmd: 'location',
      icon: Icons.location_on_rounded,
      color: Color(0xFF2196F3),
      description: 'Sends current GPS coordinates as a Google Maps link',
      response: 'Location:\nhttps://maps.google.com/?q=28.61,77.20',
    ),
    _Cmd(
      cmd: 'alarm',
      icon: Icons.volume_up_rounded,
      color: Color(0xFFE53935),
      description: 'Plays loud alarm overriding silent mode at maximum volume',
      response: 'Alarm started',
    ),
    _Cmd(
      cmd: 'track',
      icon: Icons.track_changes_rounded,
      color: Color(0xFF43A047),
      description: 'Starts continuous location updates every 3 minutes',
      response:
          'Tracking started\nTracking update:\nhttps://maps.google.com/?q=...',
    ),
    _Cmd(
      cmd: 'stop',
      icon: Icons.stop_circle_rounded,
      color: Color(0xFFFFA726),
      description: 'Stops alarm or tracking, whichever is active',
      response: 'Recovery stopped',
    ),
    _Cmd(
      cmd: 'lock',
      icon: Icons.lock_rounded,
      color: Color(0xFF607D8B),
      description:
          'Locks the device screen immediately (requires Device Admin)',
      response: 'Device locked',
    ),
  ];

  static List<_Example> _buildExamples(String keyword) => [
    _Example(
      title: 'Get location only',
      sms: '$keyword location',
      actions: ['Sends Google Maps link via SMS'],
    ),
    _Example(
      title: 'Multiple commands',
      sms: '$keyword location alarm',
      actions: ['Sends location link', 'Starts loud alarm'],
    ),
    _Example(
      title: 'Start loud alarm',
      sms: '$keyword alarm',
      actions: ['Overrides silent mode', 'Plays loud alarm sound'],
    ),
    _Example(
      title: 'Enable live tracking',
      sms: '$keyword track',
      actions: ['Starts continuous location updates every 3 minutes'],
    ),
    _Example(
      title: 'All default actions',
      sms: keyword,
      actions: ['Runs all enabled default actions'],
    ),
  ];
}

// ─── Data Models ─────────────────────────────────────────────────────────────

class _Cmd {
  final String cmd;
  final IconData icon;
  final Color color;
  final String description;
  final String response;
  const _Cmd({
    required this.cmd,
    required this.icon,
    required this.color,
    required this.description,
    required this.response,
  });
}

class _Example {
  final String title;
  final String sms;
  final List<String> actions;
  const _Example({
    required this.title,
    required this.sms,
    required this.actions,
  });
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _CodeBlock extends StatelessWidget {
  final String text;
  const _CodeBlock({required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: text));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF5F5FA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: isDark ? Colors.white : Theme.of(context).primaryColor,
                  fontFamily: 'monospace',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.copy_rounded, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }
}

class _CommandCard extends StatelessWidget {
  final _Cmd cmd;
  const _CommandCard({required this.cmd});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF13131A) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ExpansionTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: cmd.color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(cmd.icon, color: cmd.color, size: 20),
        ),
        title: Text(
          cmd.cmd,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          cmd.description,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        iconColor: Colors.grey,
        collapsedIconColor: Colors.grey,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Expected Response:',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF5F5FA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    cmd.response,
                    style: TextStyle(
                      color: isDark ? const Color(0xFF43A047) : const Color(0xFF2E7D32),
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExampleCard extends StatelessWidget {
  final _Example example;
  const _ExampleCard({required this.example});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF13131A) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            example.title,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          _CodeBlock(text: example.sms),
          const SizedBox(height: 8),
          ...example.actions.map(
            (a) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.arrow_right_rounded,
                    color: AppTheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      a,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
