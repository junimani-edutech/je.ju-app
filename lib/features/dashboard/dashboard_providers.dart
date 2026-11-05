import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../finance/finance_providers.dart';
import '../orders/orders_providers.dart';
import '../inventory/inventory_providers.dart';

class DailyCashFlow {
  final DateTime date;
  final int income;
  final int expense;
  DailyCashFlow({required this.date, required this.income, required this.expense});
  int get net => income - expense;
}

final last7DaysCashFlowProvider = Provider<List<DailyCashFlow>>((ref) {
  final txAsync = ref.watch(transactionsProvider);
  if (!txAsync.hasValue) return [];
  final txs = txAsync.value!;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final List<DailyCashFlow> result = [];
  for (int i = 6; i >= 0; i--) {
    final day = today.subtract(Duration(days: i));
    final dayTxs = txs.where((tx) => tx.transactionDate.year == day.year && tx.transactionDate.month == day.month && tx.transactionDate.day == day.day);
    int income = 0;
    int expense = 0;
    for (var tx in dayTxs) {
      if (tx.type == 'income') income += tx.amount;
      if (tx.type == 'expense') expense += tx.amount;
    }
    result.add(DailyCashFlow(date: day, income: income, expense: expense));
  }
  return result;
});

// ✅ OMSET HARI INI
final todayRevenueProvider = Provider<int>((ref) {
  final txAsync = ref.watch(transactionsProvider);
  if (!txAsync.hasValue) return 0;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  int total = 0;
  for (var tx in txAsync.value!) {
    if (tx.transactionDate.year == today.year && tx.transactionDate.month == today.month && tx.transactionDate.day == today.day && tx.type == 'income') {
      total += tx.amount;
    }
  }
  return total;
});

// ✅ ALERT STOK MENIPIS
final lowStockItemsProvider = Provider<List<String>>((ref) {
  final inventoryAsync = ref.watch(inventoryItemsProvider);
  if (!inventoryAsync.hasValue) return [];
  return inventoryAsync.value!
      .where((item) => item.isLowStock)
      .map((item) => item.name)
      .toList();
});

final orderStatsProvider = Provider<Map<String, int>>((ref) {
  final ordersAsync = ref.watch(ordersProvider);
  final statusesAsync = ref.watch(orderStatusesProvider);
  final orders = ordersAsync.value ?? [];
  final statuses = statusesAsync.value ?? [];
  final statusMap = {for (var s in statuses) s.id: s.code};
  
  int newCount = 0; 
  int processCount = 0; 
  int readyCount = 0; 
  int deadlineCount = 0; 
  int lateCount = 0;     
  
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  
  for (var order in orders) {
    if (order.isCancelled) continue;
    final code = order.orderStatusId != null ? statusMap[order.orderStatusId] : null;
    
    // ✅ PERBAIKAN: Kurung kurawal ditambahkan
    if (code == 'draft') {
      newCount++;
    } else if (code == 'process') {
      processCount++;
    } else if (code == 'ready') {
      readyCount++;
    }
    
    if (order.dueDate != null && code != 'done' && code != 'ready') {
      final due = DateTime(order.dueDate!.year, order.dueDate!.month, order.dueDate!.day);
      
      // ✅ PERBAIKAN: Kurung kurawal ditambahkan
      if (due.isAtSameMomentAs(today)) {
        deadlineCount++;
      } else if (due.isBefore(today)) {
        lateCount++;
      }
    }
  }
  return {'new': newCount, 'process': processCount, 'ready': readyCount, 'deadline': deadlineCount, 'late': lateCount};
});
