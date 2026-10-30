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

void main() {
  testWidgets("a rejected name keeps the field, its text and selection, and "
      "a correction saves and clears the naming rule", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      servicesService(services: [_service]),
    ]);
    await panel.services.card("Discord service", "Gabber 235").select();
    await panel.field("Name").focus();
    List<String> sentNames() => [
      for (final request in panel.world.nats.requestsTo(_updateSubject))
        skir.UpdateOrganizationServiceRequest.serializer
            .fromBytes(request.payload)
            .name,
    ];
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
    expect(sentNames(), isEmpty);

    await panel.field("Name").edit("gabber236");

    await panel.eventually(() => expect(sentNames(), ["gabber236"]));
    expect(panel.shows(_nameRule), isFalse);
    expect(name.isFocused, isTrue);

    await panel.field("Name").edit("ga");

    expect(panel.shows(_nameRule), isTrue);
    expect(name.isFocused, isTrue);
    expect(name.value, "ga");
    expect(sentNames(), ["gabber236"]);
    expect(tester.takeException(), isNull);
  });

  testWidgets("resizing the window while a rejected name is typed keeps the "
      "field and raises nothing", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      servicesService(services: [_service]),
    ]);
    await panel.services.card("Discord service", "Gabber 235").select();
    await panel.field("Name").focus();
    List<String> sentNames() => [
      for (final request in panel.world.nats.requestsTo(_updateSubject))
        skir.UpdateOrganizationServiceRequest.serializer
            .fromBytes(request.payload)
            .name,
    ];

    await panel.field("Name").edit("ga");
    tester.view.physicalSize = const Size(1401, 900);
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(panel.field("Name").isFocused, isTrue);
    expect(panel.field("Name").value, "ga");
    expect(sentNames(), isEmpty);
  });
}
