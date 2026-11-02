import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../finance/supabase_finance_services.dart';
import '../finance/transfer.dart';
import 'sync_queue_repository.dart';

Future<void> transfersDispatcher(
  SyncQueueItem item,
  SupabaseClient client,
) async {
  final payload = jsonDecode(item.payload) as Map<String, dynamic>;
  final tr = Transfer.fromMap(payload);
  final service = SupabaseTransfersService(client);
  await service.upsert(tr);
}
