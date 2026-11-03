import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../shared/widgets/app_states.dart';
import '../../shared/widgets/skeleton_loader.dart';
import 'category.dart';
import 'finance_providers.dart';
import 'transaction.dart';
import 'widgets/transaction_form_sheet.dart';
import 'widgets/transaction_list_tile.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  static const _tabs = <String?>[null, 'income', 'expense'];
  static const _tabLabels = <String>['Semua', 'Masuk', 'Keluar'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Transaction> _applyQuery(List<Transaction> list) {
    if (_query.isEmpty) return list;
    final q = _query.toLowerCase();
    return list.where((t) {
      if (t.description.toLowerCase().contains(q)) return true;
      if (t.reference != null && t.reference!.toLowerCase().contains(q)) {
        return true;
      }
      return false;
    }).toList();
  }

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
  Widget build(BuildContext context) {
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
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: TextField(
                key: const Key('tx_search'),
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Cari deskripsi atau referensi',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  isDense: true,
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          key: const Key('tx_search_clear'),
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                        ),
                ),
                onChanged: (v) => setState(() => _query = v.trim()),
              ),
            ),
            Expanded(
              child: transactionsAsync.when(
                loading: () => const SkeletonList(),
                error: (e, _) => ErrorState(
                  message: 'Gagal memuat transaksi. Periksa koneksi Anda.',
                  onRetry: () => ref.invalidate(transactionsProvider),
                ),
                data: (list) {
                  return TabBarView(
                    children: [
                      for (final filter in _tabs)
                        _buildList(
                          context,
                          ref,
                          list,
                          filter,
                          catMap,
                          canWrite,
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
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
    final searched = _applyQuery(filtered);

    if (searched.isEmpty) {
      if (_query.isNotEmpty) {
        return const EmptyState(
          icon: Icons.search_off,
          title: 'Tidak ada hasil',
          subtitle: 'Tidak ada transaksi yang cocok dengan pencarian Anda.',
        );
      }
      final label = filter == null
          ? 'Belum ada transaksi'
          : 'Tidak ada transaksi di tab ini';
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        title: label,
        subtitle:
            'Transaksi baru akan muncul di sini setelah Anda mencatatnya.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 88),
      itemCount: searched.length,
      separatorBuilder: (_, _) => const SizedBox(height: 4),
      itemBuilder: (_, i) {
        final tx = searched[i];
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
