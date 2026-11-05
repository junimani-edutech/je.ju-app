import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/providers.dart';
import 'audit_log.dart';

final auditLogsProvider = FutureProvider<List<AuditLog>>((ref) async {
  final biz = await ref.watch(currentBusinessProvider.future);
  if (biz == null) return [];

  final client = Supabase.instance.client;
  final res = await client
      .from('audit_logs')
      .select()
      .eq('business_id', biz.id)
      .order('created_at', ascending: false)
      .limit(100);

  return (res as List).map((e) => AuditLog.fromMap(e)).toList();
});

// ✅ PERBAIKAN: Menghapus pengecekan null yang tidak perlu
final memberNamesProvider = FutureProvider<Map<String, String>>((ref) async {
  final client = Supabase.instance.client;
  final res = await client.from('profiles').select('id, full_name, email');
  
  return {
    for (var m in res as List)
      m['id']: m['full_name'] ?? m['email'] ?? 'User'
  };
});
