import 'package:flutter/material.dart';

import '../../shared/widgets/coming_soon_screen.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonScreen(
      title: 'Laporan',
      icon: Icons.bar_chart_outlined,
      description: 'Laporan dan ekspor akan tersedia di Fase 6.',
    );
  }
}
