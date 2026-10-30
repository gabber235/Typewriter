import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  final host = ServiceIdentifier(
    skir.RecordId(table: "service", key: skir.RecordIdKey.wrapString("host")),
  );
  final driver = WorkDriverId(
    domain: "value",
    scope: EditorResourceKey(scope: null, identity: host.resourceId),
  );

  testWidgets("a draft already on screen offers no way to open it", (
    tester,
  ) async {
    final work = testWorkSession();
    textDraft(
      work,
      host,
      label: "Host configuration",
      saved: "original",
      draft: "draft",
    );
    final panel = await tester.pumpPanel(const [], at: saveActivityOf(work));
    work.setDestination(driver, panel.inspectorDestination(host));
    await panel.activity.open("1 draft");

    panel.container.read(selectionProvider.notifier).selectAll([host]);
    await panel.settle();

    expect(panel.shows("Open work"), isFalse);
    expect(panel.shows("Review draft"), isFalse);
  });

  testWidgets("opening a draft selects its resource and keeps the draft", (
    tester,
  ) async {
    final work = testWorkSession();
    final draft = textDraft(
      work,
      host,
      label: "Host configuration",
      saved: "original",
      draft: "draft",
    );
    final panel = await tester.pumpPanel(const [], at: saveActivityOf(work));
    work.setDestination(driver, panel.inspectorDestination(host));
    await panel.activity.open("1 draft");

    await panel.tapOn(panel.labeled("Open work").first);

    expect(panel.container.read(selectionProvider), [host]);
    expect(panel.activity.isOpen, isFalse);
    expect(
      draft.value(editorRootPath).valueOrNull,
      skir.DataValue.wrapStringValue("draft"),
    );
  });

  testWidgets("discarding a draft clears it from the activity", (tester) async {
    final work = testWorkSession();
    final draft = textDraft(
      work,
      host,
      label: "Host configuration",
      saved: "original",
      draft: "draft",
    );
    final panel = await tester.pumpPanel(const [], at: saveActivityOf(work));
    work.setDestination(driver, panel.inspectorDestination(host));
    await panel.activity.open("1 draft");

    await panel.tapOn(panel.labeled("Discard").first);

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
