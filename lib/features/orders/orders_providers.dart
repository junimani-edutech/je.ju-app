import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'order.dart';
import 'orders_service.dart';

final ordersServiceProvider = Provider<OrdersService>((ref) {
  throw UnimplementedError('ordersServiceProvider belum di-override');
});

final orderStatusesProvider = FutureProvider<List<OrderStatus>>((ref) async {
  final biz = await ref.watch(currentBusinessProvider.future);
  if (biz == null) return const <OrderStatus>[];
  return ref.watch(ordersServiceProvider).listStatuses(biz.id);
});

class OrdersNotifier extends AsyncNotifier<List<Order>> {
  @override
  Future<List<Order>> build() async {
    final biz = await ref.watch(currentBusinessProvider.future);
    if (biz == null) return const <Order>[];
    return ref.watch(ordersServiceProvider).list(businessId: biz.id);
  }

  Future<void> _reload() async {
    final biz = await ref.read(currentBusinessProvider.future);
    if (biz == null) {
      state = const AsyncData(<Order>[]);
      return;
    }
    state = AsyncData(
      await ref.read(ordersServiceProvider).list(businessId: biz.id),
    );
  }

  Future<String> create({
    required List<OrderItemInput> items,
    String? customerId,
    DateTime? orderDate,
    DateTime? dueDate,
    String? notes,
    int discountAmount = 0,
    int additionalFeeAmount = 0,
    int shippingAmount = 0,
  }) async {
    final biz = await ref.read(currentBusinessProvider.future);
    if (biz == null) throw StateError('Tidak ada bisnis aktif');
    final id = await ref
        .read(ordersServiceProvider)
        .create(
          businessId: biz.id,
          items: items,
          customerId: customerId,
          orderDate: orderDate,
          dueDate: dueDate,
          notes: notes,
          discountAmount: discountAmount,
          additionalFeeAmount: additionalFeeAmount,
          shippingAmount: shippingAmount,
        );
    await _reload();
    return id;
  }

  Future<void> changeStatus({
    required String orderId,
    required String orderStatusId,
    String? notes,
  }) async {
    await ref
        .read(ordersServiceProvider)
        .changeStatus(
          orderId: orderId,
          orderStatusId: orderStatusId,
          notes: notes,
        );
    await _reload();
  }

  Future<void> cancel(String orderId, {String? reason}) async {
    await ref.read(ordersServiceProvider).cancel(orderId, reason: reason);
    await _reload();
  }
}

final ordersProvider = AsyncNotifierProvider<OrdersNotifier, List<Order>>(
  OrdersNotifier.new,
);
