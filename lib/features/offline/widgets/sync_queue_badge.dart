import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers.dart';

/// Badge kecil di AppBar. Tampil kalau ada item antrean pending.
/// Klik -> /app/more/sync.
class SyncQueueBadge extends ConsumerWidget {
  const SyncQueueBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(syncPendingCountProvider);
    final pending = pendingAsync.value ?? 0;
    if (pending <= 0) return const SizedBox.shrink();
    return IconButton(
      key: const Key('sync_queue_badge'),
      tooltip: '$pending antrean menunggu sinkronisasi',
      onPressed: () => context.go('/app/more/sync'),
      icon: Badge(
        label: Text('$pending'),
        child: const Icon(Icons.cloud_upload_outlined),
      ),
    );
  }
}
