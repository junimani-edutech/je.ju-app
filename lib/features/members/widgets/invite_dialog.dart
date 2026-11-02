import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../invitation.dart';
import '../members_providers.dart';

class InviteDialog extends ConsumerStatefulWidget {
  const InviteDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => const InviteDialog(),
    );
  }

  @override
  ConsumerState<InviteDialog> createState() => _InviteDialogState();
}

class _InviteDialogState extends ConsumerState<InviteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  String _role = 'cashier';
  bool _loading = false;
  String? _error;
  CreatedInvitation? _created;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  List<String> _availableRoles(String? callerRole) {
    if (callerRole == 'admin') {
      return const ['cashier', 'order_staff', 'viewer'];
    }
    return const ['admin', 'cashier', 'order_staff', 'viewer'];
  }

  String _roleLabel(String r) {
    switch (r) {
      case 'owner':
        return 'Pemilik';
      case 'admin':
        return 'Admin';
      case 'cashier':
        return 'Kasir';
      case 'order_staff':
        return 'Staf Pesanan';
      case 'viewer':
        return 'Viewer';
      default:
        return r;
    }
  }

  String get _acceptUrl {
    final origin = kIsWeb ? Uri.base.origin : '';
    return '$origin/accept-invite?token=${_created?.token ?? ''}';
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _acceptUrl));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link disalin ke clipboard.')),
      );
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final created = await ref
          .read(membersControllerProvider)
          .createInvitation(email: _emailCtrl.text.trim(), role: _role);
      if (mounted) setState(() => _created = created);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final callerRole = ref.watch(currentMemberProvider).value?.role;

    if (callerRole != 'owner' && callerRole != 'admin') {
      return AlertDialog(
        title: const Text('Tidak diizinkan'),
        content: const Text(
          'Hanya pemilik atau admin yang dapat mengundang anggota baru.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Tutup'),
          ),
        ],
      );
    }

    if (_created != null) {
      return AlertDialog(
        title: const Text('Undangan dibuat'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Bagikan link berikut ke ${_emailCtrl.text.trim()}:'),
              const SizedBox(height: 8),
              SelectableText(
                _acceptUrl,
                key: const Key('invite_link_text'),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Link berlaku hingga '
                '${_created!.expiresAt.toIso8601String().substring(0, 10)}.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Tutup'),
          ),
          FilledButton.icon(
            key: const Key('invite_copy_button'),
            onPressed: _copy,
            icon: const Icon(Icons.copy),
            label: const Text('Salin Link'),
          ),
        ],
      );
    }

    final availRoles = _availableRoles(callerRole);
    final effectiveRole = availRoles.contains(_role) ? _role : availRoles.first;

    return AlertDialog(
      title: const Text('Undang Anggota'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const Key('invite_email'),
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email *'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  final t = (v ?? '').trim();
                  if (t.isEmpty) return 'Email wajib';
                  if (!t.contains('@')) return 'Email tidak valid';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: const Key('invite_role'),
                initialValue: effectiveRole,
                decoration: const InputDecoration(labelText: 'Peran'),
                items: [
                  for (final r in availRoles)
                    DropdownMenuItem(value: r, child: Text(_roleLabel(r))),
                ],
                onChanged: (v) => setState(() => _role = v ?? effectiveRole),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(
          key: const Key('invite_submit'),
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Undang'),
        ),
      ],
    );
  }
}
