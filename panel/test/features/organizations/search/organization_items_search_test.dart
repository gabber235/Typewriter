import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  final builder = role("builder", name: "Builder");
  final grace = member("Grace", roles: [builder]);
  final linus = member("Linus", roles: [builder]);
  final invite = joinCode("invite", singleUse: false, roles: [builder.roleId]);
  final other = joinCode("other");
  final discord = service(
    "discord",
    name: "discord_bridge",
    role: skir.ServiceRole.createCustom(name: "discord", version: "1.0.0"),
    organization: acme.organizationId,
  );
  final minecraft = service(
    "minecraft",
    name: "minecraft_bridge",
    role: skir.ServiceRole.createCustom(name: "minecraft", version: "1.0.0"),
    organization: acme.organizationId,
  );

  testWidgets("by keys alone, Ctrl+K, part of a member's name and Enter "
      "select that member, show them in the inspector and focus their "
      "row", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      membershipService(
        roles: [builder],
        members: [grace, linus],
        joinCodes: [other],
      ),
    ], at: membersPage(const JoinCodesRoute()));

    await panel.pressPrimary(LogicalKeyboardKey.keyK);
    await panel.queryBar.type("Lin");
    await panel.eventually(
      () => expect(panel.search.result("Linus").lines, contains("Builder")),
    );
    expect(panel.search.result("Linus").lines, contains("MEMBER"));
    await panel.press(LogicalKeyboardKey.enter);

    await panel.eventually(() => expect(panel.focusedRow, linus));
    expect(panel.item("Linus").isMarkedSelected, isTrue);
    expect(panel.item("Grace").isMarkedSelected, isFalse);
    expect(panel.inspector.texts, contains("Linus"));
  });

  testWidgets("by pointer alone, a join code found by its role opens the "
      "join codes page with that code selected and focused", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      membershipService(
        roles: [builder],
        members: [grace],
        joinCodes: [other, invite],
      ),
    ], at: membersPage());

    await panel.tapOn(panel.labeled("Search").first);
    await panel.queryBar.type("Build");
    await panel.eventually(
      () => expect(
        panel.search.result("Join code").lines,
        containsAll(["JOIN CODE", "Builder, Multi-use"]),
      ),
    );
    await panel.search.result("Join code").tap();

    await panel.eventually(() => expect(panel.focusedRow, invite));
    expect(panel.item(joinCodeUrl(invite.code)).isMarkedSelected, isTrue);
    expect(panel.item(joinCodeUrl(other.code)).isMarkedSelected, isFalse);
  });

  testWidgets("by pointer alone, a service opens the services page with "
      "that service selected, inspected and focused", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      servicesService(services: [discord, minecraft]),
      membershipService(members: [grace]),
    ], at: membersPage());

    await panel.tapOn(panel.labeled("Search").first);
    await panel.queryBar.type("mine");
    await panel.eventually(
      () => expect(
        panel.search.result("Minecraft Bridge").lines,
        containsAll(["SERVICE", "Connected"]),
      ),
    );
    await panel.search.result("Minecraft Bridge").tap();

    await panel.eventually(
      () => expect(panel.focused, contains("Minecraft Bridge")),
    );
    expect(
      panel.services
          .card("Minecraft service", "Minecraft Bridge")
          .isMarkedSelected,
      isTrue,
    );
    expect(
      panel.services.card("Discord service", "Discord Bridge").isMarkedSelected,
      isFalse,
    );
    // The inspector names the service as it was registered.
    expect(panel.inspector.texts, contains("minecraft_bridge"));
  });

  testWidgets("after moving to an organization whose membership cannot be "
      "read, the members of the one before never appear in search", (
    tester,
  ) async {
    final globex = organization("Globex");
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme, others: [globex]),
      membershipService(members: [grace]),
    ], at: membersPage());
    await panel.follow(
      OrganizationRoute(
        organizationId: globex.organizationId.id,
        children: [
          MembersRoute(children: [const MemberListRoute()]),
        ],
      ),
    );

    await panel.pressPrimary(LogicalKeyboardKey.keyK);
    await panel.queryBar.type("Gra");
    await panel.settle();

    expect(panel.search.result("Grace").isShown, isFalse);
  });
}
