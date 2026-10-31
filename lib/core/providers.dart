import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth/auth_service.dart';
import 'business/business_service.dart';
import 'models/app_user.dart';
import 'models/business.dart';
import 'models/business_member.dart';

/// Harus di-override di `main.dart` atau di test.
final authServiceProvider = Provider<AuthService>((ref) {
  throw UnimplementedError('authServiceProvider belum di-override');
});

final businessServiceProvider = Provider<BusinessService>((ref) {
  throw UnimplementedError('businessServiceProvider belum di-override');
});

final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final hasBusinessProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return false;
  return ref.watch(businessServiceProvider).hasAnyBusiness();
});

// Business aktif (bisnis pertama; multi-business UI ditunda ke Fase 7).
final currentBusinessProvider = FutureProvider<Business?>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;
  final list = await ref.watch(businessServiceProvider).listMyBusinesses();
  return list.isEmpty ? null : list.first;
});

// Member aktif user pada business aktif (untuk role-based UI).
final currentMemberProvider = FutureProvider<BusinessMember?>((ref) async {
  final biz = await ref.watch(currentBusinessProvider.future);
  if (biz == null) return null;
  return ref.watch(businessServiceProvider).getMemberForCurrentUser(biz.id);
});
