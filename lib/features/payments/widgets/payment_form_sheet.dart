import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../orders/order.dart';
import '../payment.dart';
import '../payments_providers.dart';

class PaymentFormSheet extends ConsumerStatefulWidget {
  const PaymentFormSheet({super.key, required this.order});
  final Order order;

  static Future<bool?> show(BuildContext context, {required Order order}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => PaymentFormSheet(order: order),
    );
  }

  @override
  ConsumerState<PaymentFormSheet> createState() => _PaymentFormSheetState();
}

class _PaymentFormSheetState extends ConsumerState<PaymentFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountCtrl;
  final _refCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _methodId;
  String? _accountId;
  bool _loading = false;
  String? _error;

  int get _remaining {
    final r = widget.order.totalAmount - widget.order.paidAmount;
    return r < 0 ? 0 : r;
  }

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(text: _remaining.toString());
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _refCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
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
          .read(paymentsControllerProvider)
          .record(
            orderId: widget.order.id,
            amount: amount,
            paymentMethodId: _methodId,
            accountId: _accountId,
            reference: _refCtrl.text.trim().isEmpty
                ? null
                : _refCtrl.text.trim(),
            notes: _notesCtrl.text.trim().isEmpty
                ? null
                : _notesCtrl.text.trim(),
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
    final methodsAsync = ref.watch(paymentMethodsProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final methods = methodsAsync.value ?? const <PaymentMethod>[];
    final accounts = accountsAsync.value ?? const <Account>[];

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
              Text('Catat Pembayaran', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Sisa tagihan: $_remaining',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('payment_form_amount'),
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
              DropdownButtonFormField<String?>(
                key: const Key('payment_form_method'),
                initialValue: _methodId,
                decoration: const InputDecoration(labelText: 'Metode'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('— Tanpa metode —'),
                  ),
                  for (final m in methods)
                    DropdownMenuItem<String?>(value: m.id, child: Text(m.name)),
                ],
                onChanged: (v) => setState(() => _methodId = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                key: const Key('payment_form_account'),
                initialValue: _accountId,
                decoration: const InputDecoration(labelText: 'Akun tujuan'),
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
              TextFormField(
                key: const Key('payment_form_reference'),
                controller: _refCtrl,
                decoration: const InputDecoration(labelText: 'Referensi'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('payment_form_notes'),
                controller: _notesCtrl,
                decoration: const InputDecoration(labelText: 'Catatan'),
                maxLines: 2,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('payment_form_submit'),
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Simpan Pembayaran'),
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
