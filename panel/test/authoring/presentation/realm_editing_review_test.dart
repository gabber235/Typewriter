import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  final quest = book("Quest");

  testWidgets("opening the review of a refused save compares it with the "
      "saved values the Realm reports as current", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(books: [quest]),
      heldSaves,
    ]);
    final saved = panel.world.requireRealm;
    final editing = await panel.openEditing();
    editing.form(quest.bookId)
      ..setText(
        "Rename",
        authoredFieldLocation(quest.bookId, ["title"]),
        "Mine",
      )
      ..detach();
    final group = editing.state.groups.values.single.id;
    final saving = editing.save(group);
    await panel.settle();
    saved.saves.single.reject(
      skir.CommitPreparedEditResponse.wrapConflictError(const []),
    );
    await saving;
    await panel.settle();
    // Reading the saved values reports them to everything that shows them,
    // as the Realm's session does.
    saved.answerRefresh = () {
      saved.remoteChange((edit) {});
      return Future.value(saved.document);
    };

    await panel.showAbove(RealmEditingReview(workspace: editing, id: group));

    expect(find.text("Keep mine"), findsWidgets);
  });
}
