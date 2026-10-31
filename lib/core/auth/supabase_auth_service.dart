import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../models/app_user.dart';
import 'auth_service.dart';

class SupabaseAuthService implements AuthService {
  SupabaseAuthService(this._client);
  final SupabaseClient _client;

  AppUser? _toAppUser(User? user) {
    if (user == null) return null;
    return AppUser(id: user.id, email: user.email ?? '');
  }

  @override
  Stream<AppUser?> get authStateChanges =>
      _client.auth.onAuthStateChange.map((e) => _toAppUser(e.session?.user));

  @override
  AppUser? get currentUser => _toAppUser(_client.auth.currentUser);

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final res = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final user = _toAppUser(res.user);
    if (user == null) throw Exception('Login gagal.');
    return user;
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final res = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
    final user = _toAppUser(res.user);
    if (user == null) throw Exception('Pendaftaran gagal.');
    return user;
  }

  @override
  Future<void> signOut() => _client.auth.signOut();
}
