import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../finance/finance_providers.dart';
import '../orders/orders_providers.dart';
import 'export_download.dart';
import 'export_service.dart';
import 'report_providers.dart';
import 'report_summary.dart';

enum ExportKind { ordersCsv, ordersXlsx, transactionsCsv }

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _rangeIndex = 0; // 0 = bulan ini, 1 = bulan lalu

  ({DateTime from, DateTime to}) _currentRange() {
    final now = DateTime.now();
    if (_rangeIndex == 0) {
      return (
        from: DateTime(now.year, now.month, 1),
        to: DateTime(now.year, now.month, now.day),
      );
    }
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = DateTime(now.year, now.month, 0);
    return (from: lastMonthStart, to: lastMonthEnd);
  }

  String _rangeLabel() {
    final r = _currentRange();
    String fmt(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return '${fmt(r.from)} s/d ${fmt(r.to)}';
  }

  Future<void> _handleExport(ReportSummary summary, ExportKind kind) async {
    try {
      final biz = await ref.read(currentBusinessProvider.future);
      if (biz == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tidak ada bisnis aktif.')),
          );
        }
        return;
      }
      final export = ref.read(exportServiceProvider);
      late ExportBundle bundle;
      switch (kind) {
        case ExportKind.ordersCsv:
          final orders = await ref.read(ordersProvider.future);
          bundle = export.ordersCsv(
            businessId: biz.id,
            summary: summary,
            orders: orders,
          );
          break;
        case ExportKind.ordersXlsx:
          final orders = await ref.read(ordersProvider.future);
          bundle = export.ordersXlsx(
            businessId: biz.id,
            summary: summary,
            orders: orders,
          );
          break;
        case ExportKind.transactionsCsv:
          final txs = await ref.read(transactionsProvider.future);
          bundle = export.transactionsCsv(
            businessId: biz.id,
            summary: summary,
            transactions: txs,
          );
          break;
      }
      await downloadFile(
        filename: bundle.filename,
        bytes: bundle.bytes,
        mimeType: bundle.mimeType,
      );
      if (!kIsWeb && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'File dibuat. Unduh file native akan tersedia di Fase 7.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal ekspor: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final range = _currentRange();
    final async = ref.watch(reportSummaryProvider(range));

    return Scaffold(
      appBar: AppBar(title: const Text('Laporan')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<int>(
                    key: const Key('reports_range_selector'),
                    segments: const [
                      ButtonSegment(value: 0, label: Text('Bulan ini')),
                      ButtonSegment(value: 1, label: Text('Bulan lalu')),
                    ],
                    selected: {_rangeIndex},
                    onSelectionChanged: (s) =>
                        setState(() => _rangeIndex = s.first),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(_rangeLabel(), style: theme.textTheme.bodySmall),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Gagal memuat laporan: $e'),
                ),
              ),
              data: (summary) => RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(reportSummaryProvider(range));
                },
                child: _buildContent(summary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ReportSummary summary) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Ringkasan', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Pesanan',
                value: '${summary.ordersCount}',
                icon: Icons.receipt_long_outlined,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                label: 'Total pesanan',
                value: _fmtIdr(summary.ordersTotal),
                icon: Icons.shopping_cart_outlined,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Pembayaran diterima',
                value: _fmtIdr(summary.paymentsReceived),
                icon: Icons.payments_outlined,
                color: theme.colorScheme.tertiary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                label: 'Sisa tagihan',
                value: _fmtIdr(summary.receivablesRemaining),
                icon: Icons.pending_actions_outlined,
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Arus kas', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Pemasukan',
                value: _fmtIdr(summary.income),
                icon: Icons.trending_up,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                label: 'Pengeluaran',
                value: _fmtIdr(summary.expense),
                icon: Icons.trending_down,
                color: theme.colorScheme.error,
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
                color: theme.colorScheme.tertiary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                label: 'Arus kas bersih',
                value: _fmtIdr(summary.cashFlowNet),
                icon: Icons.account_balance_wallet_outlined,
                color: theme.colorScheme.secondary,
                bold: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Ekspor', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              key: const Key('reports_export_orders_csv'),
              onPressed: () => _handleExport(summary, ExportKind.ordersCsv),
              icon: const Icon(Icons.table_view_outlined),
              label: const Text('Order CSV'),
            ),
            OutlinedButton.icon(
              key: const Key('reports_export_orders_xlsx'),
              onPressed: () => _handleExport(summary, ExportKind.ordersXlsx),
              icon: const Icon(Icons.grid_on_outlined),
              label: const Text('Order XLSX'),
            ),
            OutlinedButton.icon(
              key: const Key('reports_export_transactions_csv'),
              onPressed: () =>
                  _handleExport(summary, ExportKind.transactionsCsv),
              icon: const Icon(Icons.receipt_long_outlined),
              label: const Text('Transaksi CSV'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Saldo akun (saat ini)', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (summary.balanceByAccount.isEmpty)
          const Text('Belum ada akun aktif.')
        else
          Column(
            children: [
              for (final b in summary.balanceByAccount)
                Card(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    key: Key('reports_balance_${b.accountId}'),
                    leading: const Icon(Icons.account_balance_outlined),
                    title: Text(b.accountName),
                    trailing: Text(
                      _fmtIdr(b.balance),
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ),
            ],
          ),
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
