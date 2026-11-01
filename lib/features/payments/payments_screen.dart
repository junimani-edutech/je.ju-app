import 'package:flutter/material.dart';

import '../../shared/widgets/coming_soon_screen.dart';

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonScreen(
      title: 'Pembayaran',
      icon: Icons.payments_outlined,
      description:
          'Pembayaran dicatat per pesanan. Buka detail pesanan '
          'untuk melihat atau menambah pembayaran. Daftar semua '
          'pembayaran akan tersedia di Fase 6 (laporan).',
    );
  }
}
