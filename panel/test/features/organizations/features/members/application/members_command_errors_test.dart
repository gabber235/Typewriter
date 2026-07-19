import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/features/auth/application/auth.dart";
import "package:typewriter_panel/features/organizations/application/organization.dart";
import "package:typewriter_panel/features/organizations/features/members/application/members.dart";
import "package:typewriter_panel/features/organizations/features/members/application/roles.dart";
import "package:typewriter_panel/infrastructure/messaging/api_exception.dart";
import "package:typewriter_panel/infrastructure/messaging/nats.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/converters.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_testkit/typewriter_testkit.dart";

import "support/members_test_support.dart";

void main() {
  group("Organization command errors", () {
    late MockNatsClient mockNats;

    setUp(() => mockNats = MockNatsClient());
    tearDown(() => mockNats.dispose());

    Matcher apiException(int code, String message) => isA<ApiException>()
        .having((error) => error.code, "code", code)
        .having((error) => error.message, "message", message);

    OrganizationMember memberWithRole(OrganizationRole role) =>
        createMember(roles: [role], email: "", avatarUrl: "");

    test(
      "updateMemberRoles maps unassignable roles and restores state",
      () async {
        final oldRole = createRole(
          id: "old",
          name: "Member",
          color: Colors.grey,
          assignable: true,
        );
        final newRole = createRole(
          id: "new",
          name: "Admin",
          color: Colors.red,
          assignable: true,
        );
        final container = ProviderContainer.test(
          overrides: [
            userIdProvider.overrideWith((ref) async => testUserId),
            organizationIdProvider.overrideWith((ref) => testOrganizationId),
            natsProvider.overrideWithValue(mockNats),
            organizationMembersProvider.overrideWith(
              () => MockMembersNotifier([memberWithRole(oldRole)]),
            ),
          ],
        );
        final subscription = await retainUntilReady<List<OrganizationMember>>(
          (listener) => container.listen(
            organizationMembersProvider,
            listener,
            fireImmediately: true,
          ),
        );
        addTearDown(subscription.close);
        mockNats.registerHandler(
          memberUpdateSubject,
          (
            data,
          ) => skir.UpdateOrganizationMemberRolesResponse.serializer.toBytes(
            skir.UpdateOrganizationMemberRolesResponse.createRolesNotAssignableError(
              roleIds: [newRole.roleId],
            ),
          ),
        );

        await expectLater(
          container
              .read(organizationMembersProvider.notifier)
              .updateMemberRoles(recordId("user:m1"), [newRole]),
          throwsA(apiException(400, "One or more roles cannot be assigned")),
        );
        expect(
          container.read(organizationMembersProvider).requireValue.single.roles,
          [oldRole],
        );
      },
    );

    test("updateMemberRoles maps founder role requirement to conflict", () async {
      final role = createRole(
        id: "founder",
        name: "Founder",
        color: Colors.red,
        assignable: true,
      );
      final container = ProviderContainer.test(
        overrides: [
          userIdProvider.overrideWith((ref) async => testUserId),
          organizationIdProvider.overrideWith((ref) => testOrganizationId),
          natsProvider.overrideWithValue(mockNats),
          organizationMembersProvider.overrideWith(
            () => MockMembersNotifier([memberWithRole(role)]),
          ),
        ],
      );
      final subscription = await retainUntilReady<List<OrganizationMember>>(
        (listener) => container.listen(
          organizationMembersProvider,
          listener,
          fireImmediately: true,
        ),
      );
      addTearDown(subscription.close);
      mockNats.registerHandler(
        memberUpdateSubject,
        (data) => skir.UpdateOrganizationMemberRolesResponse.serializer.toBytes(
          skir.UpdateOrganizationMemberRolesResponse.createFounderRoleRequiredError(),
        ),
      );

      await expectLater(
        container.read(organizationMembersProvider.notifier).updateMemberRoles(
          recordId("user:m1"),
          [role],
        ),
        throwsA(
          apiException(409, "Organization must retain at least one founder"),
        ),
      );
    });

    test(
      "removeMember maps founder removal conflict and restores state",
      () async {
        final role = OrganizationRole(
          roleId: recordId("organization_role:founder"),
          name: "Founder",
          color: Colors.red,
        );
        final member = memberWithRole(role);
        final container = ProviderContainer.test(
          overrides: [
            userIdProvider.overrideWith((ref) async => testUserId),
            organizationIdProvider.overrideWith((ref) => testOrganizationId),
            natsProvider.overrideWithValue(mockNats),
            organizationMembersProvider.overrideWith(
              () => MockMembersNotifier([member]),
            ),
          ],
        );
        final subscription = await retainUntilReady<List<OrganizationMember>>(
          (listener) => container.listen(
            organizationMembersProvider,
            listener,
            fireImmediately: true,
          ),
        );
        addTearDown(subscription.close);
        mockNats.registerHandler(
          memberRemoveSubject,
          (data) => skir.RemoveOrganizationMemberResponse.serializer.toBytes(
            skir.RemoveOrganizationMemberResponse.createFounderCannotBeRemovedError(
              userId: member.userId,
            ),
          ),
        );

        await expectLater(
          container
              .read(organizationMembersProvider.notifier)
              .removeMember(member.userId),
          throwsA(apiException(409, "Organization founder cannot be removed")),
        );
        expect(container.read(organizationMembersProvider).requireValue, [
          member,
        ]);
      },
    );
  });
}
