import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/phone_utils.dart';
import '../../domain/models/trusted_number.dart';

/// Manages trusted phone numbers that can send recovery commands
class TrustedNumbersScreen extends StatelessWidget {
  const TrustedNumbersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trusted Numbers'),
        leading: const BackButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: () => _showHelp(context),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final numbers = provider.trustedNumbers;
          return Column(
            children: [
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _showAddDialog(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Add Number',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int count) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
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
                '$count Trusted ${count == 1 ? 'Number' : 'Numbers'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Text(
                'Only these numbers can send commands',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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
            const Text(
              'No trusted numbers yet',
              style: TextStyle(
                color: null, // Defer to ThemeData
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add at least one trusted number\nto enable remote recovery',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddDialog(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add First Number'),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('About Trusted Numbers'),
        content: const Text(
          'Only SMS messages from trusted numbers will be processed as recovery commands.\n\n'
          'Make sure to add numbers in international format (e.g. +919876543210).\n\n'
          'Messages from all other numbers are silently ignored.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
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

  void _confirmDelete(
    BuildContext context,
    AppProvider provider,
    TrustedNumber number,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Number?'),
        content: Text(
          'Remove "${number.label}" (${number.phoneNumber}) from trusted numbers?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              provider.removeTrustedNumber(number.id);
              Navigator.pop(ctx);
            },
            child: const Text('Remove'),
          ),
        ],
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
            color: AppTheme.primary.withValues(alpha: 0.15),
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
      setState(() => _error = 'Invalid phone number (use +country code)');
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
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              hintText: '+919876543210',
              prefixIcon: Icon(Icons.phone_rounded),
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
