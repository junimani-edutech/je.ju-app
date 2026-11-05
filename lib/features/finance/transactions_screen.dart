import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'paginated_transactions_providers.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  final String? typeFilter;
  final String? periodFilter;
  final String? accountIdFilter;

  const TransactionsScreen({
    super.key,
    this.typeFilter,
    this.periodFilter,
    this.accountIdFilter,
  });

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  String? _localType;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_initialized && mounted) {
        _initialized = true;
        final notifier = ref.read(paginatedTransactionsProvider.notifier);
        _localType = widget.typeFilter;
        if (widget.typeFilter != null) notifier.setTypeFilter(widget.typeFilter);
        if (widget.periodFilter != null) notifier.setPeriodFilter(widget.periodFilter);
        if (widget.accountIdFilter != null) notifier.setAccountFilter(widget.accountIdFilter);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) ref.read(paginatedTransactionsProvider.notifier).setSearch(value);
    });
  }

  void _onTypeSelected(String? type) {
    setState(() => _localType = type);
    ref.read(paginatedTransactionsProvider.notifier).setTypeFilter(type);
  }

  String get _appBarTitle {
    if (_localType == 'income') return 'Pemasukan';
    if (_localType == 'expense') return 'Pengeluaran';
    if (widget.accountIdFilter != null) return 'Rincian Akun';
    return 'Semua Transaksi';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final async = ref.watch(paginatedTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/app/more'),
        ),
      ),
      body: Column(
        children: [
          // Filter chips tipe
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                _buildTypeChip('Semua', null),
                const SizedBox(width: 8),
                _buildTypeChip('Masuk', 'income'),
                const SizedBox(width: 8),
                _buildTypeChip('Keluar', 'expense'),
                if (widget.periodFilter != null) ...[
                  const SizedBox(width: 8),
                  Chip(
                    label: const Text('Bulan Ini'),
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    side: BorderSide.none,
                    labelStyle: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                    onDeleted: () => context.go('/app/more/transactions'),
                  ),
                ],
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Cari keterangan transaksi...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                suffixIcon: _searchCtrl.text.isEmpty ? null : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchCtrl.clear();
                    ref.read(paginatedTransactionsProvider.notifier).setSearch(null);
                  },
                ),
              ),
            ),
          ),

          // List Transaksi
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Gagal memuat: $e')),
              data: (result) {
                if (result.items.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(_searchCtrl.text.isNotEmpty ? 'Tidak ada hasil' : 'Belum ada transaksi',
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('Transaksi yang Anda catat akan muncul di sini.',
                              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          Text('Menampilkan ${result.items.length} dari ${result.total} transaksi',
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                        itemCount: result.items.length + (result.hasMore ? 1 : 0),
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          if (i == result.items.length) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: OutlinedButton.icon(
                                  onPressed: () => ref.read(paginatedTransactionsProvider.notifier).loadMore(),
                                  icon: const Icon(Icons.expand_more),
                                  label: const Text('Muat Lebih Banyak'),
                                ),
                              ),
                            );
                          }
                          final tx = result.items[i];
                          final isIncome = tx.type == 'income';
                          return Card(
                            elevation: 0,
                            margin: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isIncome ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                                child: Icon(
                                  isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                                  color: isIncome ? Colors.green : Colors.red,
                                ),
                              ),
                              title: Text(tx.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Text(
                                '${tx.transactionDate.day}/${tx.transactionDate.month}/${tx.transactionDate.year}',
                              ),
                              trailing: Text(
                                '${isIncome ? '+' : '-'} Rp ${tx.amount}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isIncome ? Colors.green : Colors.red,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String label, String? typeValue) {
    final isSelected = _localType == typeValue;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _onTypeSelected(typeValue),
      selectedColor: Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
