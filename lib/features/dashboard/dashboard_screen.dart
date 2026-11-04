import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../shared/widgets/business_selector.dart';
import '../../core/theme/theme_mode_provider.dart';
import 'widgets/cash_flow_chart.dart';
import 'dashboard_providers.dart'; // ✅ Import provider baru
import '../transactions/presentation/expense_form_sheet.dart'; 
import '../../shared/widgets/offline_banner.dart';
import '../offline/widgets/sync_queue_badge.dart';
import '../finance/finance_models.dart';
import '../finance/finance_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final balancesAsync = ref.watch(accountBalancesProvider);
    final transactionsAsync = ref.watch(transactionsProvider);
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, 1);
    final to = DateTime(now.year, now.month, now.day);
    
    final summaryAsync = ref.watch(cashFlowSummaryProvider((from: from, to: to)));
    final orderStats = ref.watch(orderStatsProvider); // ✅ Gunakan provider asli

    final summary = summaryAsync.value ?? const CashFlowSummary(income: 0, expense: 0, paymentsNet: 0, net: 0);

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 180,
        leading: const Padding(
          padding: EdgeInsets.only(left: 8),
          child: Center(child: BusinessSelectorButton()),
        ),
        title: const Text('Dashboard'),
        centerTitle: false,
        actions: [
          if (!kIsWeb) const SyncQueueBadge(),
          IconButton(
            tooltip: 'Ganti Tema',
            icon: Icon(Theme.of(context).brightness == Brightness.dark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              final currentMode = ref.read(themeModeProvider);
              ref.read(themeModeProvider.notifier).set(currentMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => const ExpenseFormSheet(), 
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Catat Pengeluaran'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(accountBalancesProvider);
          ref.invalidate(cashFlowSummaryProvider((from: from, to: to)));
          ref.invalidate(transactionsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const OfflineBanner(),
            if (user != null)
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
                child: ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(user.email), 
                  subtitle: const Text('Pengguna aktif'),
                ),
              ),
            const SizedBox(height: 24),
            Text('Keuangan bulan ini', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _StatCard(label: 'Pemasukan', value: _fmtIdr(summary.income), icon: Icons.trending_up, color: Theme.of(context).colorScheme.primary, onTap: () => context.go('/app/more/transactions?type=income&period=this_month'))),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(label: 'Pengeluaran', value: _fmtIdr(summary.expense), icon: Icons.trending_down, color: Theme.of(context).colorScheme.error, onTap: () => context.go('/app/more/transactions?type=expense&period=this_month'))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _StatCard(label: 'Pembayaran pesanan', value: _fmtIdr(summary.paymentsNet), icon: Icons.payments_outlined, color: Colors.orange, onTap: () => context.go('/app/more/payments'))),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(label: 'Arus kas bersih', value: _fmtIdr(summary.net), icon: Icons.account_balance_wallet_outlined, color: Colors.green, bold: true, onTap: () => context.go('/app/more/transactions?period=this_month'))),
              ],
            ),
            const SizedBox(height: 24),
            Text('Status Pesanan Saat Ini', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildOrderStatusGrid(orderStats), // ✅ Panggil Grid
            const SizedBox(height: 24),
            Text('Arus Kas (7 Hari Terakhir)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const CashFlowChart(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Transaksi Terbaru', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                TextButton(onPressed: () => context.go('/app/more/transactions'), child: const Text('Lihat Semua')),
              ],
            ),
            transactionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Gagal memuat transaksi: $e'),
              data: (list) {
                if (list.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.withValues(alpha: 0.2))),
                    child: Column(children: [Icon(Icons.receipt_long, size: 48, color: Colors.grey.shade400), const SizedBox(height: 8), Text('Belum ada transaksi', style: TextStyle(color: Colors.grey.shade600))]),
                  );
                }
                final recent = list.take(3).toList();
                return Column(
                  children: recent.map((tx) => Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.withValues(alpha: 0.1))),
                    child: ListTile(
                      leading: CircleAvatar(backgroundColor: tx.type == 'income' ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1), child: Icon(tx.type == 'income' ? Icons.arrow_downward : Icons.arrow_upward, color: tx.type == 'income' ? Colors.green : Colors.red)),
                      title: Text(tx.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text('${tx.transactionDate.day}/${tx.transactionDate.month}/${tx.transactionDate.year}'),
                      trailing: Text('${tx.type == 'income' ? '+' : '-'} ${_fmtIdr(tx.amount)}', style: TextStyle(fontWeight: FontWeight.bold, color: tx.type == 'income' ? Colors.green : Colors.red)),
                    ),
                  )).toList(),
                );
              },
            ),
            const SizedBox(height: 24),
            Text('Saldo akun', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            balancesAsync.when(
              loading: () => const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Center(child: CircularProgressIndicator())),
              error: (e, _) => Text('Gagal memuat saldo: $e'),
              data: (list) => list.isEmpty ? const Text('Belum ada akun aktif.') : Column(children: [for (final b in list) _AccountBalanceCard(balance: b)]),
            ),
            const SizedBox(height: 80), 
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStatusGrid(Map<String, int> stats) {
    return Column(
      children: [
        Row(children: [
          Expanded(child: _StatusBox(label: 'Antrian Baru', count: stats['new'] ?? 0, color: Colors.amber)),
          const SizedBox(width: 8),
          Expanded(child: _StatusBox(label: 'Sedang Proses', count: stats['process'] ?? 0, color: Colors.blue)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _StatusBox(label: 'Siap Diambil', count: stats['ready'] ?? 0, color: Colors.green)),
          const SizedBox(width: 8),
          Expanded(child: _StatusBox(label: 'Deadline Hari Ini', count: stats['deadline'] ?? 0, color: Colors.orange)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _StatusBox(label: 'Terlambat', count: stats['late'] ?? 0, color: Colors.red)),
          const SizedBox(width: 8),
          const Expanded(child: SizedBox()),
        ]),
      ],
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

class _StatusBox extends StatelessWidget {
  final String label; final int count; final MaterialColor color;
  const _StatusBox({required this.label, required this.count, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color.shade700)),
        const SizedBox(height: 4),
        Text('$count', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color.shade900)),
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon, required this.color, this.bold = false, this.onTap});
  final String label; final String value; final IconData icon; final Color color; final bool bold; final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
      clipBehavior: Clip.antiAlias, 
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Icon(icon, color: color, size: 20), if (onTap != null) const Icon(Icons.chevron_right, size: 16, color: Colors.grey)]),
            const SizedBox(height: 8),
            Text(label, style: theme.textTheme.bodySmall),
            const SizedBox(height: 2),
            Text(value, style: (bold ? theme.textTheme.titleMedium : theme.textTheme.titleSmall)?.copyWith(color: color, fontWeight: FontWeight.bold)),
          ]),
        ),
      ),
    );
  }
}

class _AccountBalanceCard extends StatelessWidget {
  const _AccountBalanceCard({required this.balance});
  final AccountBalance balance;
  String _fmtIdr(int amount) { final negative = amount < 0; final abs = amount.abs(); final s = abs.toString(); final buf = StringBuffer(); for (var i = 0; i < s.length; i++) { if (i > 0 && (s.length - i) % 3 == 0) buf.write('.'); buf.write(s[i]); } return '${negative ? '-' : ''}Rp ${buf.toString()}'; }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.withValues(alpha: 0.1))),
      child: ListTile(
        key: Key('dashboard_balance_${balance.accountId}'),
        leading: const Icon(Icons.account_balance_outlined),
        title: Text(balance.accountName),
        trailing: Text(_fmtIdr(balance.balance), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        onTap: () => context.go('/app/more/transactions?account_id=${balance.accountId}'),
      ),
    );
  }
}
