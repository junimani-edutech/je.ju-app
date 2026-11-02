import 'package:supabase_flutter/supabase_flutter.dart';

import '../payments/payment.dart' show Account;
import 'category.dart';
import 'finance_models.dart';
import 'finance_services.dart';
import 'transaction.dart';
import 'transfer.dart';

String? _dateStr(DateTime? d) {
  if (d == null) return null;
  return d.toIso8601String().substring(0, 10);
}

class SupabaseTransactionsService implements TransactionsService {
  SupabaseTransactionsService(this._client);
  final SupabaseClient _client;

  @override
  Future<List<Transaction>> list({required String businessId}) async {
    final rows = await _client
        .from('transactions')
        .select()
        .eq('business_id', businessId)
        .order('transaction_date', ascending: false)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => Transaction.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Category>> listCategories(String businessId) async {
    final rows = await _client
        .from('categories')
        .select()
        .eq('business_id', businessId)
        .eq('status', 'active')
        .order('name');
    return (rows as List)
        .map((e) => Category.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Account>> listAccounts(String businessId) async {
    final rows = await _client
        .from('accounts')
        .select()
        .eq('business_id', businessId)
        .eq('status', 'active')
        .order('name');
    return (rows as List)
        .map((e) => Account.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<AccountBalance>> accountBalances(String businessId) async {
    final rows = await _client.rpc(
      'account_balances',
      params: {'p_business_id': businessId},
    );
    return (rows as List)
        .map((e) => AccountBalance.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<CashFlowSummary> cashFlowSummary({
    required String businessId,
    required DateTime from,
    required DateTime to,
  }) async {
    final json = await _client.rpc(
      'cash_flow_summary',
      params: {
        'p_business_id': businessId,
        'p_from': _dateStr(from),
        'p_to': _dateStr(to),
      },
    );
    return CashFlowSummary.fromJson(json as Map<String, dynamic>);
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
    final id = await _client.rpc(
      'record_transaction',
      params: {
        'p_business_id': businessId,
        'p_type': type,
        'p_amount': amount,
        'p_description': description,
        'p_category_id': categoryId,
        'p_account_id': accountId,
        'p_transaction_date': _dateStr(transactionDate),
        'p_reference': reference,
        'p_attachment_url': attachmentUrl,
        'p_idempotency_key': idempotencyKey,
      },
    );
    return id as String;
  }

  @override
  Future<String> voidTransaction({
    required String transactionId,
    required String reason,
  }) async {
    final id = await _client.rpc(
      'void_transaction',
      params: {'p_transaction_id': transactionId, 'p_reason': reason},
    );
    return id as String;
  }

  @override
  Future<void> upsert(Transaction t) async {
    await _client.rpc(
      'upsert_transaction',
      params: {
        'p_id': t.id,
        'p_business_id': t.businessId,
        'p_type': t.type,
        'p_amount': t.amount,
        'p_description': t.description,
        'p_category_id': t.categoryId,
        'p_account_id': t.accountId,
        'p_transaction_date': _dateStr(t.transactionDate),
        'p_reference': t.reference,
        'p_idempotency_key': null,
      },
    );
  }
}

class SupabaseTransfersService implements TransfersService {
  SupabaseTransfersService(this._client);
  final SupabaseClient _client;

  @override
  Future<List<Transfer>> list({required String businessId}) async {
    final rows = await _client
        .from('transfers')
        .select()
        .eq('business_id', businessId)
        .order('transfer_date', ascending: false)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => Transfer.fromMap(e as Map<String, dynamic>))
        .toList();
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
    final id = await _client.rpc(
      'record_transfer',
      params: {
        'p_business_id': businessId,
        'p_from_account_id': fromAccountId,
        'p_to_account_id': toAccountId,
        'p_amount': amount,
        'p_transfer_date': _dateStr(transferDate),
        'p_description': description,
        'p_idempotency_key': idempotencyKey,
      },
    );
    return id as String;
  }

  @override
  Future<void> voidTransfer({
    required String transferId,
    required String reason,
  }) async {
    await _client.rpc(
      'void_transfer',
      params: {'p_transfer_id': transferId, 'p_reason': reason},
    );
  }

  @override
  Future<void> upsert(Transfer tr) async {
    await _client.rpc(
      'upsert_transfer',
      params: {
        'p_id': tr.id,
        'p_business_id': tr.businessId,
        'p_from_account_id': tr.fromAccountId,
        'p_to_account_id': tr.toAccountId,
        'p_amount': tr.amount,
        'p_transfer_date': _dateStr(tr.transferDate),
        'p_description': tr.description,
        'p_idempotency_key': null,
      },
    );
  }
}
