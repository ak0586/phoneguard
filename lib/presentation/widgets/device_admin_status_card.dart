import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../../core/theme/app_theme.dart';

class DeviceAdminStatusCard extends StatelessWidget {
  const DeviceAdminStatusCard({super.key});

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
              provider.deactivateDeviceAdmin();
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
