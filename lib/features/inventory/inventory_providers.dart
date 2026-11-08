import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import 'inventory_item.dart';
import 'inventory_service.dart';
import 'stock_movement_providers.dart';

final inventoryServiceProvider = Provider<SupabaseInventoryService>((ref) => SupabaseInventoryService());

final inventoryItemsProvider = FutureProvider<List<InventoryItem>>((ref) async {
  final biz = await ref.watch(currentBusinessProvider.future);
  if (biz == null) return [];
  return ref.watch(inventoryServiceProvider).list(biz.id);
});

class InventoryNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> save(InventoryItem item) async {
    final biz = await ref.read(currentBusinessProvider.future);
    if (biz == null) return;
    
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final isNew = item.id.isEmpty;
      final initialStock = item.currentStock;

      // Saat create: insert item dengan current_stock (input user)
      // Saat edit: current_stock diabaikan (read-only di UI), tapi upsert perlu nilai
      //            jadi kita set 0 dan trigger akan recalculate dari movements
      final finalItem = InventoryItem(
        id: item.id.isEmpty ? '' : item.id,
        businessId: biz.id,
        name: item.name,
        category: item.category,
        categoryId: item.categoryId,
        unit: item.unit,
        currentStock: isNew ? initialStock : 0,
        minStock: item.minStock,
        pricePerUnit: item.pricePerUnit,
        isActive: item.isActive,
      );
      
      final saved = await ref.read(inventoryServiceProvider).upsert(finalItem);

      // Jika item baru dibuat dan ada stok awal, catat sebagai movement 'initial'
      if (isNew && initialStock > 0) {
        await ref.read(stockMovementServiceProvider).record(
              businessId: biz.id,
              itemId: saved.id,
              movementType: 'initial',
              quantity: initialStock,
              notes: 'Stok awal saat item dibuat',
            );
      }
      
      ref.invalidate(inventoryItemsProvider);
    });
  }

  Future<void> delete(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(inventoryServiceProvider).delete(id);
      ref.invalidate(inventoryItemsProvider);
    });
  }

  Future<void> archive(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(inventoryServiceProvider).setActive(id, false);
      ref.invalidate(inventoryItemsProvider);
    });
  }

  Future<void> restore(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(inventoryServiceProvider).setActive(id, true);
      ref.invalidate(inventoryItemsProvider);
    });
  }
}

final inventoryNotifierProvider = AsyncNotifierProvider<InventoryNotifier, void>(InventoryNotifier.new);
