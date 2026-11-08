class InventoryItem {
  final String id;
  final String businessId;
  final String name;
  final String? category;
  final String? categoryId;
  final String unit;
  final double currentStock;
  final double minStock;
  final int pricePerUnit;
  final bool isActive;

  InventoryItem({
    required this.id,
    required this.businessId,
    required this.name,
    this.category,
    this.categoryId,
    required this.unit,
    required this.currentStock,
    required this.minStock,
    required this.pricePerUnit,
    this.isActive = true,
  });

  bool get isLowStock => currentStock <= minStock;

  factory InventoryItem.fromMap(Map<String, dynamic> m) => InventoryItem(
    id: m['id'] as String,
    businessId: m['business_id'] as String,
    name: m['name'] as String,
    category: m['category'] as String?,
    categoryId: m['category_id'] as String?,
    unit: m['unit'] as String,
    currentStock: (m['current_stock'] as num).toDouble(),
    minStock: (m['min_stock'] as num).toDouble(),
    pricePerUnit: (m['price_per_unit'] as num).toInt(),
    isActive: m['is_active'] as bool? ?? true,
  );

  Map<String, dynamic> toMap() => {
    'business_id': businessId,
    'name': name,
    'category': category,
    'category_id': categoryId,
    'unit': unit,
    'current_stock': currentStock,
    'min_stock': minStock,
    'price_per_unit': pricePerUnit,
    'is_active': isActive,
  };
}
