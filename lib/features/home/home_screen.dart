import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    return Scaffold(
      appBar: AppBar(
        title: const Text('JeJu'),
        actions: [
          IconButton(
            key: const Key('home_sign_out'),
            tooltip: 'Keluar',
            onPressed: () => ref.read(authServiceProvider).signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Text(
          user == null ? 'Selamat datang' : 'Selamat datang, ${user.email}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
