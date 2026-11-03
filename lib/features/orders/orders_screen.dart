import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../shared/widgets/app_states.dart';
import '../../shared/widgets/skeleton_loader.dart';
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

  static const _tabs = <String?>[null, 'draft', 'process', 'done', 'cancelled'];
  static const _tabLabels = <String>[
    'Semua',
    'Draft',
    'Proses',
    'Selesai',
    'Dibatalkan',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Order> _applyQuery(List<Order> list) {
    if (_query.isEmpty) return list;
    final q = _query.toLowerCase();
    return list.where((o) {
      if (o.orderNumber.toLowerCase().contains(q)) return true;
      if (o.notes != null && o.notes!.toLowerCase().contains(q)) return true;
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final canWrite = ref.watch(currentMemberProvider).value?.canWrite ?? false;
    final ordersAsync = ref.watch(ordersProvider);
    final statusesAsync = ref.watch(orderStatusesProvider);
    final statusMap = <String, OrderStatus>{
      for (final s in statusesAsync.value ?? <OrderStatus>[]) s.id: s,
    };

    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pesanan'),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: TextField(
                key: const Key('orders_search'),
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Cari nomor pesanan atau catatan',
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
                      for (final filter in _tabs)
                        _buildList(context, list, filter, statusMap, canWrite),
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
    String? statusFilter,
    Map<String, OrderStatus> statusMap,
    bool canWrite,
  ) {
    final filtered = statusFilter == null
        ? all
        : all.where((o) {
            if (statusFilter == 'cancelled') return o.isCancelled;
            if (o.isCancelled) return false;
            final s = o.orderStatusId != null
                ? statusMap[o.orderStatusId!]
                : null;
            return s?.code == statusFilter;
          }).toList();

    final searched = _applyQuery(filtered);

    if (searched.isEmpty) {
      if (_query.isNotEmpty) {
        return const EmptyState(
          icon: Icons.search_off,
          title: 'Tidak ada hasil',
          subtitle: 'Tidak ada pesanan yang cocok dengan pencarian Anda.',
        );
      }
      final label = statusFilter == null
          ? 'Belum ada pesanan'
          : 'Tidak ada pesanan di tab ini';
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        title: label,
        subtitle: 'Pesanan baru akan muncul di sini setelah Anda membuatnya.',
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
