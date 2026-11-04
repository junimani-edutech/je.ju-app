import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dashboard_providers.dart';

class CashFlowChart extends ConsumerWidget {
  const CashFlowChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(last7DaysCashFlowProvider);
    
    if (data.isEmpty) {
      return const SizedBox(height: 200, child: Center(child: Text('Belum ada data transaksi')));
    }

    // Cari nilai maksimum untuk skala grafik
    double maxVal = 0;
    for (var d in data) {
      if (d.income > maxVal) maxVal = d.income.toDouble();
      if (d.expense > maxVal) maxVal = d.expense.toDouble();
    }
    if (maxVal == 0) maxVal = 100000; // Default jika kosong

    return AspectRatio(
      aspectRatio: 1.7,
      child: Padding(
        padding: const EdgeInsets.only(top: 16, right: 16, left: 8),
        child: BarChart(
          BarChartData(
            maxY: maxVal * 1.2,
            minY: -maxVal * 1.2,
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, m) {
                    final index = v.toInt();
                    if (index >= 0 && index < data.length) {
                      final day = data[index].date;
                      const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
                      return Text(days[day.weekday - 1], style: const TextStyle(fontSize: 10));
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(data.length, (index) {
              final d = data[index];
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: d.income.toDouble(),
                    color: Colors.greenAccent.shade400,
                    width: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  BarChartRodData(
                    toY: -d.expense.toDouble(),
                    color: Colors.redAccent.shade100,
                    width: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
