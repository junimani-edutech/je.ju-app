import 'package:supabase_flutter/supabase_flutter.dart';

class StockMovementService {
  final _client = Supabase.instance.client;

  static const validTypes = [
    'initial',
    'purchase',
    'usage',
    'waste',
    'adjustment',
    'return',
  ];

  Future<void> record({
    required String businessId,
    required String itemId,
    required String movementType,
    required double quantity,
    String? notes,
    String? referenceId,
  }) async {
    if (quantity == 0) {
      throw Exception('Kuantitas tidak boleh 0');
    }
    if (!validTypes.contains(movementType)) {
      throw Exception('Tipe movement tidak valid: $movementType');
    }

    await _client.from('stock_movements').insert({
      'business_id': businessId,
      'inventory_item_id': itemId,
      'movement_type': movementType,
      'quantity': quantity,
      'notes': notes,
      'reference_id': referenceId,
    });
    // Trigger di DB akan otomatis update current_stock
  }

  Future<void> delete(String movementId) async {
    await _client.from('stock_movements').delete().eq('id', movementId);
  }
}
