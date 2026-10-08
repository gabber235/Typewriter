import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "support/members_test_support.dart";

void main() {
  group("OrganizationMembers command state", () {
    late FakeNatsClient mockNats;

    setUp(() {
      mockNats = FakeNatsClient();
    });

    tearDown(() {
      mockNats.dispose();
    });

    test(
      "removeMember preserves the member when delivery is uncertain",
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
          throwsA(isA<SubmissionException>()),
        );

        final currentState = container.read(organizationMembersProvider);
        expect(currentState.value, isNotNull);
        expect(currentState.value!.length, 1);
        expect(currentState.value!.first.userId, skir.recordId("user:m1"));
      },
    );

    test("removeMember succeeds when server confirms", () async {
      final member = createMember();
      var confirmed = [member];

      final container = ProviderContainer.test(
        overrides: [
          userIdProvider.overrideWith((ref) async => testUserId),
          organizationIdProvider.overrideWith((ref) => testOrganizationId),
          natsProvider.overrideWithValue(mockNats),
          organizationMembersProvider.overrideWith(
            () => MockMembersNotifier([member], load: () => confirmed),
          ),
        ],
      );

      await readMembers(container);

      mockNats.registerHandler(memberRemoveSubject, (data) {
        confirmed = [];
        return skir.RemoveOrganizationMemberResponse.serializer.toBytes(
          successfulMemberRemoval(skir.recordId("user:m1")),
        );
      });

      await container
          .read(organizationMembersProvider.notifier)
          .removeMember(skir.recordId("user:m1"));

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
              .updateMemberRoles([testMemberId], [newRole]),
          throwsA(isA<SubmissionException>()),
        );

        final currentState = container.read(organizationMembersProvider);
        expect(currentState.value, isNotNull);
        expect(currentState.value!.first.roles.length, 1);
        expect(
          currentState.value!.first.roles.first.roleId,
          skir.recordId("organization_role:r1"),
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
      var confirmed = member;

      final container = ProviderContainer.test(
        overrides: [
          userIdProvider.overrideWith((ref) async => testUserId),
          organizationIdProvider.overrideWith((ref) => testOrganizationId),
          natsProvider.overrideWithValue(mockNats),
          organizationMembersProvider.overrideWith(
            () => MockMembersNotifier([member], load: () => [confirmed]),
          ),
          organizationRolesProvider.overrideWith(
            () => MockRolesNotifier([oldRole, newRole]),
          ),
        ],
      );

      await readMembers(container);

      mockNats.registerHandler(memberUpdateSubject, (data) {
        confirmed = member.copyWith(roles: [newRole]);
        return skir.UpdateOrganizationMemberRolesResponse.serializer.toBytes(
          successfulMemberUpdate([
            skir.OrganizationMember(
              userId: skir.recordId("user:m1"),
              name: "Test",
              email: "test@test.com",
              avatarUrl: "",
              roles: [newRole.toSkir()],
              joinedAt: testTimestamp,
            ),
          ]),
        );
      });

      await container
          .read(organizationMembersProvider.notifier)
          .updateMemberRoles([skir.recordId("user:m1")], [newRole]);

      await readMembers(container);
      final currentState = container.read(organizationMembersProvider);
      expect(currentState.value, isNotNull);
      expect(currentState.value!.first.roles.length, 1);
      expect(
        currentState.value!.first.roles.first.roleId,
        skir.recordId("organization_role:r2"),
      );
    });
  });
}
