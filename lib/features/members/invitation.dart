class Invitation {
  const Invitation({
    required this.id,
    required this.businessId,
    required this.email,
    required this.role,
    required this.token,
    required this.status,
    required this.expiresAt,
    required this.createdAt,
  });

  final String id;
  final String businessId;
  final String email;
  final String role;
  final String token;
  final String status;
  final DateTime expiresAt;
  final DateTime createdAt;

  bool get isPending => status == 'pending';
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory Invitation.fromMap(Map<String, dynamic> m) => Invitation(
    id: m['id'] as String,
    businessId: m['business_id'] as String,
    email: m['email'] as String,
    role: m['role'] as String,
    token: m['token'] as String,
    status: m['status'] as String,
    expiresAt: DateTime.parse(m['expires_at'] as String),
    createdAt: DateTime.parse(m['created_at'] as String),
  );
}

class CreatedInvitation {
  const CreatedInvitation({
    required this.invitationId,
    required this.token,
    required this.expiresAt,
  });
  final String invitationId;
  final String token;
  final DateTime expiresAt;

  factory CreatedInvitation.fromMap(Map<String, dynamic> m) =>
      CreatedInvitation(
        invitationId: m['invitation_id'] as String,
        token: m['token'] as String,
        expiresAt: DateTime.parse(m['expires_at'] as String),
      );
}
