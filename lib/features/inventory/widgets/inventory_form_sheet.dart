import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../inventory_categories_providers.dart';
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

  String? _categoryId;
  String _unit = 'Pcs';
  bool _loading = false;

  final _units = ['Liter', 'Kg', 'Gram', 'Pcs', 'Lusin', 'Pack'];

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _nameCtrl = TextEditingController(text: i?.name ?? '');
    _stockCtrl = TextEditingController(text: i?.currentStock.toString() ?? '0');
    _minStockCtrl = TextEditingController(text: i?.minStock.toString() ?? '0');
    _priceCtrl = TextEditingController(text: i?.pricePerUnit.toString() ?? '0');
    _notesCtrl = TextEditingController();
    _categoryId = i?.categoryId;
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

  Future<void> _addCategoryInline() async {
    final nameCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool loading = false;
    String? error;

    await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Kategori Baru'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Nama Kategori *',
                    hintText: 'Misal: Pelembut',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: loading ? null : () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: loading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setState(() => loading = true);
                      try {
                        await ref.read(inventoryCategoriesNotifierProvider.notifier).create(nameCtrl.text.trim());
                        // Ambil kategori terbaru untuk auto-select
                        final cats = await ref.read(inventoryCategoriesProvider.future);
                        final newCat = cats.firstWhere((c) => c.name == nameCtrl.text.trim());
                        if (mounted) setState(() => _categoryId = newCat.id);
                        if (ctx.mounted) Navigator.pop(ctx, true);
                      } catch (e) {
                        setState(() {
                          error = e.toString().replaceFirst('Exception: ', '');
                          loading = false;
                        });
                      }
                    },
              child: loading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Tambah'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final cats = await ref.read(inventoryCategoriesProvider.future);
      final selectedCat = cats.where((c) => c.id == _categoryId).firstOrNull;

      final item = InventoryItem(
        id: widget.initial?.id ?? '',
        businessId: '',
        name: _nameCtrl.text.trim(),
        category: selectedCat?.name,
        categoryId: _categoryId,
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
    final categoriesAsync = ref.watch(inventoryCategoriesProvider);

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
              Text(
                _isEdit ? 'Ubah Item' : 'Tambah Item Inventaris',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama Item *',
                  border: OutlineInputBorder(),
                  hintText: 'Contoh: Deterjen Rinso',
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              // Kategori Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Kategori', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: _addCategoryInline,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Kategori Baru', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              categoriesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                error: (e, _) => Text('Gagal memuat kategori: $e', style: const TextStyle(color: Colors.red, fontSize: 12)),
                data: (list) {
                  if (list.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.orange),
                          SizedBox(width: 8),
                          Expanded(child: Text('Belum ada kategori. Klik "Kategori Baru" untuk menambahkan.', style: TextStyle(fontSize: 12))),
                        ],
                      ),
                    );
                  }
                  return Wrap(
                    spacing: 8, runSpacing: 8,
                    children: list.map((c) {
                      final isSelected = _categoryId == c.id;
                      return ChoiceChip(
                        label: Text(c.name),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _categoryId = isSelected ? null : c.id),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Satuan Section
              Text('Satuan', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _units.map((u) => ChoiceChip(
                  label: Text(u),
                  selected: _unit == u,
                  onSelected: (_) => setState(() => _unit = u),
                )).toList(),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stockCtrl,
                      enabled: !_isEdit,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: _isEdit ? 'Stok (via Movement)' : 'Stok Awal',
                        border: const OutlineInputBorder(),
                        helperText: _isEdit ? 'Ubah via Pergerakan Stok' : null,
                        helperStyle: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _minStockCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Stok Minimum',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Harga per Satuan (Rp)',
                  border: OutlineInputBorder(),
                  prefixText: 'Rp ',
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Catatan (Opsional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              FilledButton(
                onPressed: _loading ? null : _submit,
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_isEdit ? 'Simpan Perubahan' : 'Simpan Item', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
