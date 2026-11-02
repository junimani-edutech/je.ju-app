import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../finance/supabase_finance_services.dart';
import '../finance/transaction.dart';
import 'sync_queue_repository.dart';

Future<void> transactionsDispatcher(
  SyncQueueItem item,
  SupabaseClient client,
) async {
  final payload = jsonDecode(item.payload) as Map<String, dynamic>;
  final t = Transaction.fromMap(payload);
  final service = SupabaseTransactionsService(client);
  await service.upsert(t);
}
