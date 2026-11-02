import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeju_app/core/models/app_user.dart';
import 'package:jeju_app/core/models/business.dart';
import 'package:jeju_app/core/models/business_member.dart';
import 'package:jeju_app/core/providers.dart';
import 'package:jeju_app/features/members/business_member_info.dart';
import 'package:jeju_app/features/members/invitation.dart';
import 'package:jeju_app/features/members/members_providers.dart';
import 'package:jeju_app/features/members/members_screen.dart';

import '../../fake/fake_services.dart';

const _biz = Business(
  id: 'biz-1',
  name: 'Test Biz',
  timezone: 'Asia/Jakarta',
  currency: 'IDR',
);

const _ownerMember = BusinessMember(
  id: 'm-1',
  businessId: 'biz-1',
  userId: 'u-1',
  role: 'owner',
  status: 'active',
);

const _viewerMember = BusinessMember(
  id: 'm-2',
  businessId: 'biz-1',
  userId: 'u-1',
  role: 'viewer',
  status: 'active',
);

BusinessMemberInfo _memberInfo(
  String userId,
  String email,
  String role, {
  bool isSelf = false,
}) => BusinessMemberInfo(
  userId: userId,
  email: email,
  role: role,
  status: 'active',
  isSelf: isSelf,
);

Invitation _invitation(String id, String email) => Invitation(
  id: id,
  businessId: 'biz-1',
  email: email,
  role: 'cashier',
  token: 'tok-$id',
  status: 'pending',
  expiresAt: DateTime.now().add(const Duration(days: 3)),
  createdAt: DateTime.now(),
);

class _ThrowingMembersService extends FakeMembersService {
  _ThrowingMembersService()
    : super(initialMembers: const [], initialInvitations: const []);

  @override
  Future<List<BusinessMemberInfo>> listMembers(String businessId) async {
    throw Exception('mock failure');
  }
}

Widget _wrap({
  required FakeMembersService members,
  required BusinessMember member,
}) {
  return ProviderScope(
    overrides: [
      authServiceProvider.overrideWithValue(
        FakeAuthService(
          initialUser: const AppUser(id: 'u-1', email: 'u@example.com'),
        ),
      ),
      businessServiceProvider.overrideWithValue(
        FakeBusinessService(
          initialHasBusiness: true,
          initialBusinesses: const [_biz],
          initialMember: member,
        ),
      ),
      membersServiceProvider.overrideWithValue(members),
    ],
    child: const MaterialApp(home: MembersScreen()),
  );
}

void _viewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(500, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('viewer melihat list anggota tanpa FAB', (tester) async {
    _viewport(tester);
    final fake = FakeMembersService(
      initialMembers: [
        _memberInfo('u-1', 'u@example.com', 'viewer', isSelf: true),
        _memberInfo('u-2', 'other@example.com', 'owner'),
      ],
    );
    await tester.pumpWidget(_wrap(members: fake, member: _viewerMember));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('members_invite_fab')), findsNothing);
    expect(find.byKey(const Key('member_tile_u-1')), findsOneWidget);
    expect(find.byKey(const Key('member_tile_u-2')), findsOneWidget);
  });

  testWidgets('owner melihat FAB undang + list anggota', (tester) async {
    _viewport(tester);
    final fake = FakeMembersService(
      initialMembers: [
        _memberInfo('u-1', 'u@example.com', 'owner', isSelf: true),
      ],
    );
    await tester.pumpWidget(_wrap(members: fake, member: _ownerMember));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('members_invite_fab')), findsOneWidget);
    expect(find.byKey(const Key('member_tile_u-1')), findsOneWidget);
  });

  testWidgets('owner tap FAB membuka InviteDialog', (tester) async {
    _viewport(tester);
    final fake = FakeMembersService(
      initialMembers: [
        _memberInfo('u-1', 'u@example.com', 'owner', isSelf: true),
      ],
    );
    await tester.pumpWidget(_wrap(members: fake, member: _ownerMember));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('members_invite_fab')));
    await tester.pumpAndSettle();

    expect(find.text('Undang Anggota'), findsOneWidget);
    expect(find.byKey(const Key('invite_email')), findsOneWidget);
    expect(find.byKey(const Key('invite_submit')), findsOneWidget);
  });

  testWidgets('list pending invitations ditampilkan', (tester) async {
    _viewport(tester);
    final fake = FakeMembersService(
      initialMembers: [
        _memberInfo('u-1', 'u@example.com', 'owner', isSelf: true),
      ],
      initialInvitations: [
        _invitation('inv-1', 'new@example.com'),
        _invitation('inv-2', 'other@example.com'),
      ],
    );
    await tester.pumpWidget(_wrap(members: fake, member: _ownerMember));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('invitation_tile_inv-1')), findsOneWidget);
    expect(find.byKey(const Key('invitation_tile_inv-2')), findsOneWidget);
    expect(find.text('new@example.com'), findsOneWidget);
  });

  testWidgets('error state saat load anggota gagal', (tester) async {
    _viewport(tester);
    final fake = _ThrowingMembersService();
    await tester.pumpWidget(_wrap(members: fake, member: _ownerMember));
    await tester.pumpAndSettle();

    expect(find.textContaining('Gagal memuat anggota'), findsWidgets);
  });
}
