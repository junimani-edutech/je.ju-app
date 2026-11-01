import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../payments/payment.dart' show Account;
import '../finance_providers.dart';
import '../transfer.dart';

class TransferListTile extends ConsumerWidget {
  const TransferListTile({
    super.key,
    required this.transfer,
    this.canWrite = false,
    this.onVoid,
  });

  final Transfer transfer;
  final bool canWrite;
  final VoidCallback? onVoid;

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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accounts =
        ref.watch(financeAccountsProvider).value ?? const <Account>[];
    String nameFor(String id) {
      for (final a in accounts) {
        if (a.id == id) return a.name;
      }
      return '—';
    }

    final dateStr = transfer.transferDate.toIso8601String().substring(0, 10);
    final cancelled = transfer.status == 'cancelled';

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        key: Key('transfer_tile_${transfer.id}'),
        leading: Icon(
          Icons.swap_horiz,
          color: cancelled
              ? theme.colorScheme.outline
              : theme.colorScheme.primary,
        ),
        title: Text(
          '${nameFor(transfer.fromAccountId)} → '
          '${nameFor(transfer.toAccountId)}',
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
            Text(dateStr),
            if (transfer.description != null &&
                transfer.description!.isNotEmpty)
              Text(transfer.description!),
            if (cancelled)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('Dibatalkan'),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(_fmtIdr(transfer.amount), style: theme.textTheme.titleSmall),
            if (canWrite && !cancelled) ...[
              const SizedBox(width: 4),
              IconButton(
                key: Key('transfer_void_${transfer.id}'),
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
