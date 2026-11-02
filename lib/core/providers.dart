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

/// Multi-business selection (D-01).
///
/// Menyimpan bisnis aktif yang dipilih user. Fallback ke bisnis pertama
/// jika belum ada selection. Persistent storage (`shared_preferences`)
/// ditunda ke Fase 8 (offline).
class CurrentBusinessNotifier extends AsyncNotifier<Business?> {
  String? _selectedBusinessId;

  @override
  Future<Business?> build() async {
    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      _selectedBusinessId = null;
      return null;
    }
    final list = await ref.watch(businessServiceProvider).listMyBusinesses();
    if (list.isEmpty) return null;
    if (_selectedBusinessId != null) {
      for (final b in list) {
        if (b.id == _selectedBusinessId) return b;
      }
      _selectedBusinessId = null;
    }
    final first = list.first;
    _selectedBusinessId = first.id;
    return first;
  }

  Future<void> select(String businessId) async {
    _selectedBusinessId = businessId;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final list = await ref.read(businessServiceProvider).listMyBusinesses();
      for (final b in list) {
        if (b.id == businessId) return b;
      }
      throw StateError('Bisnis tidak ditemukan atau akses dicabut.');
    });
  }
}

final currentBusinessProvider =
    AsyncNotifierProvider<CurrentBusinessNotifier, Business?>(
      CurrentBusinessNotifier.new,
    );

// Member aktif user pada business aktif (untuk role-based UI).
final currentMemberProvider = FutureProvider<BusinessMember?>((ref) async {
  final biz = await ref.watch(currentBusinessProvider.future);
  if (biz == null) return null;
  return ref.watch(businessServiceProvider).getMemberForCurrentUser(biz.id);
});
