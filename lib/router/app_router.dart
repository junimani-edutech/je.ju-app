import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers.dart';
import '../features/auth/sign_in_screen.dart';
import '../features/auth/sign_up_screen.dart';
import '../features/customers/customers_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/finance/transactions_screen.dart';
import '../features/finance/transfers_screen.dart';
import '../features/more/more_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/orders/orders_screen.dart';
import '../features/payments/payments_screen.dart';
import '../features/reports/reports_screen.dart';
import '../features/settings/settings_screen.dart';
import '../shared/widgets/app_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);
  ref.listen(authStateProvider, (_, _) => refresh.value++);
  ref.listen(hasBusinessProvider, (_, _) => refresh.value++);

  return GoRouter(
    initialLocation: '/sign-in',
    refreshListenable: refresh,
    routes: [
      // Auth + onboarding (di luar shell)
      GoRoute(path: '/sign-in', builder: (_, _) => const SignInScreen()),
      GoRoute(path: '/sign-up', builder: (_, _) => const SignUpScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),

      // Shell: branch 0..3
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          // 0 = dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/app/dashboard',
                builder: (_, _) => const DashboardScreen(),
              ),
            ],
          ),
          // 1 = orders
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/app/orders',
                builder: (_, _) => const OrdersScreen(),
              ),
            ],
          ),
          // 2 = customers
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/app/customers',
                builder: (_, _) => const CustomersScreen(),
              ),
            ],
          ),
          // 3 = more (payments, reports, settings)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/app/more',
                builder: (_, _) => const MoreScreen(),
                routes: [
                  GoRoute(
                    path: 'payments',
                    builder: (_, _) => const PaymentsScreen(),
                  ),
                  GoRoute(
                    path: 'transactions',
                    builder: (_, _) => const TransactionsScreen(),
                  ),
                  GoRoute(
                    path: 'transfers',
                    builder: (_, _) => const TransfersScreen(),
                  ),
                  GoRoute(
                    path: 'reports',
                    builder: (_, _) => const ReportsScreen(),
                  ),
                  GoRoute(
                    path: 'settings',
                    builder: (_, _) => const SettingsScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final isAuthed = ref.read(authStateProvider).value != null;
      final hasBusiness = ref.read(hasBusinessProvider).value ?? false;
      final path = state.matchedLocation;
      final isAuthRoute = path == '/sign-in' || path == '/sign-up';

      if (!isAuthed) {
        return isAuthRoute ? null : '/sign-in';
      }
      if (isAuthRoute) {
        return hasBusiness ? '/app/dashboard' : '/onboarding';
      }
      if (!hasBusiness && path != '/onboarding') return '/onboarding';
      if (hasBusiness && path == '/onboarding') return '/app/dashboard';
      if (hasBusiness && path == '/home') return '/app/dashboard';
      return null;
    },
  );
});
