// ignore_for_file: prefer_initializing_formals
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../orders/order.dart';
import '../orders/orders_service.dart';
import '../orders/supabase_orders_service.dart';
import 'local_orders_repo.dart';
import 'providers.dart';
import 'sync_queue_repository.dart';

class OfflineOrdersService implements OrdersService {
  OfflineOrdersService({
    required SupabaseOrdersService remote,
    required LocalOrdersRepo local,
    required SyncQueueRepository queue,
    required Ref ref,
  }) : _remote = remote,
       _local = local,
       _queue = queue,
       _ref = ref;

  final SupabaseOrdersService _remote;
  final LocalOrdersRepo _local;
  final SyncQueueRepository _queue;
  final Ref _ref;
  final Uuid _uuid = const Uuid();

  bool _isOnline() {
    return _ref.read(networkStatusProvider).value == NetworkStatus.online;
  }

  Map<String, dynamic> _orderToMap(Order o) => {
    'id': o.id,
    'business_id': o.businessId,
    'order_number': o.orderNumber,
    'customer_id': o.customerId,
    'order_date': o.orderDate.toIso8601String().substring(0, 10),
    'due_date': o.dueDate?.toIso8601String().substring(0, 10),
    'subtotal_amount': o.subtotalAmount,
    'discount_amount': o.discountAmount,
    'additional_fee_amount': o.additionalFeeAmount,
    'shipping_amount': o.shippingAmount,
    'total_amount': o.totalAmount,
    'paid_amount': o.paidAmount,
    'currency': o.currency,
    'notes': o.notes,
    'order_status_id': o.orderStatusId,
    'payment_status': o.paymentStatus,
    'status': o.status,
    'created_at': o.createdAt.toIso8601String(),
    'updated_at': o.updatedAt.toIso8601String(),
  };

  Map<String, dynamic> _itemToMap(OrderItem it) => {
    'id': it.id,
    'business_id': it.businessId,
    'order_id': it.orderId,
    'position': it.position,
    'description': it.description,
    'quantity': it.quantity,
    'unit_price': it.unitPrice,
    'discount_amount': it.discountAmount,
    'line_total': it.lineTotal,
  };

  @override
  Future<List<Order>> list({required String businessId}) async {
    if (_isOnline()) {
      try {
        final remote = await _remote.list(businessId: businessId);
        for (final o in remote) {
          await _local.upsertOrderOnly(o);
        }
      } catch (_) {}
    }
    return _local.list(businessId: businessId);
  }

  @override
  Future<Order> get(String orderId) async {
    if (_isOnline()) {
      try {
        final remote = await _remote.get(orderId);
        final items = await _remote.listItems(orderId);
        await _local.upsertWithItems(remote, items);
        return remote;
      } catch (_) {}
    }
    final local = await _local.byId(orderId);
    if (local == null) {
      throw StateError('Pesanan tidak ditemukan: $orderId');
    }
    return local;
  }

  @override
  Future<List<OrderItem>> listItems(String orderId) async {
    return _local.listItems(orderId);
  }

  @override
  Future<List<OrderStatus>> listStatuses(String businessId) async {
    if (_isOnline()) {
      try {
        return await _remote.listStatuses(businessId);
      } catch (_) {}
    }
    // Offline: kembalikan kosong. UI tampilkan '—' untuk status.
    return const <OrderStatus>[];
  }

  @override
  Future<String> create({
    required String businessId,
    required List<OrderItemInput> items,
    String? customerId,
    DateTime? orderDate,
    DateTime? dueDate,
    String? notes,
    int discountAmount = 0,
    int additionalFeeAmount = 0,
    int shippingAmount = 0,
  }) async {
    if (_isOnline()) {
      try {
        final id = await _remote.create(
          businessId: businessId,
          items: items,
          customerId: customerId,
          orderDate: orderDate,
          dueDate: dueDate,
          notes: notes,
          discountAmount: discountAmount,
          additionalFeeAmount: additionalFeeAmount,
          shippingAmount: shippingAmount,
        );
        final order = await _remote.get(id);
        final savedItems = await _remote.listItems(id);
        await _local.upsertWithItems(order, savedItems);
        return id;
      } catch (_) {}
    }

    final now = DateTime.now().toUtc();
    final orderId = _uuid.v4();
    final orderNumber = 'OFFLINE-${orderId.substring(0, 8).toUpperCase()}';
    final subtotal = items.fold<int>(0, (acc, e) => acc + e.lineTotal);
    final total =
        subtotal - discountAmount + additionalFeeAmount + shippingAmount;

    final order = Order(
      id: orderId,
      businessId: businessId,
      orderNumber: orderNumber,
      customerId: customerId,
      orderDate: orderDate ?? now,
      dueDate: dueDate,
      subtotalAmount: subtotal,
      discountAmount: discountAmount,
      additionalFeeAmount: additionalFeeAmount,
      shippingAmount: shippingAmount,
      totalAmount: total,
      paidAmount: 0,
      currency: 'IDR',
      notes: notes,
      paymentStatus: 'unpaid',
      status: 'active',
      createdAt: now,
      updatedAt: now,
    );

    final orderItems = <OrderItem>[];
    for (var i = 0; i < items.length; i++) {
      final inp = items[i];
      orderItems.add(
        OrderItem(
          id: _uuid.v4(),
          businessId: businessId,
          orderId: orderId,
          position: i,
          description: inp.description,
          quantity: inp.quantity,
          unitPrice: inp.unitPrice,
          discountAmount: inp.discountAmount,
          lineTotal: inp.lineTotal,
        ),
      );
    }

    await _local.upsertWithItems(order, orderItems);
    await _queue.enqueue(
      businessId: businessId,
      entityType: 'orders',
      entityId: orderId,
      operation: SyncOperation.insert,
      payload: jsonEncode({
        'order': _orderToMap(order),
        'items': orderItems.map(_itemToMap).toList(),
      }),
      idempotencyKey: 'order_${orderId}_${now.millisecondsSinceEpoch}',
    );
    return orderId;
  }

  @override
  Future<void> changeStatus({
    required String orderId,
    required String orderStatusId,
    String? notes,
  }) async {
    if (!_isOnline()) {
      throw StateError(
        'Ubah status memerlukan koneksi internet. '
        'Coba lagi saat online.',
      );
    }
    await _remote.changeStatus(
      orderId: orderId,
      orderStatusId: orderStatusId,
      notes: notes,
    );
  }

  @override
  Future<void> cancel(String orderId, {String? reason}) async {
    if (!_isOnline()) {
      throw StateError(
        'Pembatalan memerlukan koneksi internet. '
        'Coba lagi saat online.',
      );
    }
    await _remote.cancel(orderId, reason: reason);
  }

  @override
  Future<void> upsert(Order order, List<OrderItem> items) async {
    await _remote.upsert(order, items);
  }
}
