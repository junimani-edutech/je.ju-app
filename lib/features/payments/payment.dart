class Payment {
  const Payment({
    required this.id,
    required this.businessId,
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.paymentDate,
    required this.status,
    required this.createdAt,
    this.paymentMethodId,
    this.accountId,
    this.reference,
    this.notes,
    this.reversalOfPaymentId,
    this.confirmedAt,
    this.cancelledAt,
    this.cancelReason,
  });

  final String id;
  final String businessId;
  final String orderId;
  final int amount;
  final String currency;
  final DateTime paymentDate;
  final String status;
  final DateTime createdAt;
  final String? paymentMethodId;
  final String? accountId;
  final String? reference;
  final String? notes;
  final String? reversalOfPaymentId;
  final DateTime? confirmedAt;
  final DateTime? cancelledAt;
  final String? cancelReason;

  bool get isReversal => reversalOfPaymentId != null;
  bool get isConfirmed => status == 'confirmed';
  bool get isCancelled => status == 'cancelled';

  /// Efektif terhadap paid_amount: reversal mengurangi.
  int get signedAmount => isReversal ? -amount : amount;

  factory Payment.fromMap(Map<String, dynamic> m) => Payment(
    id: m['id'] as String,
    businessId: m['business_id'] as String,
    orderId: m['order_id'] as String,
    amount: (m['amount'] as num).toInt(),
    currency: m['currency'] as String,
    paymentDate: DateTime.parse(m['payment_date'] as String),
    status: m['status'] as String,
    createdAt: DateTime.parse(m['created_at'] as String),
    paymentMethodId: m['payment_method_id'] as String?,
    accountId: m['account_id'] as String?,
    reference: m['reference'] as String?,
    notes: m['notes'] as String?,
    reversalOfPaymentId: m['reversal_of_payment_id'] as String?,
    confirmedAt: m['confirmed_at'] == null
        ? null
        : DateTime.parse(m['confirmed_at'] as String),
    cancelledAt: m['cancelled_at'] == null
        ? null
        : DateTime.parse(m['cancelled_at'] as String),
    cancelReason: m['cancel_reason'] as String?,
  );
}

class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.businessId,
    required this.name,
    required this.status,
  });

  final String id;
  final String businessId;
  final String name;
  final String status;

  factory PaymentMethod.fromMap(Map<String, dynamic> m) => PaymentMethod(
    id: m['id'] as String,
    businessId: m['business_id'] as String,
    name: m['name'] as String,
    status: m['status'] as String,
  );
}

class Account {
  const Account({
    required this.id,
    required this.businessId,
    required this.name,
    required this.type,
    required this.currency,
    required this.initialBalance,
    required this.status,
  });

  final String id;
  final String businessId;
  final String name;
  final String type; // 'cash' | 'bank' | 'ewallet'
  final String currency;
  final int initialBalance;
  final String status;

  factory Account.fromMap(Map<String, dynamic> m) => Account(
    id: m['id'] as String,
    businessId: m['business_id'] as String,
    name: m['name'] as String,
    type: m['type'] as String,
    currency: m['currency'] as String,
    initialBalance: (m['initial_balance'] as num).toInt(),
    status: m['status'] as String,
  );
}
