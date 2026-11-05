import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers.dart';
import '../../customers/customers_providers.dart';
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

  Order _liveOrder() {
    final list = ref.watch(ordersProvider).value ?? const <Order>[];
    for (final o in list) {
      if (o.id == widget.order.id) return o;
    }
    return widget.order;
  }

  Future<void> _printInvoice() async {
    final biz = ref.read(currentBusinessProvider).value;
    if (biz == null) {
      _showError('Bisnis tidak ditemukan');
      return;
    }

    final customers = ref.read(activeCustomersProvider).value ?? [];
    final customer = customers.where((c) => c.id == widget.order.customerId).firstOrNull;

    try {
      final items = await _itemsFuture;
      await InvoiceService.printInvoice(widget.order, items, biz, customer);
    } catch (e) {
      _showError('Gagal mencetak: $e');
    }
  }

  Future<void> _sendWhatsApp() async {
    final customers = ref.read(activeCustomersProvider).value ?? [];
    final customer = customers.where((c) => c.id == widget.order.customerId).firstOrNull;

    if (customer == null || customer.phone == null || customer.phone!.isEmpty) {
      _showError('Nomor HP pelanggan tidak ditemukan.');
      return;
    }

    String phone = customer.phone!.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.startsWith('0')) {
      phone = '62${phone.substring(1)}';
    }

    final statusMap = {for (final s in ref.read(orderStatusesProvider).value ?? []) s.id: s.name};
    final statusName = statusMap[widget.order.orderStatusId] ?? 'Diproses';

    final message = 'Halo *${customer.name}*,\n\n'
        'Pesanan Anda dengan nomor *${widget.order.orderNumber}* saat ini berstatus: *$statusName*.\n'
        'Total tagihan: *Rp ${widget.order.totalAmount}*.\n\n'
        'Terima kasih telah berbelanja di toko kami.';

    final url = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(message)}');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _showError('Aplikasi WhatsApp tidak ditemukan.');
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _repeatOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pesan Ulang?'),
        content: Text(
          'Buat pesanan baru dengan item yang sama seperti pesanan ${widget.order.orderNumber}? '
          'Anda bisa mengubahnya setelahnya.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            key: const Key('order_repeat_confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Pesan Ulang'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final items = await _itemsFuture;
      if (items.isEmpty) {
        _showError('Tidak ada item untuk dipesan ulang.');
        return;
      }

      final inputs = items
          .map((it) => OrderItemInput(
                description: it.description,
                quantity: it.quantity,
                unitPrice: it.unitPrice,
              ))
          .toList();

      await ref.read(ordersProvider.notifier).create(
            items: inputs,
            customerId: widget.order.customerId,
            notes: widget.order.notes,
          );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pesanan baru berhasil dibuat dari pesanan ini!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError('Gagal membuat pesanan ulang: $e');
    }
  }

  Future<void> _changeStatus() async {
    final statuses = ref.read(orderStatusesProvider).value ?? const <OrderStatus>[];
    final selectable = statuses.where((s) => s.code != 'cancelled').toList();
    if (selectable.isEmpty) return;

    String? selectedId = widget.order.orderStatusId ?? selectable.first.id;
    final notesCtrl = TextEditingController();
    bool loading = false;
    String? error;

    await showDialog<bool>(
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
                decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
                maxLines: 2,
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!, style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
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
                      setStateDialog(() { loading = true; error = null; });
                      try {
                        await ref.read(ordersProvider.notifier).changeStatus(
                          orderId: widget.order.id,
                          orderStatusId: selectedId!,
                          notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                        );
                        if (ctx.mounted) Navigator.of(ctx).pop(true);
                      } catch (e) {
                        setStateDialog(() { error = e.toString(); loading = false; });
                      }
                    },
              child: loading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
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
            Text('Pesanan ${widget.order.orderNumber} akan ditandai dibatalkan.'),
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
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Tidak')),
          FilledButton(key: const Key('cancel_order_confirm'), onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Batalkan Pesanan')),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(ordersProvider.notifier).cancel(
          widget.order.id,
          reason: reasonCtrl.text.trim().isEmpty ? null : reasonCtrl.text.trim(),
        );
      } catch (e) {
        _showError('Gagal: $e');
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
    final currentStatus = liveOrder.orderStatusId != null ? statusMap[liveOrder.orderStatusId!] : null;
    final dateStr = liveOrder.orderDate.toIso8601String().substring(0, 10);
    final statusLabel = liveOrder.isCancelled ? 'Dibatalkan' : (currentStatus?.name ?? '—');

    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(liveOrder.orderNumber, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Tanggal: $dateStr'),
            Text('Status: $statusLabel'),
            Text('Pembayaran: ${liveOrder.paymentStatus}'),
            const Divider(),
            
            // ✅ PERBAIKAN UI: Daftar Item dalam Card
            Text('Item', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            FutureBuilder<List<OrderItem>>(
              future: _itemsFuture,
              builder: (ctx, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Center(child: CircularProgressIndicator()));
                }
                if (snap.hasError) return Text('Gagal memuat item: ${snap.error}');
                final items = snap.data ?? const <OrderItem>[];
                if (items.isEmpty) return const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('—'));
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        for (final it in items)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Expanded(child: Text(it.description, style: theme.textTheme.bodyMedium)),
                                Text('${it.quantity} x ${it.unitPrice}', style: theme.textTheme.bodySmall),
                                const SizedBox(width: 12),
                                Text(it.lineTotal.toString(), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            const Divider(),
            
            // RINGKASAN BIAYA
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
              Text('Catatan: ${liveOrder.notes}', style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
            ],
            const SizedBox(height: 16),
            
            // TOMBOL AKSI
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _printInvoice,
                    icon: const Icon(Icons.print, size: 18),
                    label: const Text('Cetak'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _sendWhatsApp,
                    icon: const Icon(Icons.chat, size: 18),
                    label: const Text('Kirim WA'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green.shade700,
                      side: BorderSide(color: Colors.green.shade700),
                    ),
                  ),
                ),
              ],
            ),
            if (canWrite && !liveOrder.isCancelled) ...[
              const SizedBox(height: 8),
              FilledButton.icon(
                key: const Key('order_detail_repeat'),
                onPressed: _repeatOrder,
                icon: const Icon(Icons.replay),
                label: const Text('Pesan Lagi'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
            ],
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
    final style = bold ? Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold) : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(k, style: style), Text(v.toString(), style: style)],
      ),
    );
  }
}
