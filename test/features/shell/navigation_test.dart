import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeju_app/app.dart';
import 'package:jeju_app/core/models/app_user.dart';
import 'package:jeju_app/core/providers.dart';
import 'package:jeju_app/features/customers/customers_providers.dart';
import 'package:jeju_app/features/orders/orders_providers.dart';
import 'package:jeju_app/features/reports/report_providers.dart';

import '../../fake/fake_services.dart';

Widget _app({required FakeAuthService auth, required FakeBusinessService biz}) {
  return ProviderScope(
    overrides: [
      authServiceProvider.overrideWithValue(auth),
      businessServiceProvider.overrideWithValue(biz),
      ordersServiceProvider.overrideWithValue(FakeOrdersService()),
      reportServiceProvider.overrideWithValue(FakeReportService()),
      customersServiceProvider.overrideWithValue(FakeCustomersService()),
    ],
    child: const JeJuApp(),
  );
}

FakeAuthService _authed() => FakeAuthService(
  initialUser: const AppUser(id: 'u1', email: 'u@example.com'),
);

void _mobileViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void _wideViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('mobile layout (narrow)', () {
    testWidgets('NavigationBar visible dengan 4 destinasi', (tester) async {
      _mobileViewport(tester);

      await tester.pumpWidget(
        _app(
          auth: _authed(),
          biz: FakeBusinessService(initialHasBusiness: true),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);

      final navBar = find.byType(NavigationBar);
      for (final label in ['Dashboard', 'Pesanan', 'Pelanggan', 'Lainnya']) {
        expect(
          find.descendant(of: navBar, matching: find.text(label)),
          findsOneWidget,
          reason: 'label "$label" harus ada di NavigationBar',
        );
      }
    });

    testWidgets('tap Pesanan membuka OrdersScreen', (tester) async {
      _mobileViewport(tester);

      await tester.pumpWidget(
        _app(
          auth: _authed(),
          biz: FakeBusinessService(initialHasBusiness: true),
        ),
      );
      await tester.pumpAndSettle();

      final navBar = find.byType(NavigationBar);
      await tester.tap(
        find.descendant(of: navBar, matching: find.text('Pesanan')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Belum ada pesanan'), findsOneWidget);
    });

    testWidgets('tap Lainnya membuka MoreScreen dengan menu', (tester) async {
      _mobileViewport(tester);

      await tester.pumpWidget(
        _app(
          auth: _authed(),
          biz: FakeBusinessService(initialHasBusiness: true),
        ),
      );
      await tester.pumpAndSettle();

      final navBar = find.byType(NavigationBar);
      await tester.tap(
        find.descendant(of: navBar, matching: find.text('Lainnya')),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('more_payments')), findsOneWidget);
      expect(find.byKey(const Key('more_reports')), findsOneWidget);
      expect(find.byKey(const Key('more_settings')), findsOneWidget);
      expect(find.byKey(const Key('more_sign_out')), findsOneWidget);
    });
  });

  group('wide layout', () {
    testWidgets('NavigationRail visible dengan semua destinasi', (
      tester,
    ) async {
      _wideViewport(tester);

      await tester.pumpWidget(
        _app(
          auth: _authed(),
          biz: FakeBusinessService(initialHasBusiness: true),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);

      // 'Laporan' hanya ada di rail saat di Dashboard.
      expect(find.text('Laporan'), findsWidgets);
      expect(find.text('Pembayaran'), findsWidgets);
      expect(find.text('Pengaturan'), findsWidgets);
    });

    testWidgets('tap Laporan di rail membuka ReportsScreen', (tester) async {
      _wideViewport(tester);

      await tester.pumpWidget(
        _app(
          auth: _authed(),
          biz: FakeBusinessService(initialHasBusiness: true),
        ),
      );
      await tester.pumpAndSettle();

      final rail = find.byType(NavigationRail);
      await tester.tap(
        find.descendant(of: rail, matching: find.text('Laporan')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ringkasan'), findsOneWidget);
    });
  });
}
