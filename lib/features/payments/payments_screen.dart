import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../shared/widgets/app_states.dart';
import '../../shared/widgets/skeleton_loader.dart';
import '../orders/order.dart';
import '../orders/orders_providers.dart';
import 'payment.dart';
import 'payments_providers.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          title: const Text('Pembayaran', style: TextStyle(fontWeight: FontWeight.bold)),
          bottom: const TabBar(
            tabs: [
              Tab(key: Key('payments_tab_all'), text: 'Semua'),
              Tab(key: Key('payments_tab_confirmed'), text: 'Terkonfirmasi'),
              Tab(key: Key('payments_tab_cancelled'), text: 'Dibatalkan'),
            ],
          ),
        ),
        body: Column(
          children: [
            // ✅ PERBAIKAN: Search Bar Modern
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Cari nomor pesanan...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
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
              child: TabBarView(
                children: [
                  _buildList(context, paymentsAsync, orderMap, null, canWrite),
                  _buildList(context, paymentsAsync, orderMap, 'confirmed', canWrite),
                  _buildList(context, paymentsAsync, orderMap, 'cancelled', canWrite),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
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
        // 1. Filter Tab
        var filtered = filter == null
            ? list
            : list.where((p) => p.status == filter).toList();

        // 2. Filter Pencarian
        if (_query.isNotEmpty) {
          final q = _query.toLowerCase();
          filtered = filtered.where((p) {
            final orderNo = orderMap[p.orderId]?.orderNumber.toLowerCase() ?? '';
            return orderNo.contains(q);
          }).toList();
        }

        // 3. Empty State Premium
        if (filtered.isEmpty) {
          if (_query.isNotEmpty) {
            return _buildEmpty(
              icon: Icons.search_off,
              title: 'Tidak ada hasil',
              subtitle: 'Tidak ada pembayaran yang cocok dengan "$_query".',
            );
          }
          return _buildEmpty(
            icon: Icons.payments_outlined,
            title: 'Belum ada pembayaran',
            subtitle: 'Pembayaran tercatat saat Anda mencatatnya di detail pesanan.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
          itemCount: filtered.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
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

  // ✅ Empty State Premium
  Widget _buildEmpty({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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

    // ✅ PERBAIKAN: Desain Card disamakan dengan halaman lain
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        key: Key('payment_row_${payment.id}'),
        leading: CircleAvatar(
          backgroundColor: (isReversal || isCancelled) 
              ? theme.colorScheme.error.withValues(alpha: 0.1) 
              : theme.colorScheme.primary.withValues(alpha: 0.1),
          child: Icon(
            isReversal
                ? Icons.undo
                : isCancelled
                ? Icons.cancel_outlined
                : Icons.check_circle_outline,
            color: (isReversal || isCancelled)
                ? theme.colorScheme.error
                : theme.colorScheme.primary,
          ),
        ),
        title: Row(
          children: [
            Text(
              _fmtIdr(payment.signedAmount),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isReversal || isCancelled
                    ? theme.colorScheme.error
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            if (isReversal)
              _badge('Reversal', theme.colorScheme.errorContainer, theme.colorScheme.onErrorContainer),
            if (isCancelled)
              _badge('Batal', theme.colorScheme.outline, theme.colorScheme.surface),
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
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg)),
    );
  }
}
