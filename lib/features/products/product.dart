class Product {
  const Product({
    required this.id,
    required this.businessId,
    required this.name,
    required this.price,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.category,
  });
  
  final String id;
  final String businessId;
  final String name;
  final int price;
  final String status; // 'active' | 'archived'
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? description;
  final String? category; // ✅ Tambahan Kategori

  bool get isActive => status == 'active';

  factory Product.fromMap(Map<String, dynamic> m) => Product(
    id: m['id'] as String,
    businessId: m['business_id'] as String,
    name: m['name'] as String,
    price: (m['price'] as num).toInt(),
    status: m['status'] as String,
    description: m['description'] as String?,
    category: m['category'] as String?,
    createdAt: DateTime.parse(m['created_at'] as String),
    updatedAt: DateTime.parse(m['updated_at'] as String),
  );
}
