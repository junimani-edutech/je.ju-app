import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'providers.dart';
import 'sync_queue_repository.dart';
import 'sync_service.dart';

class SyncStatusScreen extends ConsumerStatefulWidget {
  const SyncStatusScreen({super.key});

  @override
  ConsumerState<SyncStatusScreen> createState() => _SyncStatusScreenState();
}

class _SyncStatusScreenState extends ConsumerState<SyncStatusScreen> {
  bool _flushing = false;

  Future<void> _flushNow() async {
    setState(() => _flushing = true);
    try {
      await ref.read(syncServiceProvider).flush();
    } finally {
      if (mounted) setState(() => _flushing = false);
    }
  }

  Future<void> _retryFailed() async {
    final biz = ref.read(currentBusinessProvider).value;
    if (biz == null) return;
    await ref.read(syncQueueRepositoryProvider).retryFailed(biz.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item gagal dijadwalkan ulang.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final biz = ref.watch(currentBusinessProvider).value;
    final network = ref.watch(networkStatusProvider).value;

    if (biz == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Status Sinkronisasi')),
        body: const Center(child: Text('Belum ada bisnis aktif.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Status Sinkronisasi')),
      body: RefreshIndicator(
        onRefresh: _flushNow,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: Icon(
                  network == NetworkStatus.online
                      ? Icons.cloud_done_outlined
                      : Icons.cloud_off_outlined,
                ),
                title: Text(
                  network == NetworkStatus.online ? 'Online' : 'Offline',
                ),
                subtitle: const Text(
                  'Item yang dibuat offline akan disinkronkan saat online.',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    key: const Key('sync_flush_now'),
                    onPressed: _flushing ? null : _flushNow,
                    icon: _flushing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    label: const Text('Sinkronkan Sekarang'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  key: const Key('sync_retry_failed'),
                  onPressed: _retryFailed,
                  icon: const Icon(Icons.replay),
                  label: const Text('Retry Failed'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Antrean', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            _buildList(biz.id),
          ],
        ),
      ),
    );
  }

  Widget _buildList(String businessId) {
    return FutureBuilder<List<SyncQueueItem>>(
      future: ref.read(syncQueueRepositoryProvider).listAll(businessId),
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return Text('Gagal memuat antrean: ${snap.error}');
        }
        final list = snap.data ?? const <SyncQueueItem>[];
        if (list.isEmpty) {
          return const Text('Antrean kosong.');
        }
        return Column(
          children: [
            for (final item in list)
              Card(
                key: Key('sync_item_${item.id}'),
                margin: const EdgeInsets.only(bottom: 4),
                child: ListTile(
                  leading: Icon(_iconFor(item.status)),
                  title: Text('${item.entityType} • ${item.operation.name}'),
                  subtitle: Text(
                    item.status.name +
                        (item.lastError != null ? ' • ${item.lastError}' : ''),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: item.retryCount > 0
                      ? Text('retry: ${item.retryCount}')
                      : null,
                ),
              ),
          ],
        );
      },
    );
  }

  IconData _iconFor(SyncStatus s) {
    switch (s) {
      case SyncStatus.pending:
        return Icons.schedule;
      case SyncStatus.inFlight:
        return Icons.sync;
      case SyncStatus.done:
        return Icons.check_circle;
      case SyncStatus.failed:
        return Icons.error;
    }
  }
}
