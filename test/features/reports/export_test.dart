import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeju_app/core/models/app_user.dart';
import 'package:jeju_app/core/models/business.dart';
import 'package:jeju_app/core/models/business_member.dart';
import 'package:jeju_app/core/providers.dart';
import 'package:jeju_app/features/finance/finance_providers.dart';
import 'package:jeju_app/features/orders/orders_providers.dart';
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

Widget _wrap({
  required FakeReportService report,
  required FakeExportService export,
}) {
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
      reportServiceProvider.overrideWithValue(report),
      exportServiceProvider.overrideWithValue(export),
      ordersServiceProvider.overrideWithValue(FakeOrdersService()),
      transactionsServiceProvider.overrideWithValue(FakeTransactionsService()),
    ],
    child: const MaterialApp(home: ReportsScreen()),
  );
}

void _viewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(500, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

ReportSummary _summary() => ReportSummary(
  from: DateTime(2026, 11, 1),
  to: DateTime(2026, 11, 30),
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

void main() {
  testWidgets('ReportsScreen menampilkan 3 tombol ekspor', (tester) async {
    _viewport(tester);
    await tester.pumpWidget(
      _wrap(
        report: FakeReportService(initial: _summary()),
        export: FakeExportService(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('reports_export_orders_csv')), findsOneWidget);
    expect(find.byKey(const Key('reports_export_orders_xlsx')), findsOneWidget);
    expect(
      find.byKey(const Key('reports_export_transactions_csv')),
      findsOneWidget,
    );
  });

  testWidgets('tap Order CSV memicu FakeExportService.ordersCsv', (
    tester,
  ) async {
    _viewport(tester);
    final fake = FakeExportService();
    await tester.pumpWidget(
      _wrap(
        report: FakeReportService(initial: _summary()),
        export: fake,
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('reports_export_orders_csv')),
    );
    await tester.tap(find.byKey(const Key('reports_export_orders_csv')));
    await tester.pumpAndSettle();

    expect(fake.ordersCsvCalls, 1);
    expect(fake.lastFilename, 'orders.csv');
  });
}
