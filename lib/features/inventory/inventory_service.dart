import 'package:supabase_flutter/supabase_flutter.dart';
import 'inventory_item.dart';

class SupabaseInventoryService {
  final _client = Supabase.instance.client;

  Future<List<InventoryItem>> list(String businessId) async {
    final res = await _client
        .from('inventory_items')
        .select()
        .eq('business_id', businessId)
        .order('name');
    return (res as List).map((e) => InventoryItem.fromMap(e)).toList();
  }

  Future<void> upsert(InventoryItem item) async {
    await _client.from('inventory_items').upsert(item.toMap());
  }

  Future<void> delete(String id) async {
    await _client.from('inventory_items').delete().eq('id', id);
  }
}
