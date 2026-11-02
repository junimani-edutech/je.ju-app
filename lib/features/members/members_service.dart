import 'business_member_info.dart';
import 'invitation.dart';

abstract class MembersService {
  Future<List<BusinessMemberInfo>> listMembers(String businessId);
  Future<List<Invitation>> listPendingInvitations(String businessId);

  Future<CreatedInvitation> createInvitation({
    required String businessId,
    required String email,
    required String role,
  });

  Future<void> revokeInvitation(String invitationId);

  Future<String> acceptInvitation(String token);
}
