class Category {
  const Category({
    required this.id,
    required this.businessId,
    required this.type,
    required this.name,
    required this.status,
  });

  final String id;
  final String businessId;
  final String type; // 'income' | 'expense'
  final String name;
  final String status; // 'active' | 'archived'

  factory Category.fromMap(Map<String, dynamic> m) => Category(
    id: m['id'] as String,
    businessId: m['business_id'] as String,
    type: m['type'] as String,
    name: m['name'] as String,
    status: m['status'] as String,
  );
}
