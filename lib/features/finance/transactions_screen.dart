import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'finance_providers.dart';

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
  String _searchQuery = '';
  String? _localTypeFilter;

  @override
  void initState() {
    super.initState();
    _localTypeFilter = widget.typeFilter;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String get _appBarTitle {
    if (_localTypeFilter == 'income') return 'Rincian Pemasukan';
    if (_localTypeFilter == 'expense') return 'Rincian Pengeluaran';
    if (widget.accountIdFilter != null) return 'Rincian Saldo Akun';
    return 'Semua Transaksi';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transactionsAsync = ref.watch(transactionsProvider);

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
          // 1. SEARCH BAR & FILTER CHIPS
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Cari keterangan transaksi...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Semua', null),
                      const SizedBox(width: 8),
                      _buildFilterChip('Masuk', 'income'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Keluar', 'expense'),
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
              ],
            ),
          ),

          // 2. LIST DATA TRANSAKSI
          Expanded(
            child: transactionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Gagal memuat data: $e')),
              data: (allTransactions) {
                var filteredList = allTransactions;

                // Filter Tipe
                if (_localTypeFilter != null) {
                  filteredList = filteredList.where((tx) => tx.type == _localTypeFilter).toList();
                }
                
                // Filter Akun
                if (widget.accountIdFilter != null) {
                  filteredList = filteredList.where((tx) => tx.accountId == widget.accountIdFilter).toList();
                }

                // Filter Bulan Ini
                if (widget.periodFilter == 'this_month') {
                  final now = DateTime.now();
                  filteredList = filteredList.where((tx) {
                    return tx.transactionDate.month == now.month && 
                           tx.transactionDate.year == now.year;
                  }).toList();
                }

                // Filter Pencarian
                if (_searchQuery.isNotEmpty) {
                  filteredList = filteredList.where((tx) {
                    return tx.description.toLowerCase().contains(_searchQuery);
                  }).toList();
                }

                // 3. EMPTY STATE PREMIUM
                if (filteredList.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.05),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.receipt_long, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Belum ada transaksi',
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Transaksi yang Anda catat akan muncul di sini.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // 4. TAMPILAN LIST
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final tx = filteredList[index];
                    final isIncome = tx.type == 'income';
                    
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 8),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? typeValue) {
    final isSelected = _localTypeFilter == typeValue;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _localTypeFilter = selected ? typeValue : null;
        });
      },
      selectedColor: Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
