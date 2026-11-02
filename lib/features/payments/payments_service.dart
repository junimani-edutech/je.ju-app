import 'payment.dart';

abstract class PaymentsService {
  Future<List<Payment>> listForOrder(String orderId);
  Future<List<PaymentMethod>> listMethods(String businessId);
  Future<List<Account>> listAccounts(String businessId);

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
  });

  Future<String> voidPayment({
    required String paymentId,
    required String reason,
  });

  /// Upsert by id — dipakai dispatcher offline. Idempotent: create-or-replace.
  Future<void> upsert(Payment payment);
}
