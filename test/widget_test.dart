import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeju_app/app.dart';
import 'package:jeju_app/core/providers.dart';

import 'fake/fake_services.dart';

void main() {
  testWidgets('unauthenticated user diarahkan ke sign-in', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(FakeAuthService()),
          businessServiceProvider.overrideWithValue(FakeBusinessService()),
        ],
        child: const JeJuApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Masuk ke JeJu'), findsOneWidget);
    expect(find.byKey(const Key('sign_in_submit')), findsOneWidget);
  });
}
