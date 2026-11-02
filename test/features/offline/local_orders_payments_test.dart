import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeju_app/features/offline/db/app_database.dart';
import 'package:jeju_app/features/offline/local_orders_repo.dart';
import 'package:jeju_app/features/offline/local_payments_repo.dart';
import 'package:jeju_app/features/orders/order.dart';
import 'package:jeju_app/features/payments/payment.dart';

Order _order({
  String id = 'o-1',
  String businessId = 'biz-1',
  String number = '20261102-001',
}) {
  final now = DateTime.utc(2026, 11, 2);
  return Order(
    id: id,
    businessId: businessId,
    orderNumber: number,
    orderDate: now,
    subtotalAmount: 10000,
    discountAmount: 0,
    additionalFeeAmount: 0,
    shippingAmount: 0,
    totalAmount: 10000,
    paidAmount: 0,
    currency: 'IDR',
    paymentStatus: 'unpaid',
    status: 'active',
    createdAt: now,
    updatedAt: now,
  );
}

OrderItem _item({String orderId = 'o-1', int position = 0}) => OrderItem(
  id: 'it-$position',
  businessId: 'biz-1',
  orderId: orderId,
  position: position,
  description: 'Item $position',
  quantity: 1,
  unitPrice: 5000,
  discountAmount: 0,
  lineTotal: 5000,
);

Payment _payment({String id = 'p-1', String orderId = 'o-1'}) => Payment(
  id: id,
  businessId: 'biz-1',
  orderId: orderId,
  amount: 5000,
  currency: 'IDR',
  paymentDate: DateTime.utc(2026, 11, 2),
  status: 'confirmed',
  createdAt: DateTime.utc(2026, 11, 2),
);

void main() {
  late AppDatabase db;
  late LocalOrdersRepo orders;
  late LocalPaymentsRepo payments;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    orders = LocalOrdersRepo(db);
    payments = LocalPaymentsRepo(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('upsertWithItems menyimpan order + items', () async {
    await orders.upsertWithItems(_order(), [
      _item(position: 0),
      _item(position: 1),
    ]);

    final list = await orders.list(businessId: 'biz-1');
    expect(list.length, 1);
    expect(list.first.orderNumber, '20261102-001');

    final items = await orders.listItems('o-1');
    expect(items.length, 2);
    expect(items[0].position, 0);
    expect(items[1].position, 1);
  });

  test('upsertWithItems mengganti items lama (bukan duplikat)', () async {
    await orders.upsertWithItems(_order(), [_item(position: 0)]);
    await orders.upsertWithItems(_order(), [
      _item(position: 0),
      _item(position: 1),
    ]);

    final items = await orders.listItems('o-1');
    expect(items.length, 2);
  });

  test('list memfilter businessId', () async {
    await orders.upsertWithItems(_order(id: 'o-1', businessId: 'biz-1'), [
      _item(),
    ]);
    await orders.upsertWithItems(
      _order(id: 'o-2', businessId: 'biz-2', number: '20261102-002'),
      [_item(orderId: 'o-2')],
    );

    final biz1 = await orders.list(businessId: 'biz-1');
    final biz2 = await orders.list(businessId: 'biz-2');
    expect(biz1.length, 1);
    expect(biz2.length, 1);
  });

  test('payments upsert + listForOrder', () async {
    await payments.upsert(_payment(id: 'p-1', orderId: 'o-1'));
    await payments.upsert(_payment(id: 'p-2', orderId: 'o-1'));
    await payments.upsert(_payment(id: 'p-3', orderId: 'o-2'));

    final p1 = await payments.listForOrder('o-1');
    final p2 = await payments.listForOrder('o-2');
    expect(p1.length, 2);
    expect(p2.length, 1);

    final one = await payments.byId('p-1');
    expect(one?.amount, 5000);
  });
}
