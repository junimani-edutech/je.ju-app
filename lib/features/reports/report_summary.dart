import '../finance/finance_models.dart';

class ReportSummary {
  const ReportSummary({
    required this.from,
    required this.to,
    required this.ordersCount,
    required this.ordersTotal,
    required this.paymentsReceived,
    required this.receivablesRemaining,
    required this.income,
    required this.expense,
    required this.paymentsNet,
    required this.cashFlowNet,
    required this.balanceByAccount,
  });

  final DateTime from;
  final DateTime to;
  final int ordersCount;
  final int ordersTotal;
  final int paymentsReceived;
  final int receivablesRemaining;
  final int income;
  final int expense;
  final int paymentsNet;
  final int cashFlowNet;
  final List<AccountBalance> balanceByAccount;

  factory ReportSummary.fromJson(Map<String, dynamic> j) => ReportSummary(
    from: DateTime.parse(j['from'] as String),
    to: DateTime.parse(j['to'] as String),
    ordersCount: (j['orders_count'] as num).toInt(),
    ordersTotal: (j['orders_total'] as num).toInt(),
    paymentsReceived: (j['payments_received'] as num).toInt(),
    receivablesRemaining: (j['receivables_remaining'] as num).toInt(),
    income: (j['income'] as num).toInt(),
    expense: (j['expense'] as num).toInt(),
    paymentsNet: (j['payments_net'] as num).toInt(),
    cashFlowNet: (j['cash_flow_net'] as num).toInt(),
    balanceByAccount: ((j['balance_by_account'] as List?) ?? const [])
        .map((e) => AccountBalance.fromMap(e as Map<String, dynamic>))
        .toList(),
  );

  factory ReportSummary.empty({required DateTime from, required DateTime to}) =>
      ReportSummary(
        from: from,
        to: to,
        ordersCount: 0,
        ordersTotal: 0,
        paymentsReceived: 0,
        receivablesRemaining: 0,
        income: 0,
        expense: 0,
        paymentsNet: 0,
        cashFlowNet: 0,
        balanceByAccount: const [],
      );
}
