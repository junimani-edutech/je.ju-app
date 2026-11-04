import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers.dart';
import 'members_providers.dart';

enum _AcceptState { idle, loading, success, error }

class AcceptInviteScreen extends ConsumerStatefulWidget {
  const AcceptInviteScreen({super.key});
  @override
  ConsumerState<AcceptInviteScreen> createState() => _AcceptInviteScreenState();
}

class _AcceptInviteScreenState extends ConsumerState<AcceptInviteScreen> {
  _AcceptState _state = _AcceptState.idle;
  String? _error;
  bool _isMismatch = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isObscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _token(BuildContext context) {
    final qp = GoRouterState.of(context).uri.queryParameters;
    final t = qp['token'];
    if (t == null || t.trim().isEmpty) return null;
    return t.trim();
  }

  Future<void> _joinAndAccept(String token) async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _error = 'Email dan password wajib diisi');
      return;
    }

    setState(() { _state = _AcceptState.loading; _error = null; _isMismatch = false; });

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final auth = Supabase.instance.client.auth;

    try {
      try {
        await auth.signInWithPassword(email: email, password: password);
      } on AuthException catch (e) {
        final msg = e.message.toLowerCase();
        if (msg.contains('invalid login credentials')) {
          final res = await auth.signUp(email: email, password: password);
          if (res.session == null) throw Exception('Pendaftaran berhasil. Silakan cek email Anda untuk konfirmasi, lalu klik link undangan ini lagi.');
        } else if (msg.contains('email not confirmed')) {
          throw Exception('Email Anda belum dikonfirmasi. Silakan cek kotak masuk email Anda dan klik tautan konfirmasi.');
        } else {
          rethrow;
        }
      }

      await ref.read(membersControllerProvider).acceptInvitation(token);
      if (mounted) setState(() => _state = _AcceptState.success);
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = _AcceptState.error;
          String errorMsg = e.toString();
          if (errorMsg.startsWith('Exception: ')) {
            errorMsg = errorMsg.replaceFirst('Exception: ', '');
          } else if (errorMsg.contains('EMAIL_MISMATCH')) {
            errorMsg = 'Email yang Anda masukkan tidak cocok dengan email yang diundang oleh pemilik usaha.';
            _isMismatch = true; // ✅ Tandai sebagai mismatch
          }
          _error = errorMsg;
        });
      }
    }
  }

  Future<void> _accept(String token) async {
    setState(() { _state = _AcceptState.loading; _error = null; });
    try {
      await ref.read(membersControllerProvider).acceptInvitation(token);
      if (mounted) setState(() => _state = _AcceptState.success);
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = _AcceptState.error;
          String errorMsg = e.toString();
          if (errorMsg.contains('EMAIL_MISMATCH')) {
            _error = 'Email yang sedang login tidak cocok dengan email undangan. Silakan logout dan coba lagi.';
            _isMismatch = true;
          } else {
            _error = errorMsg;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final token = _token(context);
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Terima Undangan')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _buildBody(context, theme, token, user != null),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme, String? token, bool isAuthed) {
    if (token == null) return _message(theme, icon: Icons.error_outline, title: 'Token tidak valid', body: 'Link undangan tidak mengandung token yang sah.', actionLabel: 'Kembali', onAction: () => context.go(isAuthed ? '/app/dashboard' : '/sign-in'));
    if (_state == _AcceptState.success) return _message(theme, icon: Icons.check_circle_outline, title: 'Berhasil bergabung', body: 'Anda sekarang menjadi anggota bisnis ini.', actionLabel: 'Buka Dashboard', onAction: () => context.go('/app/dashboard'));
    if (_state == _AcceptState.loading) return Column(mainAxisSize: MainAxisSize.min, children: [const CircularProgressIndicator(), const SizedBox(height: 16), Text('Memproses undangan...', style: theme.textTheme.bodyMedium)]);
    
    if (_state == _AcceptState.error) {
      // ✅ PERBAIKAN: Jika mismatch dan user sudah login, tampilkan tombol Logout
      if (_isMismatch && isAuthed) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text('Email Tidak Cocok', style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(_error ?? 'Terjadi kesalahan.', textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () async {
                await ref.read(authServiceProvider).signOut(); // Logout
                // Refresh halaman agar kembali ke form input
                if (context.mounted) context.go('/accept-invite?token=$token');
              },
              icon: const Icon(Icons.logout),
              label: const Text('Logout & Coba Lagi'),
            ),
          ],
        );
      }
      return _message(theme, icon: Icons.error_outline, title: 'Gagal', body: _error ?? 'Terjadi kesalahan.', actionLabel: 'Kembali', onAction: () => setState(() { _state = _AcceptState.idle; _isMismatch = false; }));
    }

    if (isAuthed) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.mail_outline, size: 64, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text('Undangan Bergabung', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Anda diundang untuk bergabung. Klik tombol di bawah.', textAlign: TextAlign.center),
          const SizedBox(height: 24),
          FilledButton.icon(onPressed: () => _accept(token), icon: const Icon(Icons.check), label: const Text('Konfirmasi Bergabung')),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.group_add_outlined, size: 64, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text('Gabung ke Bisnis', style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text('Masukkan email yang diundang dan password baru Anda.', textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 24),
        TextField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: _passwordController, obscureText: _isObscure, decoration: InputDecoration(labelText: 'Password', border: const OutlineInputBorder(), suffixIcon: IconButton(icon: Icon(_isObscure ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _isObscure = !_isObscure)))),
        const SizedBox(height: 24),
        FilledButton(onPressed: () => _joinAndAccept(token), style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text('Gabung Sekarang')),
      ],
    );
  }

  Widget _message(ThemeData theme, {required IconData icon, required String title, required String body, required String actionLabel, required VoidCallback onAction}) {
    return Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 64, color: theme.colorScheme.primary), const SizedBox(height: 16), Text(title, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center), const SizedBox(height: 8), Text(body, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium), const SizedBox(height: 24), FilledButton(onPressed: onAction, child: Text(actionLabel))]);
  }
}
