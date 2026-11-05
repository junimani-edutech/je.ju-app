import 'product.dart';

abstract class ProductsService {
  Future<List<Product>> list({
    required String businessId,
    bool includeArchived = false,
  });
  Future<Product> create({
    required String businessId,
    required String name,
    required int price,
    String? description,
    String? category, // ✅ Tambahan
  });
  Future<Product> update({
    required String id,
    required String name,
    required int price,
    String? description,
    String? category, // ✅ Tambahan
  });
  Future<void> archive(String id);
  Future<void> restore(String id);
  Future<void> upsert(Product product);
}
