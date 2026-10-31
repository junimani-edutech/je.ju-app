class BusinessMember {
  const BusinessMember({
    required this.id,
    required this.businessId,
    required this.userId,
    required this.role,
    required this.status,
  });

  final String id;
  final String businessId;
  final String userId;
  final String role;
  final String status;

  /// Owner / admin / cashier / order_staff boleh menulis entitas transaksi.
  /// Viewer hanya membaca.
  bool get canWrite =>
      status == 'active' &&
      const {'owner', 'admin', 'cashier', 'order_staff'}.contains(role);

  factory BusinessMember.fromMap(Map<String, dynamic> m) => BusinessMember(
    id: m['id'] as String,
    businessId: m['business_id'] as String,
    userId: m['user_id'] as String,
    role: m['role'] as String,
    status: m['status'] as String,
  );
}
