import 'package:jeju_app/core/auth/auth_service.dart';
import 'package:jeju_app/core/business/business_service.dart';
import 'package:jeju_app/core/models/app_user.dart';

/// Fake auth untuk widget test tanpa jaringan.
/// Memakai Stream.value(user) statis; tidak mengubah stream setelah dibuat.
class FakeAuthService implements AuthService {
  FakeAuthService({AppUser? initialUser}) : _user = initialUser;

  final AppUser? _user;

  int signInCallCount = 0;
  int signUpCallCount = 0;
  String? lastSignInEmail;
  String? lastSignInPassword;
  String? lastSignUpEmail;
  String? lastSignUpPassword;
  String? lastSignUpName;
  bool throwOnSignIn = false;
  bool throwOnSignUp = false;

  @override
  Stream<AppUser?> get authStateChanges => Stream<AppUser?>.value(_user);

  @override
  AppUser? get currentUser => _user;

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    signInCallCount++;
    lastSignInEmail = email;
    lastSignInPassword = password;
    if (throwOnSignIn) throw Exception('invalid credentials');
    return AppUser(id: 'fake-sign-in-id', email: email);
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    signUpCallCount++;
    lastSignUpEmail = email;
    lastSignUpPassword = password;
    lastSignUpName = fullName;
    if (throwOnSignUp) throw Exception('signup failed');
    return AppUser(id: 'fake-sign-up-id', email: email);
  }

  @override
  Future<void> signOut() async {}
}

/// Fake business service. `hasAnyBusiness` bisa berubah dari false → true
/// setelah `createBusiness` dipanggil, agar alur onboarding dapat disimulasikan.
class FakeBusinessService implements BusinessService {
  FakeBusinessService({bool initialHasBusiness = false})
    : _hasBusiness = initialHasBusiness;

  bool _hasBusiness;
  int createCallCount = 0;
  String? lastCreatedName;
  String? lastCreatedTimezone;
  bool throwOnCreate = false;

  @override
  Future<bool> hasAnyBusiness() async => _hasBusiness;

  @override
  Future<String> createBusiness({
    required String name,
    String timezone = 'Asia/Jakarta',
  }) async {
    createCallCount++;
    lastCreatedName = name;
    lastCreatedTimezone = timezone;
    if (throwOnCreate) throw Exception('create failed');
    _hasBusiness = true;
    return 'fake-business-id';
  }
}
