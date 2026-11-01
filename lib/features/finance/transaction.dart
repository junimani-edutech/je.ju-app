class Transaction {
  const Transaction({
    required this.id,
    required this.businessId,
    required this.type,
    required this.amount,
    required this.currency,
    required this.transactionDate,
    required this.description,
    required this.status,
    required this.createdAt,
    this.categoryId,
    this.accountId,
    this.reference,
    this.attachmentUrl,
    this.reversalOfTransactionId,
    this.cancelledAt,
    this.cancelReason,
  });

  final String id;
  final String businessId;
  final String type; // 'income' | 'expense'
  final int amount;
  final String currency;
  final DateTime transactionDate;
  final String description;
  final String status; // 'confirmed' | 'cancelled' | 'reversed'
  final DateTime createdAt;
  final String? categoryId;
  final String? accountId;
  final String? reference;
  final String? attachmentUrl;
  final String? reversalOfTransactionId;
  final DateTime? cancelledAt;
  final String? cancelReason;

  bool get isReversal => reversalOfTransactionId != null;
  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';

  /// Efektif terhadap saldo akun: income positif, expense negatif, reversal membalik tanda.
  int get signedAmount {
    final base = isIncome ? amount : -amount;
    return isReversal ? -base : base;
  }

  factory Transaction.fromMap(Map<String, dynamic> m) => Transaction(
    id: m['id'] as String,
    businessId: m['business_id'] as String,
    type: m['type'] as String,
    amount: (m['amount'] as num).toInt(),
    currency: m['currency'] as String,
    transactionDate: DateTime.parse(m['transaction_date'] as String),
    description: m['description'] as String,
    status: m['status'] as String,
    createdAt: DateTime.parse(m['created_at'] as String),
    categoryId: m['category_id'] as String?,
    accountId: m['account_id'] as String?,
    reference: m['reference'] as String?,
    attachmentUrl: m['attachment_url'] as String?,
    reversalOfTransactionId: m['reversal_of_transaction_id'] as String?,
    cancelledAt: m['cancelled_at'] == null
        ? null
        : DateTime.parse(m['cancelled_at'] as String),
    cancelReason: m['cancel_reason'] as String?,
  );
}
