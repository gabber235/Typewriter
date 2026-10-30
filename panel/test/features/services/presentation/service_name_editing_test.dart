import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

const _updateSubject = "cloud.to.user.ada.organization.acme.services.update";
const _nameRule =
    "Use at least three lowercase letters or digits separated by underscores";

final _service = service(
  "discord",
  name: "gabber235",
  role: skir.ServiceRole.createCustom(name: "discord", version: "1.0.0"),
  status: null,
);

/// Ada in Acme, which runs [_service].
final _withService = [
  signedIn(ada, organization: acme),
  servicesService(services: [_service]),
];

void main() {
  testWidgets("a rejected name keeps the field, its text and selection, and "
      "a correction saves and clears the naming rule", (tester) async {
    final panel = await tester.pumpPanel(_withService);
    await panel.services.card("Discord service", "Gabber 235").select();
    await panel.field("Name").focus();
    final name = panel.field("Name");

    await panel
        .field("Name")
        .edit(
          "ga",
          selection: const TextSelection(baseOffset: 0, extentOffset: 1),
        );

    expect(panel.shows(_nameRule), isTrue);
    expect(name.isFocused, isTrue);
    expect(name.value, "ga");
    expect(
      find.semantics
          .byPredicate((node) => node.isFocused)
          .evaluate()
          .last
          .getSemanticsData()
          .textSelection,
      const TextSelection(baseOffset: 0, extentOffset: 1),
    );
    expect(panel.world.nats.sentServiceNames(_updateSubject), isEmpty);

    await panel.field("Name").edit("gabber236");

    await panel.eventually(
      () => expect(panel.world.nats.sentServiceNames(_updateSubject), [
        "gabber236",
      ]),
    );
    expect(panel.shows(_nameRule), isFalse);
    expect(name.isFocused, isTrue);

    await panel.field("Name").edit("ga");

    expect(panel.shows(_nameRule), isTrue);
    expect(name.isFocused, isTrue);
    expect(name.value, "ga");
    expect(panel.world.nats.sentServiceNames(_updateSubject), ["gabber236"]);
    expect(tester.takeException(), isNull);
  });

  testWidgets("resizing the window while a rejected name is typed keeps the "
      "field and raises nothing", (tester) async {
    final panel = await tester.pumpPanel(_withService);
    await panel.services.card("Discord service", "Gabber 235").select();
    await panel.field("Name").focus();

    await panel.field("Name").edit("ga");
    tester.view.physicalSize = const Size(1401, 900);
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(panel.field("Name").isFocused, isTrue);
    expect(panel.field("Name").value, "ga");
    expect(panel.world.nats.sentServiceNames(_updateSubject), isEmpty);
  });
}
