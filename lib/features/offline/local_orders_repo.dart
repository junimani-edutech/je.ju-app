import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../orders/order.dart';
import 'db/app_database.dart';
import 'providers.dart';

class LocalOrdersRepo {
  LocalOrdersRepo(this._db);
  final AppDatabase _db;

  Future<List<Order>> list({required String businessId}) async {
    final query = _db.select(_db.ordersTable)
      ..where((t) => t.businessId.equals(businessId))
      ..orderBy([
        (t) => OrderingTerm.desc(t.orderDate),
        (t) => OrderingTerm.desc(t.createdAt),
      ]);
    final rows = await query.get();
    return rows.map(_toOrder).toList();
  }

  Future<Order?> byId(String id) async {
    final row =
        await (_db.select(_db.ordersTable)
              ..where((t) => t.id.equals(id))
              ..limit(1))
            .getSingleOrNull();
    return row == null ? null : _toOrder(row);
  }

  Future<List<OrderItem>> listItems(String orderId) async {
    final rows =
        await (_db.select(_db.orderItemsTable)
              ..where((t) => t.orderId.equals(orderId))
              ..orderBy([(t) => OrderingTerm.asc(t.position)]))
            .get();
    return rows.map(_toOrderItem).toList();
  }

  Future<void> upsertWithItems(Order order, List<OrderItem> items) async {
    await _db.transaction(() async {
      await _db
          .into(_db.ordersTable)
          .insertOnConflictUpdate(_orderCompanion(order));
      // Hapus items lama dulu agar tidak ada sisa kalau update.
      await (_db.delete(
        _db.orderItemsTable,
      )..where((t) => t.orderId.equals(order.id))).go();
      if (items.isNotEmpty) {
        await _db.batch((batch) {
          for (final it in items) {
            batch.insert(
              _db.orderItemsTable,
              _itemCompanion(it),
              mode: InsertMode.insertOrReplace,
            );
          }
        });
      }
    });
  }

  /// Upsert order saja (tidak menyentuh items). Dipakai pull dari server.
  Future<void> upsertOrderOnly(Order o) async {
    await _db.into(_db.ordersTable).insertOnConflictUpdate(_orderCompanion(o));
  }

  Future<void> delete(String orderId) async {
    await _db.transaction(() async {
      await (_db.delete(
        _db.orderItemsTable,
      )..where((t) => t.orderId.equals(orderId))).go();
      await (_db.delete(
        _db.ordersTable,
      )..where((t) => t.id.equals(orderId))).go();
    });
  }

  OrdersTableCompanion _orderCompanion(Order o) => OrdersTableCompanion(
    id: Value(o.id),
    businessId: Value(o.businessId),
    orderNumber: Value(o.orderNumber),
    customerId: Value(o.customerId),
    orderDate: Value(o.orderDate),
    dueDate: Value(o.dueDate),
    subtotalAmount: Value(o.subtotalAmount),
    discountAmount: Value(o.discountAmount),
    additionalFeeAmount: Value(o.additionalFeeAmount),
    shippingAmount: Value(o.shippingAmount),
    totalAmount: Value(o.totalAmount),
    paidAmount: Value(o.paidAmount),
    currency: Value(o.currency),
    notes: Value(o.notes),
    orderStatusId: Value(o.orderStatusId),
    paymentStatus: Value(o.paymentStatus),
    status: Value(o.status),
    createdAt: Value(o.createdAt),
    updatedAt: Value(o.updatedAt),
  );

  OrderItemsTableCompanion _itemCompanion(OrderItem it) =>
      OrderItemsTableCompanion(
        id: Value(it.id),
        businessId: Value(it.businessId),
        orderId: Value(it.orderId),
        position: Value(it.position),
        description: Value(it.description),
        quantity: Value(it.quantity),
        unitPrice: Value(it.unitPrice),
        discountAmount: Value(it.discountAmount),
        lineTotal: Value(it.lineTotal),
        createdAt: Value(DateTime.now().toUtc()),
      );

  Order _toOrder(OrdersTableData row) => Order(
    id: row.id,
    businessId: row.businessId,
    orderNumber: row.orderNumber,
    customerId: row.customerId,
    orderDate: row.orderDate,
    dueDate: row.dueDate,
    subtotalAmount: row.subtotalAmount,
    discountAmount: row.discountAmount,
    additionalFeeAmount: row.additionalFeeAmount,
    shippingAmount: row.shippingAmount,
    totalAmount: row.totalAmount,
    paidAmount: row.paidAmount,
    currency: row.currency,
    notes: row.notes,
    orderStatusId: row.orderStatusId,
    paymentStatus: row.paymentStatus,
    status: row.status,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  OrderItem _toOrderItem(OrderItemsTableData row) => OrderItem(
    id: row.id,
    businessId: row.businessId,
    orderId: row.orderId,
    position: row.position,
    description: row.description,
    quantity: row.quantity,
    unitPrice: row.unitPrice,
    discountAmount: row.discountAmount,
    lineTotal: row.lineTotal,
  );
}

final localOrdersRepoProvider = Provider<LocalOrdersRepo>((ref) {
  return LocalOrdersRepo(ref.watch(appDatabaseProvider));
});
