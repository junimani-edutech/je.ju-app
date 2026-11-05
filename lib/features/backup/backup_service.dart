import 'dart:convert';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class BackupService {
  final _client = Supabase.instance.client;

  Future<Uint8List> generateBackup(String businessId) async {
    final res = await _client.rpc('get_business_backup', params: {
      'p_business_id': businessId,
    });
    
    final prettyJson = const JsonEncoder.withIndent('  ').convert(res);
    return Uint8List.fromList(utf8.encode(prettyJson));
  }
}
