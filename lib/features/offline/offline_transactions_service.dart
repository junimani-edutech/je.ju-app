// ignore_for_file: prefer_initializing_formals
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../finance/category.dart';
import '../finance/finance_models.dart';
import '../finance/finance_services.dart';
import '../finance/supabase_finance_services.dart';
import '../finance/transaction.dart';
import '../payments/payment.dart' show Account;
import 'local_transactions_repo.dart';
import 'providers.dart';
import 'sync_queue_repository.dart';

class OfflineTransactionsService implements TransactionsService {
  OfflineTransactionsService({
    required SupabaseTransactionsService remote,
    required LocalTransactionsRepo local,
    required SyncQueueRepository queue,
    required Ref ref,
  }) : _remote = remote,
       _local = local,
       _queue = queue,
       _ref = ref;

  final SupabaseTransactionsService _remote;
  final LocalTransactionsRepo _local;
  final SyncQueueRepository _queue;
  final Ref _ref;
  final Uuid _uuid = const Uuid();

  bool _isOnline() =>
      _ref.read(networkStatusProvider).value == NetworkStatus.online;

  Map<String, dynamic> _toMap(Transaction t) => {
    'id': t.id,
    'business_id': t.businessId,
    'type': t.type,
    'amount': t.amount,
    'currency': t.currency,
    'transaction_date': t.transactionDate.toIso8601String().substring(0, 10),
    'description': t.description,
    'category_id': t.categoryId,
    'account_id': t.accountId,
    'reference': t.reference,
    'status': t.status,
    'created_at': t.createdAt.toIso8601String(),
    'reversal_of_transaction_id': t.reversalOfTransactionId,
  };

  @override
  Future<List<Transaction>> list({required String businessId}) async {
    if (_isOnline()) {
      try {
        final remote = await _remote.list(businessId: businessId);
        await _local.upsertMany(remote);
      } catch (_) {}
    }
    return _local.list(businessId: businessId);
  }

  @override
  Future<List<Category>> listCategories(String businessId) async {
    if (_isOnline()) {
      try {
        return await _remote.listCategories(businessId);
      } catch (_) {}
    }
    return const <Category>[];
  }

  @override
  Future<List<Account>> listAccounts(String businessId) async {
    if (_isOnline()) {
      try {
        return await _remote.listAccounts(businessId);
      } catch (_) {}
    }
    return const <Account>[];
  }

  @override
  Future<List<AccountBalance>> accountBalances(String businessId) async {
    if (_isOnline()) {
      try {
        return await _remote.accountBalances(businessId);
      } catch (_) {}
    }
    return const <AccountBalance>[];
  }

  @override
  Future<CashFlowSummary> cashFlowSummary({
    required String businessId,
    required DateTime from,
    required DateTime to,
  }) async {
    if (_isOnline()) {
      try {
        return await _remote.cashFlowSummary(
          businessId: businessId,
          from: from,
          to: to,
        );
      } catch (_) {}
    }
    return const CashFlowSummary(income: 0, expense: 0, paymentsNet: 0, net: 0);
  }

  @override
  Future<String> record({
    required String businessId,
    required String type,
    required int amount,
    required String description,
    String? categoryId,
    String? accountId,
    DateTime? transactionDate,
    String? reference,
    String? attachmentUrl,
    String? idempotencyKey,
  }) async {
    if (_isOnline()) {
      try {
        final id = await _remote.record(
          businessId: businessId,
          type: type,
          amount: amount,
          description: description,
          categoryId: categoryId,
          accountId: accountId,
          transactionDate: transactionDate,
          reference: reference,
          attachmentUrl: attachmentUrl,
          idempotencyKey: idempotencyKey,
        );
        // Pull kembali untuk cache lokal.
        final list = await _remote.list(businessId: businessId);
        await _local.upsertMany(list);
        return id;
      } catch (_) {}
    }

    final now = DateTime.now().toUtc();
    final id = _uuid.v4();
    final t = Transaction(
      id: id,
      businessId: businessId,
      type: type,
      amount: amount,
      currency: 'IDR',
      transactionDate: transactionDate ?? now,
      description: description,
      status: 'confirmed',
      createdAt: now,
      categoryId: categoryId,
      accountId: accountId,
      reference: reference,
      attachmentUrl: attachmentUrl,
    );
    await _local.upsert(t);
    await _queue.enqueue(
      businessId: businessId,
      entityType: 'transactions',
      entityId: id,
      operation: SyncOperation.insert,
      payload: jsonEncode(_toMap(t)),
      idempotencyKey:
          idempotencyKey ?? 'tx_${id}_${now.millisecondsSinceEpoch}',
    );
    return id;
  }

  @override
  Future<String> voidTransaction({
    required String transactionId,
    required String reason,
  }) async {
    if (!_isOnline()) {
      throw StateError(
        'Void transaksi memerlukan koneksi internet. '
        'Coba lagi saat online.',
      );
    }
    return _remote.voidTransaction(
      transactionId: transactionId,
      reason: reason,
    );
  }

  @override
  Future<void> upsert(Transaction transaction) async {
    await _remote.upsert(transaction);
  }
}
