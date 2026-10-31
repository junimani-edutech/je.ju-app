import 'package:flutter/material.dart';

import '../../shared/widgets/coming_soon_screen.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonScreen(
      title: 'Pesanan',
      icon: Icons.receipt_long_outlined,
      description: 'Modul pesanan akan tersedia di Fase 4.',
    );
  }
}
