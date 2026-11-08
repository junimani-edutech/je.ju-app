class ProductCategory {
  final String id;
  final String businessId;
  final String name;
  final String color;
  final int sortOrder;

  ProductCategory({
    required this.id,
    required this.businessId,
    required this.name,
    required this.color,
    required this.sortOrder,
  });

  factory ProductCategory.fromMap(Map<String, dynamic> m) => ProductCategory(
    id: m['id'] as String,
    businessId: m['business_id'] as String,
    name: m['name'] as String,
    color: m['color'] as String? ?? '#607D8B',
    sortOrder: (m['sort_order'] as num?)?.toInt() ?? 0,
  );

  Map<String, dynamic> toMap() => {
    'business_id': businessId,
    'name': name,
    'color': color,
    'sort_order': sortOrder,
  };
}
