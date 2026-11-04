import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../shared/widgets/app_states.dart';
import '../../shared/widgets/skeleton_loader.dart';
import '../customers/customer.dart';
import '../customers/customers_providers.dart';
import 'order.dart';
import 'orders_providers.dart';
import 'widgets/order_detail_sheet.dart';
import 'widgets/order_form_sheet.dart';
import 'widgets/order_list_tile.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  static const _tabs = <String?>[null, 'draft', 'process', 'ready', 'done', 'cancelled'];
  static const _tabLabels = <String>[
    'Semua',
    'Draft Pre-Order',
    'Sedang Proses',
    'Siap Antar/Ambil',
    'Selesai',
    'Dibatalkan',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Order> _applyQuery(List<Order> list, Map<String, String> customerNames) {
    if (_query.isEmpty) return list;
    final q = _query.toLowerCase();
    return list.where((o) {
      if (o.orderNumber.toLowerCase().contains(q)) return true;
      if (o.notes != null && o.notes!.toLowerCase().contains(q)) return true;
      
      if (o.customerId != null) {
        final custName = customerNames[o.customerId!];
        if (custName != null && custName.toLowerCase().contains(q)) return true;
      }
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final statusParam = GoRouterState.of(context).uri.queryParameters['status'];
    final specialFilter = GoRouterState.of(context).uri.queryParameters['filter']; // ✅ Baca filter waktu
    
    final initialIndex = _tabs.indexOf(statusParam).clamp(0, _tabs.length - 1);

    final canWrite = ref.watch(currentMemberProvider).value?.canWrite ?? false;
    final ordersAsync = ref.watch(ordersProvider);
    final statusesAsync = ref.watch(orderStatusesProvider);
    final customersAsync = ref.watch(activeCustomersProvider); 
    
    final statusMap = <String, OrderStatus>{
      for (final s in statusesAsync.value ?? <OrderStatus>[]) s.id: s,
    };

    final customerNames = <String, String>{
      for (final c in customersAsync.value ?? <Customer>[]) c.id: c.name,
    };

    return DefaultTabController(
      key: ValueKey('${statusParam}_$specialFilter'), 
      length: _tabs.length,
      initialIndex: initialIndex,
      child: Scaffold(
        appBar: AppBar(
          title: Text(specialFilter == 'deadline' 
              ? 'Deadline Hari Ini' 
              : specialFilter == 'late' 
                  ? 'Pesanan Terlambat' 
                  : 'Pesanan'),
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              for (var i = 0; i < _tabs.length; i++)
                Tab(
                  key: Key('orders_tab_${_tabs[i] ?? 'all'}'),
                  text: _tabLabels[i],
                ),
            ],
          ),
        ),
        body: Column(
          children: [
            // Banner info jika sedang dalam mode filter khusus
            if (specialFilter != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: specialFilter == 'late' ? Colors.red.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                child: Text(
                  specialFilter == 'late' 
                      ? 'Menampilkan pesanan yang melewati tanggal pengiriman.' 
                      : 'Menampilkan pesanan yang harus dikirim hari ini.',
                  style: TextStyle(
                    fontSize: 12, 
                    fontWeight: FontWeight.bold,
                    color: specialFilter == 'late' ? Colors.red.shade700 : Colors.orange.shade700
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: TextField(
                key: const Key('orders_search'),
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Cari nomor pesanan, pelanggan, atau catatan', 
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  isDense: true,
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          key: const Key('orders_search_clear'),
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
              child: ordersAsync.when(
                loading: () => const SkeletonList(),
                error: (e, _) => ErrorState(
                  message: 'Gagal memuat pesanan. Periksa koneksi Anda.',
                  onRetry: () => ref.invalidate(ordersProvider),
                ),
                data: (list) {
                  return TabBarView(
                    children: [
                      for (final tabStatus in _tabs)
                        _buildList(context, list, tabStatus, specialFilter, statusMap, canWrite, customerNames),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: canWrite
            ? FloatingActionButton.extended(
                key: const Key('orders_fab'),
                onPressed: () => OrderFormSheet.show(context),
                icon: const Icon(Icons.add),
                label: const Text('Buat'),
              )
            : null,
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    List<Order> all,
    String? tabStatus,
    String? specialFilter, // ✅ Parameter filter khusus waktu
    Map<String, OrderStatus> statusMap,
    bool canWrite,
    Map<String, String> customerNames,
  ) {
    // 1. Filter berdasarkan Tab Status
    var filtered = tabStatus == null
        ? all
        : all.where((o) {
            if (tabStatus == 'cancelled') return o.isCancelled;
            if (o.isCancelled) return false;
            final s = o.orderStatusId != null
                ? statusMap[o.orderStatusId!]
                : null;
            return s?.code == tabStatus;
          }).toList();

    // 2. Filter berdasarkan Waktu (Deadline / Late)
    if (specialFilter != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      filtered = filtered.where((o) {
        // Abaikan yang sudah selesai atau dibatalkan
        if (o.isCancelled) return false;
        final s = o.orderStatusId != null ? statusMap[o.orderStatusId!] : null;
        if (s?.code == 'done') return false;

        if (o.dueDate == null) return false;
        
        final due = DateTime(o.dueDate!.year, o.dueDate!.month, o.dueDate!.day);
        
        if (specialFilter == 'deadline') {
          return due.isAtSameMomentAs(today);
        } else if (specialFilter == 'late') {
          return due.isBefore(today);
        }
        return true;
      }).toList();
    }

    // 3. Filter Pencarian
    final searched = _applyQuery(filtered, customerNames);

    if (searched.isEmpty) {
      if (_query.isNotEmpty) {
        return const EmptyState(
          icon: Icons.search_off,
          title: 'Tidak ada hasil',
          subtitle: 'Tidak ada pesanan yang cocok dengan pencarian Anda.',
        );
      }
      final label = tabStatus == null
          ? 'Belum ada pesanan'
          : 'Tidak ada pesanan di tab ini';
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        title: label,
        subtitle: specialFilter != null
            ? 'Tidak ada pesanan yang sesuai dengan filter waktu ini.'
            : 'Pesanan baru akan muncul di sini setelah Anda membuatnya.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 88),
      itemCount: searched.length,
      separatorBuilder: (_, _) => const SizedBox(height: 4),
      itemBuilder: (_, i) {
        final o = searched[i];
        final status = o.orderStatusId != null
            ? statusMap[o.orderStatusId!]
            : null;
        final label = o.isCancelled ? 'Dibatalkan' : (status?.name ?? '—');
        return OrderListTile(
          order: o,
          statusLabel: label,
          onTap: () => OrderDetailSheet.show(context, order: o),
        );
      },
    );
  }
}
