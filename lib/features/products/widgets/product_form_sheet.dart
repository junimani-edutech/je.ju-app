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
  late final _nameCtrl = TextEditingController(
    text: widget.initial?.name ?? '',
  );
  late final _priceCtrl = TextEditingController(
    text: widget.initial?.price.toString() ?? '',
  );
  late final _descCtrl = TextEditingController(
    text: widget.initial?.description ?? '',
  );
  bool _loading = false;
  String? _error;

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
    if (price < 0) {
      setState(() => _error = 'Harga tidak boleh negatif.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final notifier = ref.read(productsProvider.notifier);
      if (widget.initial != null) {
        await notifier.updateProduct(
          id: widget.initial!.id,
          name: _nameCtrl.text.trim(),
          price: price,
          description: _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
        );
      } else {
        await notifier.create(
          name: _nameCtrl.text.trim(),
          price: price,
          description: _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
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
              Text(
                widget.initial == null ? 'Tambah Produk' : 'Ubah Produk',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nama Produk *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceCtrl,
                decoration: const InputDecoration(labelText: 'Harga (Rp) *'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse((v ?? '').trim());
                  if (n == null || n < 0) return 'Harga tidak valid';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi (Opsional)',
                ),
                maxLines: 2,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
