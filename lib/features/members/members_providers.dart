import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'business_member_info.dart';
import 'invitation.dart';
import 'members_service.dart';

final membersServiceProvider = Provider<MembersService>((ref) {
  throw UnimplementedError('membersServiceProvider belum di-override');
});

final membersProvider = FutureProvider<List<BusinessMemberInfo>>((ref) async {
  final biz = await ref.watch(currentBusinessProvider.future);
  if (biz == null) return const <BusinessMemberInfo>[];
  return ref.watch(membersServiceProvider).listMembers(biz.id);
});

final pendingInvitationsProvider = FutureProvider<List<Invitation>>((
  ref,
) async {
  final biz = await ref.watch(currentBusinessProvider.future);
  if (biz == null) return const <Invitation>[];
  return ref.watch(membersServiceProvider).listPendingInvitations(biz.id);
});

class MembersController {
  MembersController(this._ref);
  final Ref _ref;

  Future<CreatedInvitation> createInvitation({
    required String email,
    required String role,
  }) async {
    final biz = await _ref.read(currentBusinessProvider.future);
    if (biz == null) throw StateError('Tidak ada bisnis aktif');
    final created = await _ref
        .read(membersServiceProvider)
        .createInvitation(businessId: biz.id, email: email, role: role);
    _ref.invalidate(pendingInvitationsProvider);
    return created;
  }

  Future<void> revokeInvitation(String invitationId) async {
    await _ref.read(membersServiceProvider).revokeInvitation(invitationId);
    _ref.invalidate(pendingInvitationsProvider);
  }

  Future<String> acceptInvitation(String token) async {
    final bizId = await _ref
        .read(membersServiceProvider)
        .acceptInvitation(token);
    _ref.invalidate(currentBusinessProvider);
    _ref.invalidate(hasBusinessProvider);
    _ref.invalidate(membersProvider);
    return bizId;
  }
}

final membersControllerProvider = Provider<MembersController>(
  (ref) => MembersController(ref),
);
