import 'package:supabase_flutter/supabase_flutter.dart';

import 'business_member_info.dart';
import 'invitation.dart';
import 'members_service.dart';

class SupabaseMembersService implements MembersService {
  SupabaseMembersService(this._client);
  final SupabaseClient _client;

  @override
  Future<List<BusinessMemberInfo>> listMembers(String businessId) async {
    final rows = await _client.rpc(
      'list_business_members',
      params: {'p_business_id': businessId},
    );
    return (rows as List)
        .map((e) => BusinessMemberInfo.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Invitation>> listPendingInvitations(String businessId) async {
    final rows = await _client
        .from('business_invitations')
        .select()
        .eq('business_id', businessId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => Invitation.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<CreatedInvitation> createInvitation({
    required String businessId,
    required String email,
    required String role,
  }) async {
    final rows = await _client.rpc(
      'create_invitation',
      params: {'p_business_id': businessId, 'p_email': email, 'p_role': role},
    );
    final first = (rows as List).first as Map<String, dynamic>;
    return CreatedInvitation.fromMap(first);
  }

  @override
  Future<void> revokeInvitation(String invitationId) async {
    await _client.rpc(
      'revoke_invitation',
      params: {'p_invitation_id': invitationId},
    );
  }

  @override
  Future<String> acceptInvitation(String token) async {
    final result = await _client.rpc(
      'accept_invitation',
      params: {'p_token': token},
    );
    return result as String;
  }
}
