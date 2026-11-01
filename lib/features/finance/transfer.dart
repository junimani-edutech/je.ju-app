class Transfer {
  const Transfer({
    required this.id,
    required this.businessId,
    required this.fromAccountId,
    required this.toAccountId,
    required this.amount,
    required this.currency,
    required this.transferDate,
    required this.status,
    required this.createdAt,
    this.description,
    this.cancelledAt,
    this.cancelReason,
  });

  final String id;
  final String businessId;
  final String fromAccountId;
  final String toAccountId;
  final int amount;
  final String currency;
  final DateTime transferDate;
  final String status; // 'confirmed' | 'cancelled' | 'reversed'
  final DateTime createdAt;
  final String? description;
  final DateTime? cancelledAt;
  final String? cancelReason;

  bool get isConfirmed => status == 'confirmed';

  factory Transfer.fromMap(Map<String, dynamic> m) => Transfer(
    id: m['id'] as String,
    businessId: m['business_id'] as String,
    fromAccountId: m['from_account_id'] as String,
    toAccountId: m['to_account_id'] as String,
    amount: (m['amount'] as num).toInt(),
    currency: m['currency'] as String,
    transferDate: DateTime.parse(m['transfer_date'] as String),
    status: m['status'] as String,
    createdAt: DateTime.parse(m['created_at'] as String),
    description: m['description'] as String?,
    cancelledAt: m['cancelled_at'] == null
        ? null
        : DateTime.parse(m['cancelled_at'] as String),
    cancelReason: m['cancel_reason'] as String?,
  );
}
