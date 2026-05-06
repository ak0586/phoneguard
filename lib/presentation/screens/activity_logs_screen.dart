import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/native_ad_widget.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../domain/models/activity_log.dart';
import 'package:lost_phone_finder/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';

/// Shows history of all received commands and recovery actions
class ActivityLogsScreen extends StatelessWidget {
  const ActivityLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text(l10n.activityLogsTitle),
        actions: [
          Consumer<AppProvider>(
            builder: (ctx, provider, _) {
              if (provider.logs.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: l10n.clearLogsTooltip,
                onPressed: () => _confirmClear(ctx, provider),
              );
            },
          ),
        ],
      ),
      body: Consumer2<AppProvider, AuthProvider>(
        builder: (context, provider, auth, _) {
          final logs = provider.logs;
          final isPremium = auth.profile?.isPremium ?? false;

          if (logs.isEmpty) return _buildEmptyState(context, isPremium);

          // Build item list with ads interspersed ONLY for non-premium users
          final items = <dynamic>[];
          for (int i = 0; i < logs.length; i++) {
            items.add(logs[i]);
            if (!isPremium) {
              // Insert an ad after the 1st log and then every 5 logs
              if (i == 0 || (i > 0 && (i + 1) % 5 == 0)) {
                items.add('ad');
              }
            }
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              if (item == 'ad') {
                return const NativeAdWidget(templateType: TemplateType.small);
              }
              return _LogTile(log: item as ActivityLog);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isPremium) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_rounded, size: 80, color: Colors.grey.shade700),
          const SizedBox(height: 16),
          Text(
            l10n.noActivityYet,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.recoveryWillAppear,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          if (!isPremium) ...[
            const SizedBox(height: 32),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: NativeAdWidget(templateType: TemplateType.medium),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context, AppProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.clearLogsConfirm),
        content: Text(l10n.clearLogsDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              provider.clearLogs();
              Navigator.pop(ctx);
            },
            child: Text(l10n.clear, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ─── Log Tile ─────────────────────────────────────────────────────────────────

class _LogTile extends StatelessWidget {
  final ActivityLog log;
  const _LogTile({required this.log});

  Color get _commandColor {
    switch (log.command.toLowerCase()) {
      case 'location':
        return const Color(0xFF2196F3);
      case 'camera':
        return const Color(0xFF9C27B0);
      case 'alarm':
        return AppTheme.primary;
      case 'track':
        return const Color(0xFF43A047);
      case 'stop':
        return const Color(0xFFFFA726);
      case 'audio':
        return const Color(0xFF00BCD4);
      case 'lock':
        return const Color(0xFF607D8B);
      default:
        return Colors.grey;
    }
  }

  IconData get _commandIcon {
    switch (log.command.toLowerCase()) {
      case 'location':
        return Icons.location_on_rounded;
      case 'camera':
        return Icons.camera_front_rounded;
      case 'alarm':
        return Icons.volume_up_rounded;
      case 'track':
        return Icons.track_changes_rounded;
      case 'stop':
        return Icons.stop_circle_rounded;
      case 'audio':
        return Icons.mic_rounded;
      case 'lock':
        return Icons.lock_rounded;
      default:
        return Icons.terminal_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _commandColor;
    final dateStr = DateFormat(
      'MMM dd, yyyy · HH:mm:ss',
    ).format(log.timestamp.toLocal());

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: log.success
              ? color.withOpacity(0.3)
              : Theme.of(context).colorScheme.error.withOpacity(0.3),
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(_commandIcon, color: color, size: 20),
        ),
        title: Text(
          log.command,
          style: TextStyle(
            color: log.success
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.error,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
          ),
        ),
        subtitle: Text(
          'From: ${log.senderNumber}  ·  $dateStr',
          style: const TextStyle(color: Colors.grey, fontSize: 11),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              log.success ? Icons.check_circle_rounded : Icons.error_rounded,
              color: log.success
                  ? AppTheme.success
                  : Theme.of(context).colorScheme.error,
              size: 18,
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: 20,
                color: Colors.grey,
              ),
              onPressed: () => context.read<AppProvider>().removeLog(log.id),
            ),
            const Icon(Icons.expand_more_rounded, color: Colors.grey),
          ],
        ),
        iconColor: Colors.transparent,
        collapsedIconColor: Colors.transparent,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                log.result,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
