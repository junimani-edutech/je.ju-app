import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/providers.dart';
import 'inventory_category.dart';
import 'inventory_providers.dart';

final inventoryCategoriesProvider = FutureProvider<List<InventoryCategory>>((ref) async {
  final biz = await ref.watch(currentBusinessProvider.future);
  if (biz == null) return [];

  final client = Supabase.instance.client;
  final res = await client
      .from('inventory_categories')
      .select()
      .eq('business_id', biz.id)
      .order('sort_order')
      .order('name');

  return (res as List).map((e) => InventoryCategory.fromMap(e as Map<String, dynamic>)).toList();
});

final inventoryCategoriesWithCountProvider =
    FutureProvider<List<({InventoryCategory category, int itemCount})>>((ref) async {
  final categories = await ref.watch(inventoryCategoriesProvider.future);
  final items = await ref.watch(inventoryItemsProvider.future);

  return categories.map((cat) {
    final count = items.where((i) => i.categoryId == cat.id).length;
    return (category: cat, itemCount: count);
  }).toList();
});

class InventoryCategoriesNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> create(String name) async {
    final biz = await ref.read(currentBusinessProvider.future);
    if (biz == null) throw Exception('Tidak ada bisnis aktif');
    final client = Supabase.instance.client;

    final existing = await client
        .from('inventory_categories')
        .select('id')
        .eq('business_id', biz.id)
        .eq('name', name)
        .maybeSingle();
    if (existing != null) throw Exception('Kategori "$name" sudah ada');

    final maxRes = await client
        .from('inventory_categories')
        .select('sort_order')
        .eq('business_id', biz.id)
        .order('sort_order', ascending: false)
        .limit(1)
        .maybeSingle();
    final nextOrder = ((maxRes?['sort_order'] as int?) ?? 0) + 1;

    await client.from('inventory_categories').insert({
      'business_id': biz.id,
      'name': name,
      'sort_order': nextOrder,
    });

    ref.invalidate(inventoryCategoriesProvider);
    ref.invalidate(inventoryCategoriesWithCountProvider);
  }

  Future<void> updateCategory(String id, String name) async {
    final client = Supabase.instance.client;
    await client.from('inventory_categories').update({'name': name}).eq('id', id);
    ref.invalidate(inventoryCategoriesProvider);
    ref.invalidate(inventoryCategoriesWithCountProvider);
    ref.invalidate(inventoryItemsProvider);
  }

  Future<void> delete(String id) async {
    final client = Supabase.instance.client;
    final items = await client.from('inventory_items').select('id').eq('category_id', id).limit(1);
    if ((items as List).isNotEmpty) {
      throw Exception('Kategori masih digunakan oleh item. Pindahkan item terlebih dahulu.');
    }
    await client.from('inventory_categories').delete().eq('id', id);
    ref.invalidate(inventoryCategoriesProvider);
    ref.invalidate(inventoryCategoriesWithCountProvider);
  }
}

final inventoryCategoriesNotifierProvider =
    AsyncNotifierProvider<InventoryCategoriesNotifier, void>(InventoryCategoriesNotifier.new);
