import 'package:jeju_app/core/auth/auth_service.dart';
import 'package:jeju_app/core/business/business_service.dart';
import 'package:jeju_app/core/models/app_user.dart';
import 'package:jeju_app/core/models/business.dart';
import 'package:jeju_app/core/models/business_member.dart';
import 'package:jeju_app/features/customers/customer.dart';
import 'package:jeju_app/features/orders/order.dart';
import 'package:jeju_app/features/orders/orders_service.dart';
import 'package:jeju_app/features/payments/payment.dart';
import 'package:jeju_app/features/payments/payments_service.dart';
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

class FakeOrdersService implements OrdersService {
  FakeOrdersService({
    List<Order> initialOrders = const [],
    List<OrderStatus> initialStatuses = const [],
  }) : _orders = List.of(initialOrders),
       _statuses = List.of(initialStatuses);

  final List<Order> _orders;
  final List<OrderStatus> _statuses;

  int createCallCount = 0;
  int changeStatusCallCount = 0;
  int cancelCallCount = 0;
  String? lastCreatedNotes;
  int lastCreatedItemCount = 0;

  @override
  Future<List<Order>> list({required String businessId}) async {
    return _orders.where((o) => o.businessId == businessId).toList();
  }

  @override
  Future<Order> get(String orderId) async {
    return _orders.firstWhere((o) => o.id == orderId);
  }

  @override
  Future<List<OrderItem>> listItems(String orderId) async => const [];

  @override
  Future<List<OrderStatus>> listStatuses(String businessId) async {
    return _statuses.where((s) => s.businessId == businessId).toList();
  }

  @override
  Future<String> create({
    required String businessId,
    required List<OrderItemInput> items,
    String? customerId,
    DateTime? orderDate,
    DateTime? dueDate,
    String? notes,
    int discountAmount = 0,
    int additionalFeeAmount = 0,
    int shippingAmount = 0,
  }) async {
    createCallCount++;
    lastCreatedNotes = notes;
    lastCreatedItemCount = items.length;
    final now = DateTime.now();
    final id = 'fake-order-${_orders.length + 1}';
    final subtotal = items.fold<int>(0, (acc, e) => acc + e.lineTotal);
    final total =
        subtotal - discountAmount + additionalFeeAmount + shippingAmount;
    _orders.insert(
      0,
      Order(
        id: id,
        businessId: businessId,
        orderNumber:
            '20260101-${(_orders.length + 1).toString().padLeft(3, '0')}',
        customerId: customerId,
        orderDate: orderDate ?? now,
        dueDate: dueDate,
        subtotalAmount: subtotal,
        discountAmount: discountAmount,
        additionalFeeAmount: additionalFeeAmount,
        shippingAmount: shippingAmount,
        totalAmount: total,
        paidAmount: 0,
        currency: 'IDR',
        notes: notes,
        orderStatusId: _statuses.isEmpty ? null : _statuses.first.id,
        paymentStatus: 'unpaid',
        status: 'active',
        createdAt: now,
        updatedAt: now,
      ),
    );
    return id;
  }

  @override
  Future<void> changeStatus({
    required String orderId,
    required String orderStatusId,
    String? notes,
  }) async {
    changeStatusCallCount++;
  }

  @override
  Future<void> cancel(String orderId, {String? reason}) async {
    cancelCallCount++;
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx < 0) return;
    final old = _orders[idx];
    _orders[idx] = Order(
      id: old.id,
      businessId: old.businessId,
      orderNumber: old.orderNumber,
      customerId: old.customerId,
      orderDate: old.orderDate,
      dueDate: old.dueDate,
      subtotalAmount: old.subtotalAmount,
      discountAmount: old.discountAmount,
      additionalFeeAmount: old.additionalFeeAmount,
      shippingAmount: old.shippingAmount,
      totalAmount: old.totalAmount,
      paidAmount: old.paidAmount,
      currency: old.currency,
      notes: old.notes,
      orderStatusId: old.orderStatusId,
      paymentStatus: old.paymentStatus,
      status: 'cancelled',
      createdAt: old.createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class FakePaymentsService implements PaymentsService {
  FakePaymentsService({
    List<Payment> initialPayments = const [],
    List<PaymentMethod> initialMethods = const [],
    List<Account> initialAccounts = const [],
  }) : _payments = List.of(initialPayments),
       _methods = List.of(initialMethods),
       _accounts = List.of(initialAccounts);

  final List<Payment> _payments;
  final List<PaymentMethod> _methods;
  final List<Account> _accounts;

  int recordCallCount = 0;
  int voidCallCount = 0;
  String? lastRecordedIdempotencyKey;
  int? lastRecordedAmount;
  String? lastVoidReason;

  @override
  Future<List<Payment>> listForOrder(String orderId) async {
    return _payments.where((p) => p.orderId == orderId).toList();
  }

  @override
  Future<List<PaymentMethod>> listMethods(String businessId) async {
    return _methods.where((m) => m.businessId == businessId).toList();
  }

  @override
  Future<List<Account>> listAccounts(String businessId) async {
    return _accounts.where((a) => a.businessId == businessId).toList();
  }

  @override
  Future<String> record({
    required String businessId,
    required String orderId,
    required int amount,
    String? paymentMethodId,
    String? accountId,
    DateTime? paymentDate,
    String? reference,
    String? notes,
    String? idempotencyKey,
  }) async {
    recordCallCount++;
    lastRecordedAmount = amount;
    lastRecordedIdempotencyKey = idempotencyKey;

    if (idempotencyKey != null) {
      final existing = _payments
          .where((p) => p.businessId == businessId && p.notes == idempotencyKey)
          .firstOrNull;
      if (existing != null) return existing.id;
    }

    final id = 'fake-pay-${_payments.length + 1}';
    final now = DateTime.now();
    _payments.insert(
      0,
      Payment(
        id: id,
        businessId: businessId,
        orderId: orderId,
        amount: amount,
        currency: 'IDR',
        paymentDate: paymentDate ?? now,
        status: 'confirmed',
        createdAt: now,
        paymentMethodId: paymentMethodId,
        accountId: accountId,
        reference: reference,
        notes: notes ?? idempotencyKey,
        confirmedAt: now,
      ),
    );
    return id;
  }

  @override
  Future<String> voidPayment({
    required String paymentId,
    required String reason,
  }) async {
    voidCallCount++;
    lastVoidReason = reason;

    final original = _payments.firstWhere((p) => p.id == paymentId);
    final reversalId = 'fake-pay-${_payments.length + 1}';
    final now = DateTime.now();
    _payments.insert(
      0,
      Payment(
        id: reversalId,
        businessId: original.businessId,
        orderId: original.orderId,
        amount: original.amount,
        currency: original.currency,
        paymentDate: now,
        status: 'confirmed',
        createdAt: now,
        reversalOfPaymentId: paymentId,
        notes: 'Reversal: $reason',
        confirmedAt: now,
      ),
    );
    return reversalId;
  }
}
