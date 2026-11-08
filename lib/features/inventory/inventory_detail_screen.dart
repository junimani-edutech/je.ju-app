import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/utils/format.dart';
import 'inventory_providers.dart';
import 'stock_movement.dart';
import 'stock_movement_providers.dart';
import 'widgets/inventory_form_sheet.dart';
import 'widgets/stock_movement_form_sheet.dart';

class InventoryDetailScreen extends ConsumerWidget {
  final String itemId;

  const InventoryDetailScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final itemsAsync = ref.watch(inventoryItemsProvider);
    final movementsAsync = ref.watch(stockMovementsProvider(itemId));

    return itemsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Gagal memuat: $e')),
      ),
      data: (items) {
        final item = items.where((i) => i.id == itemId).firstOrNull;
        if (item == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Item Tidak Ditemukan')),
            body: const Center(child: Text('Item sudah dihapus atau tidak tersedia.')),
          );
        }
        final isLow = item.isLowStock && item.isActive;
        return Scaffold(
          appBar: AppBar(
            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                tooltip: 'Ubah Info Item',
                icon: const Icon(Icons.edit),
                onPressed: () => InventoryFormSheet.show(context, initial: item),
              ),
            ],
          ),
          body: Column(
            children: [
              // Info Card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isLow ? Colors.red.withValues(alpha: 0.05) : theme.colorScheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isLow ? Colors.red.withValues(alpha: 0.3) : theme.colorScheme.primary.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Stok Saat Ini', style: theme.textTheme.bodySmall),
                        if (isLow)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(6)),
                            child: const Text('MENIPIS', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        style: DefaultTextStyle.of(context).style,
                        children: [
                          TextSpan(
                            text: '${item.currentStock}',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: isLow ? Colors.red : theme.colorScheme.primary,
                            ),
                          ),
                          TextSpan(
                            text: ' ${item.unit}',
                            style: TextStyle(fontSize: 20, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                          ),
                        ],
                      ),
                    ),
                    if (item.minStock > 0)
                      Text('Minimum: ${item.minStock} ${item.unit}', style: theme.textTheme.bodySmall),
                    const Divider(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _InfoTile(
                            label: 'Kategori',
                            value: item.category ?? 'Umum',
                            icon: Icons.folder_outlined,
                          ),
                        ),
                        Expanded(
                          child: _InfoTile(
                            label: 'Harga/Satuan',
                            value: formatIdr(item.pricePerUnit),
                            icon: Icons.attach_money,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Tombol Aksi Cepat
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.add_circle,
                        label: 'Stok Masuk',
                        color: Colors.green,
                        onTap: () => StockMovementFormSheet.show(context, item: item, initialType: 'purchase'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.remove_circle,
                        label: 'Pemakaian',
                        color: Colors.blue,
                        onTap: () => StockMovementFormSheet.show(context, item: item, initialType: 'usage'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.delete_outline,
                        label: 'Rusak/Basi',
                        color: Colors.red,
                        onTap: () => StockMovementFormSheet.show(context, item: item, initialType: 'waste'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.tune,
                        label: 'Penyesuaian',
                        color: Colors.orange,
                        onTap: () => StockMovementFormSheet.show(context, item: item, initialType: 'adjustment'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Judul Riwayat
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.history, size: 20),
                    const SizedBox(width: 8),
                    Text('Riwayat Pergerakan', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              
              // Timeline Movement
              Expanded(
                child: movementsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Gagal memuat riwayat: $e')),
                  data: (movements) {
                    if (movements.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.timeline, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text('Belum ada riwayat', style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
                              const SizedBox(height: 8),
                              Text('Pergerakan stok akan muncul di sini.', style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: movements.length,
                      itemBuilder: (ctx, i) {
                        final mv = movements[i];
                        return _MovementTile(movement: mv, unit: item.unit);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoTile({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
            const SizedBox(width: 4),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 2),
        Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MovementTile extends StatelessWidget {
  final StockMovement movement;
  final String unit;

  const _MovementTile({required this.movement, required this.unit});

  Color get _color {
    switch (movement.movementType) {
      case 'purchase':
        return Colors.green;
      case 'usage':
        return Colors.blue;
      case 'waste':
        return Colors.red;
      case 'adjustment':
        return Colors.orange;
      case 'initial':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData get _icon {
    switch (movement.movementType) {
      case 'purchase':
        return Icons.add_circle;
      case 'usage':
        return Icons.remove_circle;
      case 'waste':
        return Icons.delete_outline;
      case 'adjustment':
        return Icons.tune;
      case 'initial':
        return Icons.flag;
      default:
        return Icons.circle;
    }
  }

  String _fmtQty() {
    final abs = movement.quantity.abs();
    final sign = movement.quantity > 0 ? '+' : '';
    final num = abs == abs.toInt() ? abs.toInt().toString() : abs.toString();
    return '$sign$num';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = formatDateId(movement.createdAt);
    final timeStr = '${movement.createdAt.hour.toString().padLeft(2, '0')}:${movement.createdAt.minute.toString().padLeft(2, '0')}';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: _color.withValues(alpha: 0.1),
              child: Icon(_icon, color: _color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(movement.typeLabel, style: TextStyle(fontWeight: FontWeight.bold, color: _color)),
                      const SizedBox(width: 8),
                      Text(
                        '${_fmtQty()} $unit',
                        style: TextStyle(fontWeight: FontWeight.bold, color: _color, fontSize: 16),
                      ),
                    ],
                  ),
                  if (movement.notes != null && movement.notes!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(movement.notes!, style: theme.textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('$dateStr • $timeStr', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey, fontSize: 11)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
