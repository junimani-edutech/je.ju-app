import 'package:supabase_flutter/supabase_flutter.dart';

import 'product.dart';
import 'products_service.dart';

class SupabaseProductsService implements ProductsService {
  SupabaseProductsService(this._client);
  final SupabaseClient _client;

  @override
  Future<List<Product>> list({
    required String businessId,
    bool includeArchived = false,
  }) async {
    var q = _client.from('products').select().eq('business_id', businessId);
    if (!includeArchived) q = q.eq('status', 'active');
    final rows = await q.order('name');
    return (rows as List)
        .map((e) => Product.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Product> create({
    required String businessId,
    required String name,
    required int price,
    String? description,
  }) async {
    final row = await _client
        .from('products')
        .insert({
          'business_id': businessId,
          'name': name,
          'price': price,
          'description': description,
        })
        .select()
        .single();
    return Product.fromMap(row);
  }

  @override
  Future<Product> update({
    required String id,
    required String name,
    required int price,
    String? description,
  }) async {
    final row = await _client
        .from('products')
        .update({'name': name, 'price': price, 'description': description})
        .eq('id', id)
        .select()
        .single();
    return Product.fromMap(row);
  }

  @override
  Future<void> archive(String id) async {
    await _client.from('products').update({'status': 'archived'}).eq('id', id);
  }

  @override
  Future<void> restore(String id) async {
    await _client.from('products').update({'status': 'active'}).eq('id', id);
  }

  @override
  Future<void> upsert(Product p) async {
    await _client.rpc(
      'upsert_product',
      params: {
        'p_id': p.id,
        'p_business_id': p.businessId,
        'p_name': p.name,
        'p_price': p.price,
        'p_description': p.description,
        'p_status': p.status,
      },
    );
  }
}
