import 'package:flutter/material.dart';

import '../invitation.dart';

class InvitationListTile extends StatelessWidget {
  const InvitationListTile({
    super.key,
    required this.invitation,
    this.onRevoke,
    this.canRevoke = false,
  });

  final Invitation invitation;
  final VoidCallback? onRevoke;
  final bool canRevoke;

  String get _roleLabel {
    switch (invitation.role) {
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
        return invitation.role;
    }
  }

  String get _expiryLabel {
    final now = DateTime.now();
    final diff = invitation.expiresAt.difference(now);
    if (diff.isNegative) return 'Kedaluwarsa';
    if (diff.inDays > 0) return '${diff.inDays} hari lagi';
    if (diff.inHours > 0) return '${diff.inHours} jam lagi';
    return '${diff.inMinutes} menit lagi';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        key: Key('invitation_tile_${invitation.id}'),
        leading: const Icon(Icons.mail_outline),
        title: Text(invitation.email),
        subtitle: Text('$_roleLabel • $_expiryLabel'),
        trailing: canRevoke
            ? IconButton(
                key: Key('invitation_revoke_${invitation.id}'),
                tooltip: 'Cabut undangan',
                icon: const Icon(Icons.block),
                onPressed: onRevoke,
              )
            : Icon(Icons.hourglass_empty, color: theme.colorScheme.outline),
      ),
    );
  }
}
