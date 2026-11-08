import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/providers.dart';

class PaymentExcess {
  final String id;
  final String paymentId;
  final String orderId;
  final String orderNumber;
  final String? customerName;
  final int amount;
  final String status;
  final DateTime createdAt;

  PaymentExcess({
    required this.id,
    required this.paymentId,
    required this.orderId,
    required this.orderNumber,
    this.customerName,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  factory PaymentExcess.fromMap(Map<String, dynamic> m) {
    final order = m['orders'] as Map<String, dynamic>?;
    final customer = order != null ? order['customers'] as Map<String, dynamic>? : null;
    return PaymentExcess(
      id: m['id'] as String,
      paymentId: m['payment_id'] as String,
      orderId: m['order_id'] as String,
      orderNumber: order?['order_number'] as String? ?? '-',
      customerName: customer?['name'] as String?,
      amount: (m['amount'] as num).toInt(),
      status: m['status'] as String,
      createdAt: DateTime.parse(m['created_at'] as String),
    );
  }
}

final excessHistoryProvider = FutureProvider<List<PaymentExcess>>((ref) async {
  final biz = await ref.watch(currentBusinessProvider.future);
  if (biz == null) return [];
  
  final client = Supabase.instance.client;
  final res = await client
      .from('payment_excesses')
      .select('id, payment_id, order_id, amount, status, created_at, orders(order_number, customers(name))')
      .eq('business_id', biz.id)
      .order('created_at', ascending: false);
  
  return (res as List).map((e) => PaymentExcess.fromMap(e as Map<String, dynamic>)).toList();
});

final totalExcessProvider = FutureProvider<int>((ref) async {
  final list = await ref.watch(excessHistoryProvider.future);
  return list.where((e) => e.status == 'kept_as_income').fold<int>(0, (s, e) => s + e.amount);
});
