import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../customers/customer.dart';
import '../../customers/customers_providers.dart';
import '../order.dart';
import '../orders_providers.dart';
import 'product_picker.dart';

class OrderFormSheet extends ConsumerStatefulWidget {
  const OrderFormSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const OrderFormSheet(),
    );
  }

  @override
  ConsumerState<OrderFormSheet> createState() => _OrderFormSheetState();
}

class _ItemRow {
  _ItemRow()
    : descCtrl = TextEditingController(),
      qtyCtrl = TextEditingController(text: '1'),
      priceCtrl = TextEditingController(text: '0');

  String? productId;

  final TextEditingController descCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController priceCtrl;

  void dispose() {
    descCtrl.dispose();
    qtyCtrl.dispose();
    priceCtrl.dispose();
  }

  double get qty => double.tryParse(qtyCtrl.text.replaceAll(',', '.')) ?? 0;
  int get price => int.tryParse(priceCtrl.text) ?? 0;
  int get lineTotal => (qty * price).round();
}

class _OrderFormSheetState extends ConsumerState<OrderFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _notesCtrl = TextEditingController();
  final _discountCtrl = TextEditingController(text: '0');
  final _feeCtrl = TextEditingController(text: '0');
  final _shippingCtrl = TextEditingController(text: '0');
  final List<_ItemRow> _items = [_ItemRow()];
  
  String? _customerId;
  DateTime? _dueDate; // ✅ State untuk menyimpan tanggal deadline
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _notesCtrl.dispose();
    _discountCtrl.dispose();
    _feeCtrl.dispose();
    _shippingCtrl.dispose();
    for (final r in _items) {
      r.dispose();
    }
    super.dispose();
  }

  int _intOrZero(TextEditingController c) => int.tryParse(c.text.trim()) ?? 0;

  int get _subtotal => _items.fold(0, (acc, r) => acc + r.lineTotal);
  int get _total =>
      _subtotal -
      _intOrZero(_discountCtrl) +
      _intOrZero(_feeCtrl) +
      _intOrZero(_shippingCtrl);

  void _addItem() {
    setState(() => _items.add(_ItemRow()));
    _wireListeners(_items.last);
  }

  void _removeItem(int i) {
    if (_items.length == 1) return;
    setState(() {
      _items[i].dispose();
      _items.removeAt(i);
    });
  }

  void _wireListeners(_ItemRow r) {
    r.qtyCtrl.addListener(_recalc);
    r.priceCtrl.addListener(_recalc);
  }

  void _recalc() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _wireListeners(_items.first);
    for (final c in [_discountCtrl, _feeCtrl, _shippingCtrl]) {
      c.addListener(_recalc);
    }
  }

  // ✅ FUNGSI BARU: Menampilkan Date & Time Picker
  Future<void> _pickDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Pilih Tanggal Pengiriman',
    );
    if (date != null) {
      if (!mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_dueDate ?? DateTime.now()),
        helpText: 'Pilih Waktu Pengiriman',
      );
      if (time != null) {
        setState(() {
          _dueDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_items.isEmpty) {
      setState(() => _error = 'Minimal 1 item.');
      return;
    }

    final inputs = <OrderItemInput>[];
    for (var i = 0; i < _items.length; i++) {
      final r = _items[i];
      if (r.descCtrl.text.trim().isEmpty) {
        setState(() => _error = 'Item #${i + 1}: deskripsi wajib.');
        return;
      }
      if (r.qty <= 0) {
        setState(() => _error = 'Item #${i + 1}: kuantitas harus > 0.');
        return;
      }
      if (r.price < 0) {
        setState(() => _error = 'Item #${i + 1}: harga tidak boleh negatif.');
        return;
      }
      inputs.add(
        OrderItemInput(
          description: r.descCtrl.text.trim(),
          quantity: r.qty,
          unitPrice: r.price,
        ),
      );
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(ordersProvider.notifier)
          .create(
            items: inputs,
            customerId: _customerId,
            notes: _notesCtrl.text.trim().isEmpty
                ? null
                : _notesCtrl.text.trim(),
            discountAmount: _intOrZero(_discountCtrl),
            additionalFeeAmount: _intOrZero(_feeCtrl),
            shippingAmount: _intOrZero(_shippingCtrl),
            dueDate: _dueDate, // ✅ Kirim dueDate ke provider
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
    final customersAsync = ref.watch(activeCustomersProvider);
    final customers = customersAsync.value ?? const <Customer>[];

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
              Text('Buat Pesanan', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                key: const Key('order_form_customer'),
                initialValue: _customerId,
                decoration: const InputDecoration(labelText: 'Pelanggan'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('— Tanpa pelanggan —'),
                  ),
                  for (final c in customers)
                    DropdownMenuItem<String?>(value: c.id, child: Text(c.name)),
                ],
                onChanged: (v) => setState(() => _customerId = v),
              ),
              const SizedBox(height: 12),
              Text('Item', style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              for (var i = 0; i < _items.length; i++) _buildItemRow(i),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const Key('order_form_add_item'),
                  onPressed: _addItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Item'),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _numField(
                      key: const Key('order_form_discount'),
                      ctrl: _discountCtrl,
                      label: 'Diskon',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _numField(
                      key: const Key('order_form_fee'),
                      ctrl: _feeCtrl,
                      label: 'Biaya tambahan',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _numField(
                key: const Key('order_form_shipping'),
                ctrl: _shippingCtrl,
                label: 'Ongkir',
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('order_form_notes'),
                controller: _notesCtrl,
                decoration: const InputDecoration(labelText: 'Catatan'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              
              // ✅ UI BARU: Input Tanggal & Waktu Pengiriman
              InkWell(
                onTap: _pickDueDate,
                borderRadius: BorderRadius.circular(8),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Tanggal & Waktu Pengiriman (Opsional)',
                    suffixIcon: Icon(Icons.event),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _dueDate == null
                        ? 'Pilih tanggal dan waktu'
                        : '${_dueDate!.day.toString().padLeft(2, '0')}/${_dueDate!.month.toString().padLeft(2, '0')}/${_dueDate!.year}  ${_dueDate!.hour.toString().padLeft(2, '0')}:${_dueDate!.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: _dueDate == null ? Colors.grey : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              _summaryRow('Subtotal', _subtotal),
              _summaryRow('Diskon', -_intOrZero(_discountCtrl)),
              _summaryRow('Biaya tambahan', _intOrZero(_feeCtrl)),
              _summaryRow('Ongkir', _intOrZero(_shippingCtrl)),
              const Divider(),
              _summaryRow('Total', _total, bold: true),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('order_form_submit'),
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Buat Pesanan'),
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

  Widget _buildItemRow(int i) {
    final r = _items[i];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: TextFormField(
              key: Key('order_form_item_desc_$i'),
              controller: r.descCtrl,
              decoration: InputDecoration(
                labelText: 'Deskripsi #${i + 1}',
                isDense: true,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.inventory_2_outlined, size: 20),
                  tooltip: 'Pilih Produk',
                  onPressed: () async {
                    final p = await ProductPicker.show(context);
                    if (p != null) {
                      setState(() {
                        r.productId = p.id;
                        r.descCtrl.text = p.name;
                        r.priceCtrl.text = p.price.toString();
                      });
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 60,
            child: TextFormField(
              key: Key('order_form_item_qty_$i'),
              controller: r.qtyCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Qty',
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 90,
            child: TextFormField(
              key: Key('order_form_item_price_$i'),
              controller: r.priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Harga',
                isDense: true,
              ),
            ),
          ),
          IconButton(
            key: Key('order_form_item_remove_$i'),
            tooltip: 'Hapus item',
            onPressed: _items.length == 1 ? null : () => _removeItem(i),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }

  Widget _numField({
    required Key key,
    required TextEditingController ctrl,
    required String label,
  }) {
    return TextFormField(
      key: key,
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget _summaryRow(String label, int value, {bool bold = false}) {
    final style = bold
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value.toString(), style: style),
        ],
      ),
    );
  }
}
