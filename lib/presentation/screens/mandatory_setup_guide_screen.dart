import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/app_provider.dart';
import 'package:lost_phone_finder/l10n/app_localizations.dart';
import '../../data/datasources/native_service.dart';

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

class _SetupGuideContentState extends State<SetupGuideContent> with WidgetsBindingObserver {
  int? _expandedIndex;
  bool _isSavingKeyword = false;
  bool _isEditingKeyword = false;
  String? _keywordError;
  final TextEditingController _keywordController = TextEditingController();
  Map<Permission, PermissionStatus> _permissionStatuses = {};
  bool _requestingPermissions = false;
  bool _isGoogleMessagesDefault = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAllStatuses();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _keywordController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAllStatuses();
    }
  }

  Future<void> _checkAllStatuses() async {
    if (!mounted) return;
    final provider = Provider.of<AppProvider>(context, listen: false);

    final permissions = [
      Permission.sms,
      Permission.location,
      Permission.camera,
      Permission.contacts,
    ];
    
    final Map<Permission, PermissionStatus> newStatuses = {};
    for (final p in permissions) {
      newStatuses[p] = await p.status;
    }

    await provider.refreshActiveActions();
    final isGoogleMessagesDefault = await NativeService().isGoogleMessagesDefault();

    if (mounted) {
      setState(() {
        _permissionStatuses = newStatuses;
        _isGoogleMessagesDefault = isGoogleMessagesDefault;
        _keywordController.text = provider.settings.triggerKeyword;
        _keywordError = null; // clear error on refresh
      });
    }
  }

  /// Returns an error message string, or null if the keyword is valid.
  String? _validateKeyword(String value) {
    final trimmed = value.trim();

    // 1. Minimum length
    if (trimmed.length < 5) return 'Keyword must be at least 5 characters.';

    // 2. Reserved command words (app commands that would create ambiguous triggers)
    const reservedWords = [
      'alarm', 'lock', 'locate', 'location', 'track', 'stop', 'audio',
      'wipe', 'ring', 'ping', 'help', 'unlock',
    ];
    if (reservedWords.contains(trimmed.toLowerCase())) {
      return '"$trimmed" is a reserved command word. Choose something unique.';
    }

    // 3. Date patterns: dd/mm/yyyy, dd-mm-yyyy, dd.mm.yyyy, ddmmyyyy etc.
    final datePatterns = [
      RegExp(r'^\d{1,2}[/\-.\s]\d{1,2}[/\-.\s]\d{2,4}$'), // 23/04/2002, 23-04-2002, 23.04.2002
      RegExp(r'^\d{6,8}$'), // 230402 or 23042002 (pure numeric date)
      RegExp(r'^\d{4}[/\-.\s]\d{1,2}[/\-.\s]\d{1,2}$'), // 2002/04/23 (ISO style)
    ];
    for (final pattern in datePatterns) {
      if (pattern.hasMatch(trimmed)) {
        return 'Dates are easy to guess. Use a unique word or phrase.';
      }
    }

    return null; // valid
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

  Future<void> _requestAllPermissions() async {
    setState(() => _requestingPermissions = true);
    final l10n = AppLocalizations.of(context)!;

    final permissions = [
      Permission.sms,
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

    await _checkAllStatuses();
    setState(() => _requestingPermissions = false);
    if (!mounted) return;

    if (anyPermanentlyDenied) {
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

  Widget _permRow(Permission p, IconData icon, String title, String subtitle) {
    final status = _permissionStatuses[p] ?? PermissionStatus.denied;
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

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<AppProvider>();

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
            instruction: l10n.chatInstr,
            color: Colors.green,
            isActive: provider.isNotificationListenerEnabled,
            actionButton: ElevatedButton.icon(
              onPressed: () => provider.openNotificationListenerSettings(),
              icon: const Icon(Icons.settings_suggest_rounded, size: 16),
              label: Text(l10n.activateChat),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          _buildRequirementItem(
            context,
            index: 1,
            icon: Icons.admin_panel_settings_rounded,
            title: l10n.deviceAdmin,
            description: l10n.deviceAdminDesc,
            instruction: l10n.adminInstr,
            color: Colors.blue,
            isActive: provider.isDeviceAdminActive,
            actionButton: ElevatedButton.icon(
              onPressed: () => provider.requestDeviceAdmin(),
              icon: const Icon(Icons.shield_rounded, size: 16),
              label: Text(l10n.activateAdmin),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          _buildRequirementItem(
            context,
            index: 2,
            icon: Icons.lock_open_rounded,
            title: l10n.systemPermissions,
            description: _permissionStatuses.values.isNotEmpty && _permissionStatuses.values.every((s) => s.isGranted)
                ? l10n.allPermsGranted
                : l10n.permsRequired,
            instruction: "Grant all required permissions to enable recovery commands (SMS, Location, Camera, Contacts).",
            color: Colors.purple,
            isActive: _permissionStatuses.values.isNotEmpty && _permissionStatuses.values.every((s) => s.isGranted) && _isGoogleMessagesDefault,
            customWidget: Column(
              children: [
                const SizedBox(height: 8),
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
              ],
            ),
            actionButton: ElevatedButton.icon(
              onPressed: (_requestingPermissions || (_permissionStatuses.values.isNotEmpty && _permissionStatuses.values.every((s) => s.isGranted) && _isGoogleMessagesDefault))
                  ? null
                  : _requestAllPermissions,
              icon: _requestingPermissions
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(
                      (_permissionStatuses.values.isNotEmpty && _permissionStatuses.values.every((s) => s.isGranted) && _isGoogleMessagesDefault)
                          ? Icons.verified_rounded
                          : Icons.lock_open_rounded,
                      size: 18,
                    ),
              label: Text(
                _requestingPermissions
                    ? l10n.checking
                    : ((_permissionStatuses.values.isNotEmpty && _permissionStatuses.values.every((s) => s.isGranted) && _isGoogleMessagesDefault)
                        ? l10n.allPermsGranted
                        : l10n.checkGrantPerms),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          _buildRequirementItem(
            context,
            index: 3,
            icon: Icons.people_alt_rounded,
            title: l10n.trustedNumbers,
            description: l10n.trustedNumbersDesc,
            instruction: l10n.trustedInstr,
            color: Colors.orange,
            isActive: provider.trustedNumbers.isNotEmpty,
            actionButton: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/trusted-numbers');
              },
              icon: const Icon(Icons.add_call, size: 16),
              label: Text(l10n.addTrustedNumberBtn),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          _buildRequirementItem(
            context,
            index: 4,
            icon: Icons.vpn_key_rounded,
            title: l10n.keywordTitle,
            description: l10n.keywordDesc,
            instruction: l10n.keywordInstr,
            color: Colors.indigo,
            isActive: provider.settings.triggerKeyword.isNotEmpty,
            customWidget: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                // Saved / view mode: show keyword chip + pencil edit button
                if (provider.settings.triggerKeyword.isNotEmpty && !_isEditingKeyword)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.indigo.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.vpn_key_rounded, size: 16, color: Colors.indigo),
                            const SizedBox(width: 8),
                            Text(
                              provider.settings.triggerKeyword,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Colors.indigo,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () => setState(() => _isEditingKeyword = true),
                        tooltip: 'Edit keyword',
                        icon: const Icon(Icons.edit_rounded, color: Colors.indigo, size: 20),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.indigo.withOpacity(0.08),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  )
                // Edit / input mode: show text field + save button
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _keywordController,
                              autofocus: _isEditingKeyword,
                              onChanged: (_) {
                                if (_keywordError != null) {
                                  setState(() => _keywordError = null);
                                }
                              },
                              decoration: InputDecoration(
                                hintText: 'e.g. lostphone',
                                labelText: l10n.triggerKeyword,
                                isDense: true,
                                errorText: _keywordError,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.red, width: 1.5),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Padding(
                            padding: EdgeInsets.only(
                              top: _keywordError != null ? 0 : 0,
                            ),
                            child: ElevatedButton(
                              onPressed: _isSavingKeyword
                                  ? null
                                  : () async {
                                      final error = _validateKeyword(_keywordController.text);
                                      if (error != null) {
                                        setState(() => _keywordError = error);
                                        return;
                                      }
                                      setState(() => _isSavingKeyword = true);
                                      await provider.setTriggerKeyword(_keywordController.text.trim());
                                      await _checkAllStatuses();
                                      setState(() {
                                        _isSavingKeyword = false;
                                        _isEditingKeyword = false;
                                        _keywordError = null;
                                      });
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(l10n.keywordSaved)),
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _isSavingKeyword
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                  : Text(l10n.save),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
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
    required bool isActive,
    Widget? actionButton,
    Widget? customWidget,
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
              color: isActive
                  ? Colors.green.withOpacity(0.4)
                  : (isExpanded
                        ? primaryColor.withOpacity(0.3)
                        : (isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.black.withOpacity(0.05))),
              width: isActive || isExpanded ? 1.5 : 1,
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
                      color: (isActive ? Colors.green : color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isActive ? Icons.verified_user_rounded : icon, 
                      color: isActive ? Colors.green : color, 
                      size: 20
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
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
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (isActive ? Colors.green : Colors.red).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isActive ? 'ACTIVE' : 'REQUIRED',
                                style: TextStyle(
                                  color: isActive ? Colors.green.shade800 : Colors.red.shade800,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
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
                    Icon(Icons.info_outline_rounded, size: 16, color: primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        instruction,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.grey.shade300 : Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
                if (customWidget != null) customWidget,
                if (!isActive && actionButton != null) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: actionButton,
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
