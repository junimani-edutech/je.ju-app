import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers.dart';
import '../features/auth/sign_in_screen.dart';
import '../features/auth/sign_up_screen.dart';
import '../features/home/home_screen.dart';
import '../features/onboarding/onboarding_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);
  ref.listen(authStateProvider, (_, _) => refresh.value++);
  ref.listen(hasBusinessProvider, (_, _) => refresh.value++);

  return GoRouter(
    initialLocation: '/sign-in',
    refreshListenable: refresh,
    routes: [
      GoRoute(path: '/sign-in', builder: (_, _) => const SignInScreen()),
      GoRoute(path: '/sign-up', builder: (_, _) => const SignUpScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
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
        return hasBusiness ? '/home' : '/onboarding';
      }
      if (!hasBusiness && path != '/onboarding') return '/onboarding';
      if (hasBusiness && path == '/onboarding') return '/home';
      return null;
    },
  );
});
