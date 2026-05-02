import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'package:lost_phone_finder/l10n/app_localizations.dart';

/// Setup screen - configure trigger keyword, PIN, and stealth mode
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> with WidgetsBindingObserver {
  late TextEditingController _keywordController;
  late TextEditingController _pinController;
  bool _isPinVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final settings = context.read<AppProvider>().settings;
    _keywordController = TextEditingController(text: settings.triggerKeyword);
    _pinController = TextEditingController(text: settings.pin);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh device admin status when returning from settings
      context.read<AppProvider>().checkDeviceAdminStatus();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _keywordController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    final provider = context.read<AppProvider>();
    final settings = provider.settings;
    final l10n = AppLocalizations.of(context)!;

    await provider.updateSettings(
      settings.copyWith(
        triggerKeyword: _keywordController.text.trim().isEmpty
            ? 'miss you phone'
            : _keywordController.text.trim(),
        pin: _pinController.text,
      ),
    );

    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsSavedMsg)),
      );
    }
  }

  Future<bool?> _showPinDialog(BuildContext context, AppProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    if (_pinController.text.isEmpty) {
      _pinController.text = provider.settings.pin;
    }
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.setSecurityPin),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.setPinDesc),
              const SizedBox(height: 16),
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                maxLength: 8,
                decoration: InputDecoration(
                  labelText: l10n.password,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                if (_pinController.text.trim().length >= 4) {
                  provider.updateSettings(
                    provider.settings.copyWith(pin: _pinController.text.trim()),
                  );
                  Navigator.pop(context, true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.pinLengthError)),
                  );
                }
              },
              child: Text(l10n.enable),
            ),
          ],
        );
      },
    );
  }

  //hssgdjasg

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setup'), leading: const BackButton()),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final settings = provider.settings;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _SectionHeader(
                title: 'TRIGGER KEYWORD',
                subtitle: 'Phrase to activate recovery commands',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _keywordController,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  labelText: 'Trigger Keyword',
                  hintText: 'e.g. miss you phone',
                  prefixIcon: Icon(
                    Icons.key_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _InfoChip(
                text:
                    'Example: "${_keywordController.text.isNotEmpty ? _keywordController.text : 'miss you phone'}"',
              ),
              const SizedBox(height: 28),

              _SectionHeader(
                title: 'SECURITY PIN',
                subtitle: 'Optional PIN verification for commands',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Require PIN for commands',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Switch(
                    value: settings.isPinEnabled,
                    onChanged: (v) async {
                      if (v) {
                        final enable = await _showPinDialog(context, provider);
                        if (enable == true) {
                          provider.setPinEnabled(true);
                        }
                      } else {
                        provider.setPinEnabled(false);
                      }
                    },
                  ),
                ],
              ),
              if (settings.isPinEnabled) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _pinController,
                  obscureText: !_isPinVisible,
                  keyboardType: TextInputType.number,
                  maxLength: 8,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Security PIN',
                    hintText: '4-8 digit PIN',
                    prefixIcon: Icon(
                      Icons.lock_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPinVisible ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () =>
                          setState(() => _isPinVisible = !_isPinVisible),
                    ),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 8),
                _InfoChip(
                  text: 'Command format: keyword PIN command',
                ),
              ],
              const SizedBox(height: 28),

              _SectionHeader(
                title: 'DEVICE ADMIN',
                subtitle: 'Required for screen lock command',
              ),
              const SizedBox(height: 12),
              _DeviceAdminCard(provider: provider),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Save Settings'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String text;
  final bool isWarning;

  const _InfoChip({required this.text, this.isWarning = false});

  @override
  Widget build(BuildContext context) {
    final color = isWarning
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isWarning
                ? Icons.warning_amber_rounded
                : Icons.info_outline_rounded,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: color, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}


class _DeviceAdminCard extends StatelessWidget {
  final AppProvider provider;
  const _DeviceAdminCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Icon(
            provider.isDeviceAdminActive
                ? Icons.admin_panel_settings_rounded
                : Icons.admin_panel_settings_outlined,
            color: provider.isDeviceAdminActive ? Colors.green : Colors.grey,
            size: 36,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.isDeviceAdminActive
                      ? 'Device Admin Active'
                      : 'Device Admin Not Active',
                  style: TextStyle(
                    color: provider.isDeviceAdminActive
                        ? Colors.green
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Text(
                  'Required for lock command \nand Uninstall protection',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          if (provider.isDeviceAdminActive)
            TextButton(
              onPressed: provider.deactivateDeviceAdmin,
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Disable'),
            )
          else
            TextButton(
              onPressed: provider.requestDeviceAdmin,
              child: const Text('Enable'),
            ),
        ],
      ),
    );
  }
}
