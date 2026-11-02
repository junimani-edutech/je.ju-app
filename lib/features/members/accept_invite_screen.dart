import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

  String? _token(BuildContext context) {
    final qp = GoRouterState.of(context).uri.queryParameters;
    final t = qp['token'];
    if (t == null || t.trim().isEmpty) return null;
    return t.trim();
  }

  Future<void> _accept(String token) async {
    setState(() {
      _state = _AcceptState.loading;
      _error = null;
    });
    try {
      await ref.read(membersControllerProvider).acceptInvitation(token);
      if (mounted) setState(() => _state = _AcceptState.success);
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = _AcceptState.error;
          _error = e.toString();
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
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _buildBody(context, theme, token, user != null),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    String? token,
    bool isAuthed,
  ) {
    if (token == null) {
      return _message(
        theme,
        icon: Icons.error_outline,
        title: 'Token tidak valid',
        body:
            'Link undangan tidak mengandung token yang sah. '
            'Minta pengirim untuk mengirim ulang link.',
        actionLabel: 'Kembali',
        onAction: () => context.go(isAuthed ? '/app/dashboard' : '/sign-in'),
      );
    }

    if (!isAuthed) {
      return _message(
        theme,
        icon: Icons.lock_outline,
        title: 'Login dulu',
        body: 'Masuk atau daftar untuk menerima undangan.',
        actionLabel: 'Masuk',
        onAction: () => context.go('/sign-in'),
      );
    }

    switch (_state) {
      case _AcceptState.success:
        return _message(
          theme,
          icon: Icons.check_circle_outline,
          title: 'Berhasil bergabung',
          body: 'Anda sekarang menjadi anggota bisnis ini.',
          actionLabel: 'Buka Dashboard',
          onAction: () => context.go('/app/dashboard'),
        );
      case _AcceptState.loading:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Memproses undangan...', style: theme.textTheme.bodyMedium),
          ],
        );
      case _AcceptState.error:
        return _message(
          theme,
          icon: Icons.error_outline,
          title: 'Gagal menerima undangan',
          body: _error ?? 'Terjadi kesalahan.',
          actionLabel: 'Coba Lagi',
          onAction: () {
            setState(() => _state = _AcceptState.idle);
            _accept(token);
          },
        );
      case _AcceptState.idle:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mail_outline,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text('Undangan Bergabung', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Anda diundang untuk bergabung ke sebuah bisnis. '
              'Klik tombol di bawah untuk menerima.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const Key('accept_invite_confirm'),
              onPressed: () => _accept(token),
              icon: const Icon(Icons.check),
              label: const Text('Konfirmasi Bergabung'),
            ),
          ],
        );
    }
  }

  Widget _message(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String body,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 64, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          title,
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          body,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        FilledButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }
}
