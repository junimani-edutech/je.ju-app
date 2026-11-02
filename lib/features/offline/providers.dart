import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'db/app_database.dart';
import 'sync_queue_repository.dart';

/// Instance Drift global. Di-override di test dengan `AppDatabase.forTesting`.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

enum NetworkStatus { online, offline }

/// Stream status jaringan. `online` = punya koneksi internet yang terdeteksi.
/// Di-override di test untuk simulate offline.
final networkStatusProvider = StreamProvider<NetworkStatus>((ref) async* {
  final connectivity = Connectivity();

  NetworkStatus map(List<ConnectivityResult> results) {
    if (results.isEmpty) return NetworkStatus.offline;
    if (results.every((r) => r == ConnectivityResult.none)) {
      return NetworkStatus.offline;
    }
    return NetworkStatus.online;
  }

  final initial = await connectivity.checkConnectivity();
  yield map(initial);

  await for (final results in connectivity.onConnectivityChanged) {
    yield map(results);
  }
});

/// Jumlah item antrean pending untuk business aktif. Di-watch oleh badge.
final syncPendingCountProvider = StreamProvider<int>((ref) {
  final biz = ref.watch(currentBusinessProvider).value;
  if (biz == null) return const Stream.empty();
  final repo = ref.watch(syncQueueRepositoryProvider);
  return repo.watchPendingCount(biz.id);
});
