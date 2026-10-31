import 'package:flutter/material.dart';

import '../../shared/widgets/coming_soon_screen.dart';

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonScreen(
      title: 'Pembayaran',
      icon: Icons.payments_outlined,
      description: 'Modul pembayaran akan tersedia di Fase 4–5.',
    );
  }
}
