import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../products/product.dart';
import 'db/app_database.dart';
import 'providers.dart';

class LocalProductsRepo {
  LocalProductsRepo(this._db);
  final AppDatabase _db;

  Future<List<Product>> list({
    required String businessId,
    bool includeArchived = false,
  }) async {
    final q = _db.select(_db.productsTable)
      ..where((t) => t.businessId.equals(businessId));
    if (!includeArchived) q.where((t) => t.status.equals('active'));
    q.orderBy([(t) => OrderingTerm.asc(t.name)]);
    final rows = await q.get();
    return rows.map(_toProduct).toList();
  }

  Future<Product?> byId(String id) async {
    final row =
        await (_db.select(_db.productsTable)
              ..where((t) => t.id.equals(id))
              ..limit(1))
            .getSingleOrNull();
    return row == null ? null : _toProduct(row);
  }

  Future<void> upsert(Product p) async {
    await _db
        .into(_db.productsTable)
        .insertOnConflictUpdate(
          ProductsTableCompanion(
            id: Value(p.id),
            businessId: Value(p.businessId),
            name: Value(p.name),
            price: Value(p.price),
            description: Value(p.description),
            status: Value(p.status),
            createdAt: Value(p.createdAt),
            updatedAt: Value(p.updatedAt),
          ),
        );
  }

  Future<void> upsertMany(List<Product> list) async {
    if (list.isEmpty) return;
    await _db.batch((batch) {
      for (final p in list) {
        batch.insert(
          _db.productsTable,
          ProductsTableCompanion(
            id: Value(p.id),
            businessId: Value(p.businessId),
            name: Value(p.name),
            price: Value(p.price),
            description: Value(p.description),
            status: Value(p.status),
            createdAt: Value(p.createdAt),
            updatedAt: Value(p.updatedAt),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Product _toProduct(ProductsTableData r) => Product(
    id: r.id,
    businessId: r.businessId,
    name: r.name,
    price: r.price,
    status: r.status,
    description: r.description,
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
  );
}

final localProductsRepoProvider = Provider<LocalProductsRepo>(
  (ref) => LocalProductsRepo(ref.watch(appDatabaseProvider)),
);
