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
    this.omzetKotor = 0,
    this.totalOngkir = 0,
    this.omzetBersih = 0,
    this.labaKotor = 0,
    this.piutang = 0,
    this.cashInHand = 0,
  });

  final int income;
  final int expense;
  final int paymentsNet;
  final int net;
  final int omzetKotor;
  final int totalOngkir;
  final int omzetBersih;
  final int labaKotor;
  final int piutang;
  final int cashInHand;

  factory CashFlowSummary.fromJson(Map<String, dynamic> j) => CashFlowSummary(
    income: (j['income'] as num?)?.toInt() ?? 0,
    expense: (j['expense'] as num?)?.toInt() ?? 0,
    paymentsNet: (j['payments_net'] as num?)?.toInt() ?? 0,
    net: (j['net'] as num?)?.toInt() ?? 0,
    omzetKotor: (j['omzet_kotor'] as num?)?.toInt() ?? 0,
    totalOngkir: (j['total_ongkir'] as num?)?.toInt() ?? 0,
    omzetBersih: (j['omzet_bersih'] as num?)?.toInt() ?? 0,
    labaKotor: (j['laba_kotor'] as num?)?.toInt() ?? 0,
    piutang: (j['piutang'] as num?)?.toInt() ?? 0,
    cashInHand: (j['cash_in_hand'] as num?)?.toInt() ?? 0,
  );
}
