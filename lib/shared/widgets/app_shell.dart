import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Adaptive shell:
/// - narrow (< 720px): NavigationBar 4 tab.
/// - wide (>= 720px): NavigationRail 6 entri.
///
/// Branch index pada StatefulShellRoute:
///   0 = /app/dashboard
///   1 = /app/orders
///   2 = /app/customers
///   3 = /app/more (sub-route: payments, reports, settings)
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const double _wideBreakpoint = 720;

  void _onTapNarrow(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  void _onTapWide(BuildContext context, int index) {
    switch (index) {
      case 0:
      case 1:
      case 2:
        navigationShell.goBranch(index);
        break;
      case 3:
        context.go('/app/more/payments');
        break;
      case 4:
        context.go('/app/more/reports');
        break;
      case 5:
        context.go('/app/more/settings');
        break;
    }
  }

  int _wideIndexForLocation(String path) {
    if (path.startsWith('/app/more/payments')) return 3;
    if (path.startsWith('/app/more/reports')) return 4;
    if (path.startsWith('/app/more/settings')) return 5;
    if (path.startsWith('/app/orders')) return 1;
    if (path.startsWith('/app/customers')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _wideBreakpoint) {
          return _buildWide(context);
        }
        return _buildNarrow();
      },
    );
  }

  Widget _buildNarrow() {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTapNarrow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Pesanan',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Pelanggan',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz),
            selectedIcon: Icon(Icons.more_horiz),
            label: 'Lainnya',
          ),
        ],
      ),
    );
  }

  Widget _buildWide(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selected = _wideIndexForLocation(location);

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selected,
            onDestinationSelected: (i) => _onTapWide(context, i),
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: Text('Pesanan'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: Text('Pelanggan'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.payments_outlined),
                selectedIcon: Icon(Icons.payments),
                label: Text('Pembayaran'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart),
                label: Text('Laporan'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Pengaturan'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}
