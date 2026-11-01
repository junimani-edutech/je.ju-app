import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../payments/payment.dart' show Account;
import 'category.dart';
import 'finance_models.dart';
import 'finance_services.dart';
import 'transaction.dart';
import 'transfer.dart';

final transactionsServiceProvider = Provider<TransactionsService>((ref) {
  throw UnimplementedError('transactionsServiceProvider belum di-override');
});

final transfersServiceProvider = Provider<TransfersService>((ref) {
  throw UnimplementedError('transfersServiceProvider belum di-override');
});

// ------------------- reads -------------------

final financeCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  final biz = await ref.watch(currentBusinessProvider.future);
  if (biz == null) return const <Category>[];
  return ref.watch(transactionsServiceProvider).listCategories(biz.id);
});

final financeAccountsProvider = FutureProvider<List<Account>>((ref) async {
  final biz = await ref.watch(currentBusinessProvider.future);
  if (biz == null) return const <Account>[];
  return ref.watch(transactionsServiceProvider).listAccounts(biz.id);
});

final accountBalancesProvider = FutureProvider<List<AccountBalance>>((
  ref,
) async {
  final biz = await ref.watch(currentBusinessProvider.future);
  if (biz == null) return const <AccountBalance>[];
  return ref.watch(transactionsServiceProvider).accountBalances(biz.id);
});

final cashFlowSummaryProvider =
    FutureProvider.family<CashFlowSummary, ({DateTime from, DateTime to})>((
      ref,
      range,
    ) async {
      final biz = await ref.watch(currentBusinessProvider.future);
      if (biz == null) {
        return const CashFlowSummary(
          income: 0,
          expense: 0,
          paymentsNet: 0,
          net: 0,
        );
      }
      return ref
          .watch(transactionsServiceProvider)
          .cashFlowSummary(businessId: biz.id, from: range.from, to: range.to);
    });

// ------------------- list notifiers -------------------

class TransactionsNotifier extends AsyncNotifier<List<Transaction>> {
  @override
  Future<List<Transaction>> build() async {
    final biz = await ref.watch(currentBusinessProvider.future);
    if (biz == null) return const <Transaction>[];
    return ref.watch(transactionsServiceProvider).list(businessId: biz.id);
  }

  Future<void> _reload() async {
    final biz = await ref.read(currentBusinessProvider.future);
    if (biz == null) {
      state = const AsyncData(<Transaction>[]);
      return;
    }
    state = AsyncData(
      await ref.read(transactionsServiceProvider).list(businessId: biz.id),
    );
  }

  Future<String> record({
    required String type,
    required int amount,
    required String description,
    String? categoryId,
    String? accountId,
    DateTime? transactionDate,
    String? reference,
    String? idempotencyKey,
  }) async {
    final biz = await ref.read(currentBusinessProvider.future);
    if (biz == null) throw StateError('Tidak ada bisnis aktif');
    final id = await ref
        .read(transactionsServiceProvider)
        .record(
          businessId: biz.id,
          type: type,
          amount: amount,
          description: description,
          categoryId: categoryId,
          accountId: accountId,
          transactionDate: transactionDate,
          reference: reference,
          idempotencyKey: idempotencyKey,
        );
    await _reload();
    ref.invalidate(accountBalancesProvider);
    return id;
  }

  Future<String> voidTransaction({
    required String transactionId,
    required String reason,
  }) async {
    final id = await ref
        .read(transactionsServiceProvider)
        .voidTransaction(transactionId: transactionId, reason: reason);
    await _reload();
    ref.invalidate(accountBalancesProvider);
    return id;
  }
}

final transactionsProvider =
    AsyncNotifierProvider<TransactionsNotifier, List<Transaction>>(
      TransactionsNotifier.new,
    );

class TransfersNotifier extends AsyncNotifier<List<Transfer>> {
  @override
  Future<List<Transfer>> build() async {
    final biz = await ref.watch(currentBusinessProvider.future);
    if (biz == null) return const <Transfer>[];
    return ref.watch(transfersServiceProvider).list(businessId: biz.id);
  }

  Future<void> _reload() async {
    final biz = await ref.read(currentBusinessProvider.future);
    if (biz == null) {
      state = const AsyncData(<Transfer>[]);
      return;
    }
    state = AsyncData(
      await ref.read(transfersServiceProvider).list(businessId: biz.id),
    );
  }

  Future<String> record({
    required String fromAccountId,
    required String toAccountId,
    required int amount,
    DateTime? transferDate,
    String? description,
    String? idempotencyKey,
  }) async {
    final biz = await ref.read(currentBusinessProvider.future);
    if (biz == null) throw StateError('Tidak ada bisnis aktif');
    final id = await ref
        .read(transfersServiceProvider)
        .record(
          businessId: biz.id,
          fromAccountId: fromAccountId,
          toAccountId: toAccountId,
          amount: amount,
          transferDate: transferDate,
          description: description,
          idempotencyKey: idempotencyKey,
        );
    await _reload();
    ref.invalidate(accountBalancesProvider);
    return id;
  }

  Future<void> voidTransfer({
    required String transferId,
    required String reason,
  }) async {
    await ref
        .read(transfersServiceProvider)
        .voidTransfer(transferId: transferId, reason: reason);
    await _reload();
    ref.invalidate(accountBalancesProvider);
  }
}

final transfersProvider =
    AsyncNotifierProvider<TransfersNotifier, List<Transfer>>(
      TransfersNotifier.new,
    );
