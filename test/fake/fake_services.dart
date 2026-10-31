import 'package:jeju_app/core/auth/auth_service.dart';
import 'package:jeju_app/core/business/business_service.dart';
import 'package:jeju_app/core/models/app_user.dart';
import 'package:jeju_app/core/models/business.dart';
import 'package:jeju_app/core/models/business_member.dart';
import 'package:jeju_app/features/customers/customer.dart';
import 'package:jeju_app/features/customers/customers_service.dart';

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

class FakeBusinessService implements BusinessService {
  FakeBusinessService({
    bool initialHasBusiness = false,
    List<Business> initialBusinesses = const [],
    BusinessMember? initialMember,
  }) : _hasBusiness = initialHasBusiness,
       _businesses = List.of(initialBusinesses),
       _member = initialMember;

  bool _hasBusiness;
  final List<Business> _businesses;
  final BusinessMember? _member;

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

  @override
  Future<List<Business>> listMyBusinesses() async =>
      List.unmodifiable(_businesses);

  @override
  Future<BusinessMember?> getMemberForCurrentUser(String businessId) async =>
      _member;
}

class FakeCustomersService implements CustomersService {
  FakeCustomersService({List<Customer> initial = const []})
    : _store = List.of(initial);

  final List<Customer> _store;

  int createCallCount = 0;
  int updateCallCount = 0;
  int archiveCallCount = 0;
  int restoreCallCount = 0;
  String? lastCreatedName;

  @override
  Future<List<Customer>> list({
    required String businessId,
    bool includeArchived = false,
  }) async {
    return _store
        .where((c) => c.businessId == businessId)
        .where((c) => includeArchived || c.status == 'active')
        .toList();
  }

  @override
  Future<Customer> create({
    required String businessId,
    required String name,
    String? phone,
    String? email,
    String? address,
    String? notes,
  }) async {
    createCallCount++;
    lastCreatedName = name;
    final now = DateTime.now();
    final c = Customer(
      id: 'fake-${_store.length + 1}',
      businessId: businessId,
      name: name,
      status: 'active',
      createdAt: now,
      updatedAt: now,
      phone: phone,
      email: email,
      address: address,
      notes: notes,
    );
    _store.add(c);
    return c;
  }

  @override
  Future<Customer> update({
    required String id,
    required String name,
    String? phone,
    String? email,
    String? address,
    String? notes,
  }) async {
    updateCallCount++;
    final idx = _store.indexWhere((c) => c.id == id);
    if (idx < 0) throw Exception('not found');
    final old = _store[idx];
    final c = Customer(
      id: old.id,
      businessId: old.businessId,
      name: name,
      status: old.status,
      createdAt: old.createdAt,
      updatedAt: DateTime.now(),
      phone: phone,
      email: email,
      address: address,
      notes: notes,
    );
    _store[idx] = c;
    return c;
  }

  @override
  Future<void> archive(String id) async {
    archiveCallCount++;
    final idx = _store.indexWhere((c) => c.id == id);
    if (idx < 0) return;
    _store[idx] = _withStatus(_store[idx], 'archived');
  }

  @override
  Future<void> restore(String id) async {
    restoreCallCount++;
    final idx = _store.indexWhere((c) => c.id == id);
    if (idx < 0) return;
    _store[idx] = _withStatus(_store[idx], 'active');
  }

  Customer _withStatus(Customer c, String status) => Customer(
    id: c.id,
    businessId: c.businessId,
    name: c.name,
    status: status,
    createdAt: c.createdAt,
    updatedAt: DateTime.now(),
    phone: c.phone,
    email: c.email,
    address: c.address,
    notes: c.notes,
  );
}
