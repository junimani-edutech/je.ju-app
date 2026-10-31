import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        children: [
          if (user != null)
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(user.email),
              subtitle: const Text('Akun aktif'),
            ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.storefront_outlined),
            title: Text('Profil usaha'),
            subtitle: Text('Akan tersedia di Fase 6'),
            enabled: false,
          ),
          const ListTile(
            leading: Icon(Icons.palette_outlined),
            title: Text('Tema'),
            subtitle: Text('Mengikuti sistem; toggle manual di Fase 6'),
            enabled: false,
          ),
          const Divider(),
          ListTile(
            key: const Key('settings_sign_out'),
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
