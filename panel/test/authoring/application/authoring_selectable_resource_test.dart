import "package:flutter_test/flutter_test.dart";
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
