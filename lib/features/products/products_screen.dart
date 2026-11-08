import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import 'paginated_products_providers.dart';
import 'product_categories_providers.dart';
import 'products_providers.dart';
import 'widgets/product_form_sheet.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  String? _categoryId;
  bool _isArchivedTab = false;
  late TabController _tabController;


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _switchTab(_tabController.index == 1);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) ref.read(paginatedProductsProvider.notifier).setSearch(value);
    });
  }

  void _switchTab(bool archived) {
    if (_isArchivedTab == archived) return;
    setState(() => _isArchivedTab = archived);
    ref.read(paginatedProductsProvider.notifier).setArchived(archived);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canWrite = ref.watch(currentMemberProvider).value?.canWrite ?? false;
    final async = ref.watch(paginatedProductsProvider);
    final categoriesAsync = ref.watch(productCategoriesProvider);
    final categories = categoriesAsync.value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Produk & Jasa', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Kelola Kategori',
            icon: const Icon(Icons.category_outlined),
            onPressed: () => context.go('/app/more/product-categories'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Aktif'),
            Tab(text: 'Arsip'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Cari produk...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                suffixIcon: _searchCtrl.text.isEmpty ? null : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchCtrl.clear();
                    ref.read(paginatedProductsProvider.notifier).setSearch(null);
                  },
                ),
              ),
            ),
          ),
          if (categories.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Semua'),
                    selected: _categoryId == null,
                    onSelected: (_) {
                      setState(() => _categoryId = null);
                      ref.read(paginatedProductsProvider.notifier).setCategoryId(null);
                    },
                  ),
                  const SizedBox(width: 8),
                  ...categories.map((c) {
                    final isSelected = _categoryId == c.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(c.name),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() => _categoryId = c.id);
                          ref.read(paginatedProductsProvider.notifier).setCategoryId(c.id);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Gagal memuat: $e')),
              data: (result) {
                if (result.items.isEmpty) {
                  return _empty(theme, _searchCtrl.text.isNotEmpty);
                }
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          Text('Menampilkan ${result.items.length} dari ${result.total} produk',
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                        itemCount: result.items.length + (result.hasMore ? 1 : 0),
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          if (i == result.items.length) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: OutlinedButton.icon(
                                  onPressed: () => ref.read(paginatedProductsProvider.notifier).loadMore(),
                                  icon: const Icon(Icons.expand_more),
                                  label: const Text('Muat Lebih Banyak'),
                                ),
                              ),
                            );
                          }
                          return _buildProductCard(context, theme, canWrite, result.items[i]);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: canWrite
          ? FloatingActionButton.extended(
              key: const Key('products_fab'),
              onPressed: () async {
                final saved = await ProductFormSheet.show(context);
                if (saved == true) ref.read(paginatedProductsProvider.notifier).refresh();
              },
              icon: const Icon(Icons.add),
              label: const Text('Tambah Produk'),
            )
          : null,
    );
  }

  Widget _buildProductCard(BuildContext context, ThemeData theme, bool canWrite, dynamic p) {
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
                onSelected: (v) async {
                  switch (v) {
                    case 'edit':
                      await ProductFormSheet.show(context, initial: p);
                      ref.read(paginatedProductsProvider.notifier).refresh();
                      break;
                    case 'archive':
                      await ref.read(productsProvider.notifier).archive(p.id);
                      ref.read(paginatedProductsProvider.notifier).refresh();
                      break;
                    case 'restore':
                      await ref.read(productsProvider.notifier).restore(p.id);
                      ref.read(paginatedProductsProvider.notifier).refresh();
                      break;
                    case 'delete':
                      await _confirmHardDelete(context, ref, p);
                      break;
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Ubah')),
                  if (p.isActive)
                    const PopupMenuItem(value: 'archive', child: Text('Arsipkan'))
                  else
                    const PopupMenuItem(value: 'restore', child: Text('Pulihkan')),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Hapus Permanen', style: TextStyle(color: Colors.red)),
                  ),
                ],
              )
            : null,
        onTap: canWrite ? () async {
          await ProductFormSheet.show(context, initial: p);
          ref.read(paginatedProductsProvider.notifier).refresh();
        } : null,
      ),
    );
  }

  Future<void> _confirmHardDelete(BuildContext context, WidgetRef ref, dynamic product) async {
    try {
      final canDelete = await ref.read(productsProvider.notifier).canHardDelete(product.id);
      if (!canDelete) {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Tidak Bisa Hapus'),
              content: const Text('Produk ini sudah pernah dipakai di pesanan. Untuk menjaga integritas laporan, gunakan opsi "Arsipkan" saja.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Mengerti')),
              ],
            ),
          );
        }
        return;
      }

      if (!context.mounted) return;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Hapus Permanen?'),
          content: Text('"${product.name}" akan dihapus selamanya. Tindakan ini tidak dapat dibatalkan.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Hapus'),
            ),
          ],
        ),
      );

      if (ok == true) {
        await ref.read(productsProvider.notifier).delete(product.id);
        ref.read(paginatedProductsProvider.notifier).refresh();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produk dihapus permanen')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Widget _empty(ThemeData theme, bool isSearching) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.05), shape: BoxShape.circle),
              child: Icon(isSearching ? Icons.search_off : Icons.inventory_2_outlined, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 24),
            Text(isSearching ? 'Tidak ada hasil' : (_isArchivedTab ? 'Belum ada arsip' : 'Belum ada produk'),
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(isSearching ? 'Coba kata kunci lain.' : (_isArchivedTab ? 'Produk yang diarsipkan akan muncul di sini.' : 'Tambahkan produk pertama Anda.'),
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
