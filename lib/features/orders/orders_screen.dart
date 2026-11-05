import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../shared/widgets/app_states.dart';
import '../../shared/widgets/skeleton_loader.dart';
import 'order.dart';
import 'orders_providers.dart';
import 'paginated_orders_providers.dart';
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
  Timer? _debounce;
  String? _localStatusFilter;
  String? _localSpecialFilter;
  bool _initialized = false;

  static const _statusOptions = <({String? code, String label})>[
    (code: null, label: 'Semua'),
    (code: 'draft', label: 'Draft'),
    (code: 'process', label: 'Proses'),
    (code: 'ready', label: 'Siap'),
    (code: 'done', label: 'Selesai'),
    (code: 'cancelled', label: 'Batal'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_initialized && mounted) {
        _initialized = true;
        final state = GoRouterState.of(context);
        final statusParam = state.uri.queryParameters['status'];
        final specialFilter = state.uri.queryParameters['filter'];

        if (specialFilter != null) {
          _localSpecialFilter = specialFilter;
          ref.read(paginatedOrdersProvider.notifier).setSpecialFilter(specialFilter);
        } else if (statusParam != null) {
          _localStatusFilter = statusParam;
          ref.read(paginatedOrdersProvider.notifier).setStatusFilter(statusParam);
        }
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
      if (mounted) {
        ref.read(paginatedOrdersProvider.notifier).setSearch(value);
      }
    });
  }

  void _onStatusSelected(String? code) {
    setState(() => _localStatusFilter = code);
    ref.read(paginatedOrdersProvider.notifier).setStatusFilter(code);
  }

  void _clearSpecialFilter() {
    setState(() => _localSpecialFilter = null);
    ref.read(paginatedOrdersProvider.notifier).setSpecialFilter(null);
    if (mounted) context.go('/app/orders');
  }

  String get _appBarTitle {
    if (_localSpecialFilter == 'deadline') return 'Deadline Hari Ini';
    if (_localSpecialFilter == 'late') return 'Pesanan Terlambat';
    return 'Pesanan';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canWrite = ref.watch(currentMemberProvider).value?.canWrite ?? false;
    final async = ref.watch(paginatedOrdersProvider);
    final statusesAsync = ref.watch(orderStatusesProvider);
    final statusMap = <String, OrderStatus>{
      for (final s in statusesAsync.value ?? <OrderStatus>[]) s.id: s,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Banner filter khusus (deadline/late)
          if (_localSpecialFilter != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: _localSpecialFilter == 'late' 
                  ? Colors.red.withValues(alpha: 0.1) 
                  : Colors.orange.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _localSpecialFilter == 'late'
                          ? 'Menampilkan pesanan terlambat.'
                          : 'Menampilkan pesanan yang dikirim hari ini.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _localSpecialFilter == 'late' ? Colors.red.shade700 : Colors.orange.shade700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _clearSpecialFilter,
                    child: const Text('Hapus Filter', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),

          // Status Chips (hanya jika tidak ada special filter)
          if (_localSpecialFilter == null)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: _statusOptions.map((opt) {
                  final isSelected = _localStatusFilter == opt.code;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(opt.label),
                      selected: isSelected,
                      selectedColor: theme.colorScheme.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) => _onStatusSelected(opt.code),
                    ),
                  );
                }).toList(),
              ),
            ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Cari nomor pesanan, pelanggan, atau catatan',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                suffixIcon: _searchCtrl.text.isEmpty ? null : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchCtrl.clear();
                    ref.read(paginatedOrdersProvider.notifier).setSearch(null);
                  },
                ),
              ),
            ),
          ),

          // List Pesanan
          Expanded(
            child: async.when(
              loading: () => const SkeletonList(),
              error: (e, _) => ErrorState(
                message: 'Gagal memuat pesanan: $e',
                onRetry: () => ref.read(paginatedOrdersProvider.notifier).refresh(),
              ),
              data: (result) {
                if (result.items.isEmpty) {
                  return EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: _searchCtrl.text.isNotEmpty ? 'Tidak ada hasil' : 'Belum ada pesanan',
                    subtitle: _searchCtrl.text.isNotEmpty
                        ? 'Coba kata kunci lain.'
                        : 'Pesanan baru akan muncul di sini.',
                  );
                }

                return Column(
                  children: [
                    // Info Total
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Menampilkan ${result.items.length} dari ${result.total} pesanan',
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                        ],
                      ),
                    ),
                    // List
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                        itemCount: result.items.length + (result.hasMore ? 1 : 0),
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          if (i == result.items.length) {
                            // Load More Button
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: OutlinedButton.icon(
                                  onPressed: () => ref.read(paginatedOrdersProvider.notifier).loadMore(),
                                  icon: const Icon(Icons.expand_more),
                                  label: const Text('Muat Lebih Banyak'),
                                ),
                              ),
                            );
                          }
                          final o = result.items[i];
                          final status = o.orderStatusId != null ? statusMap[o.orderStatusId!] : null;
                          final label = o.isCancelled ? 'Dibatalkan' : (status?.name ?? '—');
                          return OrderListTile(
                            order: o,
                            statusLabel: label,
                            customerName: o.customerName,
                            onTap: () => OrderDetailSheet.show(context, order: o),
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
      floatingActionButton: canWrite
          ? FloatingActionButton.extended(
              key: const Key('orders_fab'),
              onPressed: () => OrderFormSheet.show(context),
              icon: const Icon(Icons.add),
              label: const Text('Buat'),
            )
          : null,
    );
  }
}
