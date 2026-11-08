import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/providers.dart';
import 'paginated_products_providers.dart';
import 'product_category.dart';

final productCategoriesProvider = FutureProvider<List<ProductCategory>>((ref) async {
  final biz = await ref.watch(currentBusinessProvider.future);
  if (biz == null) return [];

  final client = Supabase.instance.client;
  final res = await client
      .from('product_categories')
      .select()
      .eq('business_id', biz.id)
      .order('sort_order')
      .order('name');

  return (res as List).map((e) => ProductCategory.fromMap(e as Map<String, dynamic>)).toList();
});

final productCategoriesWithCountProvider =
    FutureProvider<List<({ProductCategory category, int itemCount})>>((ref) async {
  final categories = await ref.watch(productCategoriesProvider.future);

  // Ambil semua produk untuk hitung (bisa pakai cached paginatedProductsProvider jika sudah di-load)
  final client = Supabase.instance.client;
  final biz = await ref.watch(currentBusinessProvider.future);
  if (biz == null) return [];

  final productsRes = await client
      .from('products')
      .select('category_id')
      .eq('business_id', biz.id);

  final products = productsRes as List;
  return categories.map((cat) {
    final count = products.where((p) => p['category_id'] == cat.id).length;
    return (category: cat, itemCount: count);
  }).toList();
});

class ProductCategoriesNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> create(String name) async {
    final biz = await ref.read(currentBusinessProvider.future);
    if (biz == null) throw Exception('Tidak ada bisnis aktif');
    final client = Supabase.instance.client;

    // Cek duplikat
    final existing = await client
        .from('product_categories')
        .select('id')
        .eq('business_id', biz.id)
        .eq('name', name)
        .maybeSingle();
    if (existing != null) throw Exception('Kategori "$name" sudah ada');

    // Next sort order
    final maxRes = await client
        .from('product_categories')
        .select('sort_order')
        .eq('business_id', biz.id)
        .order('sort_order', ascending: false)
        .limit(1)
        .maybeSingle();
    final nextOrder = ((maxRes?['sort_order'] as int?) ?? 0) + 1;

    await client.from('product_categories').insert({
      'business_id': biz.id,
      'name': name,
      'sort_order': nextOrder,
    });

    ref.invalidate(productCategoriesProvider);
    ref.invalidate(productCategoriesWithCountProvider);
  }

  Future<void> updateCategory(String id, String name) async {
    final client = Supabase.instance.client;
    await client.from('product_categories').update({'name': name}).eq('id', id);
    ref.invalidate(productCategoriesProvider);
    ref.invalidate(productCategoriesWithCountProvider);
    ref.invalidate(paginatedProductsProvider);
  }

  Future<void> delete(String id) async {
    final client = Supabase.instance.client;
    final items = await client.from('products').select('id').eq('category_id', id).limit(1);
    if ((items as List).isNotEmpty) {
      throw Exception('Kategori masih digunakan oleh produk. Pindahkan produk terlebih dahulu.');
    }
    await client.from('product_categories').delete().eq('id', id);
    ref.invalidate(productCategoriesProvider);
    ref.invalidate(productCategoriesWithCountProvider);
  }
}

final productCategoriesNotifierProvider =
    AsyncNotifierProvider<ProductCategoriesNotifier, void>(ProductCategoriesNotifier.new);
