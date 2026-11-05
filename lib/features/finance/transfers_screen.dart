import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../shared/utils/format.dart'; // ✅ Gunakan helper format
import 'finance_providers.dart';
import 'transfer.dart';
import 'widgets/transfer_form_sheet.dart';
import 'widgets/transfer_list_tile.dart';

class TransfersScreen extends ConsumerStatefulWidget {
  const TransfersScreen({super.key});

  @override
  ConsumerState<TransfersScreen> createState() => _TransfersScreenState();
}

class _TransfersScreenState extends ConsumerState<TransfersScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _void(BuildContext context, WidgetRef ref, Transfer tr) async {
    // (Logika void sama, dibungkus agar rapi)
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Void transfer?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Transfer ${formatIdr(tr.amount)} akan ditandai dibatalkan.'),
            const SizedBox(height: 12),
            TextField(key: const Key('transfer_void_reason'), controller: reasonCtrl, decoration: const InputDecoration(labelText: 'Alasan *'), maxLines: 2),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
          FilledButton(key: const Key('transfer_void_confirm'), onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Void')),
        ],
      ),
    );

    if (confirmed == true) {
      final reason = reasonCtrl.text.trim();
      if (reason.isEmpty) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alasan wajib.')));
      } else {
        try {
          await ref.read(transfersProvider.notifier).voidTransfer(transferId: tr.id, reason: reason);
        } catch (e) {
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canWrite = ref.watch(currentMemberProvider).value?.canWrite ?? false;
    final transfersAsync = ref.watch(transfersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Transfer', style: TextStyle(fontWeight: FontWeight.bold))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Cari catatan transfer...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: transfersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Gagal memuat: $e')),
              data: (list) {
                var filtered = list;
                if (_query.isNotEmpty) {
                  filtered = filtered.where((t) => (t.description ?? '').toLowerCase().contains(_query)).toList();
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.05), shape: BoxShape.circle),
                            child: Icon(Icons.swap_horiz, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                          ),
                          const SizedBox(height: 24),
                          Text('Belum ada transfer', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('Pindah dana antar akun akan muncul di sini.', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey), textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final tr = filtered[i];
                    return TransferListTile(transfer: tr, canWrite: canWrite, onVoid: () => _void(context, ref, tr));
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: canWrite
          ? FloatingActionButton.extended(
              onPressed: () => TransferFormSheet.show(context),
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Transfer'),
            )
          : null,
    );
  }
}
