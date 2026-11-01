import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../orders/orders_providers.dart';
import 'payment.dart';
import 'payments_service.dart';

final paymentsServiceProvider = Provider<PaymentsService>((ref) {
  throw UnimplementedError('paymentsServiceProvider belum di-override');
});

final paymentMethodsProvider = FutureProvider<List<PaymentMethod>>((ref) async {
  final biz = await ref.watch(currentBusinessProvider.future);
  if (biz == null) return const <PaymentMethod>[];
  return ref.watch(paymentsServiceProvider).listMethods(biz.id);
});

final accountsProvider = FutureProvider<List<Account>>((ref) async {
  final biz = await ref.watch(currentBusinessProvider.future);
  if (biz == null) return const <Account>[];
  return ref.watch(paymentsServiceProvider).listAccounts(biz.id);
});

/// Baca daftar payment untuk satu order. Di-invalidate manual oleh
/// [PaymentsController] setelah record/void.
final paymentsForOrderProvider = FutureProvider.family<List<Payment>, String>((
  ref,
  orderId,
) async {
  return ref.watch(paymentsServiceProvider).listForOrder(orderId);
});

/// Controller untuk mutasi pembayaran. Memanggil service lalu
/// meng-invalidate provider yang terpengaruh.
class PaymentsController {
  PaymentsController(this._ref);
  final Ref _ref;

  Future<String> record({
    required String orderId,
    required int amount,
    String? paymentMethodId,
    String? accountId,
    String? reference,
    String? notes,
    String? idempotencyKey,
  }) async {
    final biz = await _ref.read(currentBusinessProvider.future);
    if (biz == null) throw StateError('Tidak ada bisnis aktif');
    final id = await _ref
        .read(paymentsServiceProvider)
        .record(
          businessId: biz.id,
          orderId: orderId,
          amount: amount,
          paymentMethodId: paymentMethodId,
          accountId: accountId,
          reference: reference,
          notes: notes,
          idempotencyKey: idempotencyKey,
        );
    _ref.invalidate(paymentsForOrderProvider(orderId));
    _ref.invalidate(ordersProvider);
    return id;
  }

  Future<String> voidPayment({
    required String paymentId,
    required String orderId,
    required String reason,
  }) async {
    final id = await _ref
        .read(paymentsServiceProvider)
        .voidPayment(paymentId: paymentId, reason: reason);
    _ref.invalidate(paymentsForOrderProvider(orderId));
    _ref.invalidate(ordersProvider);
    return id;
  }
}

final paymentsControllerProvider = Provider<PaymentsController>(
  (ref) => PaymentsController(ref),
);
