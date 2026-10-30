import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  test(
    "service projection overlays identity and preserves canonical state",
    () {
      final canonical = service(
        "first",
        name: "Canonical",
        revision: 4,
        organization: acme.organizationId,
        lastSeen: DateTime.utc(2026, 1, 1),
      );
      final local = LocalEditorValue(
        value: skir.DataValue.createRecord(
          fields: [
            skir.FieldValue(
              name: "name",
              value: skir.DataValue.wrapStringValue("Edited"),
            ),
          ],
        ),
        editedPaths: {editorRootPath.field("name")},
      );

      final projected = canonical.projected(local);

      expect(projected.name, "Edited");
      expect(projected.revision, canonical.revision);
      expect(projected.state, canonical.state);
      expect(projected.lastSeen, canonical.lastSeen);
    },
  );

  testWidgets("a name draft shows on its own service only", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      servicesBackend(
        services: [
          for (final id in ["first", "second"])
            service(
              id,
              revision: 4,
              role: skir.ServiceRole.createCustom(
                name: "discord",
                version: "1.0.0",
              ),
              organization: acme.organizationId,
              lastSeen: DateTime.utc(2026, 1, 1),
            ),
        ],
      ),
    ]);
    // The rename stays in flight, so the draft is what the panel shows.
    panel.world.nats.registerHandler(
      "cloud.to.user.ada.organization.acme.services.update",
      (_) => Completer<Uint8List>().future,
    );
    await panel.services.card("Discord service", "First").select();
    await panel.field("Name").focus();

    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: "edited_first",
        selection: TextSelection.collapsed(offset: 12),
      ),
    );
    for (var frame = 0; frame < 10; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(
      panel.services.cards.map((card) => card.split(", ")[1]),
      unorderedEquals(["Edited First", "Second"]),
    );
  });
}
