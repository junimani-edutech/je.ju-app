import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lainnya')),
      body: ListView(
        children: [
          ListTile(
            key: const Key('more_payments'),
            leading: const Icon(Icons.payments_outlined),
            title: const Text('Pembayaran'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/app/more/payments'),
          ),
          ListTile(
            key: const Key('more_reports'),
            leading: const Icon(Icons.bar_chart_outlined),
            title: const Text('Laporan'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/app/more/reports'),
          ),
          ListTile(
            key: const Key('more_settings'),
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Pengaturan'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/app/more/settings'),
          ),
          const Divider(),
          ListTile(
            key: const Key('more_sign_out'),
            leading: const Icon(Icons.logout),
            title: const Text('Keluar'),
            onTap: () async {
              await ref.read(authServiceProvider).signOut();
            },
          ),
        ],
      ),
    );
  }
}
