import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'stock_movement.dart';
import 'stock_movement_service.dart';

final stockMovementServiceProvider =
    Provider<StockMovementService>((ref) => StockMovementService());

/// List movement untuk 1 item (dipakai di halaman detail).
final stockMovementsProvider =
    FutureProvider.family<List<StockMovement>, String>((ref, itemId) async {
  final client = Supabase.instance.client;
  final res = await client
      .from('stock_movements')
      .select()
      .eq('inventory_item_id', itemId)
      .order('created_at', ascending: false);
  return (res as List)
      .map((e) => StockMovement.fromMap(e as Map<String, dynamic>))
      .toList();
});

/// List movement untuk semua item di bisnis (untuk halaman "Riwayat Global" nanti).
final allStockMovementsProvider =
    FutureProvider<List<StockMovement>>((ref) async {
  final client = Supabase.instance.client;
  final biz = await client
      .from('business_members')
      .select('business_id')
      .eq('user_id', client.auth.currentUser!.id)
      .eq('status', 'active')
      .limit(1)
      .maybeSingle();
  if (biz == null) return [];

  final res = await client
      .from('stock_movements')
      .select()
      .eq('business_id', biz['business_id'] as String)
      .order('created_at', ascending: false)
      .limit(200);
  return (res as List)
      .map((e) => StockMovement.fromMap(e as Map<String, dynamic>))
      .toList();
});
