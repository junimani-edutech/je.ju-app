import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../finance/transfer.dart';
import 'db/app_database.dart';
import 'providers.dart';

class LocalTransfersRepo {
  LocalTransfersRepo(this._db);
  final AppDatabase _db;

  Future<List<Transfer>> list({required String businessId}) async {
    final rows =
        await (_db.select(_db.transfersTable)
              ..where((t) => t.businessId.equals(businessId))
              ..orderBy([
                (t) => OrderingTerm.desc(t.transferDate),
                (t) => OrderingTerm.desc(t.createdAt),
              ]))
            .get();
    return rows.map(_toTransfer).toList();
  }

  Future<Transfer?> byId(String id) async {
    final row =
        await (_db.select(_db.transfersTable)
              ..where((t) => t.id.equals(id))
              ..limit(1))
            .getSingleOrNull();
    return row == null ? null : _toTransfer(row);
  }

  Future<void> upsert(Transfer tr) async {
    await _db.into(_db.transfersTable).insertOnConflictUpdate(_companion(tr));
  }

  Future<void> upsertMany(List<Transfer> list) async {
    if (list.isEmpty) return;
    await _db.batch((batch) {
      for (final tr in list) {
        batch.insert(
          _db.transfersTable,
          _companion(tr),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> delete(String id) async {
    await (_db.delete(_db.transfersTable)..where((t) => t.id.equals(id))).go();
  }

  TransfersTableCompanion _companion(Transfer tr) => TransfersTableCompanion(
    id: Value(tr.id),
    businessId: Value(tr.businessId),
    fromAccountId: Value(tr.fromAccountId),
    toAccountId: Value(tr.toAccountId),
    amount: Value(tr.amount),
    currency: Value(tr.currency),
    transferDate: Value(tr.transferDate),
    description: Value(tr.description),
    status: Value(tr.status),
    cancelledAt: Value(tr.cancelledAt),
    cancelReason: Value(tr.cancelReason),
    createdAt: Value(tr.createdAt),
    updatedAt: Value(tr.createdAt),
  );

  Transfer _toTransfer(TransfersTableData row) => Transfer(
    id: row.id,
    businessId: row.businessId,
    fromAccountId: row.fromAccountId,
    toAccountId: row.toAccountId,
    amount: row.amount,
    currency: row.currency,
    transferDate: row.transferDate,
    status: row.status,
    createdAt: row.createdAt,
    description: row.description,
    cancelledAt: row.cancelledAt,
    cancelReason: row.cancelReason,
  );
}

final localTransfersRepoProvider = Provider<LocalTransfersRepo>((ref) {
  return LocalTransfersRepo(ref.watch(appDatabaseProvider));
});
