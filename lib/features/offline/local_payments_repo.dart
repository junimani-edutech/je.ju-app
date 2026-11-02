import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../payments/payment.dart';
import 'db/app_database.dart';
import 'providers.dart';

class LocalPaymentsRepo {
  LocalPaymentsRepo(this._db);
  final AppDatabase _db;

  Future<List<Payment>> listForOrder(String orderId) async {
    final rows =
        await (_db.select(_db.paymentsTable)
              ..where((t) => t.orderId.equals(orderId))
              ..orderBy([
                (t) => OrderingTerm.desc(t.paymentDate),
                (t) => OrderingTerm.desc(t.createdAt),
              ]))
            .get();
    return rows.map(_toPayment).toList();
  }

  Future<Payment?> byId(String id) async {
    final row =
        await (_db.select(_db.paymentsTable)
              ..where((t) => t.id.equals(id))
              ..limit(1))
            .getSingleOrNull();
    return row == null ? null : _toPayment(row);
  }

  Future<void> upsert(Payment p) async {
    await _db.into(_db.paymentsTable).insertOnConflictUpdate(_companion(p));
  }

  Future<void> upsertMany(List<Payment> list) async {
    if (list.isEmpty) return;
    await _db.batch((batch) {
      for (final p in list) {
        batch.insert(
          _db.paymentsTable,
          _companion(p),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> delete(String id) async {
    await (_db.delete(_db.paymentsTable)..where((t) => t.id.equals(id))).go();
  }

  PaymentsTableCompanion _companion(Payment p) => PaymentsTableCompanion(
    id: Value(p.id),
    businessId: Value(p.businessId),
    orderId: Value(p.orderId),
    amount: Value(p.amount),
    currency: Value(p.currency),
    paymentDate: Value(p.paymentDate),
    paymentMethodId: Value(p.paymentMethodId),
    accountId: Value(p.accountId),
    reference: Value(p.reference),
    notes: Value(p.notes),
    status: Value(p.status),
    confirmedAt: Value(p.confirmedAt),
    cancelledAt: Value(p.cancelledAt),
    cancelReason: Value(p.cancelReason),
    reversalOfPaymentId: Value(p.reversalOfPaymentId),
    createdAt: Value(p.createdAt),
    updatedAt: Value(p.createdAt), // dibuat = diupdate saat insert
  );

  Payment _toPayment(PaymentsTableData row) => Payment(
    id: row.id,
    businessId: row.businessId,
    orderId: row.orderId,
    amount: row.amount,
    currency: row.currency,
    paymentDate: row.paymentDate,
    status: row.status,
    createdAt: row.createdAt,
    paymentMethodId: row.paymentMethodId,
    accountId: row.accountId,
    reference: row.reference,
    notes: row.notes,
    reversalOfPaymentId: row.reversalOfPaymentId,
    confirmedAt: row.confirmedAt,
    cancelledAt: row.cancelledAt,
    cancelReason: row.cancelReason,
  );
}

final localPaymentsRepoProvider = Provider<LocalPaymentsRepo>((ref) {
  return LocalPaymentsRepo(ref.watch(appDatabaseProvider));
});
