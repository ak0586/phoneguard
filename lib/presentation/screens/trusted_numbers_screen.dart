import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/phone_utils.dart';
import '../../domain/models/trusted_number.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../widgets/native_ad_widget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:lost_phone_finder/l10n/app_localizations.dart';

/// Manages trusted phone numbers that can send recovery commands
class TrustedNumbersScreen extends StatelessWidget {
  const TrustedNumbersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.trustedNumbersTitle),
        leading: const BackButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: () => _showHelp(context),
          ),
        ],
      ),
      body: Consumer2<AppProvider, AuthProvider>(
        builder: (context, provider, auth, _) {
          final numbers = provider.trustedNumbers;
          final isPremium = auth.profile?.isPremium ?? false;
          
          return Column(
            children: [
              if (!isPremium) const NativeAdWidget(templateType: TemplateType.small),
              _buildHeader(context, numbers.length),
              if (numbers.isEmpty)
                _buildEmptyState(context)
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: numbers.length,
                    itemBuilder: (context, index) => _NumberTile(
                      number: numbers[index],
                      onEdit: () => _showEditDialog(context, numbers[index]),
                      onDelete: () =>
                          _confirmDelete(context, provider, numbers[index]),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: null,
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Theme.of(context).dividerColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.addNumberTitle,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ActionButton(
                    icon: Icons.contact_phone_rounded,
                    onTap: () => _pickFromContacts(context),
                    isOutlined: true,
                  ),
                  const SizedBox(width: 40),
                  _ActionButton(
                    icon: Icons.keyboard_rounded,
                    onTap: () => _showAddDialog(context),
                    isOutlined: false,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int count) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.security_rounded, color: Colors.white, size: 40),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count == 1 ? l10n.trustedNumberCount(count) : l10n.trustedNumbersCount(count),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                l10n.onlyTheseNumbers,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.contacts_outlined,
              size: 80,
              color: Colors.grey.shade700,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noTrustedNumbers,
              style: const TextStyle(
                color: null, // Defer to ThemeData
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.addTrustedDesc,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddDialog(context),
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.addFirstNumber),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelp(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.aboutTrustedNumbers),
        content: Text(l10n.aboutTrustedDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.gotIt),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    _NumberDialog.show(context, null);
  }

  void _showEditDialog(BuildContext context, TrustedNumber number) {
    _NumberDialog.show(context, number);
  }

  Future<void> _pickFromContacts(BuildContext context) async {
    try {
      if (await Permission.contacts.request().isGranted) {
        final pickedId = await FlutterContacts.native.showPicker();
        debugPrint('Picker: pickedId=$pickedId');

        if (pickedId != null) {
          final contact = await FlutterContacts.get(
            pickedId,
            properties: {ContactProperty.phone, ContactProperty.name},
          );
          debugPrint('Picker: contact=$contact, phones=${contact?.phones}');

          if (contact != null && contact.phones.isNotEmpty) {
            final rawPhone = contact.phones.first.number;
            final phone = PhoneUtils.normalize(rawPhone);
            final name = (contact.displayName?.isNotEmpty ?? false) ? contact.displayName! : 'Unknown';
            debugPrint('Picker: Raw=$rawPhone, Normalized=$phone, Name=$name');

            if (context.mounted) {
              final provider = context.read<AppProvider>();
              final messenger = ScaffoldMessenger.of(context);

              await provider.addTrustedNumber(name, phone);

              if (provider.errorMessage != null) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('✕ ${provider.errorMessage}'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
                provider.clearError();
              } else {
                messenger.showSnackBar(
                  SnackBar(content: Text('✓ Added $name')),
                );
              }
            }
          } else if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('✕ This contact has no phone number.')),
            );
          }
        }
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✕ Contacts permission denied.')),
        );
      }
    } catch (e) {
      debugPrint('Picker Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✕ Error: $e')),
        );
      }
    }
  }

  void _confirmDelete(
    BuildContext context,
    AppProvider provider,
    TrustedNumber number,
  ) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.removeNumberConfirm),
        content: Text(
          '${l10n.remove} "${number.label}" (${number.phoneNumber}) ${l10n.fromTrustedNumbers}?',
        ),
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
              provider.removeTrustedNumber(number.id);
              Navigator.pop(ctx);
            },
            child: Text(l10n.remove),
          ),
        ],
      ),
    );
  }
}

// ─── Shared Components ────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isOutlined;

  const _ActionButton({
    required this.icon,
    required this.onTap,
    required this.isOutlined,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return SizedBox(
        width: 56,
        height: 56,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primary,
            side: const BorderSide(color: AppTheme.primary, width: 2),
            shape: const CircleBorder(),
            padding: EdgeInsets.zero,
          ),
          child: Icon(icon, size: 26),
        ),
      );
    }

    return SizedBox(
      width: 56,
      height: 56,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
          elevation: 2,
        ),
        child: Icon(icon, size: 26),
      ),
    );
  }
}

// ─── Tile ─────────────────────────────────────────────────────────────────────

class _NumberTile extends StatelessWidget {
  final TrustedNumber number;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _NumberTile({
    required this.number,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number.label.isNotEmpty ? number.label[0].toUpperCase() : '?',
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
        ),
        title: Text(
          number.label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          number.phoneNumber,
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_rounded, size: 20),
              color: AppTheme.primary,
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              color: Theme.of(context).colorScheme.error,
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Add/Edit Dialog ─────────────────────────────────────────────────────────

class _NumberDialog extends StatefulWidget {
  final TrustedNumber? existing;

  const _NumberDialog({this.existing});

  static void show(BuildContext context, TrustedNumber? existing) {
    showDialog(
      context: context,
      builder: (ctx) => _NumberDialog(existing: existing),
    );
  }

  @override
  State<_NumberDialog> createState() => _NumberDialogState();
}

class _NumberDialogState extends State<_NumberDialog> {
  late final TextEditingController _labelCtrl;
  late final TextEditingController _phoneCtrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController(text: widget.existing?.label ?? '');
    _phoneCtrl = TextEditingController(
      text: widget.existing?.phoneNumber ?? '',
    );
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final label = _labelCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    if (label.isEmpty) {
      setState(() => _error = 'Label is required');
      return;
    }
    if (!PhoneUtils.isValid(phone)) {
      setState(() => _error = 'Invalid phone number format');
      return;
    }

    final provider = context.read<AppProvider>();
    if (widget.existing == null) {
      await provider.addTrustedNumber(label, phone);
    } else {
      await provider.updateTrustedNumber(
        widget.existing!.copyWith(
          label: label,
          phoneNumber: PhoneUtils.normalize(phone),
        ),
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existing == null ? 'Add Trusted Number' : 'Edit Number',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _labelCtrl,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            decoration: const InputDecoration(
              labelText: 'Label (e.g. Wife, Brother)',
              prefixIcon: Icon(Icons.label_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: 'Phone Number',
              hintText: '+919876543210',
              prefixIcon: const Icon(Icons.phone_rounded),
              suffixIcon: IconButton(
                icon: const Icon(Icons.contact_page_rounded, color: AppTheme.primary),
                onPressed: () async {
                  try {
                    if (await Permission.contacts.request().isGranted) {
                      final pickedId = await FlutterContacts.native.showPicker();
                      if (pickedId == null) return;
                      final contact = await FlutterContacts.get(
                        pickedId!,
                        properties: {ContactProperty.phone, ContactProperty.name},
                      );
                      if (!mounted) return;
                      if (contact != null && contact.phones.isNotEmpty) {
                        setState(() {
                          _phoneCtrl.text = PhoneUtils.normalize(contact.phones.first.number);
                          if (_labelCtrl.text.isEmpty) {
                            _labelCtrl.text = (contact.displayName?.isNotEmpty ?? false) ? contact.displayName! : 'Unknown';
                          }
                        });
                      }
                    }
                  } catch (e) {
                    debugPrint('Contact pick internal error: $e');
                  }
                },
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: Text(widget.existing == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }
}
