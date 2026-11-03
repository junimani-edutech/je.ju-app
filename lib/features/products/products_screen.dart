import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../shared/widgets/app_states.dart';
import '../../shared/widgets/skeleton_loader.dart';
import 'product.dart';
import 'products_providers.dart';
import 'widgets/product_form_sheet.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canWrite = ref.watch(currentMemberProvider).value?.canWrite ?? false;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Master Produk'),
          bottom: const TabBar(
            tabs: [
              Tab(key: Key('products_tab_active'), text: 'Aktif'),
              Tab(key: Key('products_tab_archived'), text: 'Arsip'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ProductsList(
              async: ref.watch(activeProductsProvider),
              canWrite: canWrite,
              isArchivedTab: false,
            ),
            _ProductsList(
              async: ref.watch(archivedProductsProvider),
              canWrite: canWrite,
              isArchivedTab: true,
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
  });

  final AsyncValue<List<Product>> async;
  final bool canWrite;
  final bool isArchivedTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return async.when(
      loading: () => const SkeletonList(),
      error: (e, _) => ErrorState(
        message: 'Gagal memuat produk. Periksa koneksi Anda.',
        onRetry: () => ref.invalidate(productsProvider),
      ),
      data: (list) {
        if (list.isEmpty) {
          if (isArchivedTab) {
            return const EmptyState(
              icon: Icons.archive_outlined,
              title: 'Belum ada produk diarsip',
              subtitle: 'Produk yang Anda arsipkan akan muncul di sini dan bisa dipulihkan.',
            );
          }
          return EmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'Belum ada produk',
            subtitle: canWrite
                ? 'Tekan tombol Tambah Produk untuk mulai membuat master data.'
                : 'Produk akan muncul di sini setelah ditambahkan.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) {
            final p = list[i];
            return Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                key: Key('product_tile_${p.id}'),
                title: Text(p.name),
                subtitle: Text(
                  'Rp ${_fmtIdr(p.price)}'
                  '${p.description != null && p.description!.isNotEmpty ? ' • ${p.description}' : ''}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: canWrite
                    ? PopupMenuButton<String>(
                        key: Key('product_menu_${p.id}'),
                        tooltip: 'Aksi',
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
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Ubah'),
                          ),
                          if (p.isActive)
                            const PopupMenuItem(
                              value: 'archive',
                              child: Text('Arsipkan'),
                            )
                          else
                            const PopupMenuItem(
                              value: 'restore',
                              child: Text('Pulihkan'),
                            ),
                        ],
                      )
                    : (p.isActive
                          ? null
                          : Icon(
                              Icons.archive_outlined,
                              color: Theme.of(context).colorScheme.outline,
                            )),
                onTap: canWrite
                    ? () => ProductFormSheet.show(context, initial: p)
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  static String _fmtIdr(int amount) {
    final s = amount.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
