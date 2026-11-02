import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeju_app/core/models/app_user.dart';
import 'package:jeju_app/core/models/business.dart';
import 'package:jeju_app/core/models/business_member.dart';
import 'package:jeju_app/core/providers.dart';
import 'package:jeju_app/features/finance/finance_models.dart';
import 'package:jeju_app/features/reports/report_providers.dart';
import 'package:jeju_app/features/reports/report_summary.dart';
import 'package:jeju_app/features/reports/reports_screen.dart';

import '../../fake/fake_services.dart';

const _biz = Business(
  id: 'biz-1',
  name: 'Test Biz',
  timezone: 'Asia/Jakarta',
  currency: 'IDR',
);

const _owner = BusinessMember(
  id: 'm-1',
  businessId: 'biz-1',
  userId: 'u-1',
  role: 'owner',
  status: 'active',
);

ReportSummary _summary({
  int orders = 3,
  int ordersTotal = 75000,
  int paymentsReceived = 30000,
  int receivablesRemaining = 45000,
  int income = 200000,
  int expense = 50000,
  int paymentsNet = 25000,
  int cashFlowNet = 175000,
  List<AccountBalance> balances = const [],
}) {
  return ReportSummary(
    from: DateTime(2026, 11, 1),
    to: DateTime(2026, 11, 30),
    ordersCount: orders,
    ordersTotal: ordersTotal,
    paymentsReceived: paymentsReceived,
    receivablesRemaining: receivablesRemaining,
    income: income,
    expense: expense,
    paymentsNet: paymentsNet,
    cashFlowNet: cashFlowNet,
    balanceByAccount: balances,
  );
}

Widget _wrap({required FakeReportService reportService}) {
  return ProviderScope(
    overrides: [
      authServiceProvider.overrideWithValue(
        FakeAuthService(
          initialUser: const AppUser(id: 'u-1', email: 'u@example.com'),
        ),
      ),
      businessServiceProvider.overrideWithValue(
        FakeBusinessService(
          initialHasBusiness: true,
          initialBusinesses: const [_biz],
          initialMember: _owner,
        ),
      ),
      reportServiceProvider.overrideWithValue(reportService),
    ],
    child: const MaterialApp(home: ReportsScreen()),
  );
}

void _viewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(500, 1800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('ReportsScreen renders empty summary', (tester) async {
    _viewport(tester);
    final fake = FakeReportService(
      initial: _summary(
        orders: 0,
        ordersTotal: 0,
        paymentsReceived: 0,
        receivablesRemaining: 0,
        income: 0,
        expense: 0,
        paymentsNet: 0,
        cashFlowNet: 0,
      ),
    );
    await tester.pumpWidget(_wrap(reportService: fake));
    await tester.pumpAndSettle();

    expect(find.text('Ringkasan'), findsOneWidget);
    expect(find.text('Arus kas'), findsOneWidget);
    expect(find.text('Rp 0'), findsWidgets);
    expect(find.text('Belum ada akun aktif.'), findsOneWidget);
  });

  testWidgets('ReportsScreen renders populated summary', (tester) async {
    _viewport(tester);
    final fake = FakeReportService(
      initial: _summary(
        balances: const [
          AccountBalance(accountId: 'acc-1', accountName: 'Kas', balance: 7000),
          AccountBalance(
            accountId: 'acc-2',
            accountName: 'Bank',
            balance: 20000,
          ),
        ],
      ),
    );
    await tester.pumpWidget(_wrap(reportService: fake));
    await tester.pumpAndSettle();

    expect(find.text('Rp 75.000'), findsOneWidget); // ordersTotal
    expect(find.text('Rp 30.000'), findsOneWidget); // paymentsReceived
    expect(find.text('Rp 45.000'), findsOneWidget); // receivables
    expect(find.text('Rp 200.000'), findsOneWidget); // income
    expect(find.text('Rp 50.000'), findsOneWidget); // expense
    expect(find.text('Rp 25.000'), findsOneWidget); // paymentsNet
    expect(find.text('Rp 175.000'), findsOneWidget); // cashFlowNet

    expect(find.byKey(const Key('reports_balance_acc-1')), findsOneWidget);
    expect(find.byKey(const Key('reports_balance_acc-2')), findsOneWidget);
  });

  testWidgets('toggle Bulan lalu memanggil service dengan range bulan lalu', (
    tester,
  ) async {
    _viewport(tester);
    final fake = FakeReportService(initial: _summary());
    await tester.pumpWidget(_wrap(reportService: fake));
    await tester.pumpAndSettle();

    // Awal: bulan ini (call count minimal 1)
    final initialCalls = fake.callCount;
    expect(initialCalls, greaterThan(0));

    // Tap "Bulan lalu"
    await tester.tap(find.text('Bulan lalu'));
    await tester.pumpAndSettle();

    expect(fake.callCount, greaterThan(initialCalls));

    final now = DateTime.now();
    final expectedFrom = DateTime(now.year, now.month - 1, 1);
    final expectedTo = DateTime(now.year, now.month, 0);
    expect(fake.lastFrom?.year, expectedFrom.year);
    expect(fake.lastFrom?.month, expectedFrom.month);
    expect(fake.lastFrom?.day, expectedFrom.day);
    expect(fake.lastTo?.year, expectedTo.year);
    expect(fake.lastTo?.month, expectedTo.month);
    expect(fake.lastTo?.day, expectedTo.day);
  });

  testWidgets('error state ditampilkan jika service gagal', (tester) async {
    _viewport(tester);
    final fake = FakeReportService()..throwOnCall = true;
    await tester.pumpWidget(_wrap(reportService: fake));
    await tester.pumpAndSettle();

    expect(find.textContaining('report failed'), findsOneWidget);
  });
}
