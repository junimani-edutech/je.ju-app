import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeju_app/core/models/app_user.dart';
import 'package:jeju_app/core/models/business.dart';
import 'package:jeju_app/core/models/business_member.dart';
import 'package:jeju_app/core/providers.dart';
import 'package:jeju_app/features/finance/finance_providers.dart';
import 'package:jeju_app/features/settings/settings_screen.dart';

import '../../fake/fake_services.dart';

const _biz = Business(
  id: 'biz-1',
  name: 'Toko Lama',
  legalName: 'Toko Lama CV',
  timezone: 'Asia/Jakarta',
  currency: 'IDR',
  contactEmail: 'old@example.com',
  contactPhone: '081234567890',
  address: 'Jl. Lama No.1',
);

const _owner = BusinessMember(
  id: 'm-1',
  businessId: 'biz-1',
  userId: 'u-1',
  role: 'owner',
  status: 'active',
);

const _viewer = BusinessMember(
  id: 'm-2',
  businessId: 'biz-1',
  userId: 'u-1',
  role: 'viewer',
  status: 'active',
);

Widget _wrap({
  required FakeBusinessService bizService,
  required BusinessMember member,
  required Widget child,
}) {
  return ProviderScope(
    overrides: [
      authServiceProvider.overrideWithValue(
        FakeAuthService(
          initialUser: const AppUser(id: 'u-1', email: 'u@example.com'),
        ),
      ),
      businessServiceProvider.overrideWithValue(bizService),
      transactionsServiceProvider.overrideWithValue(FakeTransactionsService()),
      transfersServiceProvider.overrideWithValue(FakeTransfersService()),
    ],
    child: MaterialApp(home: child),
  );
}

void _viewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(500, 1500);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('owner melihat form aktif + tombol Simpan', (tester) async {
    _viewport(tester);
    final bizService = FakeBusinessService(
      initialHasBusiness: true,
      initialBusinesses: const [_biz],
      initialMember: _owner,
    );
    await tester.pumpWidget(
      _wrap(
        bizService: bizService,
        member: _owner,
        child: const SettingsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('settings_name')), findsOneWidget);
    expect(find.byKey(const Key('settings_save')), findsOneWidget);

    // Form terisi dari bisnis
    final nameField = tester.widget<TextFormField>(
      find.byKey(const Key('settings_name')),
    );
    expect(nameField.controller?.text, 'Toko Lama');

    // Currency read-only
    expect(find.textContaining('IDR'), findsWidgets);
  });

  testWidgets('viewer tidak melihat tombol Simpan, field disabled', (
    tester,
  ) async {
    _viewport(tester);
    final bizService = FakeBusinessService(
      initialHasBusiness: true,
      initialBusinesses: const [_biz],
      initialMember: _viewer,
    );
    await tester.pumpWidget(
      _wrap(
        bizService: bizService,
        member: _viewer,
        child: const SettingsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('settings_name')), findsOneWidget);
    expect(find.byKey(const Key('settings_save')), findsNothing);

    final nameField = tester.widget<TextFormField>(
      find.byKey(const Key('settings_name')),
    );
    expect(nameField.enabled, isFalse);
  });

  testWidgets('owner save memanggil businessService.updateProfile', (
    tester,
  ) async {
    _viewport(tester);
    final bizService = FakeBusinessService(
      initialHasBusiness: true,
      initialBusinesses: const [_biz],
      initialMember: _owner,
    );
    await tester.pumpWidget(
      _wrap(
        bizService: bizService,
        member: _owner,
        child: const SettingsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('settings_name')), 'Toko Baru');
    await tester.enterText(
      find.byKey(const Key('settings_email')),
      'baru@example.com',
    );
    await tester.tap(find.byKey(const Key('settings_save')));
    await tester.pumpAndSettle();

    expect(bizService.updateProfileCallCount, 1);
    expect(bizService.lastUpdateProfileArgs?['p_name'], 'Toko Baru');
    expect(
      bizService.lastUpdateProfileArgs?['p_contact_email'],
      'baru@example.com',
    );
    expect(bizService.lastUpdateProfileArgs?['p_business_id'], 'biz-1');
  });

  testWidgets('error saat update profil ditampilkan', (tester) async {
    _viewport(tester);
    final bizService = FakeBusinessService(
      initialHasBusiness: true,
      initialBusinesses: const [_biz],
      initialMember: _owner,
    )..throwOnUpdateProfile = true;

    await tester.pumpWidget(
      _wrap(
        bizService: bizService,
        member: _owner,
        child: const SettingsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('settings_save')));
    await tester.pumpAndSettle();

    expect(find.textContaining('update profile failed'), findsOneWidget);
    expect(find.byKey(const Key('settings_save')), findsOneWidget);
  });
}
