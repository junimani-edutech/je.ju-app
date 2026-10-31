import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeju_app/core/business/business_service.dart';
import 'package:jeju_app/core/models/app_user.dart';
import 'package:jeju_app/core/models/business.dart';
import 'package:jeju_app/core/models/business_member.dart';
import 'package:jeju_app/core/providers.dart';
import 'package:jeju_app/features/customers/customer.dart';
import 'package:jeju_app/features/customers/customers_providers.dart';
import 'package:jeju_app/features/customers/customers_screen.dart';

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

Customer _cust(String id, String name) => Customer(
  id: id,
  businessId: 'biz-1',
  name: name,
  status: 'active',
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

Widget _app({
  required FakeCustomersService customers,
  required BusinessMember member,
}) {
  // ignore: unused_local_variable
  final BusinessService _ = FakeBusinessService();
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
      customersServiceProvider.overrideWithValue(customers),
    ],
    child: const MaterialApp(home: CustomersScreen()),
  );
}

void main() {
  testWidgets('empty state muncul saat belum ada pelanggan', (tester) async {
    await tester.pumpWidget(
      _app(customers: FakeCustomersService(), member: _ownerMember),
    );
    await tester.pumpAndSettle();

    expect(find.text('Belum ada pelanggan'), findsOneWidget);
    expect(find.byKey(const Key('customers_fab')), findsOneWidget);
  });

  testWidgets('list menampilkan pelanggan aktif', (tester) async {
    final fake = FakeCustomersService(
      initial: [_cust('c-1', 'Ani'), _cust('c-2', 'Budi')],
    );
    await tester.pumpWidget(_app(customers: fake, member: _ownerMember));
    await tester.pumpAndSettle();

    expect(find.text('Ani'), findsOneWidget);
    expect(find.text('Budi'), findsOneWidget);
    expect(find.text('Belum ada pelanggan'), findsNothing);
  });

  testWidgets('search memfilter berdasarkan nama', (tester) async {
    final fake = FakeCustomersService(
      initial: [_cust('c-1', 'Ani'), _cust('c-2', 'Budi')],
    );
    await tester.pumpWidget(_app(customers: fake, member: _ownerMember));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('customers_search')), 'ani');
    await tester.pump();

    expect(find.text('Ani'), findsOneWidget);
    expect(find.text('Budi'), findsNothing);
  });

  testWidgets('FAB membuka form dan submit menambah pelanggan', (tester) async {
    final fake = FakeCustomersService();
    await tester.pumpWidget(_app(customers: fake, member: _ownerMember));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('customers_fab')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('customer_form_name')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('customer_form_name')),
      'Citra',
    );
    await tester.tap(find.byKey(const Key('customer_form_submit')));
    await tester.pumpAndSettle();

    expect(fake.createCallCount, 1);
    expect(fake.lastCreatedName, 'Citra');
    expect(find.text('Citra'), findsOneWidget);
  });

  testWidgets('arsip via menu memanggil archive setelah konfirmasi', (
    tester,
  ) async {
    final fake = FakeCustomersService(initial: [_cust('c-1', 'Ani')]);
    await tester.pumpWidget(_app(customers: fake, member: _ownerMember));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('customer_menu_c-1')));
    await tester.pumpAndSettle();

    // Menu item "Arsipkan"
    await tester.tap(find.text('Arsipkan'));
    await tester.pumpAndSettle();

    // Dialog confirm
    await tester.tap(find.byKey(const Key('customer_archive_confirm')));
    await tester.pumpAndSettle();

    expect(fake.archiveCallCount, 1);
  });

  testWidgets('viewer tidak melihat FAB dan menu aksi', (tester) async {
    final fake = FakeCustomersService(initial: [_cust('c-1', 'Ani')]);
    await tester.pumpWidget(_app(customers: fake, member: _viewerMember));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('customers_fab')), findsNothing);
    expect(find.byKey(const Key('customer_menu_c-1')), findsNothing);
    // List tetap terlihat
    expect(find.text('Ani'), findsOneWidget);
  });
}
