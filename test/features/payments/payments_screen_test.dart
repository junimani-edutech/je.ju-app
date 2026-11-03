import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeju_app/core/models/app_user.dart';
import 'package:jeju_app/core/models/business.dart';
import 'package:jeju_app/core/models/business_member.dart';
import 'package:jeju_app/core/providers.dart';
import 'package:jeju_app/features/offline/providers.dart';
import 'package:jeju_app/features/orders/order.dart';
import 'package:jeju_app/features/orders/orders_providers.dart';
import 'package:jeju_app/features/payments/payment.dart';
import 'package:jeju_app/features/payments/payments_providers.dart';
import 'package:jeju_app/features/payments/payments_screen.dart';

import '../../fake/fake_services.dart';

const _biz = Business(
  id: 'biz-1',
  name: 'Test',
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

Payment _payment({
  String id = 'p-1',
  String orderId = 'o-1',
  int amount = 5000,
  String status = 'confirmed',
}) {
  final now = DateTime(2026, 11, 3);
  return Payment(
    id: id,
    businessId: 'biz-1',
    orderId: orderId,
    amount: amount,
    currency: 'IDR',
    paymentDate: now,
    status: status,
    createdAt: now,
  );
}

Order _order({String id = 'o-1', String number = '20261103-001'}) {
  final now = DateTime(2026, 11, 3);
  return Order(
    id: id,
    businessId: 'biz-1',
    orderNumber: number,
    orderDate: now,
    subtotalAmount: 5000,
    discountAmount: 0,
    additionalFeeAmount: 0,
    shippingAmount: 0,
    totalAmount: 5000,
    paidAmount: 5000,
    currency: 'IDR',
    paymentStatus: 'paid',
    status: 'active',
    createdAt: now,
    updatedAt: now,
  );
}

Widget _wrap({
  required FakePaymentsService payments,
  required FakeOrdersService orders,
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
      paymentsServiceProvider.overrideWithValue(payments),
      ordersServiceProvider.overrideWithValue(orders),
      syncPendingCountProvider.overrideWith((ref) => const Stream<int>.empty()),
    ],
    child: const MaterialApp(home: PaymentsScreen()),
  );
}

void _viewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(500, 1500);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('empty state', (tester) async {
    _viewport(tester);
    await tester.pumpWidget(
      _wrap(payments: FakePaymentsService(), orders: FakeOrdersService()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Belum ada pembayaran'), findsOneWidget);
  });

  testWidgets('shows payments with order numbers', (tester) async {
    _viewport(tester);
    final payments = FakePaymentsService(
      initialPayments: [
        _payment(id: 'p-1', orderId: 'o-1', amount: 5000),
        _payment(id: 'p-2', orderId: 'o-2', amount: 3000),
      ],
    );
    final orders = FakeOrdersService(
      initialStatuses: const [],
      initialOrders: [
        _order(id: 'o-1', number: '20261103-001'),
        _order(id: 'o-2', number: '20261103-002'),
      ],
    );
    await tester.pumpWidget(_wrap(payments: payments, orders: orders));
    await tester.pumpAndSettle();

    expect(find.textContaining('20261103-001'), findsOneWidget);
    expect(find.textContaining('20261103-002'), findsOneWidget);
  });

  testWidgets('void dialog calls voidPayment', (tester) async {
    _viewport(tester);
    final payments = FakePaymentsService(
      initialPayments: [_payment(id: 'p-1')],
    );
    final orders = FakeOrdersService(
      initialStatuses: const [],
      initialOrders: [_order()],
    );
    await tester.pumpWidget(_wrap(payments: payments, orders: orders));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('payment_void_p-1')));
    await tester.pumpAndSettle();

    expect(find.text('Void pembayaran?'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('payment_void_reason_input')),
      'salah input',
    );
    await tester.tap(find.byKey(const Key('payment_void_confirm')));
    await tester.pumpAndSettle();

    expect(payments.voidCallCount, 1);
  });
}
