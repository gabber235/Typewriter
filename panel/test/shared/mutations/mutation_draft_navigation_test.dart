import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  final host = ServiceIdentifier(
    skir.RecordId(table: "service", key: skir.RecordIdKey.wrapString("host")),
  );

  testWidgets("a draft already on screen offers no way to open it", (
    tester,
  ) async {
    final (:panel, draft: _) = await tester.openDraftActivity(host);

    panel.container.read(selectionProvider.notifier).selectAll([host]);
    await panel.settle();

    expect(panel.shows("Open work"), isFalse);
    expect(panel.shows("Review draft"), isFalse);
  });

  testWidgets("opening a draft selects its resource and keeps the draft", (
    tester,
  ) async {
    final (:panel, :draft) = await tester.openDraftActivity(host);

    await panel.tapOn(panel.labeled("Open work").first);

    expect(panel.container.read(selectionProvider), [host]);
    expect(panel.activity.isOpen, isFalse);
    expect(
      draft.value(editorRootPath).valueOrNull,
      skir.DataValue.wrapStringValue("draft"),
    );
  });

  testWidgets("discarding a draft clears it from the activity", (tester) async {
    final (:panel, :draft) = await tester.openDraftActivity(host);

    await panel.holdButton("Discard");

    expect(panel.shows("1 draft"), isFalse);
    expect(
      draft.value(editorRootPath).valueOrNull,
      skir.DataValue.wrapStringValue("original"),
    );
  });

  test("matching selection on another route is not the destination", () {
    final container = testWorld(const []).container;
    container.read(selectionProvider.notifier).selectAll([host]);
    final destination = InspectorDestination(
      container: container,
      router: container.read(appRouterProvider),
      path: "/another-route",
      identity: host,
    );
    addTearDown(destination.dispose);
    expect(destination.isCurrent, isFalse);
  });
}
