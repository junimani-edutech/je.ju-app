import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../inventory_item.dart';
import '../inventory_providers.dart';
import '../stock_movement_providers.dart';

class StockMovementFormSheet extends ConsumerStatefulWidget {
  final InventoryItem item;
  final String initialType; // 'purchase', 'usage', 'waste', 'adjustment'

  const StockMovementFormSheet({
    super.key,
    required this.item,
    this.initialType = 'purchase',
  });

  static Future<bool?> show(
    BuildContext context, {
    required InventoryItem item,
    String initialType = 'purchase',
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => StockMovementFormSheet(
        item: item,
        initialType: initialType,
      ),
    );
  }

  @override
  ConsumerState<StockMovementFormSheet> createState() =>
      _StockMovementFormSheetState();
}

class _StockMovementFormSheetState extends ConsumerState<StockMovementFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _qtyCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  late String _selectedType;
  bool _loading = false;
  String? _error;

  final _types = <({String key, String label, IconData icon, Color color})>[
    (key: 'purchase', label: 'Stok Masuk', icon: Icons.add_circle, color: Colors.green),
    (key: 'usage', label: 'Pemakaian', icon: Icons.remove_circle, color: Colors.blue),
    (key: 'waste', label: 'Rusak/Basi', icon: Icons.delete_outline, color: Colors.red),
    (key: 'adjustment', label: 'Penyesuaian', icon: Icons.tune, color: Colors.orange),
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  bool get _isIncoming =>
      _selectedType == 'purchase' || _selectedType == 'adjustment';

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final qtyInput = double.tryParse(_qtyCtrl.text.trim()) ?? 0;
    if (qtyInput <= 0) {
      setState(() => _error = 'Kuantitas harus > 0');
      return;
    }

    final signedQty = _isIncoming ? qtyInput : -qtyInput;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final biz = await ref.read(currentBusinessProvider.future);
      if (biz == null) throw Exception('Tidak ada bisnis aktif');

      await ref.read(stockMovementServiceProvider).record(
            businessId: biz.id,
            itemId: widget.item.id,
            movementType: _selectedType,
            quantity: signedQty,
            notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          );

      // Refresh list item & movement history
      ref.invalidate(inventoryItemsProvider);
      ref.invalidate(stockMovementsProvider(widget.item.id));

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_types.firstWhere((t) => t.key == _selectedType).label} berhasil dicatat'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentType = _types.firstWhere((t) => t.key == _selectedType);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
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
                  Text(
                    'Catat Pergerakan Stok',
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            'Stok saat ini: ${widget.item.currentStock} ${widget.item.unit}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Text('Jenis Pergerakan *', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _types.map((t) {
                  final isSelected = _selectedType == t.key;
                  return ChoiceChip(
                    label: Text(t.label),
                    avatar: Icon(t.icon, size: 18, color: isSelected ? Colors.white : t.color),
                    selected: isSelected,
                    selectedColor: t.color,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) => setState(() => _selectedType = t.key),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _qtyCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Kuantitas (${widget.item.unit}) *',
                  hintText: '0',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: Icon(
                    _isIncoming ? Icons.add : Icons.remove,
                    color: currentType.color,
                  ),
                ),
                validator: (v) {
                  final n = double.tryParse((v ?? '').trim());
                  if (n == null || n <= 0) return 'Harus berupa angka > 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Catatan (opsional)',
                  hintText: _selectedType == 'purchase'
                      ? 'Misal: Beli dari Supplier Andi'
                      : _selectedType == 'waste'
                          ? 'Misal: Tumpah / Basi'
                          : 'Misal: Pemakaian untuk cucian hari ini',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  alignLabelWithHint: true,
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                ),
              ],
              const SizedBox(height: 24),

              FilledButton.icon(
                onPressed: _loading ? null : _submit,
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(currentType.icon),
                label: Text(
                  _loading ? 'Menyimpan...' : 'Simpan ${currentType.label}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: currentType.color,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
