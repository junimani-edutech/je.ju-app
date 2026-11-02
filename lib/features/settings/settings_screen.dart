import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/business.dart';
import '../../core/providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _legalNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _timezoneCtrl = TextEditingController();

  bool _seeded = false;
  bool _saving = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _legalNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _timezoneCtrl.dispose();
    super.dispose();
  }

  void _seedFrom(Business b) {
    if (_seeded) return;
    _seeded = true;
    _nameCtrl.text = b.name;
    _legalNameCtrl.text = b.legalName ?? '';
    _emailCtrl.text = b.contactEmail ?? '';
    _phoneCtrl.text = b.contactPhone ?? '';
    _addressCtrl.text = b.address ?? '';
    _timezoneCtrl.text = b.timezone;
  }

  String? _blankToNull(String s) {
    final t = s.trim();
    return t.isEmpty ? null : t;
  }

  Future<void> _save(Business b) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
      _success = null;
    });
    try {
      await ref
          .read(businessServiceProvider)
          .updateProfile(
            businessId: b.id,
            name: _nameCtrl.text.trim(),
            legalName: _blankToNull(_legalNameCtrl.text),
            contactEmail: _blankToNull(_emailCtrl.text),
            contactPhone: _blankToNull(_phoneCtrl.text),
            address: _blankToNull(_addressCtrl.text),
            timezone: _timezoneCtrl.text.trim(),
          );
      ref.invalidate(currentBusinessProvider);
      if (mounted) setState(() => _success = 'Profil tersimpan.');
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final bizAsync = ref.watch(currentBusinessProvider);
    final member = ref.watch(currentMemberProvider).value;
    final canEdit =
        member != null && (member.role == 'owner' || member.role == 'admin');
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: bizAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Gagal memuat bisnis: $e'),
          ),
        ),
        data: (biz) {
          if (biz == null) {
            return const Center(child: Text('Belum ada bisnis aktif.'));
          }
          _seedFrom(biz);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (user != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.person_outline),
                      title: Text(user.email),
                      subtitle: const Text('Akun aktif'),
                    ),
                  const Divider(),
                  Text('Profil Usaha', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  TextFormField(
                    key: const Key('settings_name'),
                    controller: _nameCtrl,
                    enabled: canEdit,
                    decoration: const InputDecoration(
                      labelText: 'Nama usaha *',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Nama wajib' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('settings_legal_name'),
                    controller: _legalNameCtrl,
                    enabled: canEdit,
                    decoration: const InputDecoration(labelText: 'Nama legal'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('settings_email'),
                    controller: _emailCtrl,
                    enabled: canEdit,
                    decoration: const InputDecoration(
                      labelText: 'Email kontak',
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('settings_phone'),
                    controller: _phoneCtrl,
                    enabled: canEdit,
                    decoration: const InputDecoration(labelText: 'Telepon'),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('settings_address'),
                    controller: _addressCtrl,
                    enabled: canEdit,
                    decoration: const InputDecoration(labelText: 'Alamat'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('settings_timezone'),
                    controller: _timezoneCtrl,
                    enabled: canEdit,
                    decoration: const InputDecoration(
                      labelText: 'Zona waktu *',
                      hintText: 'Asia/Jakarta',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Zona waktu wajib'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  InputDecorator(
                    decoration: const InputDecoration(labelText: 'Mata uang'),
                    child: Text('${biz.currency} (tidak dapat diubah)'),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                  if (_success != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _success!,
                      style: TextStyle(color: theme.colorScheme.primary),
                    ),
                  ],
                  if (canEdit) ...[
                    const SizedBox(height: 16),
                    FilledButton(
                      key: const Key('settings_save'),
                      onPressed: _saving ? null : () => _save(biz),
                      child: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Simpan'),
                    ),
                  ],
                  const Divider(height: 32),
                  const ListTile(
                    leading: Icon(Icons.palette_outlined),
                    title: Text('Tema'),
                    subtitle: Text(
                      'Mengikuti sistem; toggle manual di Fase 7+',
                    ),
                    enabled: false,
                  ),
                  const Divider(),
                  ListTile(
                    key: const Key('settings_sign_out'),
                    leading: const Icon(Icons.logout),
                    title: const Text('Keluar'),
                    onTap: () async {
                      await ref.read(authServiceProvider).signOut();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
