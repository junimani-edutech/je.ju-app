class BusinessMemberInfo {
  const BusinessMemberInfo({
    required this.userId,
    required this.email,
    required this.role,
    required this.status,
    required this.isSelf,
    this.fullName,
    this.avatarUrl,
    this.joinedAt,
  });

  final String userId;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final String role;
  final String status;
  final DateTime? joinedAt;
  final bool isSelf;

  bool get isActive => status == 'active';
  bool get isOwner => role == 'owner';
  bool get isAdmin => role == 'admin';

  String get displayName {
    final n = fullName?.trim();
    if (n != null && n.isNotEmpty) return n;
    return email;
  }

  factory BusinessMemberInfo.fromMap(Map<String, dynamic> m) =>
      BusinessMemberInfo(
        userId: m['user_id'] as String,
        email: (m['email'] as String?) ?? '',
        fullName: m['full_name'] as String?,
        avatarUrl: m['avatar_url'] as String?,
        role: m['role'] as String,
        status: m['status'] as String,
        joinedAt: m['joined_at'] == null
            ? null
            : DateTime.parse(m['joined_at'] as String),
        isSelf: (m['is_self'] as bool?) ?? false,
      );
}
