import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../inventory_item.dart';
import '../inventory_providers.dart';

class InventoryFormSheet extends ConsumerStatefulWidget {
  final InventoryItem? initial;
  const InventoryFormSheet({super.key, this.initial});

  static Future<void> show(BuildContext context, {InventoryItem? initial}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => InventoryFormSheet(initial: initial),
    );
  }

  @override
  ConsumerState<InventoryFormSheet> createState() => _InventoryFormSheetState();
}

class _InventoryFormSheetState extends ConsumerState<InventoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _stockCtrl;
  late TextEditingController _minStockCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _notesCtrl;

  String? _category;
  String _unit = 'Pcs';
  bool _loading = false;

  final _categories = ['Deterjen', 'Pewangi', 'Pembersih', 'Plastik', 'Lainnya'];
  final _units = ['Liter', 'Kg', 'Gram', 'Pcs', 'Lusin', 'Pack'];

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _nameCtrl = TextEditingController(text: i?.name ?? '');
    _stockCtrl = TextEditingController(text: i?.currentStock.toString() ?? '0');
    _minStockCtrl = TextEditingController(text: i?.minStock.toString() ?? '0');
    _priceCtrl = TextEditingController(text: i?.pricePerUnit.toString() ?? '0');
    _notesCtrl = TextEditingController();
    _category = i?.category ?? 'Deterjen';
    _unit = i?.unit ?? 'Pcs';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _stockCtrl.dispose();
    _minStockCtrl.dispose();
    _priceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final item = InventoryItem(
        id: widget.initial?.id ?? '',
        businessId: '', // Akan diisi oleh provider
        name: _nameCtrl.text.trim(),
        category: _category,
        unit: _unit,
        currentStock: double.tryParse(_stockCtrl.text) ?? 0,
        minStock: double.tryParse(_minStockCtrl.text) ?? 0,
        pricePerUnit: int.tryParse(_priceCtrl.text) ?? 0,
      );

      await ref.read(inventoryNotifierProvider.notifier).save(item);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item inventaris berhasil disimpan'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16, right: 16, top: 16,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.initial == null ? 'Tambah Item Inventaris' : 'Ubah Item', 
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nama Item *', border: OutlineInputBorder(), hintText: 'Contoh: Deterjen Rinso'),
                validator: (v) => v!.trim().isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              
              Text('Kategori', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _categories.map((c) => ChoiceChip(
                  label: Text(c),
                  selected: _category == c,
                  onSelected: (v) => setState(() => _category = v ? c : null),
                )).toList(),
              ),
              const SizedBox(height: 16),

              Text('Satuan', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _units.map((u) => ChoiceChip(
                  label: Text(u),
                  selected: _unit == u,
                  onSelected: (v) => setState(() => _unit = u),
                )).toList(),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(child: TextFormField(
                    controller: _stockCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Stok Saat Ini', border: OutlineInputBorder()),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(
                    controller: _minStockCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Stok Minimum', border: OutlineInputBorder()),
                  )),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Harga per Satuan (Rp)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Catatan (Opsional)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),

              FilledButton(
                onPressed: _loading ? null : _submit,
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _loading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Simpan Item'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
