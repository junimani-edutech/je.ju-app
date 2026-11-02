import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../payments/payment.dart';
import '../payments/supabase_payments_service.dart';
import 'sync_queue_repository.dart';

Future<void> paymentsDispatcher(
  SyncQueueItem item,
  SupabaseClient client,
) async {
  final payload = jsonDecode(item.payload) as Map<String, dynamic>;
  final payment = Payment.fromMap(payload);
  final service = SupabasePaymentsService(client);
  await service.upsert(payment);
}
