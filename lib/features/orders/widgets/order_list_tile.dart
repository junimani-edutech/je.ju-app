import 'package:flutter/material.dart';

import '../order.dart';

class OrderListTile extends StatelessWidget {
  const OrderListTile({
    super.key,
    required this.order,
    this.statusLabel,
    this.onTap,
  });

  final Order order;
  final String? statusLabel;
  final VoidCallback? onTap;

  String _fmtIdr(int amount) {
    final s = amount.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return 'Rp ${buf.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cancelled = order.isCancelled;
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        key: Key('order_tile_${order.id}'),
        title: Text(
          order.orderNumber,
          style: cancelled
              ? theme.textTheme.titleMedium?.copyWith(
                  decoration: TextDecoration.lineThrough,
                )
              : theme.textTheme.titleMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${order.orderDate.year}-'
              '${order.orderDate.month.toString().padLeft(2, '0')}-'
              '${order.orderDate.day.toString().padLeft(2, '0')}',
            ),
            if (statusLabel != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      cancelled ? Icons.cancel_outlined : Icons.circle,
                      size: 12,
                      color: cancelled
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(statusLabel!),
                  ],
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_fmtIdr(order.totalAmount), style: theme.textTheme.titleSmall),
            const SizedBox(height: 2),
            Text(order.paymentStatus, style: theme.textTheme.bodySmall),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
