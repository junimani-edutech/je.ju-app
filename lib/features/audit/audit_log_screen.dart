import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/utils/format.dart';
import 'audit_log_providers.dart';

class AuditLogScreen extends ConsumerWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final logsAsync = ref.watch(auditLogsProvider);
    final membersAsync = ref.watch(memberNamesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Log Aktivitas', style: TextStyle(fontWeight: FontWeight.bold))),
      body: logsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat log: $e')),
        data: (logs) {
          if (logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('Belum ada aktivitas', style: theme.textTheme.titleMedium),
                ],
              ),
            );
          }

          final actorMap = membersAsync.value ?? {};

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (ctx, i) {
              final log = logs[i];
              final actorName = log.actorId != null ? (actorMap[log.actorId] ?? 'User') : 'Sistem';
              
              // Format aksi menjadi lebih manusiawi (mis: void_payment -> Void Pembayaran)
              final actionLabel = log.action
                  .replaceAll('_', ' ')
                  .split(' ')
                  .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
                  .join(' ');

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    child: Icon(_iconFor(log.entityType), color: theme.colorScheme.primary, size: 20),
                  ),
                  title: Text(actionLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text('Oleh: $actorName • ${formatDateId(log.createdAt)} ${log.createdAt.hour}:${log.createdAt.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 11)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (log.entityId != null) Text('ID Entitas: ${log.entityId}', style: const TextStyle(fontSize: 10, fontFamily: 'monospace')),
                          const SizedBox(height: 8),
                          if (log.payload != null && log.payload!.isNotEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                              child: Text(log.payload.toString(), style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _iconFor(String entityType) {
    switch (entityType) {
      case 'order': return Icons.receipt_long;
      case 'payment': return Icons.payments;
      case 'transaction': return Icons.swap_horiz;
      case 'business': return Icons.store;
      case 'invitation': return Icons.person_add;
      default: return Icons.history;
    }
  }
}
