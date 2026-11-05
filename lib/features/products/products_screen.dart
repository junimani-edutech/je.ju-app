import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../shared/widgets/app_states.dart';
import '../../shared/widgets/skeleton_loader.dart';
import 'product.dart';
import 'products_providers.dart';
import 'widgets/product_form_sheet.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String? _categoryFilter;

  final List<String> _categories = ['Semua', 'Umum', 'Cuci Kering', 'Cuci Setrika', 'Setrika', 'Bed Cover', 'Sepatu', 'Lainnya'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Product> _applyFilter(List<Product> list) {
    var filtered = list;
    if (_query.isNotEmpty) {
      filtered = filtered.where((p) => p.name.toLowerCase().contains(_query.toLowerCase())).toList();
    }
    if (_categoryFilter != null && _categoryFilter != 'Semua') {
      filtered = filtered.where((p) => p.category == _categoryFilter).toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canWrite = ref.watch(currentMemberProvider).value?.canWrite ?? false;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Produk & Jasa', style: TextStyle(fontWeight: FontWeight.bold)),
          bottom: const TabBar(
            tabs: [
              Tab(key: Key('products_tab_active'), text: 'Aktif'),
              Tab(key: Key('products_tab_archived'), text: 'Arsip'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Cari produk...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                onChanged: (v) => setState(() => _query = v.trim()),
              ),
            ),
            
            // Filter Kategori
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _categories.map((c) {
                  final isSelected = (_categoryFilter ?? 'Semua') == c;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(c),
                      selected: isSelected,
                      onSelected: (v) => setState(() => _categoryFilter = c),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            
            Expanded(
              child: TabBarView(
                children: [
                  _ProductsList(
                    async: ref.watch(activeProductsProvider),
                    canWrite: canWrite,
                    isArchivedTab: false,
                    applyFilter: _applyFilter,
                  ),
                  _ProductsList(
                    async: ref.watch(archivedProductsProvider),
                    canWrite: canWrite,
                    isArchivedTab: true,
                    applyFilter: _applyFilter,
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: canWrite
            ? FloatingActionButton.extended(
                key: const Key('products_fab'),
                onPressed: () => ProductFormSheet.show(context),
                icon: const Icon(Icons.add),
                label: const Text('Tambah Produk'),
              )
            : null,
      ),
    );
  }
}

class _ProductsList extends ConsumerWidget {
  const _ProductsList({
    required this.async,
    required this.canWrite,
    required this.isArchivedTab,
    required this.applyFilter,
  });

  final AsyncValue<List<Product>> async;
  final bool canWrite;
  final bool isArchivedTab;
  final List<Product> Function(List<Product>) applyFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return async.when(
      loading: () => const SkeletonList(),
      error: (e, _) => ErrorState(
        message: 'Gagal memuat produk. Periksa koneksi Anda.',
        onRetry: () => ref.invalidate(productsProvider),
      ),
      data: (rawList) {
        final list = applyFilter(rawList);
        
        if (list.isEmpty) {
          return EmptyState(
            icon: isArchivedTab ? Icons.archive_outlined : Icons.inventory_2_outlined,
            title: isArchivedTab ? 'Belum ada arsip' : 'Belum ada produk',
            subtitle: isArchivedTab 
                ? 'Produk yang Anda arsipkan akan muncul di sini.' 
                : (canWrite ? 'Tekan tombol Tambah untuk memulai.' : 'Produk akan muncul di sini.'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) {
            final p = list[i];
            return Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
              child: ListTile(
                key: Key('product_tile_${p.id}'),
                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (p.category != null)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text(p.category!, style: TextStyle(fontSize: 10, color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                      ),
                    const SizedBox(height: 4),
                    Text('Rp ${p.price}'),
                  ],
                ),
                trailing: canWrite
                    ? PopupMenuButton<String>(
                        key: Key('product_menu_${p.id}'),
                        onSelected: (v) {
                          switch (v) {
                            case 'edit':
                              ProductFormSheet.show(context, initial: p);
                              break;
                            case 'archive':
                              ref.read(productsProvider.notifier).archive(p.id);
                              break;
                            case 'restore':
                              ref.read(productsProvider.notifier).restore(p.id);
                              break;
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'edit', child: Text('Ubah')),
                          if (p.isActive)
                            const PopupMenuItem(value: 'archive', child: Text('Arsipkan'))
                          else
                            const PopupMenuItem(value: 'restore', child: Text('Pulihkan')),
                        ],
                      )
                    : null,
                onTap: canWrite ? () => ProductFormSheet.show(context, initial: p) : null,
              ),
            );
          },
        );
      },
    );
  }
}
