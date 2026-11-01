class AccountBalance {
  const AccountBalance({
    required this.accountId,
    required this.accountName,
    required this.balance,
  });

  final String accountId;
  final String accountName;
  final int balance;

  factory AccountBalance.fromMap(Map<String, dynamic> m) => AccountBalance(
    accountId: m['account_id'] as String,
    accountName: m['account_name'] as String,
    balance: (m['balance'] as num).toInt(),
  );
}

class CashFlowSummary {
  const CashFlowSummary({
    required this.income,
    required this.expense,
    required this.paymentsNet,
    required this.net,
  });

  final int income;
  final int expense;
  final int paymentsNet;
  final int net;

  factory CashFlowSummary.fromJson(Map<String, dynamic> j) => CashFlowSummary(
    income: (j['income'] as num).toInt(),
    expense: (j['expense'] as num).toInt(),
    paymentsNet: (j['payments_net'] as num).toInt(),
    net: (j['net'] as num).toInt(),
  );
}
