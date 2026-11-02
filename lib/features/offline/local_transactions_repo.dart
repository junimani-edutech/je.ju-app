import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../finance/transaction.dart';
import 'db/app_database.dart';
import 'providers.dart';

class LocalTransactionsRepo {
  LocalTransactionsRepo(this._db);
  final AppDatabase _db;

  Future<List<Transaction>> list({required String businessId}) async {
    final rows =
        await (_db.select(_db.transactionsTable)
              ..where((t) => t.businessId.equals(businessId))
              ..orderBy([
                (t) => OrderingTerm.desc(t.transactionDate),
                (t) => OrderingTerm.desc(t.createdAt),
              ]))
            .get();
    return rows.map(_toTransaction).toList();
  }

  Future<Transaction?> byId(String id) async {
    final row =
        await (_db.select(_db.transactionsTable)
              ..where((t) => t.id.equals(id))
              ..limit(1))
            .getSingleOrNull();
    return row == null ? null : _toTransaction(row);
  }

  Future<void> upsert(Transaction t) async {
    await _db.into(_db.transactionsTable).insertOnConflictUpdate(_companion(t));
  }

  Future<void> upsertMany(List<Transaction> list) async {
    if (list.isEmpty) return;
    await _db.batch((batch) {
      for (final t in list) {
        batch.insert(
          _db.transactionsTable,
          _companion(t),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> delete(String id) async {
    await (_db.delete(
      _db.transactionsTable,
    )..where((t) => t.id.equals(id))).go();
  }

  TransactionsTableCompanion _companion(Transaction t) =>
      TransactionsTableCompanion(
        id: Value(t.id),
        businessId: Value(t.businessId),
        type: Value(t.type),
        categoryId: Value(t.categoryId),
        accountId: Value(t.accountId),
        amount: Value(t.amount),
        currency: Value(t.currency),
        transactionDate: Value(t.transactionDate),
        description: Value(t.description),
        reference: Value(t.reference),
        attachmentUrl: Value(t.attachmentUrl),
        status: Value(t.status),
        reversalOfTransactionId: Value(t.reversalOfTransactionId),
        cancelledAt: Value(t.cancelledAt),
        cancelReason: Value(t.cancelReason),
        createdAt: Value(t.createdAt),
        updatedAt: Value(t.createdAt),
      );

  Transaction _toTransaction(TransactionsTableData row) => Transaction(
    id: row.id,
    businessId: row.businessId,
    type: row.type,
    amount: row.amount,
    currency: row.currency,
    transactionDate: row.transactionDate,
    description: row.description,
    status: row.status,
    createdAt: row.createdAt,
    categoryId: row.categoryId,
    accountId: row.accountId,
    reference: row.reference,
    attachmentUrl: row.attachmentUrl,
    reversalOfTransactionId: row.reversalOfTransactionId,
    cancelledAt: row.cancelledAt,
    cancelReason: row.cancelReason,
  );
}

final localTransactionsRepoProvider = Provider<LocalTransactionsRepo>((ref) {
  return LocalTransactionsRepo(ref.watch(appDatabaseProvider));
});
