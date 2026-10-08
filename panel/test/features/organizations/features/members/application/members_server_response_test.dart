import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "support/members_test_support.dart";

void main() {
  group("OrganizationMembers.updateMemberRoles role merging", () {
    late FakeNatsClient mockNats;

    setUp(() {
      mockNats = FakeNatsClient();
    });

    tearDown(() {
      mockNats.dispose();
    });

    test(
      "ignores a historical receipt older than current membership",
      () async {
        final role = createRole(
          id: "member",
          name: "Member",
          color: Colors.grey,
          assignable: true,
        );

        final member = OrganizationMember(
          userId: skir.recordId("user:m1"),
          name: "Current Name",
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
              () => _SequencedMembers([member], sequence: 2),
            ),
            organizationRolesProvider.overrideWith(
              () => MockRolesNotifier([role]),
            ),
          ],
        );

        await readMembers(container);

        mockNats.registerHandler(
          memberUpdateSubject,
          (data) =>
              skir.UpdateOrganizationMemberRolesResponse.serializer.toBytes(
                successfulMemberUpdate([
                  skir.OrganizationMember(
                    userId: skir.recordId("user:m1"),
                    name: "Historical Name",
                    email: "test@test.com",
                    avatarUrl: "",
                    roles: [],
                    joinedAt: testTimestamp,
                  ),
                ]),
              ),
        );

        await container
            .read(organizationMembersProvider.notifier)
            .updateMemberRoles([skir.recordId("user:m1")], [role]);

        final current = await readMembers(container);
        expect(current.single.name, "Current Name");
      },
    );
  });
}

class _SequencedMembers extends OrganizationMembers {
  _SequencedMembers(this.members, {required this.sequence});
  final List<OrganizationMember> members;
  final int sequence;

  @override
  Stream<List<OrganizationMember>> build() async* {
    sequencedCollection.snapshot = SequencedSnapshot(
      sequence: sequence,
      value: members,
    );
    yield members;
  }
}
