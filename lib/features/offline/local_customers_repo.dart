import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../customers/customer.dart';
import 'db/app_database.dart';
import 'providers.dart';

class LocalCustomersRepo {
  LocalCustomersRepo(this._db);
  final AppDatabase _db;

  Future<List<Customer>> list({
    required String businessId,
    bool includeArchived = false,
  }) async {
    final query = _db.select(_db.customersTable)
      ..where((t) => t.businessId.equals(businessId));
    if (!includeArchived) {
      query.where((t) => t.status.equals('active'));
    }
    query.orderBy([(t) => OrderingTerm.asc(t.name)]);
    final rows = await query.get();
    return rows.map(_toCustomer).toList();
  }

  Future<Customer?> byId(String id) async {
    final row =
        await (_db.select(_db.customersTable)
              ..where((t) => t.id.equals(id))
              ..limit(1))
            .getSingleOrNull();
    return row == null ? null : _toCustomer(row);
  }

  Future<void> upsert(Customer c) async {
    await _db
        .into(_db.customersTable)
        .insertOnConflictUpdate(
          CustomersTableCompanion(
            id: Value(c.id),
            businessId: Value(c.businessId),
            name: Value(c.name),
            phone: Value(c.phone),
            email: Value(c.email),
            address: Value(c.address),
            notes: Value(c.notes),
            status: Value(c.status),
            createdAt: Value(c.createdAt),
            updatedAt: Value(c.updatedAt),
          ),
        );
  }

  Future<void> upsertMany(List<Customer> list) async {
    if (list.isEmpty) return;
    await _db.batch((batch) {
      for (final c in list) {
        batch.insert(
          _db.customersTable,
          CustomersTableCompanion(
            id: Value(c.id),
            businessId: Value(c.businessId),
            name: Value(c.name),
            phone: Value(c.phone),
            email: Value(c.email),
            address: Value(c.address),
            notes: Value(c.notes),
            status: Value(c.status),
            createdAt: Value(c.createdAt),
            updatedAt: Value(c.updatedAt),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> delete(String id) async {
    await (_db.delete(_db.customersTable)..where((t) => t.id.equals(id))).go();
  }

  Customer _toCustomer(CustomersTableData row) => Customer(
    id: row.id,
    businessId: row.businessId,
    name: row.name,
    status: row.status,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    phone: row.phone,
    email: row.email,
    address: row.address,
    notes: row.notes,
  );
}

final localCustomersRepoProvider = Provider<LocalCustomersRepo>((ref) {
  return LocalCustomersRepo(ref.watch(appDatabaseProvider));
});
