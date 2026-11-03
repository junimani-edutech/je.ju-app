class Order {
  const Order({
    required this.id,
    required this.businessId,
    required this.orderNumber,
    required this.orderDate,
    required this.subtotalAmount,
    required this.discountAmount,
    required this.additionalFeeAmount,
    required this.shippingAmount,
    required this.totalAmount,
    required this.paidAmount,
    required this.currency,
    required this.paymentStatus,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.customerId,
    this.dueDate,
    this.notes,
    this.orderStatusId,
  });

  final String id;
  final String businessId;
  final String orderNumber;
  final String? customerId;
  final DateTime orderDate;
  final DateTime? dueDate;
  final int subtotalAmount;
  final int discountAmount;
  final int additionalFeeAmount;
  final int shippingAmount;
  final int totalAmount;
  final int paidAmount;
  final String currency;
  final String? notes;
  final String? orderStatusId;
  final String paymentStatus;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isCancelled => status == 'cancelled';

  factory Order.fromMap(Map<String, dynamic> m) => Order(
    id: m['id'] as String,
    businessId: m['business_id'] as String,
    orderNumber: m['order_number'] as String,
    customerId: m['customer_id'] as String?,
    orderDate: DateTime.parse(m['order_date'] as String),
    dueDate: m['due_date'] == null
        ? null
        : DateTime.parse(m['due_date'] as String),
    subtotalAmount: (m['subtotal_amount'] as num).toInt(),
    discountAmount: (m['discount_amount'] as num).toInt(),
    additionalFeeAmount: (m['additional_fee_amount'] as num).toInt(),
    shippingAmount: (m['shipping_amount'] as num).toInt(),
    totalAmount: (m['total_amount'] as num).toInt(),
    paidAmount: (m['paid_amount'] as num).toInt(),
    currency: m['currency'] as String,
    notes: m['notes'] as String?,
    orderStatusId: m['order_status_id'] as String?,
    paymentStatus: m['payment_status'] as String,
    status: m['status'] as String,
    createdAt: DateTime.parse(m['created_at'] as String),
    updatedAt: DateTime.parse(m['updated_at'] as String),
  );
}

class OrderItem {
  const OrderItem({
    required this.id,
    required this.businessId,
    required this.orderId,
    required this.position,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.discountAmount,
    required this.lineTotal,
    this.productId,
  });

  final String id;
  final String businessId;
  final String orderId;
  final int position;
  final String description;
  final double quantity;
  final int unitPrice;
  final int discountAmount;
  final int lineTotal;
  final String? productId;

  factory OrderItem.fromMap(Map<String, dynamic> m) => OrderItem(
    id: m['id'] as String,
    businessId: m['business_id'] as String,
    orderId: m['order_id'] as String,
    position: (m['position'] as num).toInt(),
    description: m['description'] as String,
    quantity: (m['quantity'] as num).toDouble(),
    unitPrice: (m['unit_price'] as num).toInt(),
    discountAmount: (m['discount_amount'] as num).toInt(),
    lineTotal: (m['line_total'] as num).toInt(),
  );
}

class OrderStatus {
  const OrderStatus({
    required this.id,
    required this.businessId,
    required this.name,
    required this.code,
    required this.sortOrder,
    required this.isFinal,
  });

  final String id;
  final String businessId;
  final String name;
  final String code;
  final int sortOrder;
  final bool isFinal;

  factory OrderStatus.fromMap(Map<String, dynamic> m) => OrderStatus(
    id: m['id'] as String,
    businessId: m['business_id'] as String,
    name: m['name'] as String,
    code: m['code'] as String,
    sortOrder: (m['sort_order'] as num).toInt(),
    isFinal: m['is_final'] as bool,
  );
}

class OrderItemInput {
  const OrderItemInput({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.discountAmount = 0,
  });

  final String description;
  final double quantity;
  final int unitPrice;
  final int discountAmount;

  int get lineTotal => (quantity * unitPrice).round() - discountAmount;

  Map<String, dynamic> toJson() => {
    'description': description,
    'quantity': quantity,
    'unit_price': unitPrice,
    'discount_amount': discountAmount,
  };
}
