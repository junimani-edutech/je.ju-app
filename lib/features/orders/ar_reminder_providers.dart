import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'order.dart';
import 'orders_providers.dart';

/// Provider yang memfilter pesanan yang belum lunas (unpaid / partial)
final arReminderProvider = Provider<AsyncValue<List<Order>>>((ref) {
  final ordersAsync = ref.watch(ordersProvider);
  
  return ordersAsync.whenData((orders) {
    final filtered = orders.where((o) {
      if (o.isCancelled) return false;
      if (o.paymentStatus == 'paid') return false;
      if (o.paidAmount >= o.totalAmount) return false;
      return true;
    }).toList();
    
    // Urutkan dari yang paling lama (paling mendesak ditagih)
    filtered.sort((a, b) => a.orderDate.compareTo(b.orderDate));
    return filtered;
  });
});

/// Total piutang keseluruhan
final totalReceivablesProvider = Provider<AsyncValue<int>>((ref) {
  final ar = ref.watch(arReminderProvider);
  return ar.whenData((orders) => 
    orders.fold<int>(0, (sum, o) => sum + (o.totalAmount - o.paidAmount))
  );
});
