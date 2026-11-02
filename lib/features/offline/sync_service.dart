// ignore_for_file: prefer_initializing_formals
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'providers.dart';
import 'sync_queue_repository.dart';

/// Dispatcher: mengirim satu item antrean ke server.
/// Di 15B masih no-op; di 15C akan di-inject dispatcher asli
/// yang memanggil Supabase RPC.
typedef SyncDispatcher = Future<void> Function(SyncQueueItem item);

class SyncService {
  SyncService({
    required SyncQueueRepository queue,
    required Ref ref,
    required SyncDispatcher dispatcher,
    this.maxRetries = 3,
  }) : _queue = queue,
       _ref = ref,
       _dispatcher = dispatcher;

  final SyncQueueRepository _queue;
  final Ref _ref;
  final SyncDispatcher _dispatcher;
  final int maxRetries;

  bool _flushing = false;
  Timer? _periodicTimer;

  /// Mulai flush berkala (dipanggil di main setelah login).
  void startPeriodic({Duration interval = const Duration(seconds: 30)}) {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(interval, (_) => unawaited(flush()));
    // Flush pertama langsung.
    unawaited(flush());
  }

  void stopPeriodic() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  bool get isFlushing => _flushing;

  /// Flush semua item pending ke server. Aman dipanggil paralel —
  /// panggilan kedua diabaikan jika yang pertama masih berjalan.
  Future<void> flush() async {
    if (_flushing) return;
    final network = _ref.read(networkStatusProvider).value;
    if (network != NetworkStatus.online) return;

    final biz = _ref.read(currentBusinessProvider).value;
    if (biz == null) return;

    _flushing = true;
    try {
      final items = await _queue.listPending(biz.id);
      for (final item in items) {
        await _processOne(item);
      }
    } catch (e) {
      debugPrint('SyncService.flush error: $e');
    } finally {
      _flushing = false;
    }
  }

  Future<void> _processOne(SyncQueueItem item) async {
    await _queue.markInFlight(item.id);
    try {
      await _dispatcher(item);
      await _queue.markDone(item.id);
    } catch (e) {
      final nextRetry = item.retryCount + 1;
      final failed = nextRetry >= maxRetries;
      await _queue.markFailed(item.id, e.toString(), retryCount: nextRetry);
      if (failed) {
        debugPrint(
          'SyncService: item ${item.id} gagal permanen setelah '
          '$nextRetry percobaan: $e',
        );
      }
    }
  }

  void dispose() {
    stopPeriodic();
  }
}

/// Dispatcher default untuk 15B — no-op. Di 15C diganti dengan
/// implementasi yang memanggil Supabase RPC.
Future<void> _noopDispatcher(SyncQueueItem item) async {
  // intentionally no-op
}

/// Override `syncDispatcherProvider` di main (15C) untuk dispatcher asli.
final syncDispatcherProvider = Provider<SyncDispatcher>(
  (ref) => _noopDispatcher,
);

final syncServiceProvider = Provider<SyncService>((ref) {
  final service = SyncService(
    queue: ref.watch(syncQueueRepositoryProvider),
    ref: ref,
    dispatcher: ref.watch(syncDispatcherProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});
