import '../models/app_user.dart';

abstract class AuthService {
  Stream<AppUser?> get authStateChanges;
  AppUser? get currentUser;
  Future<AppUser> signIn({required String email, required String password});
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String fullName,
  });
  Future<void> signOut();
}
