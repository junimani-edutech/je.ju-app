import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'customer.dart';
import 'customers_service.dart';

final customersServiceProvider = Provider<CustomersService>((ref) {
  throw UnimplementedError('customersServiceProvider belum di-override');
});

class CustomersNotifier extends AsyncNotifier<List<Customer>> {
  @override
  Future<List<Customer>> build() async {
    final biz = await ref.watch(currentBusinessProvider.future);
    if (biz == null) return const <Customer>[];
    return ref
        .watch(customersServiceProvider)
        .list(businessId: biz.id, includeArchived: true);
  }

  Future<void> _reload() async {
    final biz = await ref.read(currentBusinessProvider.future);
    if (biz == null) {
      state = const AsyncData(<Customer>[]);
      return;
    }
    final list = await ref
        .read(customersServiceProvider)
        .list(businessId: biz.id);
    state = AsyncData(list);
  }

  Future<void> create({
    required String name,
    String? phone,
    String? email,
    String? address,
    String? notes,
  }) async {
    final biz = await ref.read(currentBusinessProvider.future);
    if (biz == null) throw StateError('Tidak ada bisnis aktif');
    await ref
        .read(customersServiceProvider)
        .create(
          businessId: biz.id,
          name: name,
          phone: phone,
          email: email,
          address: address,
          notes: notes,
        );
    await _reload();
  }

  Future<void> updateCustomer({
    required String id,
    required String name,
    String? phone,
    String? email,
    String? address,
    String? notes,
  }) async {
    await ref
        .read(customersServiceProvider)
        .update(
          id: id,
          name: name,
          phone: phone,
          email: email,
          address: address,
          notes: notes,
        );
    await _reload();
  }

  Future<void> archive(String id) async {
    await ref.read(customersServiceProvider).archive(id);
    await _reload();
  }

  Future<void> restore(String id) async {
    await ref.read(customersServiceProvider).restore(id);
    await _reload();
  }
}

final customersProvider =
    AsyncNotifierProvider<CustomersNotifier, List<Customer>>(
      CustomersNotifier.new,
    );

final activeCustomersProvider = Provider<AsyncValue<List<Customer>>>((ref) {
  return ref
      .watch(customersProvider)
      .whenData((list) => list.where((c) => !c.isArchived).toList());
});

final archivedCustomersProvider = Provider<AsyncValue<List<Customer>>>((ref) {
  return ref
      .watch(customersProvider)
      .whenData((list) => list.where((c) => c.isArchived).toList());
});
