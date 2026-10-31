import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("opening the review of a refused save compares it with the "
      "saved values the Realm reports as current", (tester) async {
    final fixture = AuthoredDraft.titled();
    final panel = await tester.pumpPanel(fixture.servedHeld);
    await panel.inspectDraft(fixture);
    final saved = panel.world.requireRealm;
    await panel.fieldAt(0).type("Mine");
    await tester.pump(const Duration(milliseconds: 250));
    await panel.settle();
    // Someone else saved "Theirs" meanwhile; the panel learns of it only by
    // reading the saved values again, which reports them to everything that
    // shows them, as the Realm's session does.
    saved.answerRefresh = () {
      saved.remoteChange(
        (edit) => edit.set(
          authoredFieldLocation(fixture.resource, ["title"]),
          skir.DataValue.wrapStringValue("Theirs"),
        ),
      );
      return Future.value(saved.document);
    };
    saved.saves.single.reject(
      skir.CommitPreparedEditResponse.wrapConflictError(const []),
    );
    await panel.settle();

    await panel.tapOn(find.text("Review changes"));

    expect(panel.conflictReview.column("Your proposal"), ["Mine"]);
    expect(panel.conflictReview.column("Saved now"), ["Theirs"]);
    expect(panel.dialog.showing("Keep mine"), isTrue);
  });
}
