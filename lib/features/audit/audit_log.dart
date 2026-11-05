class AuditLog {
  final String id;
  final String businessId;
  final String? actorId;
  final String action;
  final String entityType;
  final String? entityId;
  final Map<String, dynamic>? payload;
  final DateTime createdAt;

  AuditLog({
    required this.id,
    required this.businessId,
    this.actorId,
    required this.action,
    required this.entityType,
    this.entityId,
    this.payload,
    required this.createdAt,
  });

  factory AuditLog.fromMap(Map<String, dynamic> m) => AuditLog(
    id: m['id'] as String,
    businessId: m['business_id'] as String,
    actorId: m['actor_id'] as String?,
    action: m['action'] as String,
    entityType: m['entity_type'] as String,
    entityId: m['entity_id'] as String?,
    payload: m['payload'] != null ? Map<String, dynamic>.from(m['payload'] as Map) : null,
    createdAt: DateTime.parse(m['created_at'] as String),
  );
}
