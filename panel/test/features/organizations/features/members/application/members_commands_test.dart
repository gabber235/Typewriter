import "dart:async";

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
  group("OrganizationMembers command state", () {
    late MockNatsClient mockNats;

    setUp(() {
      mockNats = MockNatsClient();
    });

    tearDown(() {
      mockNats.dispose();
    });

    test(
      "removeMember optimistically removes then restores on error",
      () async {
        final member = createMember();

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

        await readMembers(container);

        mockNats.registerHandler(memberRemoveSubject, (data) {
          throw TimeoutException("Connection error");
        });

        await expectLater(
          container
              .read(organizationMembersProvider.notifier)
              .removeMember(testMemberId),
          throwsA(isA<TimeoutException>()),
        );

        final currentState = container.read(organizationMembersProvider);
        expect(currentState.value, isNotNull);
        expect(currentState.value!.length, 1);
        expect(currentState.value!.first.userId, recordId("user:m1"));
      },
    );

    test("removeMember succeeds when server confirms", () async {
      final member = createMember();

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

      await readMembers(container);

      mockNats.registerHandler(
        memberRemoveSubject,
        (data) => skir.RemoveOrganizationMemberResponse.serializer.toBytes(
          skir.RemoveOrganizationMemberResponse.createSuccess(),
        ),
      );

      await container
          .read(organizationMembersProvider.notifier)
          .removeMember(recordId("user:m1"));

      final currentState = container.read(organizationMembersProvider);
      expect(currentState.value, isNotNull);
      expect(currentState.value!.isEmpty, true);
    });

    test(
      "updateMemberRoles optimistically updates then restores on error",
      () async {
        final oldRole = createRole(
          id: "r1",
          name: "Member",
          color: Colors.grey,
          assignable: true,
        );
        final newRole = createRole(
          id: "r2",
          name: "Admin",
          color: Colors.red,
          assignable: true,
        );

        final member = createMember(roles: [oldRole]);

        final container = ProviderContainer.test(
          overrides: [
            userIdProvider.overrideWith((ref) async => testUserId),
            organizationIdProvider.overrideWith((ref) => testOrganizationId),
            natsProvider.overrideWithValue(mockNats),
            organizationMembersProvider.overrideWith(
              () => MockMembersNotifier([member]),
            ),
            organizationRolesProvider.overrideWith(
              () => MockRolesNotifier([oldRole, newRole]),
            ),
          ],
        );

        await readMembers(container);

        mockNats.registerHandler(memberUpdateSubject, (data) {
          throw TimeoutException("Connection error");
        });

        await expectLater(
          container
              .read(organizationMembersProvider.notifier)
              .updateMemberRoles(testMemberId, [newRole]),
          throwsA(isA<TimeoutException>()),
        );

        final currentState = container.read(organizationMembersProvider);
        expect(currentState.value, isNotNull);
        expect(currentState.value!.first.roles.length, 1);
        expect(
          currentState.value!.first.roles.first.roleId,
          recordId("organization_role:r1"),
        );
      },
    );

    test("updateMemberRoles succeeds when server confirms", () async {
      final oldRole = createRole(
        id: "r1",
        name: "Member",
        color: Colors.grey,
        assignable: true,
      );
      final newRole = createRole(
        id: "r2",
        name: "Admin",
        color: Colors.red,
        assignable: true,
      );

      final member = createMember(roles: [oldRole]);

      final container = ProviderContainer.test(
        overrides: [
          userIdProvider.overrideWith((ref) async => testUserId),
          organizationIdProvider.overrideWith((ref) => testOrganizationId),
          natsProvider.overrideWithValue(mockNats),
          organizationMembersProvider.overrideWith(
            () => MockMembersNotifier([member]),
          ),
          organizationRolesProvider.overrideWith(
            () => MockRolesNotifier([oldRole, newRole]),
          ),
        ],
      );

      await readMembers(container);

      mockNats.registerHandler(
        memberUpdateSubject,
        (data) => skir.UpdateOrganizationMemberRolesResponse.serializer.toBytes(
          skir.UpdateOrganizationMemberRolesResponse.createSuccess(
            userId: recordId("user:m1"),
            name: "Test",
            email: "test@test.com",
            avatarUrl: "",
            roles: [newRole.toSkir()],
            joinedAt: testTimestamp,
          ),
        ),
      );

      await container
          .read(organizationMembersProvider.notifier)
          .updateMemberRoles(recordId("user:m1"), [newRole]);

      final currentState = container.read(organizationMembersProvider);
      expect(currentState.value, isNotNull);
      expect(currentState.value!.first.roles.length, 1);
      expect(
        currentState.value!.first.roles.first.roleId,
        recordId("organization_role:r2"),
      );
    });
  });
}
