import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../shared/widgets/app_states.dart';
import 'order.dart';
import 'orders_providers.dart';
import 'widgets/order_detail_sheet.dart';
import 'widgets/order_form_sheet.dart';
import 'widgets/order_list_tile.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  static const _tabs = <String?>[
    null, // Semua
    'draft',
    'process',
    'done',
    'cancelled',
  ];
  static const _tabLabels = <String>[
    'Semua',
    'Draft',
    'Proses',
    'Selesai',
    'Dibatalkan',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        body: ordersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorState(
            message: 'Gagal memuat pesanan. Periksa koneksi Anda.',
            onRetry: () => ref.invalidate(ordersProvider),
          ),
          data: (list) {
            return TabBarView(
              children: [
                for (final filter in _tabs)
                  _buildList(context, ref, list, filter, statusMap, canWrite),
              ],
            );
          },
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
    WidgetRef ref,
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

    if (filtered.isEmpty) {
      return _buildEmpty(context, statusFilter);
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 88),
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const SizedBox(height: 4),
      itemBuilder: (_, i) {
        final o = filtered[i];
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

  Widget _buildEmpty(BuildContext context, String? statusFilter) {
    final theme = Theme.of(context);
    final label = statusFilter == null
        ? 'Belum ada pesanan'
        : 'Tidak ada pesanan di tab ini';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 56,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
