import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'products_providers.dart';
import 'widgets/product_form_sheet.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canWrite = ref.watch(currentMemberProvider).value?.canWrite ?? false;
    final async = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Master Produk')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Text('Belum ada produk. Tambahkan produk pertama Anda.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final p = list[i];
              return Card(
                child: ListTile(
                  title: Text(p.name),
                  subtitle: Text(
                    'Rp ${p.price} ${p.isActive ? '' : '(Arsip)'}',
                  ),
                  trailing: canWrite
                      ? IconButton(
                          icon: Icon(
                            p.isActive ? Icons.archive_outlined : Icons.restore,
                          ),
                          onPressed: () => p.isActive
                              ? ref
                                    .read(productsProvider.notifier)
                                    .archive(p.id)
                              : ref
                                    .read(productsProvider.notifier)
                                    .restore(p.id),
                        )
                      : null,
                  onTap: canWrite
                      ? () => ProductFormSheet.show(context, initial: p)
                      : null,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: canWrite
          ? FloatingActionButton.extended(
              onPressed: () => ProductFormSheet.show(context),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Produk'),
            )
          : null,
    );
  }
}
