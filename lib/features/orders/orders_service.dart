import 'order.dart';

abstract class OrdersService {
  Future<List<Order>> list({required String businessId});
  Future<Order> get(String orderId);
  Future<List<OrderItem>> listItems(String orderId);
  Future<List<OrderStatus>> listStatuses(String businessId);

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
  });

  Future<void> changeStatus({
    required String orderId,
    required String orderStatusId,
    String? notes,
  });

  Future<void> cancel(String orderId, {String? reason});

  /// Upsert by id — dipakai dispatcher offline. Idempotent: create-or-replace.
  Future<void> upsert(Order order, List<OrderItem> items);
}
