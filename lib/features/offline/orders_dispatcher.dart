import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../orders/order.dart';
import '../orders/supabase_orders_service.dart';
import 'sync_queue_repository.dart';

Future<void> ordersDispatcher(SyncQueueItem item, SupabaseClient client) async {
  final payload = jsonDecode(item.payload) as Map<String, dynamic>;
  final orderMap = payload['order'] as Map<String, dynamic>;
  final itemsList = (payload['items'] as List)
      .map((e) => OrderItem.fromMap(e as Map<String, dynamic>))
      .toList();
  final order = Order.fromMap(orderMap);
  final service = SupabaseOrdersService(client);
  await service.upsert(order, itemsList);
}
