import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/auth/supabase_auth_service.dart';
import 'core/business/supabase_business_service.dart';
import 'core/providers.dart';
import 'features/customers/customers_providers.dart';
import 'features/orders/orders_providers.dart';
import 'features/finance/finance_providers.dart';
import 'features/finance/supabase_finance_services.dart';
import 'features/payments/payments_providers.dart';
import 'features/members/members_providers.dart';
import 'features/members/supabase_members_service.dart';
import 'features/reports/report_providers.dart';
import 'features/reports/supabase_report_service.dart';
import 'features/payments/supabase_payments_service.dart';
import 'features/orders/supabase_orders_service.dart';
import 'features/products/products_providers.dart';
import 'features/products/supabase_products_service.dart';
import 'features/offline/local_products_repo.dart';
import 'features/offline/offline_products_service.dart';
import 'features/customers/supabase_customers_service.dart';
import 'features/offline/customers_dispatcher.dart';
import 'features/offline/local_customers_repo.dart';
import 'features/offline/offline_customers_service.dart';
import 'features/offline/offline_orders_service.dart';
import 'features/offline/offline_transactions_service.dart';
import 'features/offline/offline_transfers_service.dart';
import 'features/offline/local_transactions_repo.dart';
import 'features/offline/local_transfers_repo.dart';
import 'features/offline/offline_payments_service.dart';
import 'features/offline/local_orders_repo.dart';
import 'features/offline/local_payments_repo.dart';
import 'features/offline/sync_queue_repository.dart';
import 'features/offline/sync_service.dart';
import 'shared/widgets/sync_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? url;
  String? anon;

  // 1. Coba baca dari --dart-define (untuk production Vercel)
  const envUrl = String.fromEnvironment('SUPABASE_URL');
  const envAnon = String.fromEnvironment('SUPABASE_ANON_KEY');

  if (envUrl.isNotEmpty && envAnon.isNotEmpty) {
    url = envUrl;
    anon = envAnon;
  } else {
    // 2. Fallback ke .env (untuk development lokal)
    try {
      await dotenv.load(fileName: '.env');
      url = dotenv.env['SUPABASE_URL'];
      anon = dotenv.env['SUPABASE_ANON_KEY'];
    } catch (_) {}
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
        customersServiceProvider.overrideWith((ref) {
          if (kIsWeb) return SupabaseCustomersService(client);
          return OfflineCustomersService(
            remote: SupabaseCustomersService(client),
            local: ref.watch(localCustomersRepoProvider),
            queue: ref.watch(syncQueueRepositoryProvider),
            ref: ref,
          );
        }),
        productsServiceProvider.overrideWith((ref) {
          if (kIsWeb) return SupabaseProductsService(client);
          return OfflineProductsService(
            remote: SupabaseProductsService(client),
            local: ref.watch(localProductsRepoProvider),
            queue: ref.watch(syncQueueRepositoryProvider),
            ref: ref,
          );
        }),
        ordersServiceProvider.overrideWith((ref) {
          if (kIsWeb) return SupabaseOrdersService(client);
          return OfflineOrdersService(
            remote: SupabaseOrdersService(client),
            local: ref.watch(localOrdersRepoProvider),
            queue: ref.watch(syncQueueRepositoryProvider),
            ref: ref,
          );
        }),
        paymentsServiceProvider.overrideWith((ref) {
          if (kIsWeb) return SupabasePaymentsService(client);
          return OfflinePaymentsService(
            remote: SupabasePaymentsService(client),
            local: ref.watch(localPaymentsRepoProvider),
            orders: ref.watch(localOrdersRepoProvider),
            queue: ref.watch(syncQueueRepositoryProvider),
            ref: ref,
          );
        }),
        transactionsServiceProvider.overrideWith((ref) {
          if (kIsWeb) return SupabaseTransactionsService(client);
          return OfflineTransactionsService(
            remote: SupabaseTransactionsService(client),
            local: ref.watch(localTransactionsRepoProvider),
            queue: ref.watch(syncQueueRepositoryProvider),
            ref: ref,
          );
        }),
        transfersServiceProvider.overrideWith((ref) {
          if (kIsWeb) return SupabaseTransfersService(client);
          return OfflineTransfersService(
            remote: SupabaseTransfersService(client),
            local: ref.watch(localTransfersRepoProvider),
            queue: ref.watch(syncQueueRepositoryProvider),
            ref: ref,
          );
        }),
        reportServiceProvider.overrideWithValue(SupabaseReportService(client)),
        membersServiceProvider.overrideWithValue(
          SupabaseMembersService(client),
        ),
        syncDispatcherProvider.overrideWithValue(
          (item) => compositeDispatcher(item, client),
        ),
      ],
      child: const SyncBootstrap(child: JeJuApp()),
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
