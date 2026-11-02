import 'package:flutter/material.dart';

import '../business_member_info.dart';

class MemberListTile extends StatelessWidget {
  const MemberListTile({super.key, required this.member, this.onTap});

  final BusinessMemberInfo member;
  final VoidCallback? onTap;

  String get _initial {
    final n = member.displayName.trim();
    if (n.isEmpty) return '?';
    return n.substring(0, 1).toUpperCase();
  }

  Color _roleColor(ColorScheme scheme) {
    switch (member.role) {
      case 'owner':
        return scheme.primary;
      case 'admin':
        return scheme.secondary;
      case 'cashier':
        return scheme.tertiary;
      case 'order_staff':
        return scheme.tertiaryContainer;
      default:
        return scheme.outline;
    }
  }

  String get _roleLabel {
    switch (member.role) {
      case 'owner':
        return 'Pemilik';
      case 'admin':
        return 'Admin';
      case 'cashier':
        return 'Kasir';
      case 'order_staff':
        return 'Staf Pesanan';
      case 'viewer':
        return 'Viewer';
      default:
        return member.role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = _roleColor(scheme);
    final dateStr = member.joinedAt?.toIso8601String().substring(0, 10);

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        key: Key('member_tile_${member.userId}'),
        leading: CircleAvatar(
          backgroundColor: color,
          child: Text(_initial, style: const TextStyle(color: Colors.white)),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(member.displayName, overflow: TextOverflow.ellipsis),
            ),
            if (member.isSelf) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Anda',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          [member.email, if (dateStr != null) 'bergabung $dateStr'].join(' • '),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _roleLabel,
            style: theme.textTheme.labelSmall?.copyWith(color: color),
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
