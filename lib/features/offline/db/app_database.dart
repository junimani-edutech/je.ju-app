import 'package:drift/drift.dart';

import 'app_database_stub.dart' if (dart.library.io) 'app_database_io.dart';

part 'app_database.g.dart';

// ============================================================
// Mirror tables — schema mengikuti Supabase/PostgreSQL.
// Uang: IntColumn (bigint rupiah). Tanggal: DateTimeColumn (UTC).
// ============================================================

class CustomersTable extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  TextColumn get createdBy => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class OrdersTable extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get orderNumber => text()();
  TextColumn get customerId => text().nullable()();
  DateTimeColumn get orderDate => dateTime()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  IntColumn get subtotalAmount => integer().withDefault(const Constant(0))();
  IntColumn get discountAmount => integer().withDefault(const Constant(0))();
  IntColumn get additionalFeeAmount =>
      integer().withDefault(const Constant(0))();
  IntColumn get shippingAmount => integer().withDefault(const Constant(0))();
  IntColumn get totalAmount => integer().withDefault(const Constant(0))();
  IntColumn get paidAmount => integer().withDefault(const Constant(0))();
  TextColumn get currency => text().withDefault(const Constant('IDR'))();
  TextColumn get notes => text().nullable()();
  TextColumn get orderStatusId => text().nullable()();
  TextColumn get paymentStatus =>
      text().withDefault(const Constant('unpaid'))();
  TextColumn get status => text().withDefault(const Constant('active'))();
  DateTimeColumn get cancelledAt => dateTime().nullable()();
  TextColumn get cancelledBy => text().nullable()();
  TextColumn get cancelReason => text().nullable()();
  TextColumn get createdBy => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class OrderItemsTable extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get orderId => text()();
  IntColumn get position => integer().withDefault(const Constant(0))();
  TextColumn get description => text()();
  RealColumn get quantity => real()();
  IntColumn get unitPrice => integer()();
  IntColumn get discountAmount => integer().withDefault(const Constant(0))();
  IntColumn get lineTotal => integer()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class PaymentsTable extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get orderId => text()();
  IntColumn get amount => integer()();
  TextColumn get currency => text().withDefault(const Constant('IDR'))();
  DateTimeColumn get paymentDate => dateTime()();
  TextColumn get paymentMethodId => text().nullable()();
  TextColumn get accountId => text().nullable()();
  TextColumn get reference => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('confirmed'))();
  TextColumn get idempotencyKey => text().nullable()();
  DateTimeColumn get confirmedAt => dateTime().nullable()();
  TextColumn get confirmedBy => text().nullable()();
  DateTimeColumn get cancelledAt => dateTime().nullable()();
  TextColumn get cancelledBy => text().nullable()();
  TextColumn get cancelReason => text().nullable()();
  TextColumn get reversalOfPaymentId => text().nullable()();
  TextColumn get createdBy => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class TransactionsTable extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get type => text()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get accountId => text().nullable()();
  IntColumn get amount => integer()();
  TextColumn get currency => text().withDefault(const Constant('IDR'))();
  DateTimeColumn get transactionDate => dateTime()();
  TextColumn get description => text()();
  TextColumn get reference => text().nullable()();
  TextColumn get attachmentUrl => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('confirmed'))();
  TextColumn get idempotencyKey => text().nullable()();
  TextColumn get reversalOfTransactionId => text().nullable()();
  DateTimeColumn get cancelledAt => dateTime().nullable()();
  TextColumn get cancelledBy => text().nullable()();
  TextColumn get cancelReason => text().nullable()();
  TextColumn get createdBy => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class TransfersTable extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get fromAccountId => text()();
  TextColumn get toAccountId => text()();
  IntColumn get amount => integer()();
  TextColumn get currency => text().withDefault(const Constant('IDR'))();
  DateTimeColumn get transferDate => dateTime()();
  TextColumn get description => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('confirmed'))();
  TextColumn get idempotencyKey => text().nullable()();
  DateTimeColumn get cancelledAt => dateTime().nullable()();
  TextColumn get cancelledBy => text().nullable()();
  TextColumn get cancelReason => text().nullable()();
  TextColumn get createdBy => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class AccountsTable extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get name => text()();
  TextColumn get type => text()(); // cash, bank, ewallet
  TextColumn get currency => text().withDefault(const Constant('IDR'))();
  IntColumn get initialBalance => integer().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('active'))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class CategoriesTable extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get type => text()(); // income, expense
  TextColumn get name => text()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class PaymentMethodsTable extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get name => text()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class OrderStatusesTable extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get name => text()();
  TextColumn get code => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isFinal => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Antrean mutasi offline. Satu baris = satu operasi tulis yang harus
/// dipush ke server. Idempotency key mencegah duplikasi saat flush ganda.
class ProductsTable extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get name => text()();
  IntColumn get price => integer()();
  TextColumn get description => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  TextColumn get createdBy => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class SyncQueueTable extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get entityType => text()(); // customers, orders, payments, ...
  TextColumn get entityId => text()();
  TextColumn get operation => text()(); // insert, update, delete
  TextColumn get payload => text()(); // JSON
  TextColumn get idempotencyKey => text().nullable()();
  TextColumn get status => text().withDefault(
    const Constant('pending'),
  )(); // pending, in_flight, done, failed
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    CustomersTable,
    OrdersTable,
    OrderItemsTable,
    PaymentsTable,
    TransactionsTable,
    TransfersTable,
    AccountsTable,
    CategoriesTable,
    PaymentMethodsTable,
    ProductsTable,
    OrderStatusesTable,
    SyncQueueTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(createExecutor());

  /// Test-only: in-memory atau dengan QueryExecutor kustom.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;
}
