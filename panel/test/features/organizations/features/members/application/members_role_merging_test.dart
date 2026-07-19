import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/features/auth/application/auth.dart";
import "package:typewriter_panel/features/organizations/application/organization.dart";
import "package:typewriter_panel/features/organizations/features/members/application/members.dart";
import "package:typewriter_panel/features/organizations/features/members/application/roles.dart";
import "package:typewriter_panel/infrastructure/messaging/nats.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/converters.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_testkit/typewriter_testkit.dart";

import "support/members_test_support.dart";

void main() {
  group("OrganizationMembers.updateMemberRoles role merging", () {
    late MockNatsClient mockNats;

    setUp(() {
      mockNats = MockNatsClient();
    });

    tearDown(() {
      mockNats.dispose();
    });

    test("preserves non-assignable roles from current member", () async {
      final nonAssignableRole = createRole(
        id: "owner",
        name: "Owner",
        color: Colors.purple,
        assignable: false,
      );
      final assignableRole = createRole(
        id: "editor",
        name: "Editor",
        color: Colors.blue,
        assignable: true,
      );
      final newRole = createRole(
        id: "viewer",
        name: "Viewer",
        color: Colors.green,
        assignable: true,
      );

      final member = OrganizationMember(
        userId: recordId("user:m1"),
        name: "Test",
        email: "test@test.com",
        avatarUrl: "",
        roles: [nonAssignableRole, assignableRole],
        joinedAt: testTimestamp,
      );

      final container = ProviderContainer.test(
        overrides: [
          userIdProvider.overrideWith((ref) async => testUserId),
          organizationIdProvider.overrideWith((ref) => testOrganizationId),
          natsProvider.overrideWithValue(mockNats),
          organizationMembersProvider.overrideWith(
            () => MockMembersNotifier([member]),
          ),
          organizationRolesProvider.overrideWith(
            () =>
                MockRolesNotifier([nonAssignableRole, assignableRole, newRole]),
          ),
        ],
      );

      await readMembers(container);

      List<skir.RecordId>? capturedRoleIds;
      mockNats.registerHandler(memberUpdateSubject, (data) {
        final request = skir.UpdateOrganizationMemberRolesRequest.serializer
            .fromBytes(data);
        capturedRoleIds = request.roleIds.toList();
        return skir.UpdateOrganizationMemberRolesResponse.serializer.toBytes(
          skir.UpdateOrganizationMemberRolesResponse.createSuccess(
            userId: recordId("user:m1"),
            name: "Test",
            email: "test@test.com",
            avatarUrl: "",
            roles: [],
            joinedAt: testTimestamp,
          ),
        );
      });

      await container
          .read(organizationMembersProvider.notifier)
          .updateMemberRoles(recordId("user:m1"), [newRole]);

      expect(capturedRoleIds, isNotNull);
      expect(
        capturedRoleIds!.contains(recordId("organization_role:owner")),
        true,
      );
      expect(
        capturedRoleIds!.contains(recordId("organization_role:viewer")),
        true,
      );
      expect(
        capturedRoleIds!.contains(recordId("organization_role:editor")),
        false,
      );
    });

    test("only includes assignable roles from requested roles", () async {
      final assignableRole = createRole(
        id: "member",
        name: "Member",
        color: Colors.grey,
        assignable: true,
      );
      final nonAssignableRequested = createRole(
        id: "admin",
        name: "Admin",
        color: Colors.red,
        assignable: false,
      );

      final member = createMember(roles: [assignableRole]);

      final container = ProviderContainer.test(
        overrides: [
          userIdProvider.overrideWith((ref) async => testUserId),
          organizationIdProvider.overrideWith((ref) => testOrganizationId),
          natsProvider.overrideWithValue(mockNats),
          organizationMembersProvider.overrideWith(
            () => MockMembersNotifier([member]),
          ),
          organizationRolesProvider.overrideWith(
            () => MockRolesNotifier([assignableRole, nonAssignableRequested]),
          ),
        ],
      );

      await readMembers(container);

      List<skir.RecordId>? capturedRoleIds;
      mockNats.registerHandler(memberUpdateSubject, (data) {
        final request = skir.UpdateOrganizationMemberRolesRequest.serializer
            .fromBytes(data);
        capturedRoleIds = request.roleIds.toList();
        return skir.UpdateOrganizationMemberRolesResponse.serializer.toBytes(
          skir.UpdateOrganizationMemberRolesResponse.createSuccess(
            userId: recordId("user:m1"),
            name: "Test",
            email: "test@test.com",
            avatarUrl: "",
            roles: [],
            joinedAt: testTimestamp,
          ),
        );
      });

      await container
          .read(organizationMembersProvider.notifier)
          .updateMemberRoles(recordId("user:m1"), [
            assignableRole,
            nonAssignableRequested,
          ]);

      expect(capturedRoleIds, isNotNull);
      expect(
        capturedRoleIds!.contains(recordId("organization_role:member")),
        true,
      );
      expect(
        capturedRoleIds!.contains(recordId("organization_role:admin")),
        false,
      );
    });

    test("falls back to default roles when result is empty", () async {
      final defaultRole = OrganizationRole(
        roleId: recordId("organization_role:default"),
        name: "Default",
        color: Colors.grey,
        defaultRole: true,
        assignable: true,
      );
      final currentRole = createRole(
        id: "member",
        name: "Member",
        color: Colors.blue,
        assignable: true,
      );

      final member = createMember(roles: [currentRole]);

      final container = ProviderContainer.test(
        overrides: [
          userIdProvider.overrideWith((ref) async => testUserId),
          organizationIdProvider.overrideWith((ref) => testOrganizationId),
          natsProvider.overrideWithValue(mockNats),
          organizationMembersProvider.overrideWith(
            () => MockMembersNotifier([member]),
          ),
          organizationRolesProvider.overrideWith(
            () => MockRolesNotifier([defaultRole, currentRole]),
          ),
        ],
      );

      await readMembers(container);
      await readRoles(container);

      List<skir.RecordId>? capturedRoleIds;
      mockNats.registerHandler(memberUpdateSubject, (data) {
        final request = skir.UpdateOrganizationMemberRolesRequest.serializer
            .fromBytes(data);
        capturedRoleIds = request.roleIds.toList();
        return skir.UpdateOrganizationMemberRolesResponse.serializer.toBytes(
          skir.UpdateOrganizationMemberRolesResponse.createSuccess(
            userId: recordId("user:m1"),
            name: "Test",
            email: "test@test.com",
            avatarUrl: "",
            roles: [],
            joinedAt: testTimestamp,
          ),
        );
      });

      await container
          .read(organizationMembersProvider.notifier)
          .updateMemberRoles(recordId("user:m1"), []);

      expect(capturedRoleIds, isNotNull);
      expect(
        capturedRoleIds!.contains(recordId("organization_role:default")),
        true,
      );
      expect(capturedRoleIds!.length, 1);
    });
  });
}
