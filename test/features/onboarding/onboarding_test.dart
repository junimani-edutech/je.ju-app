import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeju_app/app.dart';
import 'package:jeju_app/core/models/app_user.dart';
import 'package:jeju_app/core/providers.dart';

import 'package:jeju_app/features/finance/finance_providers.dart';

import '../../fake/fake_services.dart';

Widget _app({required FakeAuthService auth, required FakeBusinessService biz}) {
  return ProviderScope(
    overrides: [
      authServiceProvider.overrideWithValue(auth),
      businessServiceProvider.overrideWithValue(biz),
      transactionsServiceProvider.overrideWithValue(FakeTransactionsService()),
      transfersServiceProvider.overrideWithValue(FakeTransfersService()),
    ],
    child: const JeJuApp(),
  );
}

void main() {
  testWidgets('user login tanpa bisnis diarahkan ke onboarding', (
    tester,
  ) async {
    final auth = FakeAuthService(
      initialUser: const AppUser(id: 'u1', email: 'u@example.com'),
    );
    await tester.pumpWidget(
      _app(auth: auth, biz: FakeBusinessService(initialHasBusiness: false)),
    );
    await tester.pumpAndSettle();

    // Dua widget bertext 'Buat Usaha' (AppBar + tombol) memang diharapkan.
    expect(find.text('Buat Usaha'), findsWidgets);
    expect(find.byKey(const Key('onboarding_name')), findsOneWidget);
    expect(find.byKey(const Key('onboarding_submit')), findsOneWidget);
  });

  testWidgets('submit onboarding memanggil businessService.createBusiness', (
    tester,
  ) async {
    final auth = FakeAuthService(
      initialUser: const AppUser(id: 'u1', email: 'u@example.com'),
    );
    final biz = FakeBusinessService(initialHasBusiness: false);
    await tester.pumpWidget(_app(auth: auth, biz: biz));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('onboarding_name')),
      'Toko Test',
    );

    await tester.tap(find.byKey(const Key('onboarding_submit')));
    await tester.pumpAndSettle();

    expect(biz.createCallCount, 1);
    expect(biz.lastCreatedName, 'Toko Test');
    expect(biz.lastCreatedTimezone, 'Asia/Jakarta');
  });

  testWidgets('user login yang sudah punya bisnis diarahkan ke dashboard', (
    tester,
  ) async {
    final auth = FakeAuthService(
      initialUser: const AppUser(id: 'u1', email: 'u@example.com'),
    );
    await tester.pumpWidget(
      _app(auth: auth, biz: FakeBusinessService(initialHasBusiness: true)),
    );
    await tester.pumpAndSettle();

    // DashboardScreen: section 'Ringkasan' unik, kartu pengguna menampilkan email.
    expect(find.text('Keuangan bulan ini'), findsOneWidget);
    expect(find.text('u@example.com'), findsOneWidget);
  });
}
