import 'package:flutter/material.dart';

import '../../shared/widgets/coming_soon_screen.dart';

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonScreen(
      title: 'Pelanggan',
      icon: Icons.people_outline,
      description: 'Daftar dan kelola pelanggan akan tersedia di Fase 4.',
    );
  }
}
