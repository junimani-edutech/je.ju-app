import 'package:supabase_flutter/supabase_flutter.dart';

import 'customer.dart';
import 'customers_service.dart';

class SupabaseCustomersService implements CustomersService {
  SupabaseCustomersService(this._client);
  final SupabaseClient _client;

  @override
  Future<List<Customer>> list({
    required String businessId,
    bool includeArchived = false,
  }) async {
    var q = _client.from('customers').select().eq('business_id', businessId);
    if (!includeArchived) {
      q = q.eq('status', 'active');
    }
    final rows = await q.order('name');
    return (rows as List)
        .map((e) => Customer.fromMap(e as Map<String, dynamic>))
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
    final row = await _client
        .from('customers')
        .insert({
          'business_id': businessId,
          'name': name,
          'phone': phone,
          'email': email,
          'address': address,
          'notes': notes,
        })
        .select()
        .single();
    return Customer.fromMap(row);
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
    final row = await _client
        .from('customers')
        .update({
          'name': name,
          'phone': phone,
          'email': email,
          'address': address,
          'notes': notes,
        })
        .eq('id', id)
        .select()
        .single();
    return Customer.fromMap(row);
  }

  @override
  Future<void> archive(String id) async {
    await _client.from('customers').update({'status': 'archived'}).eq('id', id);
  }

  @override
  Future<void> restore(String id) async {
    await _client.from('customers').update({'status': 'active'}).eq('id', id);
  }

  @override
  Future<void> upsert(Customer c) async {
    await _client.from('customers').upsert({
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
    }, onConflict: 'id');
  }
}
