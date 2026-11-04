import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authServiceProvider)
          .signIn(email: _emailCtrl.text.trim(), password: _passwordCtrl.text);

      // ✅ PERBAIKAN: Membaca parameter redirect setelah login sukses
      if (mounted) {
        final redirectTarget = GoRouterState.of(context).uri.queryParameters['redirect'];
        if (redirectTarget != null && redirectTarget.startsWith('/')) {
          context.go(Uri.decodeComponent(redirectTarget));
        } else {
          context.go('/app/dashboard');
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        // ✅ PERBAIKAN: Pesan error yang ramah
        String msg = e.message;
        if (msg.contains('Invalid login credentials')) {
          msg = 'Email atau password salah. Silakan coba lagi.';
        } else if (msg.contains('Email not confirmed')) {
          msg = 'Email belum dikonfirmasi. Cek kotak masuk email Anda.';
        }
        setState(() => _error = msg);
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Terjadi kesalahan sistem. Coba lagi nanti.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF0FDF4);
    final cardColor = isDark ? const Color(0xFF1E293B).withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.95);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: Stack(
        children: [
          Container(color: bgColor),
          Positioned(
            top: -100,
            left: -100,
            child: _buildBlob(isDark ? Colors.teal.withValues(alpha: 0.2) : Colors.greenAccent.withValues(alpha: 0.3), 400),
          ),
          Positioned(
            bottom: -50,
            right: -100,
            child: _buildBlob(isDark ? Colors.blue.withValues(alpha: 0.2) : Colors.tealAccent.withValues(alpha: 0.3), 350),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black.withValues(alpha: 0.3) : primaryColor.withValues(alpha: 0.1),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.wallet_rounded, size: 40, color: primaryColor),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'PayNote',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'powered by JeJu-App',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          key: const Key('sign_in_email'),
                          controller: _emailCtrl,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: isDark ? Colors.black12 : Colors.grey.shade50,
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Email wajib diisi' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          key: const Key('sign_in_password'),
                          controller: _passwordCtrl,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: isDark ? Colors.black12 : Colors.grey.shade50,
                          ),
                          obscureText: true,
                          validator: (v) => (v == null || v.length < 6) ? 'Min 6 karakter' : null,
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red, fontSize: 13),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        Container(
                          height: 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: [primaryColor.withValues(alpha: 0.8), primaryColor],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: _loading ? null : _submit,
                              child: Center(
                                child: _loading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : const Text(
                                        'Masuk',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          key: const Key('go_sign_up'),
                          onPressed: () => context.go('/sign-up'),
                          child: Text(
                            'Belum punya akun? Daftar',
                            style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlob(Color color, double size) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
