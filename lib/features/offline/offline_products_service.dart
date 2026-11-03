// ignore_for_file: prefer_initializing_formals
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../products/product.dart';
import '../products/products_service.dart';
import '../products/supabase_products_service.dart';
import 'local_products_repo.dart';
import 'providers.dart';
import 'sync_queue_repository.dart';

class OfflineProductsService implements ProductsService {
  OfflineProductsService({
    required SupabaseProductsService remote,
    required LocalProductsRepo local,
    required SyncQueueRepository queue,
    required Ref ref,
  }) : _remote = remote,
       _local = local,
       _queue = queue,
       _ref = ref;
  final SupabaseProductsService _remote;
  final LocalProductsRepo _local;
  final SyncQueueRepository _queue;
  final Ref _ref;
  final Uuid _uuid = const Uuid();

  bool _isOnline() =>
      _ref.read(networkStatusProvider).value == NetworkStatus.online;

  Map<String, dynamic> _toMap(Product p) => {
    'id': p.id,
    'business_id': p.businessId,
    'name': p.name,
    'price': p.price,
    'description': p.description,
    'status': p.status,
    'created_at': p.createdAt.toIso8601String(),
    'updated_at': p.updatedAt.toIso8601String(),
  };

  @override
  Future<List<Product>> list({
    required String businessId,
    bool includeArchived = false,
  }) async {
    if (_isOnline()) {
      try {
        await _local.upsertMany(
          await _remote.list(businessId: businessId, includeArchived: true),
        );
      } catch (_) {}
    }
    return _local.list(
      businessId: businessId,
      includeArchived: includeArchived,
    );
  }

  @override
  Future<Product> create({
    required String businessId,
    required String name,
    required int price,
    String? description,
  }) async {
    if (_isOnline()) {
      try {
        final r = await _remote.create(
          businessId: businessId,
          name: name,
          price: price,
          description: description,
        );
        await _local.upsert(r);
        return r;
      } catch (_) {}
    }
    final now = DateTime.now().toUtc();
    final p = Product(
      id: _uuid.v4(),
      businessId: businessId,
      name: name,
      price: price,
      description: description,
      status: 'active',
      createdAt: now,
      updatedAt: now,
    );
    await _local.upsert(p);
    await _queue.enqueue(
      businessId: businessId,
      entityType: 'products',
      entityId: p.id,
      operation: SyncOperation.insert,
      payload: jsonEncode(_toMap(p)),
      idempotencyKey: 'prod_${p.id}',
    );
    return p;
  }

  @override
  Future<Product> update({
    required String id,
    required String name,
    required int price,
    String? description,
  }) async {
    if (_isOnline()) {
      try {
        final r = await _remote.update(
          id: id,
          name: name,
          price: price,
          description: description,
        );
        await _local.upsert(r);
        return r;
      } catch (_) {}
    }
    final existing = await _local.byId(id);
    if (existing == null) throw StateError('Product tidak ditemukan');
    final now = DateTime.now().toUtc();
    final p = Product(
      id: id,
      businessId: existing.businessId,
      name: name,
      price: price,
      description: description,
      status: existing.status,
      createdAt: existing.createdAt,
      updatedAt: now,
    );
    await _local.upsert(p);
    await _queue.enqueue(
      businessId: p.businessId,
      entityType: 'products',
      entityId: p.id,
      operation: SyncOperation.update,
      payload: jsonEncode(_toMap(p)),
      idempotencyKey: 'prod_${p.id}_${now.millisecondsSinceEpoch}',
    );
    return p;
  }

  Future<void> _setStatus(String id, String newStatus) async {
    final existing = await _local.byId(id);
    if (existing == null) return;
    final now = DateTime.now().toUtc();
    final p = Product(
      id: id,
      businessId: existing.businessId,
      name: existing.name,
      price: existing.price,
      description: existing.description,
      status: newStatus,
      createdAt: existing.createdAt,
      updatedAt: now,
    );
    await _local.upsert(p);
    if (_isOnline()) {
      try {
        if (newStatus == 'archived') {
          await _remote.archive(id);
        } else {
          await _remote.restore(id);
        }
        return;
      } catch (_) {}
    }
    await _queue.enqueue(
      businessId: p.businessId,
      entityType: 'products',
      entityId: p.id,
      operation: SyncOperation.update,
      payload: jsonEncode(_toMap(p)),
      idempotencyKey: 'prod_${p.id}_${now.millisecondsSinceEpoch}',
    );
  }

  @override
  Future<void> archive(String id) => _setStatus(id, 'archived');
  @override
  Future<void> restore(String id) => _setStatus(id, 'active');
  @override
  Future<void> upsert(Product p) async => _remote.upsert(p);
}
