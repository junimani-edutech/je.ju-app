import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'finance_providers.dart';

class TransactionsScreen extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    String appBarTitle = 'Semua Transaksi';
    if (typeFilter == 'income') appBarTitle = 'Rincian Pemasukan';
    if (typeFilter == 'expense') appBarTitle = 'Rincian Pengeluaran';
    if (accountIdFilter != null) appBarTitle = 'Rincian Saldo Akun';

    final hasActiveFilter = typeFilter != null || periodFilter != null || accountIdFilter != null;
    final transactionsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/app/more'),
        ),
      ),
      body: Column(
        children: [
          if (hasActiveFilter)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (typeFilter != null)
                    InputChip(
                      label: Text(typeFilter == 'income' ? 'Pemasukan' : 'Pengeluaran'),
                      onDeleted: () => context.go('/app/more/transactions'),
                    ),
                  if (periodFilter != null)
                    InputChip(
                      label: const Text('Bulan Ini'),
                      onDeleted: () => context.go('/app/more/transactions'),
                    ),
                  if (accountIdFilter != null)
                    InputChip(
                      label: const Text('Akun Spesifik'),
                      onDeleted: () => context.go('/app/more/transactions'),
                    ),
                ],
              ),
            ),
          Expanded(
            child: transactionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Gagal memuat data: $e')),
              data: (allTransactions) {
                var filteredList = allTransactions;

                if (typeFilter != null) {
                  filteredList = filteredList.where((tx) => tx.type == typeFilter).toList();
                }
                
                if (accountIdFilter != null) {
                  filteredList = filteredList.where((tx) => tx.accountId == accountIdFilter).toList();
                }

                if (periodFilter == 'this_month') {
                  final now = DateTime.now();
                  filteredList = filteredList.where((tx) {
                    return tx.transactionDate.month == now.month && 
                           tx.transactionDate.year == now.year;
                  }).toList();
                }

                if (filteredList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada data untuk filter ini.',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final tx = filteredList[index];
                    final isIncome = tx.type == 'income';
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isIncome ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                          child: Icon(
                            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                            color: isIncome ? Colors.green : Colors.red,
                          ),
                        ),
                        title: Text(tx.description),
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
}
