import 'package:drift/drift.dart';

/// Web fallback: offline tidak didukung di web.
/// Semua operasi harus online; pemanggil bertanggung jawab memakai service online.
LazyDatabase createExecutor() {
  throw UnsupportedError(
    'Offline SQLite tidak tersedia di web. '
    'Gunakan versi online (mobile/desktop) untuk offline mode.',
  );
}
