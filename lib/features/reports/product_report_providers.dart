import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/providers.dart';

class TopProduct {
  final String? productId;
  final String description;
  final double totalQty;
  final int totalRevenue;

  TopProduct({
    this.productId,
    required this.description,
    required this.totalQty,
    required this.totalRevenue,
  });

  factory TopProduct.fromMap(Map<String, dynamic> m) => TopProduct(
    productId: m['product_id'] as String?,
    description: m['description'] as String,
    totalQty: (m['total_qty'] as num).toDouble(),
    totalRevenue: (m['total_revenue'] as num).toInt(),
  );
}

final topProductsProvider = FutureProvider<List<TopProduct>>((ref) async {
  final biz = await ref.watch(currentBusinessProvider.future);
  if (biz == null) return [];

  final client = Supabase.instance.client;
  final res = await client.rpc('get_top_products', params: {
    'p_business_id': biz.id,
    'p_limit': 10,
  });

  return (res as List).map((e) => TopProduct.fromMap(e)).toList();
});
