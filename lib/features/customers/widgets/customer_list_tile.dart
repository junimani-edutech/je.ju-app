import 'package:flutter/material.dart';

import '../customer.dart';

class CustomerListTile extends StatelessWidget {
  const CustomerListTile({
    super.key,
    required this.customer,
    required this.canWrite,
    this.onTap,
    this.onArchive,
    this.onRestore,
  });

  final Customer customer;
  final bool canWrite;
  final VoidCallback? onTap;
  final VoidCallback? onArchive;
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    final initial = customer.name.isNotEmpty
        ? customer.name.substring(0, 1).toUpperCase()
        : '?';

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        key: Key('customer_tile_${customer.id}'),
        leading: CircleAvatar(child: Text(initial)),
        title: Text(customer.name),
        subtitle: _buildSubtitle(),
        onTap: onTap,
        trailing: canWrite
            ? PopupMenuButton<String>(
                key: Key('customer_menu_${customer.id}'),
                tooltip: 'Aksi',
                onSelected: (v) {
                  switch (v) {
                    case 'edit':
                      onTap?.call();
                      break;
                    case 'archive':
                      onArchive?.call();
                      break;
                    case 'restore':
                      onRestore?.call();
                      break;
                  }
                },
                itemBuilder: (_) {
                  final items = <PopupMenuEntry<String>>[
                    const PopupMenuItem(value: 'edit', child: Text('Ubah')),
                  ];
                  if (customer.isArchived) {
                    items.add(
                      const PopupMenuItem(
                        value: 'restore',
                        child: Text('Pulihkan'),
                      ),
                    );
                  } else {
                    items.add(
                      const PopupMenuItem(
                        value: 'archive',
                        child: Text('Arsipkan'),
                      ),
                    );
                  }
                  return items;
                },
              )
            : null,
      ),
    );
  }

  Widget? _buildSubtitle() {
    final parts = <Widget>[];
    if (customer.phone != null && customer.phone!.isNotEmpty) {
      parts.add(Text(customer.phone!));
    }
    if (customer.isArchived) {
      if (parts.isNotEmpty) parts.add(const SizedBox(height: 4));
      parts.add(
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.archive_outlined, size: 14),
            SizedBox(width: 4),
            Text('Arsip'),
          ],
        ),
      );
    }
    if (parts.isEmpty) return null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: parts,
    );
  }
}
