import 'package:fl_chart/fl_chart.dart'; import 'package:flutter/material.dart';

class CashFlowChart extends StatelessWidget {
  const CashFlowChart({super.key});
  @override Widget build(BuildContext context) {
    return AspectRatio(aspectRatio: 1.7, child: Padding(padding: const EdgeInsets.only(top: 16, right: 16, left: 8), child: BarChart(BarChartData(
      titlesData: FlTitlesData(bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) { const d = ['Sen','Sel','Rab','Kam','Jum','Sab','Min']; return Text(v.toInt() >= 0 && v.toInt() < d.length ? d[v.toInt()] : ''); })), leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false))),
      gridData: const FlGridData(show: false), borderData: FlBorderData(show: false),
      barGroups: [ _make(0, 50000, 20000), _make(1, 80000, 30000), _make(2, 45000, 60000), _make(3, 90000, 10000), _make(4, 120000, 40000), _make(5, 150000, 50000), _make(6, 100000, 25000) ],
    ))));
  }
  BarChartGroupData _make(int x, double i, double e) => BarChartGroupData(x: x, barRods: [ BarChartRodData(toY: i, color: Colors.greenAccent.shade400, width: 8, borderRadius: BorderRadius.circular(4)), BarChartRodData(toY: -e, color: Colors.redAccent.shade100, width: 8, borderRadius: BorderRadius.circular(4)) ]);
}
