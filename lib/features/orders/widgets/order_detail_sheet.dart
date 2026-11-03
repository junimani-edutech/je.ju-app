import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../payments/widgets/payments_section.dart';
import '../order.dart';
import '../orders_providers.dart';
import '../invoice_service.dart';

class OrderDetailSheet extends ConsumerStatefulWidget {
  const OrderDetailSheet({super.key, required this.order});
  final Order order;

  static Future<void> show(BuildContext context, {required Order order}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => OrderDetailSheet(order: order),
    );
  }

  @override
  ConsumerState<OrderDetailSheet> createState() => _OrderDetailSheetState();
}

class _OrderDetailSheetState extends ConsumerState<OrderDetailSheet> {
  late Future<List<OrderItem>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _itemsFuture = ref.read(ordersServiceProvider).listItems(widget.order.id);
  }

  /// Cari versi terbaru order ini dari ordersProvider agar header reaktif
  /// setelah record/void payment. Fallback ke widget.order bila belum ada.
  Order _liveOrder() {
    final list = ref.watch(ordersProvider).value ?? const <Order>[];
    for (final o in list) {
      if (o.id == widget.order.id) return o;
    }
    return widget.order;
  }

  Future<void> _changeStatus() async {
    final statuses =
        ref.read(orderStatusesProvider).value ?? const <OrderStatus>[];
    final selectable = statuses.where((s) => s.code != 'cancelled').toList();
    if (selectable.isEmpty) return;

    String? selectedId = widget.order.orderStatusId ?? selectable.first.id;
    final notesCtrl = TextEditingController();
    bool loading = false;
    String? error;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Ubah Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                key: const Key('change_status_dropdown'),
                initialValue: selectedId,
                items: [
                  for (final s in selectable)
                    DropdownMenuItem(value: s.id, child: Text(s.name)),
                ],
                onChanged: (v) => setStateDialog(() => selectedId = v),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('change_status_notes'),
                controller: notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                ),
                maxLines: 2,
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(
                  error!,
                  style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              key: const Key('change_status_confirm'),
              onPressed: loading
                  ? null
                  : () async {
                      setStateDialog(() {
                        loading = true;
                        error = null;
                      });
                      try {
                        await ref
                            .read(ordersProvider.notifier)
                            .changeStatus(
                              orderId: widget.order.id,
                              orderStatusId: selectedId!,
                              notes: notesCtrl.text.trim().isEmpty
                                  ? null
                                  : notesCtrl.text.trim(),
                            );
                        if (ctx.mounted) Navigator.of(ctx).pop(true);
                      } catch (e) {
                        setStateDialog(() {
                          error = e.toString();
                          loading = false;
                        });
                      }
                    },
              child: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      // Sheet tidak perlu ditutup; liveOrder otomatis re-render.
    }
  }

  Future<void> _cancelOrder() async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan pesanan?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Pesanan ${widget.order.orderNumber} akan ditandai '
              'dibatalkan. Data tidak dihapus.',
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('cancel_order_reason'),
              controller: reasonCtrl,
              decoration: const InputDecoration(labelText: 'Alasan (opsional)'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Tidak'),
          ),
          FilledButton(
            key: const Key('cancel_order_confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Batalkan Pesanan'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(ordersProvider.notifier)
            .cancel(
              widget.order.id,
              reason: reasonCtrl.text.trim().isEmpty
                  ? null
                  : reasonCtrl.text.trim(),
            );
        // liveOrder re-render; sheet tetap terbuka dengan status cancelled.
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Gagal: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final liveOrder = _liveOrder();
    final canWrite = ref.watch(currentMemberProvider).value?.canWrite ?? false;
    final statusesAsync = ref.watch(orderStatusesProvider);
    final statusMap = <String, OrderStatus>{
      for (final s in statusesAsync.value ?? <OrderStatus>[]) s.id: s,
    };
    final currentStatus = liveOrder.orderStatusId != null
        ? statusMap[liveOrder.orderStatusId!]
        : null;
    final dateStr = liveOrder.orderDate.toIso8601String().substring(0, 10);
    final statusLabel = liveOrder.isCancelled
        ? 'Dibatalkan'
        : (currentStatus?.name ?? '—');

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(liveOrder.orderNumber, style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('Tanggal: $dateStr'),
            Text('Status: $statusLabel'),
            Text('Pembayaran: ${liveOrder.paymentStatus}'),
            const Divider(),
            Text('Item', style: theme.textTheme.titleSmall),
            FutureBuilder<List<OrderItem>>(
              future: _itemsFuture,
              builder: (ctx, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snap.hasError) {
                  return Text('Gagal memuat item: ${snap.error}');
                }
                final items = snap.data ?? const <OrderItem>[];
                if (items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text('—'),
                  );
                }
                return Column(
                  children: [
                    for (final it in items)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(child: Text(it.description)),
                            Text('${it.quantity} x ${it.unitPrice}'),
                            const SizedBox(width: 12),
                            Text(it.lineTotal.toString()),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
            const Divider(),
            _kv('Subtotal', liveOrder.subtotalAmount),
            _kv('Diskon', -liveOrder.discountAmount),
            _kv('Biaya tambahan', liveOrder.additionalFeeAmount),
            _kv('Ongkir', liveOrder.shippingAmount),
            const Divider(),
            _kv('Total', liveOrder.totalAmount, bold: true),
            _kv('Dibayar', liveOrder.paidAmount),
            const Divider(),
            PaymentsSection(order: liveOrder),
            if (liveOrder.notes != null && liveOrder.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Catatan: ${liveOrder.notes}'),
            ],
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () async {
                final items = await _itemsFuture;
                if (!context.mounted) return;
                await InvoiceService.printInvoice(liveOrder, items, 'JeJu');
              },
              icon: const Icon(Icons.print),
              label: const Text('Cetak Invoice'),
            ),
            const SizedBox(height: 8),
            if (canWrite && !liveOrder.isCancelled) ...[
              FilledButton.icon(
                key: const Key('order_detail_change_status'),
                onPressed: _changeStatus,
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Ubah Status'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const Key('order_detail_cancel'),
                onPressed: _cancelOrder,
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Batalkan Pesanan'),
              ),
            ],
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Tutup'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, int v, {bool bold = false}) {
    final style = bold
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: style),
          Text(v.toString(), style: style),
        ],
      ),
    );
  }
}
