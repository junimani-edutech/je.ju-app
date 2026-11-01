import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'finance_providers.dart';
import 'transfer.dart';
import 'widgets/transfer_form_sheet.dart';
import 'widgets/transfer_list_tile.dart';

class TransfersScreen extends ConsumerWidget {
  const TransfersScreen({super.key});

  Future<void> _void(BuildContext context, WidgetRef ref, Transfer tr) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Void transfer?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Transfer ${tr.amount} akan ditandai dibatalkan. '
              'Data tetap tersimpan.',
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('transfer_void_reason'),
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
            key: const Key('transfer_void_confirm'),
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
              .read(transfersProvider.notifier)
              .voidTransfer(transferId: tr.id, reason: reason);
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
    final canWrite = ref.watch(currentMemberProvider).value?.canWrite ?? false;
    final transfersAsync = ref.watch(transfersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Transfer')),
      body: transfersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Gagal memuat: $e'),
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.swap_horiz,
                      size: 56,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Belum ada transfer',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 88),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 4),
            itemBuilder: (_, i) {
              final tr = list[i];
              return TransferListTile(
                transfer: tr,
                canWrite: canWrite,
                onVoid: () => _void(context, ref, tr),
              );
            },
          );
        },
      ),
      floatingActionButton: canWrite
          ? FloatingActionButton.extended(
              key: const Key('transfer_fab'),
              onPressed: () => TransferFormSheet.show(context),
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Transfer'),
            )
          : null,
    );
  }
}
