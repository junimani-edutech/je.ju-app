import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../orders/order.dart';
import '../payment.dart';
import '../payments_providers.dart';
import 'payment_form_sheet.dart';
import 'payment_list_tile.dart';

class PaymentsSection extends ConsumerWidget {
  const PaymentsSection({super.key, required this.order});
  final Order order;

  Future<void> _void(BuildContext context, WidgetRef ref, Payment p) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Void pembayaran?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Pembayaran ${p.amount} akan di-reversal.'),
            const SizedBox(height: 12),
            TextField(
              key: const Key('payment_void_reason'),
              controller: reasonCtrl,
              decoration: const InputDecoration(labelText: 'Alasan *'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            key: const Key('payment_void_confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Void'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final reason = reasonCtrl.text.trim();
      if (reason.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Alasan wajib.')));
        }
      } else {
        try {
          await ref
              .read(paymentsControllerProvider)
              .voidPayment(paymentId: p.id, orderId: order.id, reason: reason);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('Gagal: $e')));
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final canWrite = ref.watch(currentMemberProvider).value?.canWrite ?? false;
    final paymentsAsync = ref.watch(paymentsForOrderProvider(order.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Pembayaran', style: theme.textTheme.titleSmall),
            ),
            if (canWrite && !order.isCancelled)
              TextButton.icon(
                key: const Key('order_detail_record_payment'),
                onPressed: () => PaymentFormSheet.show(context, order: order),
                icon: const Icon(Icons.add_card),
                label: const Text('Catat'),
              ),
          ],
        ),
        paymentsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text('Gagal memuat pembayaran: $e'),
          data: (list) {
            if (list.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Belum ada pembayaran.',
                  style: theme.textTheme.bodySmall,
                ),
              );
            }
            return Column(
              children: [
                for (final p in list)
                  PaymentListTile(
                    payment: p,
                    canWrite: canWrite,
                    onVoid: () => _void(context, ref, p),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
