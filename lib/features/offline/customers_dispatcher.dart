import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../customers/customer.dart';
import '../customers/supabase_customers_service.dart';
import 'orders_dispatcher.dart';
import 'transactions_dispatcher.dart';
import 'transfers_dispatcher.dart';
import 'payments_dispatcher.dart';
import 'sync_queue_repository.dart';

/// Push satu item antrean `customers` ke Supabase.
/// Operasi insert/update/delete semua lewat `upsert` by id — idempoten.
Future<void> customersDispatcher(
  SyncQueueItem item,
  SupabaseClient client,
) async {
  final payload = jsonDecode(item.payload) as Map<String, dynamic>;
  final customer = Customer.fromMap(payload);
  final service = SupabaseCustomersService(client);
  await service.upsert(customer);
}

/// Router dispatcher berdasarkan `entityType`. Di 15C-1b baru menangani
/// `customers`; entity lain akan ditambah di 15C-2/15C-3.
Future<void> compositeDispatcher(
  SyncQueueItem item,
  SupabaseClient client,
) async {
  switch (item.entityType) {
    case 'customers':
      return customersDispatcher(item, client);
    case 'orders':
      return ordersDispatcher(item, client);
    case 'payments':
      return paymentsDispatcher(item, client);
    case 'transactions':
      return transactionsDispatcher(item, client);
    case 'transfers':
      return transfersDispatcher(item, client);
    default:
      throw UnsupportedError(
        'Belum ada dispatcher untuk entityType=${item.entityType}',
      );
  }
}
