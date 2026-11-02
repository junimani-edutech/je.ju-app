// ignore_for_file: prefer_initializing_formals
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../finance/finance_services.dart';
import '../finance/supabase_finance_services.dart';
import '../finance/transfer.dart';
import 'local_transfers_repo.dart';
import 'providers.dart';
import 'sync_queue_repository.dart';

class OfflineTransfersService implements TransfersService {
  OfflineTransfersService({
    required SupabaseTransfersService remote,
    required LocalTransfersRepo local,
    required SyncQueueRepository queue,
    required Ref ref,
  }) : _remote = remote,
       _local = local,
       _queue = queue,
       _ref = ref;

  final SupabaseTransfersService _remote;
  final LocalTransfersRepo _local;
  final SyncQueueRepository _queue;
  final Ref _ref;
  final Uuid _uuid = const Uuid();

  bool _isOnline() =>
      _ref.read(networkStatusProvider).value == NetworkStatus.online;

  Map<String, dynamic> _toMap(Transfer tr) => {
    'id': tr.id,
    'business_id': tr.businessId,
    'from_account_id': tr.fromAccountId,
    'to_account_id': tr.toAccountId,
    'amount': tr.amount,
    'currency': tr.currency,
    'transfer_date': tr.transferDate.toIso8601String().substring(0, 10),
    'description': tr.description,
    'status': tr.status,
    'created_at': tr.createdAt.toIso8601String(),
  };

  @override
  Future<List<Transfer>> list({required String businessId}) async {
    if (_isOnline()) {
      try {
        final remote = await _remote.list(businessId: businessId);
        await _local.upsertMany(remote);
      } catch (_) {}
    }
    return _local.list(businessId: businessId);
  }

  @override
  Future<String> record({
    required String businessId,
    required String fromAccountId,
    required String toAccountId,
    required int amount,
    DateTime? transferDate,
    String? description,
    String? idempotencyKey,
  }) async {
    if (_isOnline()) {
      try {
        final id = await _remote.record(
          businessId: businessId,
          fromAccountId: fromAccountId,
          toAccountId: toAccountId,
          amount: amount,
          transferDate: transferDate,
          description: description,
          idempotencyKey: idempotencyKey,
        );
        final list = await _remote.list(businessId: businessId);
        await _local.upsertMany(list);
        return id;
      } catch (_) {}
    }

    if (fromAccountId == toAccountId) {
      throw StateError('Akun asal dan tujuan harus berbeda.');
    }

    final now = DateTime.now().toUtc();
    final id = _uuid.v4();
    final tr = Transfer(
      id: id,
      businessId: businessId,
      fromAccountId: fromAccountId,
      toAccountId: toAccountId,
      amount: amount,
      currency: 'IDR',
      transferDate: transferDate ?? now,
      status: 'confirmed',
      createdAt: now,
      description: description,
    );
    await _local.upsert(tr);
    await _queue.enqueue(
      businessId: businessId,
      entityType: 'transfers',
      entityId: id,
      operation: SyncOperation.insert,
      payload: jsonEncode(_toMap(tr)),
      idempotencyKey:
          idempotencyKey ?? 'tr_${id}_${now.millisecondsSinceEpoch}',
    );
    return id;
  }

  @override
  Future<void> voidTransfer({
    required String transferId,
    required String reason,
  }) async {
    if (!_isOnline()) {
      throw StateError(
        'Void transfer memerlukan koneksi internet. '
        'Coba lagi saat online.',
      );
    }
    await _remote.voidTransfer(transferId: transferId, reason: reason);
  }

  @override
  Future<void> upsert(Transfer transfer) async {
    await _remote.upsert(transfer);
  }
}
