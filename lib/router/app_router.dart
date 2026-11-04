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
import '../features/members/accept_invite_screen.dart';
import '../features/members/members_screen.dart';
import '../features/offline/sync_status_screen.dart';
import '../features/products/products_screen.dart';
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
      GoRoute(
        path: '/accept-invite',
        builder: (_, _) => const AcceptInviteScreen(),
      ),

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
                  // ✅ PERBAIKAN: Menangkap query parameter untuk transaksi
                  GoRoute(
                    path: 'transactions',
                    builder: (context, state) {
                      return TransactionsScreen(
                        typeFilter: state.uri.queryParameters['type'],
                        periodFilter: state.uri.queryParameters['period'],
                        accountIdFilter: state.uri.queryParameters['account_id'],
                      );
                    },
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
                    path: 'members',
                    builder: (_, _) => const MembersScreen(),
                  ),
                  GoRoute(
                    path: 'products',
                    builder: (_, _) => const ProductsScreen(),
                  ),
                  GoRoute(
                    path: 'sync',
                    builder: (_, _) => const SyncStatusScreen(),
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
      final isLoggedIn = ref.read(authStateProvider).value != null;
      final isAuthRoute = state.matchedLocation == '/sign-in' ||
          state.matchedLocation == '/sign-up';
      final isInviteRoute = state.matchedLocation == '/accept-invite';

      if (!isLoggedIn && !isAuthRoute && !isInviteRoute) {
        final dest = Uri.encodeComponent(state.uri.toString());
        return '/sign-in?redirect=$dest';
      }
      if (isLoggedIn && isAuthRoute) {
        final target = state.uri.queryParameters['redirect'];
        if (target != null && target.startsWith('/')) {
          return Uri.decodeComponent(target);
        }
        return '/app/dashboard';
      }
      return null;
    },
  );
});