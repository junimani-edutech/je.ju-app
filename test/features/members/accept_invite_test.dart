import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jeju_app/core/models/app_user.dart';
import 'package:jeju_app/core/models/business.dart';
import 'package:jeju_app/core/models/business_member.dart';
import 'package:jeju_app/core/providers.dart';
import 'package:jeju_app/features/members/accept_invite_screen.dart';
import 'package:jeju_app/features/members/members_providers.dart';

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
  required String initialLocation,
  required AppUser? user,
  required FakeMembersService members,
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/accept-invite',
        builder: (_, _) => const AcceptInviteScreen(),
      ),
      GoRoute(
        path: '/sign-in',
        builder: (_, _) =>
            const Scaffold(body: Center(child: Text('SIGN_IN_MARKER'))),
      ),
      GoRoute(
        path: '/app/dashboard',
        builder: (_, _) =>
            const Scaffold(body: Center(child: Text('DASHBOARD_MARKER'))),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      authServiceProvider.overrideWithValue(FakeAuthService(initialUser: user)),
      businessServiceProvider.overrideWithValue(
        FakeBusinessService(
          initialHasBusiness: true,
          initialBusinesses: const [_biz],
          initialMember: _owner,
        ),
      ),
      membersServiceProvider.overrideWithValue(members),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void _viewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(500, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('tanpa token menampilkan "Token tidak valid"', (tester) async {
    _viewport(tester);
    await tester.pumpWidget(
      _wrap(
        initialLocation: '/accept-invite',
        user: const AppUser(id: 'u-1', email: 'u@example.com'),
        members: FakeMembersService(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Token tidak valid'), findsOneWidget);
  });

  testWidgets('belum login menampilkan "Login dulu"', (tester) async {
    _viewport(tester);
    await tester.pumpWidget(
      _wrap(
        initialLocation: '/accept-invite?token=abc',
        user: null,
        members: FakeMembersService(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Login dulu'), findsOneWidget);
  });

  testWidgets('user login tap Konfirmasi Bergabung -> sukses', (tester) async {
    _viewport(tester);
    final fake = FakeMembersService();
    await tester.pumpWidget(
      _wrap(
        initialLocation: '/accept-invite?token=abc',
        user: const AppUser(id: 'u-1', email: 'u@example.com'),
        members: fake,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Undangan Bergabung'), findsOneWidget);
    expect(find.byKey(const Key('accept_invite_confirm')), findsOneWidget);

    await tester.tap(find.byKey(const Key('accept_invite_confirm')));
    await tester.pumpAndSettle();

    expect(find.text('Berhasil bergabung'), findsOneWidget);
    expect(fake.acceptCallCount, 1);
    expect(fake.lastAcceptedToken, 'abc');
  });
}
