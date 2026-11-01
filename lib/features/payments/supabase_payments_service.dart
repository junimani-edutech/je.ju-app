import 'package:supabase_flutter/supabase_flutter.dart';

import 'payment.dart';
import 'payments_service.dart';

class SupabasePaymentsService implements PaymentsService {
  SupabasePaymentsService(this._client);
  final SupabaseClient _client;

  String? _dateStr(DateTime? d) {
    if (d == null) return null;
    return d.toIso8601String().substring(0, 10);
  }

  @override
  Future<List<Payment>> listForOrder(String orderId) async {
    final rows = await _client
        .from('payments')
        .select()
        .eq('order_id', orderId)
        .order('payment_date', ascending: false)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => Payment.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<PaymentMethod>> listMethods(String businessId) async {
    final rows = await _client
        .from('payment_methods')
        .select()
        .eq('business_id', businessId)
        .eq('status', 'active')
        .order('name');
    return (rows as List)
        .map((e) => PaymentMethod.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Account>> listAccounts(String businessId) async {
    final rows = await _client
        .from('accounts')
        .select()
        .eq('business_id', businessId)
        .eq('status', 'active')
        .order('name');
    return (rows as List)
        .map((e) => Account.fromMap(e as Map<String, dynamic>))
        .toList();
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
    final result = await _client.rpc(
      'record_payment',
      params: {
        'p_business_id': businessId,
        'p_order_id': orderId,
        'p_amount': amount,
        'p_payment_method_id': paymentMethodId,
        'p_account_id': accountId,
        'p_payment_date': _dateStr(paymentDate),
        'p_reference': reference,
        'p_notes': notes,
        'p_idempotency_key': idempotencyKey,
      },
    );
    return result as String;
  }

  @override
  Future<String> voidPayment({
    required String paymentId,
    required String reason,
  }) async {
    final result = await _client.rpc(
      'void_payment',
      params: {'p_payment_id': paymentId, 'p_reason': reason},
    );
    return result as String;
  }
}
