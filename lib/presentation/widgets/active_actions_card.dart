import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class ActiveActionsCard extends StatelessWidget {
  final bool showEmptyState;
  const ActiveActionsCard({super.key, this.showEmptyState = false});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final activeAlarm = provider.isAlarmActive;
        final activeTracking = provider.isTrackingActive;

        if (!activeAlarm && !activeTracking) {
          if (!showEmptyState) return const SizedBox.shrink();
          
          return Column(
            children: [
              Icon(Icons.check_circle_outline_rounded, size: 48, color: Colors.grey.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              const Text(
                'No actions are currently running',
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
              ),
            ],
          );
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 14),
                  ),
                  const Expanded(
                    child: Text(
                      'RUNNING ACTIONS',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      if (activeAlarm) provider.stopAlarm();
                      if (activeTracking) provider.stopTracking();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('STOP ALL', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (activeAlarm)
                _ActiveItem(
                  icon: Icons.volume_up_rounded,
                  label: 'Siren Alarm is active',
                  onStop: () => provider.stopAlarm(),
                ),
              if (activeAlarm && activeTracking) const Divider(height: 16),
              if (activeTracking)
                _ActiveItem(
                  icon: Icons.my_location_rounded,
                  label: 'Live Tracking is active',
                  onStop: () => provider.stopTracking(),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ActiveItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onStop;

  const _ActiveItem({
    required this.icon,
    required this.label,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.orange, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        IconButton(
          onPressed: onStop,
          icon: const Icon(Icons.stop_circle_outlined, color: Colors.red, size: 22),
          tooltip: 'Stop',
        ),
      ],
    );
  }
}
