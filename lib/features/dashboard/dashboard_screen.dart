import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/business_selector.dart';
import '../../core/theme/theme_mode_provider.dart';
import '../../shared/utils/format.dart'; // ✅ Gunakan helper format
import 'widgets/cash_flow_chart.dart';
import 'dashboard_providers.dart';
import '../transactions/presentation/expense_form_sheet.dart';
import '../orders/widgets/order_form_sheet.dart'; 
 // ✅ Form Pemasukan Baru
import '../../shared/widgets/offline_banner.dart';
import '../offline/widgets/sync_queue_badge.dart';
import '../finance/finance_models.dart';
import '../finance/finance_providers.dart';
import '../payments/excess_history_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, 1);
    final to = DateTime(now.year, now.month, now.day);
    
    final summaryAsync = ref.watch(cashFlowSummaryProvider((from: from, to: to)));
    final orderStats = ref.watch(orderStatsProvider);
    final todayRev = ref.watch(todayRevenueProvider);
    final lowStock = ref.watch(lowStockItemsProvider);
    final excessAsync = ref.watch(totalExcessProvider);

    final summary = summaryAsync.value ?? const CashFlowSummary(income: 0, expense: 0, paymentsNet: 0, net: 0);

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 180,
        leading: const Padding(padding: EdgeInsets.only(left: 8), child: Center(child: BusinessSelectorButton())),
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
      // ✅ FAB DIUBAH: Bisa Pemasukan atau Pengeluaran
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'expense_fab',
            onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => const ExpenseFormSheet()),
            tooltip: 'Catat Pengeluaran',
            backgroundColor: Colors.red.shade100,
            foregroundColor: Colors.red.shade900,
            child: const Icon(Icons.remove),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'order_fab',
            onPressed: () => OrderFormSheet.show(context),
            icon: const Icon(Icons.add),
            label: const Text('Buat Pesanan'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(cashFlowSummaryProvider((from: from, to: to)));
          ref.invalidate(transactionsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!kIsWeb) const OfflineBanner(),
            const SizedBox(height: 8),
            
            // ✅ OMSET HARI INI
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Omzet Hari Ini', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onPrimaryContainer)),
                        const SizedBox(height: 4),
                        Text(formatIdr(todayRev), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimaryContainer)),
                      ],
                    ),
                    Icon(Icons.trending_up, size: 40, color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.5)),
                  ],
                ),
              ),
            ),
            
            // ✅ ALERT STOK MENIPIS
            if (lowStock.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.withValues(alpha: 0.3))),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Stok menipis: ${lowStock.join(', ')}', style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
            Text('Status Pesanan Saat Ini', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildOrderStatusGrid(context, orderStats),
            const SizedBox(height: 24),
            Text('Keuangan bulan ini', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _StatCard(
                  label: 'Omzet Bersih',
                  value: formatIdr(summary.omzetBersih),
                  icon: Icons.shopping_bag_outlined,
                  color: Colors.blue,
                  onTap: () => context.go('/app/orders'),
                )),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(
                  label: 'Laba Kotor',
                  value: formatIdr(summary.labaKotor),
                  icon: Icons.trending_up,
                  color: summary.labaKotor >= 0 ? Colors.green : Colors.red,
                  bold: true,
                  onTap: () => context.go('/app/more/reports'),
                )),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _StatCard(
                  label: 'Uang Masuk (Cash)',
                  value: formatIdr(summary.cashInHand),
                  icon: Icons.account_balance_wallet_outlined,
                  color: Colors.teal,
                  onTap: () => context.go('/app/more/transactions?period=this_month'),
                )),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(
                  label: 'Piutang',
                  value: formatIdr(summary.piutang),
                  icon: Icons.pending_actions_outlined,
                  color: summary.piutang > 0 ? Colors.orange : Colors.grey,
                  onTap: () => context.go('/app/more/ar-reminder'),
                )),
              ],
            ),
            const SizedBox(height: 12),
            // Detail kecil: Ongkir sebagai info
            if (summary.totalOngkir > 0)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.local_shipping_outlined, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ongkir (pass-through): ${formatIdr(summary.totalOngkir)}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                      ),
                    ),
                    if (excessAsync.value != null && excessAsync.value! > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          'Kelebihan: ${formatIdr(excessAsync.value!)}',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                        ),
                      ),
                  ],
                ),
              ),
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
                final recent = list.take(5).toList();
                return Column(
                  children: recent.map((tx) => Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.withValues(alpha: 0.1))),
                    child: ListTile(
                      leading: CircleAvatar(backgroundColor: tx.type == 'income' ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1), child: Icon(tx.type == 'income' ? Icons.arrow_downward : Icons.arrow_upward, color: tx.type == 'income' ? Colors.green : Colors.red)),
                      title: Text(tx.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(formatDateId(tx.transactionDate)),
                      trailing: Text('${tx.type == 'income' ? '+' : '-'} ${formatIdr(tx.amount)}', style: TextStyle(fontWeight: FontWeight.bold, color: tx.type == 'income' ? Colors.green : Colors.red)),
                    ),
                  )).toList(),
                );
              },
            ),
            const SizedBox(height: 80), 
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStatusGrid(BuildContext context, Map<String, int> stats) {
    return Column(
      children: [
        Row(children: [
          Expanded(child: _StatusBox(label: 'Antrian Baru', count: stats['new'] ?? 0, color: Colors.amber, onTap: () => context.go('/app/orders?status=draft'))),
          const SizedBox(width: 8),
          Expanded(child: _StatusBox(label: 'Sedang Proses', count: stats['process'] ?? 0, color: Colors.blue, onTap: () => context.go('/app/orders?status=process'))),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _StatusBox(label: 'Siap Diambil', count: stats['ready'] ?? 0, color: Colors.green, onTap: () => context.go('/app/orders?status=ready'))),
          const SizedBox(width: 8),
          Expanded(child: _StatusBox(label: 'Deadline Hari Ini', count: stats['deadline'] ?? 0, color: Colors.orange, onTap: () => context.go('/app/orders?filter=deadline'))),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _StatusBox(label: 'Terlambat', count: stats['late'] ?? 0, color: Colors.red, onTap: () => context.go('/app/orders?filter=late'))),
          const SizedBox(width: 8),
          const Expanded(child: SizedBox()),
        ]),
      ],
    );
  }
}

class _StatusBox extends StatelessWidget {
  final String label; final int count; final MaterialColor color; final VoidCallback? onTap;
  const _StatusBox({required this.label, required this.count, required this.color, this.onTap});
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0, margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: color.withValues(alpha: 0.3))),
      color: color.withValues(alpha: 0.1), clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color.shade700)),
            const SizedBox(height: 4),
            Text('$count', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color.shade900)),
          ]),
        ),
      ),
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
