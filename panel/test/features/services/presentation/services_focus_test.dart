import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  final discord = service(
    "discord",
    name: "discord_bridge",
    role: skir.ServiceRole.createCustom(name: "discord", version: "1.0.0"),
    organization: acme.organizationId,
    createdAt: DateTime.utc(2026, 8, 20),
  );
  final minecraft = service(
    "minecraft",
    name: "minecraft_bridge",
    role: skir.ServiceRole.createCustom(name: "minecraft", version: "1.0.0"),
    organization: acme.organizationId,
    createdAt: DateTime.utc(2026, 8, 20),
  );

  testWidgets("the services page opens on the first service card", (
    tester,
  ) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      servicesService(services: [discord, minecraft]),
    ]);
    expect(panel.focused, contains("Discord"));
  });

  testWidgets("with no services the page opens on the registration field", (
    tester,
  ) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      servicesService(services: const []),
    ]);
    expect(panel.focusShows(find.text("Enter registration token")), isTrue);
  });

  testWidgets("unbinding the focused card focuses its neighbour", (
    tester,
  ) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      servicesService(services: [discord, minecraft]),
    ]);
    // Operations act on the selection: Space selects the focused card.
    await panel.press(LogicalKeyboardKey.space);
    await panel.pressPrimary(LogicalKeyboardKey.backspace);
    // The dialog until the hold replaces it.
    await panel.press(LogicalKeyboardKey.enter);
    await panel.eventually(() => expect(panel.focused, contains("Minecraft")));
  });
}
