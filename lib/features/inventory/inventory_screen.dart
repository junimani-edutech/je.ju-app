import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import 'inventory_categories_providers.dart';
import 'inventory_item.dart';
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
  String? _selectedCategoryId;
  bool _showArchived = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(InventoryItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Permanen?'),
        content: Text('"${item.name}" akan dihapus selamanya. Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus Permanen'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(inventoryNotifierProvider.notifier).delete(item.id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item dihapus permanen')));
    }
  }

  Future<void> _archive(InventoryItem item) async {
    await ref.read(inventoryNotifierProvider.notifier).archive(item.id);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item diarsipkan')));
  }

  Future<void> _restore(InventoryItem item) async {
    await ref.read(inventoryNotifierProvider.notifier).restore(item.id);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item dipulihkan')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canWrite = ref.watch(currentMemberProvider).value?.canWrite ?? false;
    final asyncItems = ref.watch(inventoryItemsProvider);
    final categoriesAsync = ref.watch(inventoryCategoriesProvider);
    final categories = categoriesAsync.value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventaris', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: _showArchived ? 'Tampilkan Aktif' : 'Tampilkan Arsip',
            icon: Icon(_showArchived ? Icons.inventory_2 : Icons.archive_outlined),
            onPressed: () => setState(() => _showArchived = !_showArchived),
          ),
          IconButton(
            tooltip: 'Kelola Kategori',
            icon: const Icon(Icons.category_outlined),
            onPressed: () => context.go('/app/more/inventory-categories'),
          ),
        ],
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
          // Filter chips dari DB
          if (categories.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Semua'),
                    selected: _selectedCategoryId == null,
                    onSelected: (_) => setState(() => _selectedCategoryId = null),
                  ),
                  const SizedBox(width: 8),
                  ...categories.map((c) {
                    final isSelected = _selectedCategoryId == c.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(c.name),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _selectedCategoryId = c.id),
                      ),
                    );
                  }),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: asyncItems.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Gagal memuat: $e')),
              data: (list) {
                var filtered = list.where((i) => _showArchived ? !i.isActive : i.isActive).toList();
                if (_query.isNotEmpty) {
                  filtered = filtered.where((i) => i.name.toLowerCase().contains(_query)).toList();
                }
                if (_selectedCategoryId != null) {
                  filtered = filtered.where((i) => i.categoryId == _selectedCategoryId).toList();
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_showArchived ? Icons.archive_outlined : Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(_showArchived ? 'Belum ada arsip' : 'Belum ada inventaris', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(_showArchived ? 'Item yang diarsipkan akan muncul di sini.' : 'Tambahkan item inventaris untuk mulai pantau stok.', style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
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
                    final isLow = item.isLowStock && item.isActive;
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: isLow ? Colors.red.withValues(alpha: 0.5) : Colors.grey.withValues(alpha: 0.2)),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isLow ? Colors.red.withValues(alpha: 0.1) : theme.colorScheme.primary.withValues(alpha: 0.1),
                          child: Icon(isLow ? Icons.warning_amber : Icons.inventory_2, color: isLow ? Colors.red : theme.colorScheme.primary),
                        ),
                        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Sisa: ${item.currentStock} ${item.unit} (Min: ${item.minStock})'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Rp ${item.pricePerUnit}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                if (isLow) const Text('Stok Menipis', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            if (canWrite) PopupMenuButton<String>(
                              onSelected: (v) async {
                                switch (v) {
                                  case 'edit':
                                    await InventoryFormSheet.show(context, initial: item);
                                    break;
                                  case 'archive':
                                    await _archive(item);
                                    break;
                                  case 'restore':
                                    await _restore(item);
                                    break;
                                  case 'delete':
                                    await _confirmDelete(item);
                                    break;
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(value: 'edit', child: Text('Ubah Info')),
                                if (item.isActive)
                                  const PopupMenuItem(value: 'archive', child: Text('Arsipkan'))
                                else
                                  const PopupMenuItem(value: 'restore', child: Text('Pulihkan')),
                                const PopupMenuDivider(),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Hapus Permanen', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        onTap: () => context.go('/app/more/inventory-detail/${item.id}'),
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
