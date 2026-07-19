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

    test("uses server response to update member", () async {
      final role = createRole(
        id: "member",
        name: "Member",
        color: Colors.grey,
        assignable: true,
      );

      final member = OrganizationMember(
        userId: recordId("user:m1"),
        name: "Original Name",
        email: "test@test.com",
        avatarUrl: "",
        roles: [role],
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
            () => MockRolesNotifier([role]),
          ),
        ],
      );

      await readMembers(container);

      mockNats.registerHandler(
        memberUpdateSubject,
        (data) => skir.UpdateOrganizationMemberRolesResponse.serializer.toBytes(
          skir.UpdateOrganizationMemberRolesResponse.createSuccess(
            userId: recordId("user:m1"),
            name: "Updated Name",
            email: "test@test.com",
            avatarUrl: "",
            roles: [],
            joinedAt: testTimestamp,
          ),
        ),
      );

      await container
          .read(organizationMembersProvider.notifier)
          .updateMemberRoles(recordId("user:m1"), [role]);

      final currentState = container.read(organizationMembersProvider);
      expect(currentState.value, isNotNull);
      expect(currentState.value!.first.name, "Updated Name");
    });
  });
}
