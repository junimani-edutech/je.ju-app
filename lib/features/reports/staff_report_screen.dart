import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/utils/format.dart';
import 'staff_report_providers.dart';

class StaffReportScreen extends ConsumerStatefulWidget {
  const StaffReportScreen({super.key});

  @override
  ConsumerState<StaffReportScreen> createState() => _StaffReportScreenState();
}

class _StaffReportScreenState extends ConsumerState<StaffReportScreen> {
  int _rangeIndex = 0;

  ({DateTime from, DateTime to}) _currentRange() {
    final now = DateTime.now();
    if (_rangeIndex == 0) {
      return (from: DateTime(now.year, now.month, 1), to: DateTime(now.year, now.month, now.day));
    }
    final start = DateTime(now.year, now.month - 1, 1);
    final end = DateTime(now.year, now.month, 0);
    return (from: start, to: end);
  }

  String _rangeLabel() {
    final r = _currentRange();
    return '${formatDateId(r.from)} - ${formatDateId(r.to)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final range = _currentRange();
    final async = ref.watch(staffReportProvider(range));

    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Per Kasir', style: TextStyle(fontWeight: FontWeight.bold))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Bulan ini')),
                ButtonSegment(value: 1, label: Text('Bulan lalu')),
              ],
              selected: {_rangeIndex},
              onSelectionChanged: (s) => setState(() => _rangeIndex = s.first),
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
              error: (e, _) => Center(child: Text('Gagal memuat: $e')),
              data: (list) {
                if (list.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bar_chart, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text('Belum ada data', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text('Buat pesanan terlebih dahulu untuk melihat performa kasir.', style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  );
                }

                final chartData = list.take(5).toList();
                final maxTotal = chartData.map((e) => e.ordersTotal).reduce((a, b) => a > b ? a : b).toDouble();
                final grandTotal = list.fold<int>(0, (sum, s) => sum + s.ordersTotal);

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Total Keseluruhan
                    Card(
                      elevation: 0,
                      color: theme.colorScheme.primaryContainer,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Total Omzet Tim', style: TextStyle(fontSize: 12, color: theme.colorScheme.onPrimaryContainer)),
                                const SizedBox(height: 4),
                                Text(formatIdr(grandTotal), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimaryContainer)),
                              ],
                            ),
                            Icon(Icons.groups, size: 40, color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.5)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Top 5 Kasir', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          maxY: maxTotal * 1.2,
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (v, m) {
                                  final i = v.toInt();
                                  if (i < 0 || i >= chartData.length) return const Text('');
                                  final name = chartData[i].actorName;
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(name.length > 8 ? '${name.substring(0, 8)}...' : name, style: const TextStyle(fontSize: 10)),
                                  );
                                },
                              ),
                            ),
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          barGroups: List.generate(chartData.length, (i) {
                            return BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: chartData[i].ordersTotal.toDouble(),
                                  color: theme.colorScheme.primary,
                                  width: 20,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text('Rincian Performa', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...list.map((s) => Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                          child: Text(s.actorName.isNotEmpty ? s.actorName[0].toUpperCase() : '?', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(s.actorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${s.ordersCount} pesanan ditangani'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(formatIdr(s.ordersTotal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text('Dibayar: ${formatIdr(s.ordersPaid)}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      ),
                    )),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
