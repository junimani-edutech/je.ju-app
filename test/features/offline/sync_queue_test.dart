import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeju_app/features/offline/db/app_database.dart';
import 'package:jeju_app/features/offline/sync_queue_repository.dart';

void main() {
  late AppDatabase db;
  late SyncQueueRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = SyncQueueRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('enqueue lalu listPending mengembalikan item', () async {
    await repo.enqueue(
      businessId: 'biz-1',
      entityType: 'customers',
      entityId: 'c-1',
      operation: SyncOperation.insert,
      payload: '{"name":"Budi"}',
      idempotencyKey: 'idem-1',
    );

    final items = await repo.listPending('biz-1');
    expect(items.length, 1);
    expect(items.first.entityType, 'customers');
    expect(items.first.status, SyncStatus.pending);
    expect(items.first.idempotencyKey, 'idem-1');
  });

  test('listPending memfilter businessId', () async {
    await repo.enqueue(
      businessId: 'biz-1',
      entityType: 'customers',
      entityId: 'c-1',
      operation: SyncOperation.insert,
      payload: '{}',
    );
    await repo.enqueue(
      businessId: 'biz-2',
      entityType: 'customers',
      entityId: 'c-2',
      operation: SyncOperation.insert,
      payload: '{}',
    );

    final biz1 = await repo.listPending('biz-1');
    final biz2 = await repo.listPending('biz-2');
    expect(biz1.length, 1);
    expect(biz2.length, 1);
  });

  test('markInFlight lalu markDone mengubah status', () async {
    await repo.enqueue(
      businessId: 'biz-1',
      entityType: 'customers',
      entityId: 'c-1',
      operation: SyncOperation.insert,
      payload: '{}',
    );

    final items = await repo.listPending('biz-1');
    final id = items.first.id;

    await repo.markInFlight(id);
    // in_flight tidak muncul di listPending
    final afterInFlight = await repo.listPending('biz-1');
    expect(afterInFlight.length, 0);

    await repo.markDone(id);
    final afterDone = await repo.listPending('biz-1');
    expect(afterDone.length, 0);
  });

  test('markFailed menyimpan retry dan error', () async {
    await repo.enqueue(
      businessId: 'biz-1',
      entityType: 'customers',
      entityId: 'c-1',
      operation: SyncOperation.insert,
      payload: '{}',
    );

    final items = await repo.listPending('biz-1');
    final id = items.first.id;

    await repo.markFailed(id, 'simulated error', retryCount: 2);

    final after = await db.select(db.syncQueueTable).get();
    expect(after.length, 1);
    expect(after.first.status, 'failed');
    expect(after.first.lastError, 'simulated error');
    expect(after.first.retryCount, 2);
  });

  test('countPending menghitung item pending', () async {
    expect(await repo.countPending('biz-1'), 0);

    await repo.enqueue(
      businessId: 'biz-1',
      entityType: 'customers',
      entityId: 'c-1',
      operation: SyncOperation.insert,
      payload: '{}',
    );
    await repo.enqueue(
      businessId: 'biz-1',
      entityType: 'orders',
      entityId: 'o-1',
      operation: SyncOperation.insert,
      payload: '{}',
    );

    expect(await repo.countPending('biz-1'), 2);

    final items = await repo.listPending('biz-1');
    await repo.markDone(items.first.id);
    expect(await repo.countPending('biz-1'), 1);
  });
}
