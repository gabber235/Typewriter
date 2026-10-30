import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_testkit/testing.dart";

final _founder = role("founder", assignable: false);
final _member = role("member", defaultRole: true);
final _editor = role("editor");
final _viewer = role("viewer");

/// Every role of the organization.
final _roles = [_founder, _member, _editor, _viewer];

final _graceId = skir.recordId("user:grace");

void main() {
  test("changing roles keeps the roles the editor cannot assign", () async {
    final world = testWorld([
      signedIn(ada, organization: acme),
      membership(
        roles: _roles,
        members: [
          member("Grace", roles: [_founder, _editor]),
        ],
      ),
    ]);
    final members = await world.openRoleEditor();

    expect(
      await members.ensureCorrectRoles(_graceId, [_viewer]),
      unorderedEquals([_founder, _viewer]),
    );
  });

  test("a protected role chosen in the editor is not granted", () async {
    final world = testWorld([
      signedIn(ada, organization: acme),
      membership(
        roles: _roles,
        members: [
          member("Grace", roles: [_editor]),
        ],
      ),
    ]);
    final members = await world.openRoleEditor();

    expect(await members.ensureCorrectRoles(_graceId, [_founder, _viewer]), [
      _viewer,
    ]);
  });

  test("clearing every role falls back to the default role", () async {
    final world = testWorld([
      signedIn(ada, organization: acme),
      membership(
        roles: _roles,
        members: [
          member("Grace", roles: [_editor]),
        ],
      ),
    ]);
    final members = await world.openRoleEditor();

    expect(await members.ensureCorrectRoles(_graceId, const []), [_member]);
  });
}
