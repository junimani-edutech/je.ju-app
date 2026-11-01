import '../payments/payment.dart' show Account;
import 'category.dart';
import 'finance_models.dart';
import 'transaction.dart';
import 'transfer.dart';

abstract class TransactionsService {
  Future<List<Transaction>> list({required String businessId});
  Future<List<Category>> listCategories(String businessId);
  Future<List<Account>> listAccounts(String businessId);
  Future<List<AccountBalance>> accountBalances(String businessId);
  Future<CashFlowSummary> cashFlowSummary({
    required String businessId,
    required DateTime from,
    required DateTime to,
  });

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
  });

  Future<String> voidTransaction({
    required String transactionId,
    required String reason,
  });
}

abstract class TransfersService {
  Future<List<Transfer>> list({required String businessId});

  Future<String> record({
    required String businessId,
    required String fromAccountId,
    required String toAccountId,
    required int amount,
    DateTime? transferDate,
    String? description,
    String? idempotencyKey,
  });

  Future<void> voidTransfer({
    required String transferId,
    required String reason,
  });
}
