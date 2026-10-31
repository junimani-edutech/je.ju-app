import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/auth/supabase_auth_service.dart';
import 'core/business/supabase_business_service.dart';
import 'core/providers.dart';
import 'features/customers/customers_providers.dart';
import 'features/customers/supabase_customers_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? url;
  String? anon;
  try {
    await dotenv.load(fileName: '.env');
    url = dotenv.env['SUPABASE_URL'];
    anon = dotenv.env['SUPABASE_ANON_KEY'];
  } catch (_) {
    // .env tidak wajib untuk build; UI akan menampilkan pesan.
  }

  if (url == null || url.isEmpty || anon == null || anon.isEmpty) {
    runApp(const _MissingEnvApp());
    return;
  }

  // ignore: deprecated_member_use
  await Supabase.initialize(url: url, anonKey: anon);
  final client = Supabase.instance.client;

  runApp(
    ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(SupabaseAuthService(client)),
        businessServiceProvider.overrideWithValue(
          SupabaseBusinessService(client),
        ),
        customersServiceProvider.overrideWithValue(
          SupabaseCustomersService(client),
        ),
      ],
      child: const JeJuApp(),
    ),
  );
}

class _MissingEnvApp extends StatelessWidget {
  const _MissingEnvApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Konfigurasi belum lengkap.\n\n'
              'Buat file .env di root proyek dengan:\n'
              'SUPABASE_URL=...\n'
              'SUPABASE_ANON_KEY=...\n\n'
              'Lihat .env.example untuk petunjuk.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
