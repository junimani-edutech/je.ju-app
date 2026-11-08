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
    String? category,
    String? categoryId,
  });
  Future<Product> update({
    required String id,
    required String name,
    required int price,
    String? description,
    String? category,
    String? categoryId,
  });
  Future<void> archive(String id);
  Future<void> restore(String id);
  Future<void> upsert(Product product);
  Future<bool> canHardDelete(String id);
  Future<void> delete(String id);
}
