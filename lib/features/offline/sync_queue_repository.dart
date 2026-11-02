import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'db/app_database.dart';
import 'providers.dart';

enum SyncOperation { insert, update, delete }

enum SyncStatus { pending, inFlight, done, failed }

class SyncQueueItem {
  const SyncQueueItem({
    required this.id,
    required this.businessId,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payload,
    required this.status,
    required this.retryCount,
    required this.createdAt,
    this.idempotencyKey,
    this.lastError,
  });

  final String id;
  final String businessId;
  final String entityType;
  final String entityId;
  final SyncOperation operation;
  final String payload; // JSON
  final SyncStatus status;
  final int retryCount;
  final DateTime createdAt;
  final String? idempotencyKey;
  final String? lastError;
}

class SyncQueueRepository {
  SyncQueueRepository(this._db);
  final AppDatabase _db;

  static String _statusToDb(SyncStatus s) {
    switch (s) {
      case SyncStatus.pending:
        return 'pending';
      case SyncStatus.inFlight:
        return 'in_flight';
      case SyncStatus.done:
        return 'done';
      case SyncStatus.failed:
        return 'failed';
    }
  }

  static SyncStatus _statusFromDb(String s) {
    switch (s) {
      case 'pending':
        return SyncStatus.pending;
      case 'in_flight':
        return SyncStatus.inFlight;
      case 'done':
        return SyncStatus.done;
      case 'failed':
        return SyncStatus.failed;
      default:
        return SyncStatus.pending;
    }
  }

  static SyncOperation _opFromDb(String s) {
    switch (s) {
      case 'insert':
        return SyncOperation.insert;
      case 'update':
        return SyncOperation.update;
      case 'delete':
        return SyncOperation.delete;
      default:
        return SyncOperation.insert;
    }
  }

  static String _opToDb(SyncOperation op) {
    switch (op) {
      case SyncOperation.insert:
        return 'insert';
      case SyncOperation.update:
        return 'update';
      case SyncOperation.delete:
        return 'delete';
    }
  }

  SyncQueueItem _toItem(SyncQueueTableData row) => SyncQueueItem(
    id: row.id,
    businessId: row.businessId,
    entityType: row.entityType,
    entityId: row.entityId,
    operation: _opFromDb(row.operation),
    payload: row.payload,
    status: _statusFromDb(row.status),
    retryCount: row.retryCount,
    createdAt: row.createdAt,
    idempotencyKey: row.idempotencyKey,
    lastError: row.lastError,
  );

  Future<void> enqueue({
    required String businessId,
    required String entityType,
    required String entityId,
    required SyncOperation operation,
    required String payload,
    String? idempotencyKey,
    String? queueId,
  }) async {
    final now = DateTime.now().toUtc();
    await _db
        .into(_db.syncQueueTable)
        .insert(
          SyncQueueTableCompanion.insert(
            id: queueId ?? _generateId(),
            businessId: businessId,
            entityType: entityType,
            entityId: entityId,
            operation: _opToDb(operation),
            payload: payload,
            idempotencyKey: Value(idempotencyKey),
            status: Value(_statusToDb(SyncStatus.pending)),
            retryCount: const Value(0),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<List<SyncQueueItem>> listPending(String businessId) async {
    final rows =
        await (_db.select(_db.syncQueueTable)
              ..where(
                (t) =>
                    t.businessId.equals(businessId) &
                    t.status.equals('pending'),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
            .get();
    return rows.map(_toItem).toList();
  }

  Future<void> markInFlight(String id) async {
    await (_db.update(_db.syncQueueTable)..where((t) => t.id.equals(id))).write(
      SyncQueueTableCompanion(
        status: Value(_statusToDb(SyncStatus.inFlight)),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<void> markDone(String id) async {
    await (_db.update(_db.syncQueueTable)..where((t) => t.id.equals(id))).write(
      SyncQueueTableCompanion(
        status: Value(_statusToDb(SyncStatus.done)),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<void> markFailed(String id, String error, {int? retryCount}) async {
    final values = <String, Object?>{};
    values['status'] = _statusToDb(SyncStatus.failed);
    values['last_error'] = error;
    values['updated_at'] = DateTime.now().toUtc();
    if (retryCount != null) values['retry_count'] = retryCount;
    // Bypass companion — pakai customUpdate agar dinamis.
    await _db.customUpdate(
      'UPDATE sync_queue_table '
      'SET status = ?, last_error = ?, updated_at = ?'
      '${retryCount != null ? ', retry_count = ?' : ''} '
      'WHERE id = ?',
      variables: [
        Variable(values['status'] as String),
        Variable(values['last_error'] as String),
        Variable(values['updated_at'] as DateTime),
        if (retryCount != null) Variable(retryCount),
        Variable(id),
      ],
      updates: {_db.syncQueueTable},
    );
  }

  /// List semua item (semua status) untuk halaman sync status.
  Future<List<SyncQueueItem>> listAll(String businessId) async {
    final rows =
        await (_db.select(_db.syncQueueTable)
              ..where((t) => t.businessId.equals(businessId))
              ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
            .get();
    return rows.map(_toItem).toList();
  }

  /// Reset failed -> pending (untuk tombol "Retry failed").
  Future<void> retryFailed(String businessId) async {
    await (_db.update(_db.syncQueueTable)..where(
          (t) => t.businessId.equals(businessId) & t.status.equals('failed'),
        ))
        .write(
          SyncQueueTableCompanion(
            status: Value('pending'),
            lastError: Value(null),
            updatedAt: Value(DateTime.now().toUtc()),
          ),
        );
  }

  /// Bersihkan item yang sudah done (housekeeping).
  Future<void> clearDone(String businessId) async {
    await (_db.delete(_db.syncQueueTable)..where(
          (t) => t.businessId.equals(businessId) & t.status.equals('done'),
        ))
        .go();
  }

  Future<int> countPending(String businessId) async {
    final count = _db.syncQueueTable.id.count();
    final query = _db.selectOnly(_db.syncQueueTable)
      ..addColumns([count])
      ..where(
        _db.syncQueueTable.businessId.equals(businessId) &
            _db.syncQueueTable.status.equals('pending'),
      );
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Stream<int> watchPendingCount(String businessId) {
    final count = _db.syncQueueTable.id.count();
    final query = _db.selectOnly(_db.syncQueueTable)
      ..addColumns([count])
      ..where(
        _db.syncQueueTable.businessId.equals(businessId) &
            _db.syncQueueTable.status.equals('pending'),
      );
    return query.watchSingle().map((row) => row.read(count) ?? 0);
  }

  String _generateId() {
    // 16-byte hex string, tanpa dependency uuid di repo ini.
    final now = DateTime.now().microsecondsSinceEpoch;
    final rand = (now * 31 + 17).toRadixString(16);
    return 'sq_${now.toRadixString(16)}_$rand';
  }
}

final syncQueueRepositoryProvider = Provider<SyncQueueRepository>((ref) {
  return SyncQueueRepository(ref.watch(appDatabaseProvider));
});
