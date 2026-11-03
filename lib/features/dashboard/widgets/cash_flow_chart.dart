import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class CashFlowChart extends StatelessWidget {
  const CashFlowChart({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Data dummy untuk 7 hari terakhir
    final barGroups = <BarChartGroupData>[
      _buildBar(0, 120, 50, theme),
      _buildBar(1, 200, 80, theme),
      _buildBar(2, 150, 120, theme),
      _buildBar(3, 300, 40, theme),
      _buildBar(4, 250, 100, theme),
      _buildBar(5, 400, 150, theme),
      _buildBar(6, 350, 60, theme),
    ];

    return Card(
      margin: const EdgeInsets.only(top: 16, bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Arus Kas (7 Hari Terakhir)',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _LegendItem(color: theme.colorScheme.primary, text: 'Masuk'),
                const SizedBox(width: 16),
                _LegendItem(color: theme.colorScheme.error, text: 'Keluar'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 500,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const days = [
                            'Sen',
                            'Sel',
                            'Rab',
                            'Kam',
                            'Jum',
                            'Sab',
                            'Min',
                          ];
                          if (value.toInt() >= 0 &&
                              value.toInt() < days.length) {
                            return Text(
                              days[value.toInt()],
                              style: theme.textTheme.bodySmall,
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: barGroups,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _buildBar(
    int x,
    double masuk,
    double keluar,
    ThemeData theme,
  ) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: masuk,
          color: theme.colorScheme.primary,
          width: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        BarChartRodData(
          toY: keluar,
          color: theme.colorScheme.error,
          width: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;
  const _LegendItem({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // PERBAIKAN: Hapus `color:` dan masukkan ke dalam BoxDecoration
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(text, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
