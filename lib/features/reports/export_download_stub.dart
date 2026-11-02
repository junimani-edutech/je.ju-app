import 'dart:typed_data';

/// Non-web fallback. No-op.
///
/// Pemanggil (UI) bertanggung jawab menampilkan pesan bahwa unduh file
/// native akan tersedia di fase berikutnya (butuh path_provider / share_plus).
Future<void> downloadFile({
  required String filename,
  required Uint8List bytes,
  required String mimeType,
}) async {
  // intentionally no-op
}
