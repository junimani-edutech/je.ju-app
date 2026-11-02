import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'business_member_info.dart';
import 'invitation.dart';
import 'members_providers.dart';
import 'widgets/invitation_list_tile.dart';
import 'widgets/invite_dialog.dart';
import 'widgets/member_list_tile.dart';

class MembersScreen extends ConsumerWidget {
  const MembersScreen({super.key});

  Future<void> _revoke(
    BuildContext context,
    WidgetRef ref,
    Invitation inv,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cabut undangan?'),
        content: Text(
          'Undangan untuk ${inv.email} akan dicabut. '
          'Link undangan tidak bisa dipakai lagi.',
        ),
        actions: [
          TextButton(
            key: const Key('revoke_invitation_cancel'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            key: const Key('revoke_invitation_confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cabut'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(membersControllerProvider).revokeInvitation(inv.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Undangan dicabut.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }

  Future<void> _openInvite(BuildContext context) async {
    await InviteDialog.show(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final member = ref.watch(currentMemberProvider).value;
    final canManage =
        member != null && (member.role == 'owner' || member.role == 'admin');
    final membersAsync = ref.watch(membersProvider);
    final invitationsAsync = ref.watch(pendingInvitationsProvider);

    Future<void> refresh() async {
      ref.invalidate(membersProvider);
      ref.invalidate(pendingInvitationsProvider);
      ref.invalidate(currentMemberProvider);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Anggota & Undangan'),
        actions: [
          IconButton(
            key: const Key('members_refresh'),
            tooltip: 'Muat ulang',
            icon: const Icon(Icons.refresh),
            onPressed: refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Anggota', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            _buildMembers(context, ref, membersAsync),
            const SizedBox(height: 24),
            Text('Undangan Pending', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            _buildInvitations(
              context,
              ref,
              invitationsAsync,
              canManage: canManage,
            ),
          ],
        ),
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              key: const Key('members_invite_fab'),
              onPressed: () => _openInvite(context),
              icon: const Icon(Icons.person_add),
              label: const Text('Undang'),
            )
          : null,
    );
  }

  Widget _buildMembers(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<BusinessMemberInfo>> async,
  ) {
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text('Gagal memuat anggota: $e'),
      ),
      data: (list) {
        if (list.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Belum ada anggota.'),
          );
        }
        return Column(
          children: [
            for (final m in list)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: MemberListTile(member: m),
              ),
          ],
        );
      },
    );
  }

  Widget _buildInvitations(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Invitation>> async, {
    required bool canManage,
  }) {
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text('Gagal memuat undangan: $e'),
      ),
      data: (list) {
        if (list.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              canManage
                  ? 'Belum ada undangan pending. Tekan Undang untuk menambah.'
                  : 'Belum ada undangan pending.',
            ),
          );
        }
        return Column(
          children: [
            for (final inv in list)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: InvitationListTile(
                  invitation: inv,
                  canRevoke: canManage,
                  onRevoke: () => _revoke(context, ref, inv),
                ),
              ),
          ],
        );
      },
    );
  }
}
