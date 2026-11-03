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
            key: const Key('more_transactions'),
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('Transaksi'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/app/more/transactions'),
          ),
          ListTile(
            key: const Key('more_transfers'),
            leading: const Icon(Icons.swap_horiz),
            title: const Text('Transfer'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/app/more/transfers'),
          ),
          ListTile(
            key: const Key('more_reports'),
            leading: const Icon(Icons.bar_chart_outlined),
            title: const Text('Laporan'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/app/more/reports'),
          ),
          ListTile(
            key: const Key('more_members'),
            leading: const Icon(Icons.people_outline),
            title: const Text('Anggota & Undangan'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/app/more/members'),
          ),
          ListTile(
            key: const Key('more_products'),
            leading: const Icon(Icons.inventory_2_outlined),
            title: const Text('Master Produk'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/app/more/products'),
          ),
          ListTile(
            key: const Key('more_sync'),
            leading: const Icon(Icons.cloud_upload_outlined),
            title: const Text('Status Sinkronisasi'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/app/more/sync'),
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
