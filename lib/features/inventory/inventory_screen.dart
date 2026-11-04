import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'inventory_providers.dart';
import 'widgets/inventory_form_sheet.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String? _categoryFilter;

  final _categories = ['Deterjen', 'Pewangi', 'Pembersih', 'Plastik', 'Lainnya'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canWrite = ref.watch(currentMemberProvider).value?.canWrite ?? false;
    final asyncItems = ref.watch(inventoryItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventaris', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Cari item inventaris...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Semua'),
                  selected: _categoryFilter == null,
                  onSelected: (_) => setState(() => _categoryFilter = null),
                ),
                const SizedBox(width: 8),
                ..._categories.map((c) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(c),
                    selected: _categoryFilter == c,
                    onSelected: (v) => setState(() => _categoryFilter = v ? c : null),
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: asyncItems.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Gagal memuat: $e')),
              data: (list) {
                var filtered = list;
                if (_query.isNotEmpty) {
                  filtered = filtered.where((i) => i.name.toLowerCase().contains(_query)).toList();
                }
                if (_categoryFilter != null) {
                  filtered = filtered.where((i) => i.category == _categoryFilter).toList();
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text('Belum ada inventaris', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text('Tambahkan item inventaris untuk mulai pantau stok.', style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final item = filtered[i];
                    final isLow = item.isLowStock;

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: isLow ? Colors.red.withValues(alpha: 0.5) : Colors.grey.withValues(alpha: 0.2)),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isLow ? Colors.red.withValues(alpha: 0.1) : theme.colorScheme.primary.withValues(alpha: 0.1),
                          child: Icon(
                            isLow ? Icons.warning_amber : Icons.inventory_2,
                            color: isLow ? Colors.red : theme.colorScheme.primary,
                          ),
                        ),
                        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Sisa: ${item.currentStock} ${item.unit} (Min: ${item.minStock})'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Rp ${item.pricePerUnit}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            if (isLow) const Text('Stok Menipis', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        onTap: canWrite ? () => InventoryFormSheet.show(context, initial: item) : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: canWrite ? FloatingActionButton.extended(
        onPressed: () => InventoryFormSheet.show(context),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Item'),
      ) : null,
    );
  }
}
