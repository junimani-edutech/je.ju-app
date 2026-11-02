import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeju_app/core/models/app_user.dart';
import 'package:jeju_app/core/models/business.dart';
import 'package:jeju_app/core/models/business_member.dart';
import 'package:jeju_app/core/providers.dart';
import 'package:jeju_app/features/offline/providers.dart';
import 'package:jeju_app/features/dashboard/dashboard_screen.dart';
import 'package:jeju_app/features/finance/category.dart';
import 'package:jeju_app/features/finance/finance_models.dart';
import 'package:jeju_app/features/finance/finance_providers.dart';
import 'package:jeju_app/features/finance/transaction.dart';
import 'package:jeju_app/features/finance/transactions_screen.dart';
import 'package:jeju_app/features/finance/transfer.dart';
import 'package:jeju_app/features/finance/transfers_screen.dart';
import 'package:jeju_app/features/payments/payment.dart' show Account;

import '../../fake/fake_services.dart';

const _biz = Business(
  id: 'biz-1',
  name: 'Test Biz',
  timezone: 'Asia/Jakarta',
  currency: 'IDR',
);

const _ownerMember = BusinessMember(
  id: 'm-1',
  businessId: 'biz-1',
  userId: 'u-1',
  role: 'owner',
  status: 'active',
);

Account _account(String id, String name) => Account(
  id: id,
  businessId: 'biz-1',
  name: name,
  type: 'cash',
  currency: 'IDR',
  initialBalance: 0,
  status: 'active',
);

Category _cat(String id, String type, String name) => Category(
  id: id,
  businessId: 'biz-1',
  type: type,
  name: name,
  status: 'active',
);

Transaction _tx(String id, String type, int amount, String desc) => Transaction(
  id: id,
  businessId: 'biz-1',
  type: type,
  amount: amount,
  currency: 'IDR',
  transactionDate: DateTime(2026, 11, 1),
  description: desc,
  status: 'confirmed',
  createdAt: DateTime(2026, 11, 1),
);

Transfer _tr(String id, int amount) => Transfer(
  id: id,
  businessId: 'biz-1',
  fromAccountId: 'acc-1',
  toAccountId: 'acc-2',
  amount: amount,
  currency: 'IDR',
  transferDate: DateTime(2026, 11, 1),
  status: 'confirmed',
  createdAt: DateTime(2026, 11, 1),
);

Widget _wrap({
  required FakeTransactionsService txService,
  required FakeTransfersService trService,
  BusinessMember member = _ownerMember,
  required Widget child,
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
          initialMember: member,
        ),
      ),
      transactionsServiceProvider.overrideWithValue(txService),
      transfersServiceProvider.overrideWithValue(trService),
      syncPendingCountProvider.overrideWith((ref) => const Stream<int>.empty()),
    ],
    child: MaterialApp(home: child),
  );
}

void _viewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(500, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('TransactionsScreen empty state', (tester) async {
    _viewport(tester);
    await tester.pumpWidget(
      _wrap(
        txService: FakeTransactionsService(),
        trService: FakeTransfersService(),
        child: const TransactionsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Belum ada transaksi'), findsWidgets);
    expect(find.byKey(const Key('tx_fab')), findsOneWidget);
  });

  testWidgets('TransactionsScreen list renders 2 transactions', (tester) async {
    _viewport(tester);
    final fake = FakeTransactionsService(
      initial: [
        _tx('t-1', 'income', 50000, 'Penjualan A'),
        _tx('t-2', 'expense', 10000, 'Bensin'),
      ],
      initialCategories: [_cat('c-1', 'income', 'Penjualan')],
    );
    await tester.pumpWidget(
      _wrap(
        txService: fake,
        trService: FakeTransfersService(),
        child: const TransactionsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Penjualan A'), findsOneWidget);
    expect(find.text('Bensin'), findsOneWidget);
    expect(find.text('Belum ada transaksi'), findsNothing);
  });

  testWidgets('TransactionsScreen form submit memanggil record', (
    tester,
  ) async {
    _viewport(tester);
    final fake = FakeTransactionsService();
    await tester.pumpWidget(
      _wrap(
        txService: fake,
        trService: FakeTransfersService(),
        child: const TransactionsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('tx_fab')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('tx_form_amount')), '25000');
    await tester.enterText(
      find.byKey(const Key('tx_form_description')),
      'Setoran tunai',
    );
    await tester.ensureVisible(find.byKey(const Key('tx_form_submit')));
    await tester.tap(find.byKey(const Key('tx_form_submit')));
    await tester.pumpAndSettle();

    expect(fake.recordCallCount, 1);
    expect(fake.lastRecordedType, 'income');
    expect(fake.lastRecordedAmount, 25000);
    expect(fake.lastRecordedDescription, 'Setoran tunai');
  });

  testWidgets('TransfersScreen empty state', (tester) async {
    _viewport(tester);
    await tester.pumpWidget(
      _wrap(
        txService: FakeTransactionsService(),
        trService: FakeTransfersService(),
        child: const TransfersScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Belum ada transfer'), findsOneWidget);
    expect(find.byKey(const Key('transfer_fab')), findsOneWidget);
  });

  testWidgets('TransfersScreen list renders 2 transfers', (tester) async {
    _viewport(tester);
    final fake = FakeTransfersService(
      initial: [_tr('tr-1', 5000), _tr('tr-2', 12000)],
    );
    await tester.pumpWidget(
      _wrap(
        txService: FakeTransactionsService(
          initialAccounts: [
            _account('acc-1', 'Kas'),
            _account('acc-2', 'Bank'),
          ],
        ),
        trService: fake,
        child: const TransfersScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('transfer_tile_tr-1')), findsOneWidget);
    expect(find.byKey(const Key('transfer_tile_tr-2')), findsOneWidget);
  });

  testWidgets('DashboardScreen renders cash flow summary + balance cards', (
    tester,
  ) async {
    _viewport(tester);
    final fake = FakeTransactionsService(
      initialBalances: [
        const AccountBalance(
          accountId: 'acc-1',
          accountName: 'Kas',
          balance: 3000,
        ),
        const AccountBalance(
          accountId: 'acc-2',
          accountName: 'Bank',
          balance: 7000,
        ),
      ],
      initialSummary: const CashFlowSummary(
        income: 15000,
        expense: 5000,
        paymentsNet: 0,
        net: 10000,
      ),
    );
    await tester.pumpWidget(
      _wrap(
        txService: fake,
        trService: FakeTransfersService(),
        child: const DashboardScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Keuangan bulan ini'), findsOneWidget);
    expect(find.text('Saldo akun'), findsOneWidget);
    expect(find.byKey(const Key('dashboard_balance_acc-1')), findsOneWidget);
    expect(find.byKey(const Key('dashboard_balance_acc-2')), findsOneWidget);
    expect(find.text('Rp 15.000'), findsOneWidget);
  });
}
