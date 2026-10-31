import 'package:supabase_flutter/supabase_flutter.dart';

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
}
