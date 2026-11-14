import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_testkit/testing.dart";

void main() {
  final story = book("Test Book");
  final intro = page("Intro", book: story);
  final topic = tag("Test Tag");
  const realmPath = "/organization/acme/realm/main";

  testWidgets("a Book selected beside its page shows its title in the "
      "inspector and Open leads to its surface", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(books: [story], pages: [intro], tags: [topic]),
    ]);
    await panel.openSurface(intro.pageId);

    await panel.resources.selectOnly([story.bookId]);

    expect(panel.field("title").value, "Test Book");
    await panel.inspector.run("Open");
    expect(panel.path, "$realmPath/resource/${story.bookId.value}");
  });

  testWidgets("two pages selected together edit their name in one field "
      "that says they differ, and one save renames both", (tester) async {
    final outro = page("Outro", book: story);
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(books: [story], pages: [intro, outro], tags: [topic]),
      heldSaves,
    ]);
    await panel.openSurface(taxonomyId);

    await panel.resources.selectOnly([intro.pageId, outro.pageId]);

    expect(panel.inspector.showsMixed("name"), isTrue);
    await panel.field("name").enter("Chapter");
    await tester.pump(const Duration(seconds: 1));
    await panel.settle();

    final save = panel.world.requireRealm.saves.single;
    expect(
      [
        for (final intent in save.edit.intents)
          if (intent case skir.EditIntent_setValueWrapper(:final value))
            (value.at.resource, value.value),
      ],
      unorderedEquals([
        (intro.pageId, skir.DataValue.wrapStringValue("Chapter")),
        (outro.pageId, skir.DataValue.wrapStringValue("Chapter")),
      ]),
    );
  });

  testWidgets("a Book and a page selected together keep their own "
      "inspections", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(books: [story], pages: [intro], tags: [topic]),
    ]);
    await panel.openSurface(taxonomyId);

    await panel.resources.selectOnly([story.bookId, intro.pageId]);

    expect(panel.field("title").value, "Test Book");
    expect(panel.field("name").value, "Intro");
  });

  testWidgets("a selected Tag shows its name in the inspector", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(books: [story], pages: [intro], tags: [topic]),
    ]);
    await panel.openSurface(taxonomyId);

    await panel.resources.row("Test Tag").select();

    expect(panel.field("name").value, "Test Tag");
  });
}
