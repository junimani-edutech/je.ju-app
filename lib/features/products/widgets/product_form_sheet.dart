import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../product.dart';
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
  String _selectedCategory = 'Umum';
  bool _loading = false;
  String? _error;

  final List<String> _categories = ['Umum', 'Cuci Kering', 'Cuci Setrika', 'Setrika', 'Bed Cover', 'Sepatu', 'Lainnya'];

  @override
  void initState() {
    super.initState();
    if (widget.initial?.category != null) {
      _selectedCategory = widget.initial!.category!;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final price = int.tryParse(_priceCtrl.text.trim()) ?? 0;
    setState(() { _loading = true; _error = null; });
    try {
      final notifier = ref.read(productsProvider.notifier);
      if (widget.initial != null) {
        await notifier.updateProduct(
          id: widget.initial!.id, 
          name: _nameCtrl.text.trim(), 
          price: price, 
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          category: _selectedCategory,
        );
      } else {
        await notifier.create(
          name: _nameCtrl.text.trim(), 
          price: price, 
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          category: _selectedCategory,
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
                  Text(widget.initial == null ? 'Tambah Produk' : 'Ubah Produk', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 16),
              
              // Nama Produk
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(labelText: 'Nama Produk / Jasa *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              
              // Kategori (Chips)
              Text('Kategori *', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _categories.map((c) {
                  final isSelected = _selectedCategory == c;
                  return ChoiceChip(
                    label: Text(c),
                    selected: isSelected,
                    selectedColor: theme.colorScheme.primary,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : theme.colorScheme.onSurface, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                    onSelected: (v) => setState(() => _selectedCategory = c),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              
              // Harga
              TextFormField(
                controller: _priceCtrl,
                decoration: InputDecoration(labelText: 'Harga (Rp) *', prefixText: 'Rp ', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse((v ?? '').trim());
                  if (n == null || n < 0) return 'Harga tidak valid';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Deskripsi
              TextFormField(
                controller: _descCtrl,
                decoration: InputDecoration(labelText: 'Deskripsi (Opsional)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), alignLabelWithHint: true),
                maxLines: 3,
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _submit,
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Simpan Produk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
