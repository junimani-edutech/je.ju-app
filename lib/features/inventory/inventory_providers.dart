import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import 'inventory_item.dart';
import 'inventory_service.dart';

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
      final finalItem = InventoryItem(
        id: item.id.isEmpty ? '' : item.id,
        businessId: biz.id,
        name: item.name,
        category: item.category,
        unit: item.unit,
        currentStock: item.currentStock,
        minStock: item.minStock,
        pricePerUnit: item.pricePerUnit,
      );
      await ref.read(inventoryServiceProvider).upsert(finalItem);
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
}

final inventoryNotifierProvider = AsyncNotifierProvider<InventoryNotifier, void>(InventoryNotifier.new);
