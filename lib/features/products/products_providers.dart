import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'product.dart';
import 'products_service.dart';

final productsServiceProvider = Provider<ProductsService>((ref) {
  throw UnimplementedError('productsServiceProvider belum di-override');
});

class ProductsNotifier extends AsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() async {
    final biz = await ref.watch(currentBusinessProvider.future);
    if (biz == null) return const <Product>[];
    return ref
        .watch(productsServiceProvider)
        .list(businessId: biz.id, includeArchived: true);
  }

  Future<void> _reload() async {
    final biz = await ref.read(currentBusinessProvider.future);
    if (biz == null) {
      state = const AsyncData(<Product>[]);
      return;
    }
    state = AsyncData(
      await ref
          .read(productsServiceProvider)
          .list(businessId: biz.id, includeArchived: true),
    );
  }

  Future<void> create({
    required String name,
    required int price,
    String? description,
    String? category,
  }) async {
    final biz = await ref.read(currentBusinessProvider.future);
    if (biz == null) throw StateError('Tidak ada bisnis aktif');
    await ref
        .read(productsServiceProvider)
        .create(
          businessId: biz.id,
          name: name,
          price: price,
          description: description,
          category: category,
        );
    await _reload();
  }

  Future<void> updateProduct({
    required String id,
    required String name,
    required int price,
    String? description,
    String? category,
  }) async {
    await ref
        .read(productsServiceProvider)
        .update(id: id, name: name, price: price, description: description, category: category);
    await _reload();
  }

  Future<void> archive(String id) async {
    await ref.read(productsServiceProvider).archive(id);
    await _reload();
  }

  Future<void> restore(String id) async {
    await ref.read(productsServiceProvider).restore(id);
    await _reload();
  }
}

final productsProvider = AsyncNotifierProvider<ProductsNotifier, List<Product>>(
  ProductsNotifier.new,
);

final activeProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  return ref
      .watch(productsProvider)
      .whenData((list) => list.where((p) => p.isActive).toList());
});

final archivedProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  return ref
      .watch(productsProvider)
      .whenData((list) => list.where((p) => !p.isActive).toList());
});
