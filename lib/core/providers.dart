import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth/auth_service.dart';
import 'business/business_service.dart';
import 'models/app_user.dart';

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
