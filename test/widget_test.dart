import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeju_app/app.dart';
import 'package:jeju_app/core/auth/auth_service.dart';
import 'package:jeju_app/core/business/business_service.dart';
import 'package:jeju_app/core/models/app_user.dart';
import 'package:jeju_app/core/providers.dart';

// Fake auth: tidak login, stream langsung null.
class _FakeAuth implements AuthService {
  @override
  Stream<AppUser?> get authStateChanges => Stream<AppUser?>.value(null);

  @override
  AppUser? get currentUser => null;

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async => throw UnimplementedError();

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async => throw UnimplementedError();

  @override
  Future<void> signOut() async {}
}

// Fake business: tidak ada bisnis.
class _FakeBusiness implements BusinessService {
  @override
  Future<bool> hasAnyBusiness() async => false;

  @override
  Future<String> createBusiness({
    required String name,
    String timezone = 'Asia/Jakarta',
  }) async => throw UnimplementedError();
}

void main() {
  testWidgets('unauthenticated user diarahkan ke sign-in', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(_FakeAuth()),
          businessServiceProvider.overrideWithValue(_FakeBusiness()),
        ],
        child: const JeJuApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Masuk ke JeJu'), findsOneWidget);
    expect(find.byKey(const Key('sign_in_submit')), findsOneWidget);
  });
}
