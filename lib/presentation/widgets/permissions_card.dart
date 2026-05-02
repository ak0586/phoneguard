import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/app_provider.dart';

import 'package:lost_phone_finder/l10n/app_localizations.dart';

class PermissionsCard extends StatefulWidget {
  const PermissionsCard({super.key});

  @override
  State<PermissionsCard> createState() => _PermissionsCardState();
}

class _PermissionsCardState extends State<PermissionsCard> with WidgetsBindingObserver {
  bool _requesting = false;
  Map<Permission, PermissionStatus> _statuses = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    final permissions = [
      Permission.sms,
      Permission.location,
      Permission.phone,
      Permission.camera,
      Permission.contacts,
    ];
    
    final Map<Permission, PermissionStatus> newStatuses = {};
    for (final p in permissions) {
      newStatuses[p] = await p.status;
    }
    
    if (mounted) {
      setState(() {
        _statuses = newStatuses;
      });
    }
  }

  Future<void> _requestAll() async {
    setState(() => _requesting = true);

    final permissions = [
      Permission.sms,
      Permission.location,
      Permission.phone,
      Permission.camera,
      Permission.contacts,
      Permission.notification,
    ];

    bool anyPermanentlyDenied = false;

    for (final permission in permissions) {
      final status = await permission.status;
      if (status.isPermanentlyDenied) {
        anyPermanentlyDenied = true;
        continue;
      }
      if (!status.isGranted) {
        await permission.request();
      }
    }

    // locationAlways must be requested AFTER location is granted
    final locationStatus = await Permission.location.status;
    if (locationStatus.isGranted) {
      final always = await Permission.locationAlways.status;
      if (!always.isGranted && !always.isPermanentlyDenied) {
        await Permission.locationAlways.request();
      }
    }

    await _checkPermissions();
    setState(() => _requesting = false);

    if (!mounted) return;

    if (anyPermanentlyDenied) {
      final l10n = AppLocalizations.of(context)!;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.permsRequired),
          content: Text(l10n.permsRequiredDesc),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                openAppSettings();
              },
              child: Text(l10n.openSettings),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.6),
          width: 1.5,
        ),
        boxShadow: isLight
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.systemPermissions,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              if (_statuses.values.every((s) => s.isGranted))
                const Icon(Icons.verified_user_rounded, color: Colors.green, size: 16),
            ],
          ),
          const SizedBox(height: 16),
          _permRow(
            Permission.sms,
            Icons.sms_rounded,
            l10n.smsAccess,
            l10n.smsAccessDesc,
          ),
          _permRow(
            Permission.location,
            Icons.location_on_rounded,
            l10n.locationAccessTitle,
            l10n.locationAccessSubtitle,
          ),
          _permRow(
            Permission.phone,
            Icons.phone_android_rounded,
            l10n.phoneState,
            l10n.phoneStateDesc,
          ),
          _permRow(
            Permission.camera,
            Icons.camera_alt_rounded,
            l10n.cameraAccess,
            l10n.cameraAccessDesc,
          ),
          _permRow(
            Permission.contacts,
            Icons.contacts_rounded,
            l10n.contactsAccess,
            l10n.contactsAccessDesc,
          ),
          const SizedBox(height: 16),
          Consumer<AppProvider>(
            builder: (context, provider, _) {
              final allGranted = _statuses.values.isNotEmpty && _statuses.values.every((s) => s.isGranted);
              final isDarkMode = Theme.of(context).brightness == Brightness.dark;
              
              return AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: allGranted ? 0.5 : 1.0,
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: (_requesting || allGranted) ? null : _requestAll,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      disabledForegroundColor: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                    icon: _requesting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            allGranted ? Icons.verified_rounded : Icons.lock_open_rounded,
                            size: 18,
                          ),
                    label: Text(
                      _requesting 
                          ? l10n.checking 
                          : (allGranted ? l10n.allPermsGranted : l10n.checkGrantPerms),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _permRow(Permission p, IconData icon, String title, String subtitle) {
    final status = _statuses[p] ?? PermissionStatus.denied;
    final isGranted = status.isGranted;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isGranted ? Colors.green : Colors.red).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isGranted ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
          Icon(
            isGranted ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: isGranted ? Colors.green : Colors.red,
            size: 20,
          ),
        ],
      ),
    );
  }
}
