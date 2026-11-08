// ignore_for_file: prefer_initializing_formals
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../customers/customer.dart';
import '../customers/customers_service.dart';
import '../customers/supabase_customers_service.dart';
import 'local_customers_repo.dart';
import 'providers.dart';
import 'sync_queue_repository.dart';

/// Wrapper transparan: online -> langsung ke Supabase (lalu cache lokal),
/// offline -> tulis ke lokal + enqueue untuk disinkronkan.
class OfflineCustomersService implements CustomersService {
  OfflineCustomersService({
    required SupabaseCustomersService remote,
    required LocalCustomersRepo local,
    required SyncQueueRepository queue,
    required Ref ref,
  }) : _remote = remote,
       _local = local,
       _queue = queue,
       _ref = ref;

  final SupabaseCustomersService _remote;
  final LocalCustomersRepo _local;
  final SyncQueueRepository _queue;
  final Ref _ref;
  final Uuid _uuid = const Uuid();

  bool _isOnline() {
    final status = _ref.read(networkStatusProvider).value;
    // Fail-closed: kalau belum tahu, anggap offline supaya tidak kehilangan
    // operasi (akan di-flush saat online terdeteksi).
    return status == NetworkStatus.online;
  }

  Map<String, dynamic> _toJson(Customer c) => {
    'id': c.id,
    'business_id': c.businessId,
    'name': c.name,
    'phone': c.phone,
    'email': c.email,
    'address': c.address,
    'notes': c.notes,
    'status': c.status,
    'created_at': c.createdAt.toIso8601String(),
    'updated_at': c.updatedAt.toIso8601String(),
  };

  @override
  Future<List<Customer>> list({
    required String businessId,
    bool includeArchived = false,
  }) async {
    if (_isOnline()) {
      try {
        final remote = await _remote.list(
          businessId: businessId,
          includeArchived: true,
        );
        await _local.upsertMany(remote);
      } catch (_) {
        // Gagal pull — fallback ke lokal, jangan block.
      }
    }
    return _local.list(
      businessId: businessId,
      includeArchived: includeArchived,
    );
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
    if (_isOnline()) {
      try {
        final remote = await _remote.create(
          businessId: businessId,
          name: name,
          phone: phone,
          email: email,
          address: address,
          notes: notes,
        );
        await _local.upsert(remote);
        return remote;
      } catch (_) {
        // Fall through ke offline path.
      }
    }

    final now = DateTime.now().toUtc();
    final c = Customer(
      id: _uuid.v4(),
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
    await _local.upsert(c);
    await _queue.enqueue(
      businessId: businessId,
      entityType: 'customers',
      entityId: c.id,
      operation: SyncOperation.insert,
      payload: jsonEncode(_toJson(c)),
      idempotencyKey: 'cust_${c.id}_${now.millisecondsSinceEpoch}',
    );
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
    final existing = await _local.byId(id);
    if (existing == null) {
      throw StateError('Pelanggan tidak ditemukan di lokal: $id');
    }

    if (_isOnline()) {
      try {
        final remote = await _remote.update(
          id: id,
          name: name,
          phone: phone,
          email: email,
          address: address,
          notes: notes,
        );
        await _local.upsert(remote);
        return remote;
      } catch (_) {
        // Fall through.
      }
    }

    final now = DateTime.now().toUtc();
    final updated = Customer(
      id: existing.id,
      businessId: existing.businessId,
      name: name,
      status: existing.status,
      createdAt: existing.createdAt,
      updatedAt: now,
      phone: phone,
      email: email,
      address: address,
      notes: notes,
    );
    await _local.upsert(updated);
    await _queue.enqueue(
      businessId: updated.businessId,
      entityType: 'customers',
      entityId: id,
      operation: SyncOperation.update,
      payload: jsonEncode(_toJson(updated)),
      idempotencyKey: 'cust_${id}_${now.millisecondsSinceEpoch}',
    );
    return updated;
  }

  Future<void> _setStatus(String id, String newStatus) async {
    final existing = await _local.byId(id);
    if (existing == null) return;
    final now = DateTime.now().toUtc();
    final updated = Customer(
      id: existing.id,
      businessId: existing.businessId,
      name: existing.name,
      status: newStatus,
      createdAt: existing.createdAt,
      updatedAt: now,
      phone: existing.phone,
      email: existing.email,
      address: existing.address,
      notes: existing.notes,
    );
    await _local.upsert(updated);
    if (_isOnline()) {
      try {
        if (newStatus == 'archived') {
          await _remote.archive(id);
        } else {
          await _remote.restore(id);
        }
        return;
      } catch (_) {
        // Fall through.
      }
    }
    await _queue.enqueue(
      businessId: updated.businessId,
      entityType: 'customers',
      entityId: id,
      operation: SyncOperation.update,
      payload: jsonEncode(_toJson(updated)),
      idempotencyKey: 'cust_${id}_${now.millisecondsSinceEpoch}',
    );
  }

  @override
  Future<void> archive(String id) => _setStatus(id, 'archived');

  @override
  Future<void> restore(String id) => _setStatus(id, 'active');

  @override
  Future<void> upsert(Customer customer) async {
    // Hanya dipanggil dispatcher saat online.
    await _remote.upsert(customer);
  }

  @override
  Future<bool> canHardDelete(String id) async {
    if (!_isOnline()) {
      throw Exception('Hapus permanen memerlukan koneksi internet.');
    }
    return _remote.canHardDelete(id);
  }

  @override
  Future<void> delete(String id) async {
    if (!_isOnline()) {
      throw Exception('Hapus permanen memerlukan koneksi internet.');
    }
    await _remote.delete(id);
    // Note: data lokal akan refresh otomatis saat list() dipanggil berikutnya.
  }
}
