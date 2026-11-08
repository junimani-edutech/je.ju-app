import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../product.dart';
import '../product_categories_providers.dart';
import '../products_providers.dart';

class ProductFormSheet extends ConsumerStatefulWidget {
  const ProductFormSheet({super.key, this.initial});
  final Product? initial;

  static Future<bool?> show(BuildContext context, {Product? initial}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ProductFormSheet(initial: initial),
    );
  }

  @override
  ConsumerState<ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends ConsumerState<ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nameCtrl = TextEditingController(text: widget.initial?.name ?? '');
  late final _priceCtrl = TextEditingController(text: widget.initial?.price.toString() ?? '');
  late final _descCtrl = TextEditingController(text: widget.initial?.description ?? '');
  String? _categoryId;
  bool _loading = false;
  String? _error;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.initial?.categoryId;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
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
                    hintText: 'Misal: Pempek, Minuman',
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
                        await ref.read(productCategoriesNotifierProvider.notifier).create(nameCtrl.text.trim());
                        final cats = await ref.read(productCategoriesProvider.future);
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
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final price = int.tryParse(_priceCtrl.text.trim()) ?? 0;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cats = await ref.read(productCategoriesProvider.future);
      final selectedCat = cats.where((c) => c.id == _categoryId).firstOrNull;
      final notifier = ref.read(productsProvider.notifier);

      if (_isEdit) {
        await notifier.updateProduct(
          id: widget.initial!.id,
          name: _nameCtrl.text.trim(),
          price: price,
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          category: selectedCat?.name,
          categoryId: _categoryId,
        );
      } else {
        await notifier.create(
          name: _nameCtrl.text.trim(),
          price: price,
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          category: selectedCat?.name,
          categoryId: _categoryId,
        );
      }
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
    final categoriesAsync = ref.watch(productCategoriesProvider);

    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_isEdit ? 'Ubah Produk' : 'Tambah Produk',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Nama Produk / Jasa *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                error: (e, _) => Text('Gagal memuat kategori: $e',
                    style: const TextStyle(color: Colors.red, fontSize: 12)),
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
                          Expanded(
                            child: Text('Belum ada kategori. Klik "Kategori Baru" untuk menambahkan.',
                                style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    );
                  }
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
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

              TextFormField(
                controller: _priceCtrl,
                decoration: InputDecoration(
                  labelText: 'Harga (Rp) *',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse((v ?? '').trim());
                  if (n == null || n < 0) return 'Harga tidak valid';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descCtrl,
                decoration: InputDecoration(
                  labelText: 'Deskripsi (Opsional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),

              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 24),

              FilledButton(
                onPressed: _loading ? null : _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_isEdit ? 'Simpan Perubahan' : 'Simpan Produk',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
