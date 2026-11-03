import 'package:flutter/material.dart';

/// Format error agar ramah pengguna.
/// - 'memerlukan koneksi internet' → pesan offline yang jelas.
/// - Strip prefix 'Bad state:', 'Exception:', 'StateError:'.
String formatError(Object error) {
  String message = error.toString();

  if (message.contains('memerlukan koneksi internet')) {
    return 'Tindakan ini memerlukan koneksi internet. '
        'Sambungkan perangkat Anda dan coba lagi.';
  }

  for (final prefix in ['Bad state: ', 'Exception: ', 'StateError: ']) {
    if (message.startsWith(prefix)) {
      message = message.substring(prefix.length);
      break;
    }
  }

  return message.isEmpty ? 'Terjadi kesalahan tak terduga.' : message;
}

void showErrorSnack(BuildContext context, Object error) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(formatError(error))));
}
