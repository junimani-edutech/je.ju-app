import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/app_user.dart';
import '../../core/providers.dart';
import '../../features/offline/sync_service.dart';

/// Widget pembungkus yang:
/// - start periodic sync saat user login.
/// - stop saat logout.
class SyncBootstrap extends ConsumerStatefulWidget {
  const SyncBootstrap({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<SyncBootstrap> createState() => _SyncBootstrapState();
}

class _SyncBootstrapState extends ConsumerState<SyncBootstrap> {
  bool _started = false;

  void _syncAuth(AppUser? user) {
    final service = ref.read(syncServiceProvider);
    if (user != null && !_started) {
      service.startPeriodic();
      _started = true;
    } else if (user == null && _started) {
      service.stopPeriodic();
      _started = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AppUser?>>(authStateProvider, (_, next) {
      next.whenData(_syncAuth);
    });
    // Sync dengan state saat init (kalau user sudah login saat build pertama).
    final initial = ref.watch(authStateProvider).value;
    if (initial != null && !_started) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncAuth(initial));
    }
    return widget.child;
  }
}
