import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  final host = ServiceIdentifier(
    skir.RecordId(table: "service", key: skir.RecordIdKey.wrapString("host")),
  );
  final edited = skir.DataValue.wrapStringValue("draft");

  testWidgets("a brief press on Discard keeps the unsaved edit", (
    tester,
  ) async {
    final (:panel, :draft) = await tester.openDraftActivity(host);

    await panel.holdButton("Discard", share: 0.2);

    expect(panel.shows("1 draft"), isTrue);
    expect(draft.value(editorRootPath).valueOrNull, edited);
  });

  testWidgets("holding Discard throws the unsaved edit away", (tester) async {
    final (:panel, :draft) = await tester.openDraftActivity(host);

    await panel.holdButton("Discard");

    expect(panel.shows("1 draft"), isFalse);
    expect(
      draft.value(editorRootPath).valueOrNull,
      skir.DataValue.wrapStringValue("original"),
    );
  });

  testWidgets("an edit that starts saving during the hold is kept", (
    tester,
  ) async {
    final (:panel, :draft) = await tester.openDraftActivity(host);
    final gesture = await tester.startGesture(
      tester.getCenter(find.bySemanticsLabel(RegExp("^Discard")).last),
    );
    await panel.holdFor(0.5);

    unawaited(draft.flush());
    await panel.holdFor(1);
    await gesture.up();
    await panel.settle();

    expect(draft.value(editorRootPath).valueOrNull, edited);
  });
}
