import 'package:flutter/material.dart';

import '../transaction.dart';

class TransactionListTile extends StatelessWidget {
  const TransactionListTile({
    super.key,
    required this.tx,
    this.categoryName,
    this.onVoid,
    this.canWrite = false,
  });

  final Transaction tx;
  final String? categoryName;
  final VoidCallback? onVoid;
  final bool canWrite;

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
    final dateStr = tx.transactionDate.toIso8601String().substring(0, 10);
    final subtitleParts = <String>[
      dateStr,
      if (categoryName != null && categoryName!.isNotEmpty) categoryName!,
      if (tx.reference != null && tx.reference!.isNotEmpty) tx.reference!,
    ];

    final color = tx.isIncome
        ? theme.colorScheme.primary
        : theme.colorScheme.error;

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        key: Key('tx_tile_${tx.id}'),
        leading: Icon(
          tx.isIncome ? Icons.trending_up : Icons.trending_down,
          color: tx.isReversal ? theme.colorScheme.outline : color,
        ),
        title: Row(
          children: [
            Expanded(child: Text(tx.description)),
            if (tx.isReversal)
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
        ),
        subtitle: Text(subtitleParts.join(' • ')),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              _fmtIdr(tx.signedAmount),
              style: theme.textTheme.titleSmall?.copyWith(
                color: tx.isReversal ? theme.colorScheme.outline : color,
              ),
            ),
            if (canWrite && !tx.isReversal) ...[
              const SizedBox(width: 4),
              IconButton(
                key: Key('tx_void_${tx.id}'),
                tooltip: 'Void',
                iconSize: 18,
                icon: const Icon(Icons.block),
                onPressed: onVoid,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 32,
                  height: 32,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
