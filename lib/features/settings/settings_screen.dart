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
    setState(() { _saving = true; _error = null; _success = null; });
    try {
      await ref.read(businessServiceProvider).updateProfile(
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
    final theme = Theme.of(context);
    final bizAsync = ref.watch(currentBusinessProvider);
    final member = ref.watch(currentMemberProvider).value;
    final canEdit = member != null && (member.role == 'owner' || member.role == 'admin');

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan Toko', style: TextStyle(fontWeight: FontWeight.bold))),
      body: bizAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Gagal memuat bisnis: $e'))),
        data: (biz) {
          if (biz == null) return const Center(child: Text('Belum ada bisnis aktif.'));
          _seedFrom(biz);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profil Outlet Card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Profil Usaha', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nameCtrl,
                            enabled: canEdit,
                            decoration: InputDecoration(labelText: 'Nama usaha *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _phoneCtrl,
                            enabled: canEdit,
                            decoration: InputDecoration(labelText: 'Telepon', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _addressCtrl,
                            enabled: canEdit,
                            decoration: InputDecoration(labelText: 'Alamat Lengkap', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), alignLabelWithHint: true),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_error != null) ...[
                    Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.error)),
                    const SizedBox(height: 12),
                  ],
                  if (_success != null) ...[
                    Text(_success!, textAlign: TextAlign.center, style: TextStyle(color: Colors.green)),
                    const SizedBox(height: 12),
                  ],
                  if (canEdit)
                    FilledButton.icon(
                      onPressed: _saving ? null : () => _save(biz),
                      icon: const Icon(Icons.save),
                      label: Text(_saving ? 'Menyimpan...' : 'Simpan Profil'),
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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
