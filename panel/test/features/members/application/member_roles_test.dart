import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  final founder = role("founder", assignable: false);
  final member = role("member", defaultRole: true);
  final editor = role("editor");
  final viewer = role("viewer");
  final graceId = skir.recordId("user:grace");

  test("changing roles keeps the roles the editor cannot assign", () async {
    final world = testWorld([
      signedIn(ada, organization: acme),
      membership(
        roles: [founder, member, editor, viewer],
        members: [
          skir.OrganizationMember(
            userId: graceId,
            name: "Grace",
            email: null,
            avatarUrl: null,
            roles: [founder, editor],
            joinedAt: DateTime.utc(2026),
          ),
        ],
      ),
    ]);
    final members = world.container.listen(
      organizationMembersProvider,
      (_, _) {},
    );
    // The role editor shows the organization's roles while it is open.
    final roles = world.container.listen(organizationRolesProvider, (_, _) {});
    addTearDown(members.close);
    addTearDown(roles.close);
    await world.container.read(organizationMembersProvider.future);

    expect(
      await world.container
          .read(organizationMembersProvider.notifier)
          .ensureCorrectRoles(graceId, [viewer]),
      unorderedEquals([founder, viewer]),
    );
  });

  test("a protected role chosen in the editor is not granted", () async {
    final world = testWorld([
      signedIn(ada, organization: acme),
      membership(
        roles: [founder, member, editor, viewer],
        members: [
          skir.OrganizationMember(
            userId: graceId,
            name: "Grace",
            email: null,
            avatarUrl: null,
            roles: [editor],
            joinedAt: DateTime.utc(2026),
          ),
        ],
      ),
    ]);
    final members = world.container.listen(
      organizationMembersProvider,
      (_, _) {},
    );
    // The role editor shows the organization's roles while it is open.
    final roles = world.container.listen(organizationRolesProvider, (_, _) {});
    addTearDown(members.close);
    addTearDown(roles.close);
    await world.container.read(organizationMembersProvider.future);

    expect(
      await world.container
          .read(organizationMembersProvider.notifier)
          .ensureCorrectRoles(graceId, [founder, viewer]),
      [viewer],
    );
  });

  test("clearing every role falls back to the default role", () async {
    final world = testWorld([
      signedIn(ada, organization: acme),
      membership(
        roles: [founder, member, editor, viewer],
        members: [
          skir.OrganizationMember(
            userId: graceId,
            name: "Grace",
            email: null,
            avatarUrl: null,
            roles: [editor],
            joinedAt: DateTime.utc(2026),
          ),
        ],
      ),
    ]);
    final members = world.container.listen(
      organizationMembersProvider,
      (_, _) {},
    );
    // The role editor shows the organization's roles while it is open.
    final roles = world.container.listen(organizationRolesProvider, (_, _) {});
    addTearDown(members.close);
    addTearDown(roles.close);
    await world.container.read(organizationMembersProvider.future);

    expect(
      await world.container
          .read(organizationMembersProvider.notifier)
          .ensureCorrectRoles(graceId, const []),
      [member],
    );
  });
}
