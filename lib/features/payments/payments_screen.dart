import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../shared/widgets/app_states.dart';
import '../../shared/widgets/skeleton_loader.dart';
import '../orders/order.dart';
import '../orders/orders_providers.dart';
import 'payment.dart';
import 'payments_providers.dart';

class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canWrite = ref.watch(currentMemberProvider).value?.canWrite ?? false;
    final paymentsAsync = ref.watch(allPaymentsProvider);
    final ordersAsync = ref.watch(ordersProvider);
    final orderMap = <String, Order>{
      for (final o in ordersAsync.value ?? const <Order>[]) o.id: o,
    };

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pembayaran'),
          bottom: const TabBar(
            tabs: [
              Tab(key: Key('payments_tab_all'), text: 'Semua'),
              Tab(key: Key('payments_tab_confirmed'), text: 'Terkonfirmasi'),
              Tab(key: Key('payments_tab_cancelled'), text: 'Dibatalkan'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildList(context, ref, paymentsAsync, orderMap, null, canWrite),
            _buildList(
              context,
              ref,
              paymentsAsync,
              orderMap,
              'confirmed',
              canWrite,
            ),
            _buildList(
              context,
              ref,
              paymentsAsync,
              orderMap,
              'cancelled',
              canWrite,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Payment>> async,
    Map<String, Order> orderMap,
    String? filter,
    bool canWrite,
  ) {
    return async.when(
      loading: () => const SkeletonList(),
      error: (e, _) => ErrorState(
        message: 'Gagal memuat pembayaran. Periksa koneksi Anda.',
        onRetry: () => ref.invalidate(allPaymentsProvider),
      ),
      data: (list) {
        final filtered = filter == null
            ? list
            : list.where((p) => p.status == filter).toList();
        if (filtered.isEmpty) {
          return const EmptyState(
            icon: Icons.payments_outlined,
            title: 'Belum ada pembayaran',
            subtitle:
                'Pembayaran tercatat saat Anda mencatatnya di detail pesanan.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          separatorBuilder: (_, _) => const SizedBox(height: 4),
          itemBuilder: (ctx, i) {
            final p = filtered[i];
            return _PaymentRow(
              payment: p,
              orderNumber: orderMap[p.orderId]?.orderNumber,
              canWrite: canWrite,
              onVoid: () => _void(context, ref, p),
            );
          },
        );
      },
    );
  }

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
              key: const Key('payment_void_reason_input'),
              controller: reasonCtrl,
              decoration: const InputDecoration(labelText: 'Alasan *'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            key: const Key('payment_void_cancel'),
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
    if (confirmed != true) return;
    final reason = reasonCtrl.text.trim();
    if (reason.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Alasan wajib diisi.')));
      }
      return;
    }
    try {
      await ref
          .read(allPaymentsProvider.notifier)
          .voidPayment(paymentId: p.id, reason: reason);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Pembayaran di-void.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({
    required this.payment,
    required this.orderNumber,
    required this.canWrite,
    required this.onVoid,
  });

  final Payment payment;
  final String? orderNumber;
  final bool canWrite;
  final VoidCallback onVoid;

  String _fmtIdr(int amount) {
    final negative = amount < 0;
    final abs = amount.abs();
    final s = abs.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '${negative ? '-' : ''}Rp ${buf.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = payment.paymentDate.toIso8601String().substring(0, 10);
    final isReversal = payment.isReversal;
    final isCancelled = payment.isCancelled;

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        key: Key('payment_row_${payment.id}'),
        leading: Icon(
          isReversal
              ? Icons.undo
              : isCancelled
              ? Icons.cancel_outlined
              : Icons.check_circle_outline,
          color: isReversal || isCancelled
              ? theme.colorScheme.error
              : theme.colorScheme.primary,
        ),
        title: Row(
          children: [
            Text(
              _fmtIdr(payment.signedAmount),
              style: theme.textTheme.titleMedium?.copyWith(
                color: isReversal || isCancelled
                    ? theme.colorScheme.error
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            if (isReversal)
              _badge(
                'Reversal',
                theme.colorScheme.errorContainer,
                theme.colorScheme.onErrorContainer,
              ),
            if (isCancelled)
              _badge(
                'Batal',
                theme.colorScheme.outline,
                theme.colorScheme.surface,
              ),
          ],
        ),
        subtitle: Text('${orderNumber ?? '-'} • $dateStr'),
        trailing: canWrite && !isReversal && !isCancelled
            ? IconButton(
                key: Key('payment_void_${payment.id}'),
                tooltip: 'Void',
                icon: const Icon(Icons.block),
                onPressed: onVoid,
              )
            : null,
      ),
    );
  }

  Widget _badge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, color: fg)),
    );
  }
}
