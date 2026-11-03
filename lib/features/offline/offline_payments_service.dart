// ignore_for_file: prefer_initializing_formals
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../orders/order.dart';
import '../payments/payment.dart';
import '../payments/payments_service.dart';
import '../payments/supabase_payments_service.dart';
import 'local_orders_repo.dart';
import 'local_payments_repo.dart';
import 'providers.dart';
import 'sync_queue_repository.dart';

class OfflinePaymentsService implements PaymentsService {
  OfflinePaymentsService({
    required SupabasePaymentsService remote,
    required LocalPaymentsRepo local,
    required LocalOrdersRepo orders,
    required SyncQueueRepository queue,
    required Ref ref,
  }) : _remote = remote,
       _local = local,
       _orders = orders,
       _queue = queue,
       _ref = ref;

  final SupabasePaymentsService _remote;
  final LocalPaymentsRepo _local;
  final LocalOrdersRepo _orders;
  final SyncQueueRepository _queue;
  final Ref _ref;
  final Uuid _uuid = const Uuid();

  bool _isOnline() {
    return _ref.read(networkStatusProvider).value == NetworkStatus.online;
  }

  String _computePaymentStatus(int paid, int total) {
    if (paid <= 0) return 'unpaid';
    if (paid < total) return 'partial';
    if (paid == total) return 'paid';
    return 'overpaid';
  }

  Map<String, dynamic> _paymentToMap(Payment p) => {
    'id': p.id,
    'business_id': p.businessId,
    'order_id': p.orderId,
    'amount': p.amount,
    'currency': p.currency,
    'payment_date': p.paymentDate.toIso8601String().substring(0, 10),
    'payment_method_id': p.paymentMethodId,
    'account_id': p.accountId,
    'reference': p.reference,
    'notes': p.notes,
    'status': p.status,
    'created_at': p.createdAt.toIso8601String(),
    'reversal_of_payment_id': p.reversalOfPaymentId,
  };

  @override
  Future<List<Payment>> listForOrder(String orderId) async {
    if (_isOnline()) {
      try {
        final remote = await _remote.listForOrder(orderId);
        await _local.upsertMany(remote);
      } catch (_) {}
    }
    return _local.listForOrder(orderId);
  }

  @override
  Future<List<Payment>> listAll({required String businessId}) async {
    if (_isOnline()) {
      try {
        await _local.upsertMany(await _remote.listAll(businessId: businessId));
      } catch (_) {}
    }
    return _local.listAll(businessId: businessId);
  }

  @override
  Future<List<PaymentMethod>> listMethods(String businessId) async {
    if (_isOnline()) {
      try {
        return await _remote.listMethods(businessId);
      } catch (_) {}
    }
    return const <PaymentMethod>[];
  }

  @override
  Future<List<Account>> listAccounts(String businessId) async {
    if (_isOnline()) {
      try {
        return await _remote.listAccounts(businessId);
      } catch (_) {}
    }
    return const <Account>[];
  }

  @override
  Future<String> record({
    required String businessId,
    required String orderId,
    required int amount,
    String? paymentMethodId,
    String? accountId,
    DateTime? paymentDate,
    String? reference,
    String? notes,
    String? idempotencyKey,
  }) async {
    if (_isOnline()) {
      try {
        final id = await _remote.record(
          businessId: businessId,
          orderId: orderId,
          amount: amount,
          paymentMethodId: paymentMethodId,
          accountId: accountId,
          paymentDate: paymentDate,
          reference: reference,
          notes: notes,
          idempotencyKey: idempotencyKey,
        );
        final list = await _remote.listForOrder(orderId);
        await _local.upsertMany(list);
        return id;
      } catch (_) {}
    }

    final now = DateTime.now().toUtc();
    final paymentId = _uuid.v4();
    final effectiveKey =
        idempotencyKey ?? 'payment_${paymentId}_${now.millisecondsSinceEpoch}';

    final payment = Payment(
      id: paymentId,
      businessId: businessId,
      orderId: orderId,
      amount: amount,
      currency: 'IDR',
      paymentDate: paymentDate ?? now,
      status: 'confirmed',
      createdAt: now,
      paymentMethodId: paymentMethodId,
      accountId: accountId,
      reference: reference,
      notes: notes,
      confirmedAt: now,
    );
    await _local.upsert(payment);

    // Update order's paidAmount + paymentStatus secara lokal.
    final order = await _orders.byId(orderId);
    if (order != null) {
      final newPaid = order.paidAmount + amount;
      final updated = Order(
        id: order.id,
        businessId: order.businessId,
        orderNumber: order.orderNumber,
        customerId: order.customerId,
        orderDate: order.orderDate,
        dueDate: order.dueDate,
        subtotalAmount: order.subtotalAmount,
        discountAmount: order.discountAmount,
        additionalFeeAmount: order.additionalFeeAmount,
        shippingAmount: order.shippingAmount,
        totalAmount: order.totalAmount,
        paidAmount: newPaid,
        currency: order.currency,
        notes: order.notes,
        orderStatusId: order.orderStatusId,
        paymentStatus: _computePaymentStatus(newPaid, order.totalAmount),
        status: order.status,
        createdAt: order.createdAt,
        updatedAt: now,
      );
      await _orders.upsertOrderOnly(updated);
    }

    await _queue.enqueue(
      businessId: businessId,
      entityType: 'payments',
      entityId: paymentId,
      operation: SyncOperation.insert,
      payload: jsonEncode(_paymentToMap(payment)),
      idempotencyKey: effectiveKey,
    );
    return paymentId;
  }

  @override
  Future<String> voidPayment({
    required String paymentId,
    required String reason,
  }) async {
    if (!_isOnline()) {
      throw StateError(
        'Void pembayaran memerlukan koneksi internet. '
        'Coba lagi saat online.',
      );
    }
    return _remote.voidPayment(paymentId: paymentId, reason: reason);
  }

  @override
  Future<void> upsert(Payment p) async {
    await _remote.upsert(p);
  }
}
