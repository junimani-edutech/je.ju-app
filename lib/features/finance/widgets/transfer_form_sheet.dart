import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../payments/payment.dart' show Account;
import '../finance_providers.dart';

class TransferFormSheet extends ConsumerStatefulWidget {
  const TransferFormSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const TransferFormSheet(),
    );
  }

  @override
  ConsumerState<TransferFormSheet> createState() => _TransferFormSheetState();
}

class _TransferFormSheetState extends ConsumerState<TransferFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _fromId;
  String? _toId;
  DateTime _date = DateTime.now();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_fromId == null || _toId == null) {
      setState(() => _error = 'Pilih akun asal dan tujuan.');
      return;
    }
    if (_fromId == _toId) {
      setState(() => _error = 'Akun asal dan tujuan harus berbeda.');
      return;
    }
    final amount = int.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (amount <= 0) {
      setState(() => _error = 'Nominal harus > 0.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(transfersProvider.notifier)
          .record(
            fromAccountId: _fromId!,
            toAccountId: _toId!,
            amount: amount,
            transferDate: _date,
            description: _descCtrl.text.trim().isEmpty
                ? null
                : _descCtrl.text.trim(),
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accounts =
        ref.watch(financeAccountsProvider).value ?? const <Account>[];
    final dateStr =
        '${_date.year}-'
        '${_date.month.toString().padLeft(2, '0')}-'
        '${_date.day.toString().padLeft(2, '0')}';

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Catat Transfer', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                key: const Key('transfer_form_from'),
                initialValue: _fromId,
                decoration: const InputDecoration(labelText: 'Dari akun *'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('— Pilih —'),
                  ),
                  for (final a in accounts)
                    DropdownMenuItem<String?>(value: a.id, child: Text(a.name)),
                ],
                onChanged: (v) => setState(() => _fromId = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                key: const Key('transfer_form_to'),
                initialValue: _toId,
                decoration: const InputDecoration(labelText: 'Ke akun *'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('— Pilih —'),
                  ),
                  for (final a in accounts)
                    if (a.id != _fromId)
                      DropdownMenuItem<String?>(
                        value: a.id,
                        child: Text(a.name),
                      ),
                ],
                onChanged: (v) => setState(() => _toId = v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('transfer_form_amount'),
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Nominal *'),
                validator: (v) {
                  final n = int.tryParse((v ?? '').trim());
                  if (n == null || n <= 0) return 'Nominal harus > 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              InkWell(
                key: const Key('transfer_form_date'),
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Tanggal'),
                  child: Text(dateStr),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('transfer_form_desc'),
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
                maxLines: 2,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('transfer_form_submit'),
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Simpan'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _loading ? null : () => Navigator.of(context).pop(),
                child: const Text('Batal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
