import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

const _useSaved = "Use saved? Your change to 1 value in this group is lost.";

void main() {
  testWidgets("opening the review of a refused save compares it with the "
      "saved values the Realm reports as current", (tester) async {
    final fixture = AuthoredDraft.titled();
    final panel = await tester.pumpPanel(fixture.servedHeld);

    await panel.reviewRefusedSave(fixture);

    expect(panel.conflictReview.column("Your proposal"), ["Mine"]);
    expect(panel.conflictReview.column("Saved now"), ["Theirs"]);
    expect(panel.dialog.showing("Keep mine"), isTrue);
  });

  testWidgets("a brief press on Use saved keeps the proposal", (tester) async {
    final fixture = AuthoredDraft.titled();
    final panel = await tester.pumpPanel(fixture.servedHeld);
    await panel.reviewRefusedSave(fixture);

    await panel.holdButton(_useSaved, share: 0.2);

    expect(panel.dialog.showing("Keep mine"), isTrue);
    expect(panel.conflictReview.column("Your proposal"), ["Mine"]);
  });

  testWidgets("holding Use saved takes the saved values and closes the "
      "review", (tester) async {
    final fixture = AuthoredDraft.titled();
    final panel = await tester.pumpPanel(fixture.servedHeld);
    await panel.reviewRefusedSave(fixture);

    await panel.holdButton(_useSaved);

    expect(panel.dialog.showing("Keep mine"), isFalse);
    expect(panel.fieldAt(0).value, "Theirs");
  });

  testWidgets("a refused Use saved jams its button with the message and "
      "keeps the proposal", (tester) async {
    final fixture = AuthoredDraft.titled();
    final panel = await tester.pumpPanel(fixture.servedHeld);
    final editing = await panel.reviewRefusedSave(fixture);
    // The saved values change again under the open review.
    editing.acceptConfirmed(
      (AuthoringEdit.fromDocument(panel.world.requireRealm.document)..set(
            authoredFieldLocation(fixture.resource, ["title"]),
            skir.DataValue.wrapStringValue("Changed again"),
          ))
          .toDocument(),
    );
    await panel.settle();

    await panel.holdButton(_useSaved);

    expect(
      panel.refusalOn(_useSaved),
      "These changes changed again. Review the current values",
    );
    expect(panel.conflictReview.column("Your proposal"), ["Mine"]);
  });
}
