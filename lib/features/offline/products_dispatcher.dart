import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../products/product.dart';
import '../products/supabase_products_service.dart';
import 'sync_queue_repository.dart';

Future<void> productsDispatcher(
  SyncQueueItem item,
  SupabaseClient client,
) async {
  final payload = jsonDecode(item.payload) as Map<String, dynamic>;
  final p = Product.fromMap(payload);
  await SupabaseProductsService(client).upsert(p);
}
