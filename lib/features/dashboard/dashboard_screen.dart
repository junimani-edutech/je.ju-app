import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard'), centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (user != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(user.email),
                subtitle: const Text('Pengguna aktif'),
              ),
            ),
          const SizedBox(height: 16),
          Text('Ringkasan', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          const Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Pesanan',
                  value: '—',
                  icon: Icons.receipt_long_outlined,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _MetricCard(
                  label: 'Pemasukan',
                  value: '—',
                  icon: Icons.trending_up,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Pengeluaran',
                  value: '—',
                  icon: Icons.trending_down,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _MetricCard(
                  label: 'Arus kas',
                  value: '—',
                  icon: Icons.swap_horiz,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Segera hadir', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    'Angka ringkasan akan terisi setelah modul pesanan & keuangan tersedia (Fase 4–5).',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(label, style: theme.textTheme.bodySmall),
            const SizedBox(height: 2),
            Text(value, style: theme.textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}
