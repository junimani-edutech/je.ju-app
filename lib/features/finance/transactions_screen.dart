import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'category.dart';
import 'finance_providers.dart';
import 'transaction.dart';
import 'widgets/transaction_form_sheet.dart';
import 'widgets/transaction_list_tile.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  static const _tabs = <String?>[null, 'income', 'expense'];
  static const _tabLabels = <String>['Semua', 'Masuk', 'Keluar'];

  Future<void> _void(
    BuildContext context,
    WidgetRef ref,
    Transaction tx,
  ) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Void transaksi?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${tx.description} akan di-reversal. '
              'Transaksi asli tetap tersimpan untuk audit.',
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('tx_void_reason'),
              controller: reasonCtrl,
              decoration: const InputDecoration(labelText: 'Alasan *'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            key: const Key('tx_void_confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Void'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final reason = reasonCtrl.text.trim();
      if (reason.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Alasan wajib.')));
        }
      } else {
        try {
          await ref
              .read(transactionsProvider.notifier)
              .voidTransaction(transactionId: tx.id, reason: reason);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('Gagal: $e')));
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canWrite = ref.watch(currentMemberProvider).value?.canWrite ?? false;
    final transactionsAsync = ref.watch(transactionsProvider);
    final categories =
        ref.watch(financeCategoriesProvider).value ?? const <Category>[];
    final catMap = <String, String>{for (final c in categories) c.id: c.name};

    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Transaksi'),
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              for (var i = 0; i < _tabs.length; i++)
                Tab(
                  key: Key('tx_tab_${_tabs[i] ?? 'all'}'),
                  text: _tabLabels[i],
                ),
            ],
          ),
        ),
        body: transactionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Gagal memuat: $e'),
            ),
          ),
          data: (list) {
            return TabBarView(
              children: [
                for (final filter in _tabs)
                  _buildList(context, ref, list, filter, catMap, canWrite),
              ],
            );
          },
        ),
        floatingActionButton: canWrite
            ? FloatingActionButton.extended(
                key: const Key('tx_fab'),
                onPressed: () => TransactionFormSheet.show(context),
                icon: const Icon(Icons.add),
                label: const Text('Catat'),
              )
            : null,
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    List<Transaction> all,
    String? filter,
    Map<String, String> catMap,
    bool canWrite,
  ) {
    final filtered = filter == null
        ? all
        : all.where((t) => t.type == filter).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 56,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 12),
              Text(
                filter == null
                    ? 'Belum ada transaksi'
                    : 'Tidak ada transaksi di tab ini',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 88),
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const SizedBox(height: 4),
      itemBuilder: (_, i) {
        final tx = filtered[i];
        return TransactionListTile(
          tx: tx,
          categoryName: tx.categoryId != null ? catMap[tx.categoryId] : null,
          canWrite: canWrite,
          onVoid: () => _void(context, ref, tx),
        );
      },
    );
  }
}
