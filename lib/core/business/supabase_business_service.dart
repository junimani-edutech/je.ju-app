import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/business.dart';
import '../models/business_member.dart';
import 'business_service.dart';

class SupabaseBusinessService implements BusinessService {
  SupabaseBusinessService(this._client);
  final SupabaseClient _client;

  @override
  Future<bool> hasAnyBusiness() async {
    final rows = await _client.from('businesses').select('id').limit(1);
    return (rows as List).isNotEmpty;
  }

  @override
  Future<String> createBusiness({
    required String name,
    String timezone = 'Asia/Jakarta',
  }) async {
    final result = await _client.rpc(
      'create_business_with_owner',
      params: {'p_name': name, 'p_timezone': timezone},
    );
    return result as String;
  }

  @override
  Future<List<Business>> listMyBusinesses() async {
    final rows = await _client
        .from('businesses')
        .select(
          'id, name, legal_name, contact_email, contact_phone, address, '
          'timezone, currency',
        )
        .order('created_at');
    return (rows as List)
        .map((e) => Business.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<BusinessMember?> getMemberForCurrentUser(String businessId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    final row = await _client
        .from('business_members')
        .select('id, business_id, user_id, role, status')
        .eq('business_id', businessId)
        .eq('user_id', uid)
        .maybeSingle();
    if (row == null) return null;
    return BusinessMember.fromMap(row);
  }

  @override
  Future<void> updateProfile({
    required String businessId,
    required String name,
    String? legalName,
    String? contactEmail,
    String? contactPhone,
    String? address,
    String? timezone,
  }) async {
    await _client.rpc(
      'update_business_profile',
      params: {
        'p_business_id': businessId,
        'p_name': name,
        'p_legal_name': legalName,
        'p_contact_email': contactEmail,
        'p_contact_phone': contactPhone,
        'p_address': address,
        'p_timezone': timezone,
      },
    );
  }
}
