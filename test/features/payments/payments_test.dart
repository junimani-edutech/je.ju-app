import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeju_app/core/models/app_user.dart';
import 'package:jeju_app/core/models/business.dart';
import 'package:jeju_app/core/models/business_member.dart';
import 'package:jeju_app/core/providers.dart';
import 'package:jeju_app/features/customers/customers_providers.dart';
import 'package:jeju_app/features/orders/order.dart';
import 'package:jeju_app/features/orders/orders_providers.dart';
import 'package:jeju_app/features/orders/orders_screen.dart';
import 'package:jeju_app/features/payments/payment.dart';
import 'package:jeju_app/features/payments/payments_providers.dart';

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

const _viewerMember = BusinessMember(
  id: 'm-2',
  businessId: 'biz-1',
  userId: 'u-1',
  role: 'viewer',
  status: 'active',
);

const _statusDraft = OrderStatus(
  id: 's-draft',
  businessId: 'biz-1',
  name: 'Draft',
  code: 'draft',
  sortOrder: 0,
  isFinal: false,
);

Order _order({
  required String id,
  required String number,
  int total = 10000,
  int paid = 0,
}) {
  return Order(
    id: id,
    businessId: 'biz-1',
    orderNumber: number,
    orderDate: DateTime(2026, 11, 1),
    subtotalAmount: total,
    discountAmount: 0,
    additionalFeeAmount: 0,
    shippingAmount: 0,
    totalAmount: total,
    paidAmount: paid,
    currency: 'IDR',
    paymentStatus: paid == 0 ? 'unpaid' : 'partial',
    status: 'active',
    orderStatusId: 's-draft',
    createdAt: DateTime(2026, 11, 1),
    updatedAt: DateTime(2026, 11, 1),
  );
}

Payment _payment({required String id, String? reversalOf, int amount = 5000}) {
  return Payment(
    id: id,
    businessId: 'biz-1',
    orderId: 'o-1',
    amount: amount,
    currency: 'IDR',
    paymentDate: DateTime(2026, 11, 1),
    status: 'confirmed',
    createdAt: DateTime(2026, 11, 1),
    reversalOfPaymentId: reversalOf,
  );
}

Widget _app({
  required FakeOrdersService orders,
  required FakePaymentsService payments,
  required BusinessMember member,
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
      customersServiceProvider.overrideWithValue(FakeCustomersService()),
      ordersServiceProvider.overrideWithValue(orders),
      paymentsServiceProvider.overrideWithValue(payments),
    ],
    child: const MaterialApp(home: OrdersScreen()),
  );
}

void _viewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 1500);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _openDetail(WidgetTester tester, String orderId) async {
  await tester.tap(find.byKey(Key('order_tile_$orderId')));
  await tester.pumpAndSettle();
}

Future<void> _openPaymentForm(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('order_detail_record_payment')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('form submit pakai nominal default = sisa tagihan', (
    tester,
  ) async {
    _viewport(tester);
    final orders = FakeOrdersService(
      initialStatuses: const [_statusDraft],
      initialOrders: [_order(id: 'o-1', number: '20261101-001', total: 10000)],
    );
    final payments = FakePaymentsService();

    await tester.pumpWidget(
      _app(orders: orders, payments: payments, member: _ownerMember),
    );
    await tester.pumpAndSettle();

    await _openDetail(tester, 'o-1');
    await _openPaymentForm(tester);

    expect(find.byKey(const Key('payment_form_submit')), findsOneWidget);
    await tester.tap(find.byKey(const Key('payment_form_submit')));
    await tester.pumpAndSettle();

    expect(payments.recordCallCount, 1);
    expect(payments.lastRecordedAmount, 10000);
  });

  testWidgets('record payment menambahkan payment ke list', (tester) async {
    _viewport(tester);
    final orders = FakeOrdersService(
      initialStatuses: const [_statusDraft],
      initialOrders: [_order(id: 'o-1', number: '20261101-001', total: 10000)],
    );
    final payments = FakePaymentsService();

    await tester.pumpWidget(
      _app(orders: orders, payments: payments, member: _ownerMember),
    );
    await tester.pumpAndSettle();

    await _openDetail(tester, 'o-1');
    expect(find.text('Belum ada pembayaran.'), findsOneWidget);

    await _openPaymentForm(tester);
    await tester.tap(find.byKey(const Key('payment_form_submit')));
    await tester.pumpAndSettle();

    expect(find.text('Belum ada pembayaran.'), findsNothing);
    expect(find.byKey(const Key('payment_tile_fake-pay-1')), findsOneWidget);
  });

  testWidgets('reversal payment menampilkan badge dan tanpa tombol Void', (
    tester,
  ) async {
    _viewport(tester);
    final orders = FakeOrdersService(
      initialStatuses: const [_statusDraft],
      initialOrders: [_order(id: 'o-1', number: '20261101-001', total: 10000)],
    );
    final payments = FakePaymentsService(
      initialPayments: [
        _payment(id: 'p-orig', amount: 5000),
        _payment(id: 'p-rev', reversalOf: 'p-orig', amount: 5000),
      ],
    );

    await tester.pumpWidget(
      _app(orders: orders, payments: payments, member: _ownerMember),
    );
    await tester.pumpAndSettle();

    await _openDetail(tester, 'o-1');

    expect(find.text('Reversal'), findsOneWidget);
    expect(find.byKey(const Key('payment_void_p-rev')), findsNothing);
    expect(find.byKey(const Key('payment_void_p-orig')), findsOneWidget);
  });

  testWidgets('viewer tidak melihat tombol Catat maupun Void', (tester) async {
    _viewport(tester);
    final orders = FakeOrdersService(
      initialStatuses: const [_statusDraft],
      initialOrders: [_order(id: 'o-1', number: '20261101-001', total: 10000)],
    );
    final payments = FakePaymentsService(
      initialPayments: [_payment(id: 'p-1', amount: 5000)],
    );

    await tester.pumpWidget(
      _app(orders: orders, payments: payments, member: _viewerMember),
    );
    await tester.pumpAndSettle();

    await _openDetail(tester, 'o-1');

    expect(find.byKey(const Key('order_detail_record_payment')), findsNothing);
    expect(find.byKey(const Key('payment_void_p-1')), findsNothing);
  });

  testWidgets('void dialog memanggil voidPayment dengan alasan', (
    tester,
  ) async {
    _viewport(tester);
    final orders = FakeOrdersService(
      initialStatuses: const [_statusDraft],
      initialOrders: [_order(id: 'o-1', number: '20261101-001', total: 10000)],
    );
    final payments = FakePaymentsService(
      initialPayments: [_payment(id: 'p-1', amount: 5000)],
    );

    await tester.pumpWidget(
      _app(orders: orders, payments: payments, member: _ownerMember),
    );
    await tester.pumpAndSettle();

    await _openDetail(tester, 'o-1');
    await tester.tap(find.byKey(const Key('payment_void_p-1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('payment_void_reason')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('payment_void_reason')),
      'salah input',
    );
    await tester.tap(find.byKey(const Key('payment_void_confirm')));
    await tester.pumpAndSettle();

    expect(payments.voidCallCount, 1);
    expect(payments.lastVoidReason, 'salah input');
  });
}
