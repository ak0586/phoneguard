import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/app_provider.dart';

import 'package:lost_phone_finder/l10n/app_localizations.dart';
import '../../data/datasources/native_service.dart';

class PermissionsCard extends StatefulWidget {
  const PermissionsCard({super.key});

  @override
  State<PermissionsCard> createState() => _PermissionsCardState();
}

class _PermissionsCardState extends State<PermissionsCard> with WidgetsBindingObserver {
  bool _requesting = false;
  Map<Permission, PermissionStatus> _statuses = {};
  bool _isGoogleMessagesDefault = false;

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
      Permission.location,
      Permission.camera,
      Permission.contacts,
    ];
    
    final Map<Permission, PermissionStatus> newStatuses = {};
    for (final p in permissions) {
      newStatuses[p] = await p.status;
    }
    
    // Check google messages default
    final isGoogleMessagesDefault = await NativeService().isGoogleMessagesDefault();
    
    if (mounted) {
      setState(() {
        _statuses = newStatuses;
        _isGoogleMessagesDefault = isGoogleMessagesDefault;
      });
    }
  }

  Future<void> _requestAll() async {
    setState(() => _requesting = true);
    final l10n = AppLocalizations.of(context)!;

    final permissions = [
      Permission.contacts,
      Permission.notification,
    ];

    bool anyPermanentlyDenied = false;

    // 1. Request basic permissions first
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

    // 2. Camera Disclosure & Request
    final cameraStatus = await Permission.camera.status;
    if (!cameraStatus.isGranted && !cameraStatus.isPermanentlyDenied) {
      final proceed = await _showDisclosure(
        l10n.cameraDisclosureTitle,
        l10n.cameraDisclosureDesc,
      );
      if (proceed) await Permission.camera.request();
    }

    // 3. Location Disclosure & Request (Foreground)
    final locationStatus = await Permission.location.status;
    if (!locationStatus.isGranted && !locationStatus.isPermanentlyDenied) {
      final proceed = await _showDisclosure(
        l10n.locationDisclosureTitle,
        l10n.locationDisclosureDesc,
      );
      if (proceed) await Permission.location.request();
    }

    // 4. Background Location (Critical for Google)
    if (await Permission.location.isGranted) {
      final always = await Permission.locationAlways.status;
      if (!always.isGranted && !always.isPermanentlyDenied) {
        // Show disclosure AGAIN specifically for "All the time"
        final proceed = await _showDisclosure(
          l10n.locationDisclosureTitle,
          l10n.locationDisclosureDesc + "\n\nPlease select \"Allow all the time\" in the next screen.",
        );
        if (proceed) await Permission.locationAlways.request();
      }
    }

    // 5. Request Google Messages Default
    final isGoogleMessagesDefault = await NativeService().isGoogleMessagesDefault();
    if (!isGoogleMessagesDefault) {
      final proceed = await _showDisclosure(
        "Google Messages Required",
        "For RCS Chat features to work, Google Messages must be your default SMS app. If you don't have it installed, you will be redirected to the Play Store.",
      );
      if (proceed) {
        await NativeService().requestGoogleMessagesDefault();
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_user_rounded, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Consumer<AppProvider>(
                      builder: (context, provider, _) {
                        return IconButton(
                          onPressed: () => provider.setPermissionsCardCollapsed(!provider.isPermissionsCardCollapsed),
                          icon: Icon(
                            provider.isPermissionsCardCollapsed ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded,
                            color: Colors.grey,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        );
                      },
                    ),
                  ],
                ),
            ],
          ),
          Consumer<AppProvider>(
            builder: (context, provider, _) {
              final isCollapsed = provider.isPermissionsCardCollapsed && _statuses.values.every((s) => s.isGranted);
              return AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    _permRow(
                      Permission.location,
                      Icons.location_on_rounded,
                      l10n.locationAccessTitle,
                      l10n.locationAccessSubtitle,
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
                    _customRow(
                      _isGoogleMessagesDefault,
                      Icons.message_rounded,
                      "Google Messages",
                      "Required as default SMS app for RCS features",
                    ),
                    const SizedBox(height: 16),
                    Consumer<AppProvider>(
                      builder: (context, provider, _) {
                        final allGranted = _statuses.values.isNotEmpty && _statuses.values.every((s) => s.isGranted) && _isGoogleMessagesDefault;
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
                crossFadeState: isCollapsed ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                duration: const Duration(milliseconds: 300),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<bool> _showDisclosure(String title, String content) async {
    final l10n = AppLocalizations.of(context)!;
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.privacy_tip_outlined, color: Colors.blue),
                const SizedBox(width: 10),
                Expanded(child: Text(title)),
              ],
            ),
            content: Text(
              content,
              style: const TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(l10n.iUnderstand),
              ),
            ],
          ),
        ) ??
        false;
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
  Widget _customRow(bool isGranted, IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isGranted
                  ? Colors.green.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isGranted ? Colors.green : Colors.orange,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            isGranted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: isGranted ? Colors.green : Colors.grey.shade400,
            size: 20,
          ),
        ],
      ),
    );
  }
}
