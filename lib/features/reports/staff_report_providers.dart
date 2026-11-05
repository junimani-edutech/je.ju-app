import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/providers.dart';

class StaffPerformance {
  final String? actorId;
  final String actorName;
  final int ordersCount;
  final int ordersTotal;
  final int ordersPaid;

  StaffPerformance({
    this.actorId,
    required this.actorName,
    required this.ordersCount,
    required this.ordersTotal,
    required this.ordersPaid,
  });

  factory StaffPerformance.fromMap(Map<String, dynamic> m) => StaffPerformance(
    actorId: m['actor_id'] as String?,
    actorName: m['actor_name'] as String? ?? 'Unknown',
    ordersCount: (m['orders_count'] as num).toInt(),
    ordersTotal: (m['orders_total'] as num).toInt(),
    ordersPaid: (m['orders_paid'] as num).toInt(),
  );
}

final staffReportProvider = FutureProvider.family<List<StaffPerformance>, ({DateTime from, DateTime to})>((ref, range) async {
  final biz = await ref.watch(currentBusinessProvider.future);
  if (biz == null) return [];

  final client = Supabase.instance.client;
  final fromStr = '${range.from.year}-${range.from.month.toString().padLeft(2, '0')}-${range.from.day.toString().padLeft(2, '0')}';
  final toStr = '${range.to.year}-${range.to.month.toString().padLeft(2, '0')}-${range.to.day.toString().padLeft(2, '0')}';

  final res = await client.rpc('get_sales_by_staff', params: {
    'p_business_id': biz.id,
    'p_from': fromStr,
    'p_to': toStr,
  });

  return (res as List).map((e) => StaffPerformance.fromMap(e as Map<String, dynamic>)).toList();
});
