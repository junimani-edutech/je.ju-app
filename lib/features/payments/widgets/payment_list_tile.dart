import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../payment.dart';
import '../payments_providers.dart';

class PaymentListTile extends ConsumerWidget {
  const PaymentListTile({
    super.key,
    required this.payment,
    required this.canWrite,
    this.onVoid,
  });

  final Payment payment;
  final bool canWrite;
  final VoidCallback? onVoid;

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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final methods =
        ref.watch(paymentMethodsProvider).value ?? const <PaymentMethod>[];
    final methodName = payment.paymentMethodId == null
        ? 'Tanpa metode'
        : methods
              .firstWhere(
                (m) => m.id == payment.paymentMethodId,
                orElse: () => const PaymentMethod(
                  id: '',
                  businessId: '',
                  name: '—',
                  status: 'active',
                ),
              )
              .name;

    final dateStr = payment.paymentDate.toIso8601String().substring(0, 10);
    final isReversal = payment.isReversal;

    return ListTile(
      key: Key('payment_tile_${payment.id}'),
      leading: Icon(
        isReversal ? Icons.undo : Icons.check_circle_outline,
        color: isReversal ? theme.colorScheme.error : theme.colorScheme.primary,
      ),
      title: Row(
        children: [
          Text(
            _fmtIdr(payment.signedAmount),
            style: theme.textTheme.titleMedium?.copyWith(
              color: isReversal ? theme.colorScheme.error : null,
            ),
          ),
          if (isReversal) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Reversal',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text('$dateStr • $methodName'),
      trailing: canWrite && !isReversal
          ? IconButton(
              key: Key('payment_void_${payment.id}'),
              tooltip: 'Void',
              icon: const Icon(Icons.block),
              onPressed: onVoid,
            )
          : null,
    );
  }
}
