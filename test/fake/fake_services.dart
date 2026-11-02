import 'dart:typed_data';

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
import 'package:jeju_app/features/finance/category.dart';
import 'package:jeju_app/features/finance/finance_models.dart';
import 'package:jeju_app/features/finance/finance_services.dart';
import 'package:jeju_app/features/finance/transaction.dart';
import 'package:jeju_app/features/finance/transfer.dart';
import 'package:jeju_app/features/reports/report_service.dart';
import 'package:jeju_app/features/reports/export_service.dart';
import 'package:jeju_app/features/reports/report_summary.dart';
import 'package:jeju_app/features/members/business_member_info.dart';
import 'package:jeju_app/features/members/invitation.dart';
import 'package:jeju_app/features/members/members_service.dart';
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

  int updateProfileCallCount = 0;
  Map<String, dynamic>? lastUpdateProfileArgs;
  bool throwOnUpdateProfile = false;

  @override
  Future<void> updateProfile({
    required String businessId,
    required String name,
    String? legalName,
    String? contactEmail,
    String? contactPhone,
    String? address,
    String? timezone,
  }) async {
    updateProfileCallCount++;
    lastUpdateProfileArgs = {
      'p_business_id': businessId,
      'p_name': name,
      'p_legal_name': legalName,
      'p_contact_email': contactEmail,
      'p_contact_phone': contactPhone,
      'p_address': address,
      'p_timezone': timezone,
    };
    if (throwOnUpdateProfile) throw Exception('update profile failed');
    final idx = _businesses.indexWhere((b) => b.id == businessId);
    if (idx >= 0) {
      final old = _businesses[idx];
      _businesses[idx] = Business(
        id: old.id,
        name: name,
        timezone: timezone ?? old.timezone,
        currency: old.currency,
        legalName: legalName,
        contactEmail: contactEmail,
        contactPhone: contactPhone,
        address: address,
      );
    }
  }
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

  @override
  Future<void> upsert(Customer c) async {
    final idx = _store.indexWhere((x) => x.id == c.id);
    if (idx >= 0) {
      _store[idx] = c;
    } else {
      _store.add(c);
    }
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

  int upsertOrderCallCount = 0;

  @override
  Future<void> upsert(Order order, List<OrderItem> items) async {
    upsertOrderCallCount++;
    final idx = _orders.indexWhere((o) => o.id == order.id);
    if (idx >= 0) {
      _orders[idx] = order;
    } else {
      _orders.add(order);
    }
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

  int upsertPaymentCallCount = 0;

  @override
  Future<void> upsert(Payment p) async {
    upsertPaymentCallCount++;
    final idx = _payments.indexWhere((x) => x.id == p.id);
    if (idx >= 0) {
      _payments[idx] = p;
    } else {
      _payments.add(p);
    }
  }
}

class FakeTransactionsService implements TransactionsService {
  FakeTransactionsService({
    List<Transaction> initial = const [],
    List<Category> initialCategories = const [],
    List<Account> initialAccounts = const [],
    List<AccountBalance> initialBalances = const [],
    CashFlowSummary? initialSummary,
  }) : _txs = List.of(initial),
       _cats = List.of(initialCategories),
       _accs = List.of(initialAccounts),
       _balances = List.of(initialBalances),
       _summary =
           initialSummary ??
           const CashFlowSummary(income: 0, expense: 0, paymentsNet: 0, net: 0);

  final List<Transaction> _txs;
  final List<Category> _cats;
  final List<Account> _accs;
  final List<AccountBalance> _balances;
  final CashFlowSummary _summary;

  int recordCallCount = 0;
  int voidCallCount = 0;
  String? lastRecordedType;
  int? lastRecordedAmount;
  String? lastRecordedDescription;
  String? lastVoidReason;

  @override
  Future<List<Transaction>> list({required String businessId}) async {
    return _txs.where((t) => t.businessId == businessId).toList();
  }

  @override
  Future<List<Category>> listCategories(String businessId) async {
    return _cats.where((c) => c.businessId == businessId).toList();
  }

  @override
  Future<List<Account>> listAccounts(String businessId) async {
    return _accs.where((a) => a.businessId == businessId).toList();
  }

  @override
  Future<List<AccountBalance>> accountBalances(String businessId) async {
    return List.of(_balances);
  }

  @override
  Future<CashFlowSummary> cashFlowSummary({
    required String businessId,
    required DateTime from,
    required DateTime to,
  }) async {
    return _summary;
  }

  @override
  Future<String> record({
    required String businessId,
    required String type,
    required int amount,
    required String description,
    String? categoryId,
    String? accountId,
    DateTime? transactionDate,
    String? reference,
    String? attachmentUrl,
    String? idempotencyKey,
  }) async {
    recordCallCount++;
    lastRecordedType = type;
    lastRecordedAmount = amount;
    lastRecordedDescription = description;
    final id = 'fake-tx-${_txs.length + 1}';
    final now = DateTime.now();
    _txs.insert(
      0,
      Transaction(
        id: id,
        businessId: businessId,
        type: type,
        amount: amount,
        currency: 'IDR',
        transactionDate: transactionDate ?? now,
        description: description,
        status: 'confirmed',
        createdAt: now,
        categoryId: categoryId,
        accountId: accountId,
        reference: reference,
      ),
    );
    return id;
  }

  @override
  Future<String> voidTransaction({
    required String transactionId,
    required String reason,
  }) async {
    voidCallCount++;
    lastVoidReason = reason;
    final orig = _txs.firstWhere((t) => t.id == transactionId);
    final id = 'fake-tx-${_txs.length + 1}';
    final now = DateTime.now();
    _txs.insert(
      0,
      Transaction(
        id: id,
        businessId: orig.businessId,
        type: orig.type,
        amount: orig.amount,
        currency: orig.currency,
        transactionDate: now,
        description: 'Reversal: $reason',
        status: 'confirmed',
        createdAt: now,
        categoryId: orig.categoryId,
        accountId: orig.accountId,
        reversalOfTransactionId: transactionId,
      ),
    );
    return id;
  }

  @override
  Future<void> upsert(Transaction t) async {
    final idx = _txs.indexWhere((x) => x.id == t.id);
    if (idx >= 0) {
      _txs[idx] = t;
    } else {
      _txs.add(t);
    }
  }
}

class FakeTransfersService implements TransfersService {
  FakeTransfersService({List<Transfer> initial = const []})
    : _trs = List.of(initial);

  final List<Transfer> _trs;

  int recordCallCount = 0;
  int voidCallCount = 0;
  String? lastVoidReason;

  @override
  Future<List<Transfer>> list({required String businessId}) async {
    return _trs.where((t) => t.businessId == businessId).toList();
  }

  @override
  Future<String> record({
    required String businessId,
    required String fromAccountId,
    required String toAccountId,
    required int amount,
    DateTime? transferDate,
    String? description,
    String? idempotencyKey,
  }) async {
    recordCallCount++;
    final id = 'fake-tr-${_trs.length + 1}';
    final now = DateTime.now();
    _trs.insert(
      0,
      Transfer(
        id: id,
        businessId: businessId,
        fromAccountId: fromAccountId,
        toAccountId: toAccountId,
        amount: amount,
        currency: 'IDR',
        transferDate: transferDate ?? now,
        status: 'confirmed',
        createdAt: now,
        description: description,
      ),
    );
    return id;
  }

  @override
  Future<void> voidTransfer({
    required String transferId,
    required String reason,
  }) async {
    voidCallCount++;
    lastVoidReason = reason;
    final idx = _trs.indexWhere((t) => t.id == transferId);
    if (idx < 0) return;
    final old = _trs[idx];
    _trs[idx] = Transfer(
      id: old.id,
      businessId: old.businessId,
      fromAccountId: old.fromAccountId,
      toAccountId: old.toAccountId,
      amount: old.amount,
      currency: old.currency,
      transferDate: old.transferDate,
      status: 'cancelled',
      createdAt: old.createdAt,
      description: old.description,
      cancelledAt: DateTime.now(),
      cancelReason: reason,
    );
  }

  @override
  Future<void> upsert(Transfer tr) async {
    final idx = _trs.indexWhere((x) => x.id == tr.id);
    if (idx >= 0) {
      _trs[idx] = tr;
    } else {
      _trs.add(tr);
    }
  }
}

class FakeReportService implements ReportService {
  FakeReportService({ReportSummary? initial})
    : _summary =
          initial ??
          ReportSummary.empty(
            from: DateTime(2026, 11, 1),
            to: DateTime(2026, 11, 30),
          );

  ReportSummary _summary;
  int callCount = 0;
  DateTime? lastFrom;
  DateTime? lastTo;
  bool throwOnCall = false;

  set summary(ReportSummary s) => _summary = s;

  @override
  Future<ReportSummary> reportSummary({
    required String businessId,
    required DateTime from,
    required DateTime to,
  }) async {
    callCount++;
    lastFrom = from;
    lastTo = to;
    if (throwOnCall) throw Exception('report failed');
    return _summary;
  }
}

class FakeExportService implements ExportService {
  int ordersCsvCalls = 0;
  int ordersXlsxCalls = 0;
  int paymentsCsvCalls = 0;
  int transactionsCsvCalls = 0;
  String? lastFilename;
  bool throwOnExport = false;

  ExportBundle _bundle(String name, String mime) {
    lastFilename = name;
    return ExportBundle(
      filename: name,
      bytes: Uint8List.fromList([1, 2, 3]),
      mimeType: mime,
    );
  }

  @override
  ExportBundle ordersCsv({
    required String businessId,
    required ReportSummary summary,
    required List<Order> orders,
  }) {
    ordersCsvCalls++;
    if (throwOnExport) throw Exception('export failed');
    return _bundle('orders.csv', 'text/csv');
  }

  @override
  ExportBundle ordersXlsx({
    required String businessId,
    required ReportSummary summary,
    required List<Order> orders,
  }) {
    ordersXlsxCalls++;
    if (throwOnExport) throw Exception('export failed');
    return _bundle(
      'orders.xlsx',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
  }

  @override
  ExportBundle paymentsCsv({
    required String businessId,
    required ReportSummary summary,
    required List<Payment> payments,
  }) {
    paymentsCsvCalls++;
    if (throwOnExport) throw Exception('export failed');
    return _bundle('payments.csv', 'text/csv');
  }

  @override
  ExportBundle transactionsCsv({
    required String businessId,
    required ReportSummary summary,
    required List<Transaction> transactions,
  }) {
    transactionsCsvCalls++;
    if (throwOnExport) throw Exception('export failed');
    return _bundle('transactions.csv', 'text/csv');
  }
}

class FakeMembersService implements MembersService {
  FakeMembersService({
    List<BusinessMemberInfo> initialMembers = const [],
    List<Invitation> initialInvitations = const [],
  }) : _members = List.of(initialMembers),
       _invitations = List.of(initialInvitations);

  final List<BusinessMemberInfo> _members;
  final List<Invitation> _invitations;

  int createCallCount = 0;
  int revokeCallCount = 0;
  int acceptCallCount = 0;
  String? lastCreatedEmail;
  String? lastCreatedRole;
  String? lastRevokedId;
  String? lastAcceptedToken;
  bool throwOnCreate = false;
  bool throwOnAccept = false;

  @override
  Future<List<BusinessMemberInfo>> listMembers(String businessId) async =>
      List.of(_members);

  @override
  Future<List<Invitation>> listPendingInvitations(String businessId) async =>
      List.of(_invitations);

  @override
  Future<CreatedInvitation> createInvitation({
    required String businessId,
    required String email,
    required String role,
  }) async {
    createCallCount++;
    lastCreatedEmail = email;
    lastCreatedRole = role;
    if (throwOnCreate) throw Exception('create invitation failed');
    final now = DateTime.now();
    final inv = Invitation(
      id: 'inv-${_invitations.length + 1}',
      businessId: businessId,
      email: email,
      role: role,
      token: 'tok-${_invitations.length + 1}',
      status: 'pending',
      expiresAt: now.add(const Duration(days: 7)),
      createdAt: now,
    );
    _invitations.insert(0, inv);
    return CreatedInvitation(
      invitationId: inv.id,
      token: inv.token,
      expiresAt: inv.expiresAt,
    );
  }

  @override
  Future<void> revokeInvitation(String invitationId) async {
    revokeCallCount++;
    lastRevokedId = invitationId;
    _invitations.removeWhere((i) => i.id == invitationId);
  }

  @override
  Future<String> acceptInvitation(String token) async {
    acceptCallCount++;
    lastAcceptedToken = token;
    if (throwOnAccept) throw Exception('accept failed');
    return 'biz-1';
  }
}
