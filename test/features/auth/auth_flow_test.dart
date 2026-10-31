import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeju_app/app.dart';
import 'package:jeju_app/core/providers.dart';

import '../../fake/fake_services.dart';

Widget _app({required FakeAuthService auth, required FakeBusinessService biz}) {
  return ProviderScope(
    overrides: [
      authServiceProvider.overrideWithValue(auth),
      businessServiceProvider.overrideWithValue(biz),
    ],
    child: const JeJuApp(),
  );
}

void main() {
  testWidgets('sign-in menampilkan form dan navigasi ke sign-up', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(auth: FakeAuthService(), biz: FakeBusinessService()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Masuk ke JeJu'), findsOneWidget);
    expect(find.byKey(const Key('sign_in_email')), findsOneWidget);
    expect(find.byKey(const Key('sign_in_password')), findsOneWidget);

    await tester.tap(find.byKey(const Key('go_sign_up')));
    await tester.pumpAndSettle();

    expect(find.text('Daftar JeJu'), findsOneWidget);
    expect(find.byKey(const Key('sign_up_name')), findsOneWidget);
  });

  testWidgets('sign-in submit memanggil authService dengan email+password', (
    tester,
  ) async {
    final auth = FakeAuthService();
    await tester.pumpWidget(_app(auth: auth, biz: FakeBusinessService()));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('sign_in_email')),
      'user@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('sign_in_password')),
      'secret123',
    );

    await tester.tap(find.byKey(const Key('sign_in_submit')));
    await tester.pumpAndSettle();

    expect(auth.signInCallCount, 1);
    expect(auth.lastSignInEmail, 'user@example.com');
    expect(auth.lastSignInPassword, 'secret123');
  });

  testWidgets(
    'sign-up submit memanggil authService dengan email+password+nama',
    (tester) async {
      final auth = FakeAuthService();
      await tester.pumpWidget(_app(auth: auth, biz: FakeBusinessService()));
      await tester.pumpAndSettle();

      // Navigasi ke sign-up
      await tester.tap(find.byKey(const Key('go_sign_up')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('sign_up_name')), 'Budi');
      await tester.enterText(
        find.byKey(const Key('sign_up_email')),
        'budi@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('sign_up_password')),
        'secret123',
      );

      await tester.tap(find.byKey(const Key('sign_up_submit')));
      await tester.pumpAndSettle();

      expect(auth.signUpCallCount, 1);
      expect(auth.lastSignUpName, 'Budi');
      expect(auth.lastSignUpEmail, 'budi@example.com');
      expect(auth.lastSignUpPassword, 'secret123');
    },
  );

  testWidgets('sign-in error ditampilkan di UI', (tester) async {
    final auth = FakeAuthService()..throwOnSignIn = true;
    await tester.pumpWidget(_app(auth: auth, biz: FakeBusinessService()));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('sign_in_email')),
      'user@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('sign_in_password')),
      'secret123',
    );

    await tester.tap(find.byKey(const Key('sign_in_submit')));
    await tester.pumpAndSettle();

    // Pesan error dari Exception('invalid credentials')
    expect(find.textContaining('invalid credentials'), findsOneWidget);
  });
}
