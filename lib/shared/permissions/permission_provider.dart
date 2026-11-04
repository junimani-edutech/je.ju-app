import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'app_permission.dart';
// Sesuaikan import ini dengan lokasi currentMemberProvider Anda
import '../../core/providers.dart'; 

part 'permission_provider.g.dart';

@riverpod
Set<AppPermission> currentPermissions(Ref ref) { 
  // Catatan: Jika currentMemberProvider error, pastikan importnya benar
  final member = ref.watch(currentMemberProvider).value; 
  if (member == null) return {}; 
  return member.role.permissions; 
}

@riverpod
bool can(Ref ref, AppPermission permission) { 
  return ref.watch(currentPermissionsProvider).contains(permission); 
}