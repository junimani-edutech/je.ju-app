import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../payments/payment.dart' show Account;
import '../category.dart';
import '../finance_providers.dart';

class TransactionFormSheet extends ConsumerStatefulWidget {
  const TransactionFormSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const TransactionFormSheet(),
    );
  }

  @override
  ConsumerState<TransactionFormSheet> createState() =>
      _TransactionFormSheetState();
}

class _TransactionFormSheetState extends ConsumerState<TransactionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  String _type = 'income';
  String? _categoryId;
  String? _accountId;
  DateTime _date = DateTime.now();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _refCtrl.dispose();
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
          .read(transactionsProvider.notifier)
          .record(
            type: _type,
            amount: amount,
            description: _descCtrl.text.trim(),
            categoryId: _categoryId,
            accountId: _accountId,
            transactionDate: _date,
            reference: _refCtrl.text.trim().isEmpty
                ? null
                : _refCtrl.text.trim(),
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
    final categoriesAll =
        ref.watch(financeCategoriesProvider).value ?? const <Category>[];
    final filtered = categoriesAll.where((c) => c.type == _type).toList();
    final accounts =
        ref.watch(financeAccountsProvider).value ?? const <Account>[];

    // Reset _categoryId jika tidak cocok dengan tipe baru.
    if (_categoryId != null && !filtered.any((c) => c.id == _categoryId)) {
      _categoryId = null;
    }

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
              Text('Catat Transaksi', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                key: const Key('tx_form_type'),
                segments: const [
                  ButtonSegment(
                    value: 'income',
                    label: Text('Masuk'),
                    icon: Icon(Icons.trending_up),
                  ),
                  ButtonSegment(
                    value: 'expense',
                    label: Text('Keluar'),
                    icon: Icon(Icons.trending_down),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (s) {
                  setState(() {
                    _type = s.first;
                    _categoryId = null;
                  });
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('tx_form_amount'),
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
              TextFormField(
                key: const Key('tx_form_description'),
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Deskripsi *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Deskripsi wajib' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                key: const Key('tx_form_category'),
                initialValue: _categoryId,
                decoration: const InputDecoration(labelText: 'Kategori'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('— Tanpa kategori —'),
                  ),
                  for (final c in filtered)
                    DropdownMenuItem<String?>(value: c.id, child: Text(c.name)),
                ],
                onChanged: (v) => setState(() => _categoryId = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                key: const Key('tx_form_account'),
                initialValue: _accountId,
                decoration: const InputDecoration(labelText: 'Akun'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('— Tanpa akun —'),
                  ),
                  for (final a in accounts)
                    DropdownMenuItem<String?>(value: a.id, child: Text(a.name)),
                ],
                onChanged: (v) => setState(() => _accountId = v),
              ),
              const SizedBox(height: 12),
              InkWell(
                key: const Key('tx_form_date'),
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Tanggal'),
                  child: Text(dateStr),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('tx_form_reference'),
                controller: _refCtrl,
                decoration: const InputDecoration(labelText: 'Referensi'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('tx_form_submit'),
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
