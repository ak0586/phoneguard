import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/app_settings.dart';
import 'package:permission_handler/permission_handler.dart';

/// Configure default recovery actions executed when only the trigger keyword is sent
class DefaultActionsScreen extends StatelessWidget {
  const DefaultActionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Default Actions'),
        leading: const BackButton(),
      ),
      body: Consumer<AppProvider>(
        builder: (_, provider, __) {
          final actions = provider.defaultActions;
          return ListView(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              20 + MediaQuery.of(context).padding.bottom,
            ),
            children: [
              _buildDescription(context),
              const SizedBox(height: 24),
              // ─── Active Responses ──────────────────────────────────────
              _buildSectionLabel(context, 'ACTIVE RESPONSES'),
              const SizedBox(height: 10),
              _ActionToggle(
                icon: Icons.location_on_rounded,
                title: 'Send GPS Location',
                subtitle: 'Reply with a Google Maps link to current position',
                enabled: actions.sendLocation,
                color: const Color(0xFF2196F3),
                onChanged: (v) async {
                  if (v) {
                    final status = await Permission.location.request();
                    if (!status.isGranted) return;
                  }
                  provider.setDefaultActions(actions.copyWith(sendLocation: v));
                },
              ),
              const SizedBox(height: 10),
              _ActionToggle(
                icon: Icons.volume_up_rounded,
                title: 'Start Loud Alarm',
                subtitle: 'Override silent mode and play maximum-volume alarm',
                enabled: actions.startAlarm,
                color: AppTheme.primary,
                onChanged: (v) =>
                    provider.setDefaultActions(actions.copyWith(startAlarm: v)),
              ),
              const SizedBox(height: 10),
              _ActionToggle(
                icon: Icons.track_changes_rounded,
                title: 'Enable Live Tracking',
                subtitle: 'Send GPS every 3 minutes until stopped',
                enabled: actions.enableTracking,
                color: const Color(0xFF43A047),
                onChanged: (v) async {
                  if (v) {
                    final loc = await Permission.location.request();
                    final sms = await Permission.sms.request();
                    if (!loc.isGranted || !sms.isGranted) return;
                  }
                  provider.setDefaultActions(actions.copyWith(enableTracking: v));
                },
              ),
              const SizedBox(height: 10),
              _ActionToggle(
                icon: Icons.lock_rounded,
                title: 'Lock Device Screen',
                subtitle: 'Instantly lock the screen (needs Device Admin)',
                enabled: actions.lockDevice,
                color: const Color(0xFFFF6F00),
                onChanged: (v) async {
                  if (v) {
                    if (!provider.isDeviceAdminActive) {
                      await provider.requestDeviceAdmin();
                      // Check again if they actually enabled it
                      if (!provider.isDeviceAdminActive) return;
                    }
                  }
                  provider.setDefaultActions(actions.copyWith(lockDevice: v));
                },
              ),
              const SizedBox(height: 20),
              // ─── Stop / Reset ──────────────────────────────────────────
              _buildSectionLabel(context, 'STOP / RESET'),
              const SizedBox(height: 10),
              _ActionToggle(
                icon: Icons.stop_circle_rounded,
                title: 'Stop Alarm on Trigger',
                subtitle: 'Stop any running alarm & tracking when trigger is received',
                enabled: actions.stopAlarmOnTrigger,
                color: const Color(0xFF607D8B),
                onChanged: (v) => provider.setDefaultActions(
                  actions.copyWith(stopAlarmOnTrigger: v),
                ),
              ),
              const SizedBox(height: 28),
              _buildPreview(context, actions, provider.settings.triggerKeyword),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
        color: Theme.of(context).colorScheme.primary.withOpacity(0.75),
      ),
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'These actions run automatically when you send ONLY the trigger keyword, without any specific command.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(
    BuildContext context,
    DefaultActions actions,
    String keyword,
  ) {
    final cmds = <String>[];
    if (actions.stopAlarmOnTrigger) cmds.add('stop');
    if (actions.sendLocation) cmds.add('location');
    if (actions.startAlarm) cmds.add('alarm');
    if (actions.enableTracking) cmds.add('track');
    if (actions.lockDevice) cmds.add('lock');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SMS PREVIEW',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              keyword,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '↓ Will execute:',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 6),
          if (cmds.isEmpty)
            const Text(
              'No actions enabled',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: cmds
                  .map(
                    (c) => Chip(
                      label: Text(c),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.15),
                      labelStyle: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      side: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.4),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

// ─── Action Toggle Card ───────────────────────────────────────────────────────

class _ActionToggle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final Color color;
  final ValueChanged<bool> onChanged;

  const _ActionToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: enabled
            ? color.withOpacity(0.08)
            : Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: enabled
              ? color.withOpacity(0.5)
              : Theme.of(context).dividerColor,
          width: enabled ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: enabled
                  ? color.withOpacity(0.2)
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: enabled ? color : Colors.grey, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: enabled
                        ? Theme.of(context).colorScheme.onSurface
                        : Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(value: enabled, onChanged: onChanged, activeThumbColor: color),
        ],
      ),
    );
  }
}
