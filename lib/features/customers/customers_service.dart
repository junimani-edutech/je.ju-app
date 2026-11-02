import 'customer.dart';

abstract class CustomersService {
  Future<List<Customer>> list({
    required String businessId,
    bool includeArchived = false,
  });

  Future<Customer> create({
    required String businessId,
    required String name,
    String? phone,
    String? email,
    String? address,
    String? notes,
  });

  Future<Customer> update({
    required String id,
    required String name,
    String? phone,
    String? email,
    String? address,
    String? notes,
  });

  Future<void> archive(String id);
  Future<void> restore(String id);

  /// Upsert by id. Dipakai dispatcher offline untuk push antrean
  /// secara idempoten (insert-or-update by primary key).
  Future<void> upsert(Customer customer);
}
