import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeju_app/features/finance/transaction.dart';
import 'package:jeju_app/features/finance/transfer.dart';
import 'package:jeju_app/features/offline/db/app_database.dart';
import 'package:jeju_app/features/offline/local_transactions_repo.dart';
import 'package:jeju_app/features/offline/local_transfers_repo.dart';

Transaction _tx({
  String id = 't-1',
  String businessId = 'biz-1',
  String type = 'income',
  int amount = 5000,
}) {
  final now = DateTime.utc(2026, 11, 2);
  return Transaction(
    id: id,
    businessId: businessId,
    type: type,
    amount: amount,
    currency: 'IDR',
    transactionDate: now,
    description: 'Test $type',
    status: 'confirmed',
    createdAt: now,
  );
}

Transfer _tr({String id = 'tr-1', String businessId = 'biz-1'}) {
  final now = DateTime.utc(2026, 11, 2);
  return Transfer(
    id: id,
    businessId: businessId,
    fromAccountId: 'acc-1',
    toAccountId: 'acc-2',
    amount: 3000,
    currency: 'IDR',
    transferDate: now,
    status: 'confirmed',
    createdAt: now,
  );
}

void main() {
  late AppDatabase db;
  late LocalTransactionsRepo txs;
  late LocalTransfersRepo trs;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    txs = LocalTransactionsRepo(db);
    trs = LocalTransfersRepo(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('transactions upsert + list', () async {
    await txs.upsert(_tx(id: 't-1'));
    await txs.upsert(_tx(id: 't-2', amount: 10000));

    final list = await txs.list(businessId: 'biz-1');
    expect(list.length, 2);
    expect(list.any((t) => t.id == 't-2'), true);
  });

  test('transactions upsert replaces existing', () async {
    await txs.upsert(_tx(id: 't-1', amount: 5000));
    await txs.upsert(_tx(id: 't-1', amount: 8000));

    final list = await txs.list(businessId: 'biz-1');
    expect(list.length, 1);
    expect(list.first.amount, 8000);
  });

  test('transfers upsert + list filter by businessId', () async {
    await trs.upsert(_tr(id: 'tr-1', businessId: 'biz-1'));
    await trs.upsert(_tr(id: 'tr-2', businessId: 'biz-2'));

    final biz1 = await trs.list(businessId: 'biz-1');
    final biz2 = await trs.list(businessId: 'biz-2');
    expect(biz1.length, 1);
    expect(biz2.length, 1);
    expect(biz1.first.amount, 3000);
  });

  test('byId lookup works for both repos', () async {
    await txs.upsert(_tx(id: 't-1'));
    await trs.upsert(_tr(id: 'tr-1'));

    final t = await txs.byId('t-1');
    final tr = await trs.byId('tr-1');
    expect(t?.amount, 5000);
    expect(tr?.amount, 3000);
  });
}
