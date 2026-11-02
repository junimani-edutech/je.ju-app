import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../shared/widgets/business_selector.dart';
import '../finance/finance_models.dart';
import '../finance/finance_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final balancesAsync = ref.watch(accountBalancesProvider);
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, 1);
    final to = DateTime(now.year, now.month, now.day);
    final summaryAsync = ref.watch(
      cashFlowSummaryProvider((from: from, to: to)),
    );

    final summary =
        summaryAsync.value ??
        const CashFlowSummary(income: 0, expense: 0, paymentsNet: 0, net: 0);

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 180,
        leading: const Padding(
          padding: EdgeInsets.only(left: 8),
          child: Center(child: BusinessSelectorButton()),
        ),
        title: const Text('Dashboard'),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(accountBalancesProvider);
          ref.invalidate(cashFlowSummaryProvider((from: from, to: to)));
        },
        child: ListView(
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
            Text(
              'Keuangan bulan ini',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '${from.year}-'
              '${from.month.toString().padLeft(2, '0')}-01'
              ' s/d '
              '${to.year}-'
              '${to.month.toString().padLeft(2, '0')}-'
              '${to.day.toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Pemasukan',
                    value: _fmtIdr(summary.income),
                    icon: Icons.trending_up,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    label: 'Pengeluaran',
                    value: _fmtIdr(summary.expense),
                    icon: Icons.trending_down,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Pembayaran pesanan',
                    value: _fmtIdr(summary.paymentsNet),
                    icon: Icons.payments_outlined,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    label: 'Arus kas bersih',
                    value: _fmtIdr(summary.net),
                    icon: Icons.account_balance_wallet_outlined,
                    color: Theme.of(context).colorScheme.secondary,
                    bold: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Saldo akun', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            balancesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('Gagal memuat saldo: $e'),
              data: (list) {
                if (list.isEmpty) {
                  return const Text('Belum ada akun aktif.');
                }
                return Column(
                  children: [
                    for (final b in list) _AccountBalanceCard(balance: b),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _fmtIdr(int amount) {
    final negative = amount < 0;
    final abs = amount.abs();
    final s = abs.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '${negative ? '-' : ''}Rp ${buf.toString()}';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.bold = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(label, style: theme.textTheme.bodySmall),
            const SizedBox(height: 2),
            Text(
              value,
              style:
                  (bold
                          ? theme.textTheme.titleMedium
                          : theme.textTheme.titleSmall)
                      ?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountBalanceCard extends StatelessWidget {
  const _AccountBalanceCard({required this.balance});
  final AccountBalance balance;

  String _fmtIdr(int amount) {
    final negative = amount < 0;
    final abs = amount.abs();
    final s = abs.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '${negative ? '-' : ''}Rp ${buf.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        key: Key('dashboard_balance_${balance.accountId}'),
        leading: const Icon(Icons.account_balance_outlined),
        title: Text(balance.accountName),
        trailing: Text(
          _fmtIdr(balance.balance),
          style: theme.textTheme.titleMedium,
        ),
      ),
    );
  }
}
