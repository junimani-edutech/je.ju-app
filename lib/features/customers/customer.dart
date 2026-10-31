class Customer {
  const Customer({
    required this.id,
    required this.businessId,
    required this.name,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.phone,
    this.email,
    this.address,
    this.notes,
  });

  final String id;
  final String businessId;
  final String name;
  final String status; // 'active' | 'archived'
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? phone;
  final String? email;
  final String? address;
  final String? notes;

  bool get isArchived => status == 'archived';

  factory Customer.fromMap(Map<String, dynamic> m) => Customer(
    id: m['id'] as String,
    businessId: m['business_id'] as String,
    name: m['name'] as String,
    status: m['status'] as String,
    createdAt: DateTime.parse(m['created_at'] as String),
    updatedAt: DateTime.parse(m['updated_at'] as String),
    phone: m['phone'] as String?,
    email: m['email'] as String?,
    address: m['address'] as String?,
    notes: m['notes'] as String?,
  );
}
