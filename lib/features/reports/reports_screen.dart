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
  int _rangeIndex = 0;
  DateTime? _customFrom;
  DateTime? _customTo;

  ({DateTime from, DateTime to}) _currentRange() {
    if (_rangeIndex == 2 && _customFrom != null && _customTo != null) {
      return (from: _customFrom!, to: _customTo!);
    }
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

  Future<void> _pickCustomRange() async {
    final r = _currentRange();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(start: r.from, end: r.to),
    );
    if (picked != null) {
      setState(() {
        _customFrom = picked.start;
        _customTo = picked.end;
        _rangeIndex = 2;
      });
    }
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
            content: Text('File berhasil dibuat.'),
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
      appBar: AppBar(
        title: const Text('Laporan & Analitik', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<int>(
                    key: const Key('reports_range_selector'),
                    // ✅ PERBAIKAN: Menambahkan Segment ke-3 untuk Kustom
                    segments: const [
                      ButtonSegment(value: 0, label: Text('Bulan ini')),
                      ButtonSegment(value: 1, label: Text('Bulan lalu')),
                      ButtonSegment(value: 2, label: Text('Kustom')),
                    ],
                    selected: {_rangeIndex},
                    onSelectionChanged: (s) {
                      final v = s.first;
                      if (v == 2) {
                        _pickCustomRange();
                      } else {
                        setState(() => _rangeIndex = v);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(_rangeLabel(), style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
          ),
          const SizedBox(height: 8),
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
        Text('Ringkasan', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
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
            const SizedBox(width: 12),
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
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Pembayaran diterima',
                value: _fmtIdr(summary.paymentsReceived),
                icon: Icons.payments_outlined,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
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
        const SizedBox(height: 24),
        Text('Arus Kas', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
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
            const SizedBox(width: 12),
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
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Pembayaran pesanan',
                value: _fmtIdr(summary.paymentsNet),
                icon: Icons.payments_outlined,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Laba / Arus kas bersih',
                value: _fmtIdr(summary.cashFlowNet),
                icon: Icons.account_balance_wallet_outlined,
                color: Colors.green,
                bold: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Ekspor Data', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              key: const Key('reports_export_orders_csv'),
              onPressed: () => _handleExport(summary, ExportKind.ordersCsv),
              icon: const Icon(Icons.table_view_outlined, size: 18),
              label: const Text('Order CSV'),
            ),
            OutlinedButton.icon(
              key: const Key('reports_export_orders_xlsx'),
              onPressed: () => _handleExport(summary, ExportKind.ordersXlsx),
              icon: const Icon(Icons.grid_on_outlined, size: 18),
              label: const Text('Order XLSX'),
            ),
            OutlinedButton.icon(
              key: const Key('reports_export_transactions_csv'),
              onPressed: () =>
                  _handleExport(summary, ExportKind.transactionsCsv),
              icon: const Icon(Icons.receipt_long_outlined, size: 18),
              label: const Text('Transaksi CSV'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Saldo Akun (Saat Ini)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (summary.balanceByAccount.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Belum ada akun aktif.', textAlign: TextAlign.center),
          )
        else
          Column(
            children: [
              for (final b in summary.balanceByAccount)
                Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                  child: ListTile(
                    key: Key('reports_balance_${b.accountId}'),
                    leading: const Icon(Icons.account_balance_outlined),
                    title: Text(b.accountName),
                    trailing: Text(
                      _fmtIdr(b.balance),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        const SizedBox(height: 32),
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

// ✅ PERBAIKAN: Desain StatCard disamakan dengan Dashboard (Premium)
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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 12),
            Text(label, style: theme.textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              value,
              style: (bold ? theme.textTheme.titleMedium : theme.textTheme.titleSmall)
                  ?.copyWith(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
