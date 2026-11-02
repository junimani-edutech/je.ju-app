import 'package:supabase_flutter/supabase_flutter.dart';

import 'order.dart';
import 'orders_service.dart';

class SupabaseOrdersService implements OrdersService {
  SupabaseOrdersService(this._client);
  final SupabaseClient _client;

  String? _dateStr(DateTime? d) {
    if (d == null) return null;
    final iso = d.toIso8601String();
    return iso.substring(0, 10);
  }

  @override
  Future<List<Order>> list({required String businessId}) async {
    final rows = await _client
        .from('orders')
        .select()
        .eq('business_id', businessId)
        .order('order_date', ascending: false)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => Order.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Order> get(String orderId) async {
    final row = await _client
        .from('orders')
        .select()
        .eq('id', orderId)
        .single();
    return Order.fromMap(row);
  }

  @override
  Future<List<OrderItem>> listItems(String orderId) async {
    final rows = await _client
        .from('order_items')
        .select()
        .eq('order_id', orderId)
        .order('position');
    return (rows as List)
        .map((e) => OrderItem.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<OrderStatus>> listStatuses(String businessId) async {
    final rows = await _client
        .from('order_statuses')
        .select()
        .eq('business_id', businessId)
        .order('sort_order');
    return (rows as List)
        .map((e) => OrderStatus.fromMap(e as Map<String, dynamic>))
        .toList();
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
    final result = await _client.rpc(
      'create_order',
      params: {
        'p_business_id': businessId,
        'p_customer_id': customerId,
        'p_order_date': _dateStr(orderDate),
        'p_due_date': _dateStr(dueDate),
        'p_notes': notes,
        'p_discount_amount': discountAmount,
        'p_additional_fee_amount': additionalFeeAmount,
        'p_shipping_amount': shippingAmount,
        'p_items': items.map((e) => e.toJson()).toList(),
      },
    );
    return result as String;
  }

  @override
  Future<void> changeStatus({
    required String orderId,
    required String orderStatusId,
    String? notes,
  }) async {
    await _client.rpc(
      'change_order_status',
      params: {
        'p_order_id': orderId,
        'p_to_status_id': orderStatusId,
        'p_notes': notes,
      },
    );
  }

  @override
  Future<void> cancel(String orderId, {String? reason}) async {
    await _client.rpc(
      'cancel_order',
      params: {'p_order_id': orderId, 'p_reason': reason},
    );
  }

  @override
  Future<void> upsert(Order order, List<OrderItem> items) async {
    await _client.rpc(
      'upsert_order_with_items',
      params: {
        'p_id': order.id,
        'p_business_id': order.businessId,
        'p_order_number': order.orderNumber,
        'p_customer_id': order.customerId,
        'p_order_date': _dateStr(order.orderDate),
        'p_due_date': _dateStr(order.dueDate),
        'p_discount_amount': order.discountAmount,
        'p_additional_fee_amount': order.additionalFeeAmount,
        'p_shipping_amount': order.shippingAmount,
        'p_notes': order.notes,
        'p_order_status_id': order.orderStatusId,
        'p_items': items
            .map(
              (it) => {
                'description': it.description,
                'quantity': it.quantity,
                'unit_price': it.unitPrice,
                'discount_amount': it.discountAmount,
              },
            )
            .toList(),
      },
    );
  }
}
