import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

const _rolesSubject = "cloud.to.user.ada.organization.acme.roles.watch";

void main() {
  testWidgets("the organization's roles load from the backend", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      membershipBackend(
        roles: [
          role("one", name: "Role one", color: const Color(0xff2196f3)),
          role("two", name: "Role two", color: const Color(0xff2196f3)),
        ],
      ),
    ]);

    expect((await panel.loaded(organizationRolesProvider)).requireValue, [
      role("one", name: "Role one", color: const Color(0xff2196f3)),
      role("two", name: "Role two", color: const Color(0xff2196f3)),
    ]);
  });

  for (final (name, response, code) in [
    (
      "an internal error",
      skir.WatchOrganizationRolesResponse.createInternalError(),
      500,
    ),
    ("an unknown reply", skir.WatchOrganizationRolesResponse.unknown, 422),
  ]) {
    testWidgets("$name fails loading the roles with code $code", (
      tester,
    ) async {
      final panel = await tester.pumpPanel([signedIn(ada, organization: acme)]);
      panel.world.nats.registerHandler(
        _rolesSubject,
        (_) => skir.WatchOrganizationRolesResponse.serializer.toBytes(response),
      );
      final roles = await panel.loaded(organizationRolesProvider);

      expect(
        roles.error,
        isA<ApiException>().having((error) => error.code, "code", code),
      );
    });
  }

  testWidgets("a role change answered as the snapshot fails loading", (
    tester,
  ) async {
    final panel = await tester.pumpPanel([signedIn(ada, organization: acme)]);
    panel.world.nats.registerHandler(
      _rolesSubject,
      (_) => skir.WatchOrganizationRolesResponse.serializer.toBytes(
        skir.WatchOrganizationRolesResponse.wrapAdd(
          role("one", name: "Role one", color: const Color(0xff2196f3)),
        ),
      ),
    );
    final roles = await panel.loaded(organizationRolesProvider);

    expect(roles.error, isA<StateError>());
  });
}
