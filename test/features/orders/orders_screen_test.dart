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
const _statusProcess = OrderStatus(
  id: 's-process',
  businessId: 'biz-1',
  name: 'Diproses',
  code: 'process',
  sortOrder: 1,
  isFinal: false,
);
const _statusDone = OrderStatus(
  id: 's-done',
  businessId: 'biz-1',
  name: 'Selesai',
  code: 'done',
  sortOrder: 2,
  isFinal: true,
);
const _statusCancelled = OrderStatus(
  id: 's-cancelled',
  businessId: 'biz-1',
  name: 'Dibatalkan',
  code: 'cancelled',
  sortOrder: 3,
  isFinal: true,
);

const _allStatuses = [
  _statusDraft,
  _statusProcess,
  _statusDone,
  _statusCancelled,
];

Order _order({
  required String id,
  required String number,
  String? statusId,
  String status = 'active',
}) {
  return Order(
    id: id,
    businessId: 'biz-1',
    orderNumber: number,
    orderDate: DateTime(2026, 11, 1),
    subtotalAmount: 10000,
    discountAmount: 0,
    additionalFeeAmount: 0,
    shippingAmount: 0,
    totalAmount: 10000,
    paidAmount: 0,
    currency: 'IDR',
    paymentStatus: 'unpaid',
    status: status,
    orderStatusId: statusId,
    createdAt: DateTime(2026, 11, 1),
    updatedAt: DateTime(2026, 11, 1),
  );
}

Widget _app({
  required FakeOrdersService orders,
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
      ordersServiceProvider.overrideWithValue(orders),
      customersServiceProvider.overrideWithValue(FakeCustomersService()),
    ],
    child: const MaterialApp(home: OrdersScreen()),
  );
}

void _mobileViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('empty state saat belum ada pesanan', (tester) async {
    _mobileViewport(tester);
    await tester.pumpWidget(
      _app(
        orders: FakeOrdersService(initialStatuses: _allStatuses),
        member: _ownerMember,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Belum ada pesanan'), findsOneWidget);
    expect(find.byKey(const Key('orders_fab')), findsOneWidget);
  });

  testWidgets('list menampilkan pesanan', (tester) async {
    _mobileViewport(tester);
    final fake = FakeOrdersService(
      initialStatuses: _allStatuses,
      initialOrders: [
        _order(id: 'o-1', number: '20261101-001', statusId: 's-draft'),
        _order(id: 'o-2', number: '20261101-002', statusId: 's-process'),
      ],
    );
    await tester.pumpWidget(_app(orders: fake, member: _ownerMember));
    await tester.pumpAndSettle();

    expect(find.text('20261101-001'), findsOneWidget);
    expect(find.text('20261101-002'), findsOneWidget);
    expect(find.text('Belum ada pesanan'), findsNothing);
  });

  testWidgets('tab Draft memfilter pesanan', (tester) async {
    _mobileViewport(tester);
    final fake = FakeOrdersService(
      initialStatuses: _allStatuses,
      initialOrders: [
        _order(id: 'o-1', number: '20261101-001', statusId: 's-draft'),
        _order(id: 'o-2', number: '20261101-002', statusId: 's-process'),
      ],
    );
    await tester.pumpWidget(_app(orders: fake, member: _ownerMember));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('orders_tab_draft')));
    await tester.pumpAndSettle();

    expect(find.text('20261101-001'), findsOneWidget);
    expect(find.text('20261101-002'), findsNothing);
  });

  testWidgets('tap pesanan membuka detail sheet', (tester) async {
    _mobileViewport(tester);
    final fake = FakeOrdersService(
      initialStatuses: _allStatuses,
      initialOrders: [
        _order(id: 'o-1', number: '20261101-042', statusId: 's-draft'),
      ],
    );
    await tester.pumpWidget(_app(orders: fake, member: _ownerMember));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('order_tile_o-1')));
    await tester.pumpAndSettle();

    // Detail sheet menampilkan order number
    expect(find.text('20261101-042'), findsWidgets);
    // Tombol Ubah Status muncul untuk owner
    expect(find.byKey(const Key('order_detail_change_status')), findsOneWidget);
    expect(find.byKey(const Key('order_detail_cancel')), findsOneWidget);
  });

  testWidgets('FAB membuka form buat pesanan', (tester) async {
    _mobileViewport(tester);
    final fake = FakeOrdersService(initialStatuses: _allStatuses);
    await tester.pumpWidget(_app(orders: fake, member: _ownerMember));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('orders_fab')));
    await tester.pumpAndSettle();

    expect(find.text('Buat Pesanan'), findsWidgets);
    expect(find.byKey(const Key('order_form_item_desc_0')), findsOneWidget);
    expect(find.byKey(const Key('order_form_submit')), findsOneWidget);
  });

  testWidgets('form tambah item memanggil ordersService.create', (
    tester,
  ) async {
    _mobileViewport(tester);
    final fake = FakeOrdersService(initialStatuses: _allStatuses);
    await tester.pumpWidget(_app(orders: fake, member: _ownerMember));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('orders_fab')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('order_form_item_desc_0')),
      'Kopi Susu',
    );
    await tester.enterText(find.byKey(const Key('order_form_item_qty_0')), '2');
    await tester.enterText(
      find.byKey(const Key('order_form_item_price_0')),
      '15000',
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('order_form_submit')));
    await tester.pumpAndSettle();

    expect(fake.createCallCount, 1);
    expect(fake.lastCreatedItemCount, 1);
  });

  testWidgets('viewer tidak melihat FAB', (tester) async {
    _mobileViewport(tester);
    final fake = FakeOrdersService(
      initialStatuses: _allStatuses,
      initialOrders: [
        _order(id: 'o-1', number: '20261101-001', statusId: 's-draft'),
      ],
    );
    await tester.pumpWidget(_app(orders: fake, member: _viewerMember));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('orders_fab')), findsNothing);
    // List tetap tampil
    expect(find.text('20261101-001'), findsOneWidget);
  });
}
