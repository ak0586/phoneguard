import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../../core/theme/app_theme.dart';

class DeviceAdminStatusCard extends StatelessWidget {
  const DeviceAdminStatusCard({super.key});

  void _confirmDeactivation(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate Protection?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Warning: Disabling Device Admin will allow anyone to uninstall the app and stop remote protection.',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            Text('Are you sure you want to proceed?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              provider.deactivateDeviceAdmin();
              Navigator.pop(context);
            },
            child: const Text('DEACTIVATE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final isActive = provider.isDeviceAdminActive;

        return GestureDetector(
          onTap: () {
            if (!isActive) {
              provider.requestDeviceAdmin();
            } else {
              _confirmDeactivation(context, provider);
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isActive
                  ? AppTheme.success.withOpacity(0.1)
                  : AppTheme.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive
                    ? AppTheme.success.withOpacity(0.3)
                    : AppTheme.error.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.success : AppTheme.error,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isActive ? Icons.shield_rounded : Icons.gpp_maybe_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Uninstall Protection',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isActive
                            ? 'Active — App cannot be uninstalled'
                            : 'Inactive — Tap to enable protection',
                        style: TextStyle(
                          color: isActive ? AppTheme.success : AppTheme.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isActive ? AppTheme.success : AppTheme.error,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
