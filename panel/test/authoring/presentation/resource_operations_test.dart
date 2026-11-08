import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  final first = book("First");
  final second = book("Second");
  const reveal = RealmOperation.duplicate();
  const move = RealmOperation.moveTo();
  const delete = RealmOperation.delete();

  testWidgets("menus lead with Open and Inspect, then list the operations by "
      "group", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(books: [first, second]),
      operations(const [reveal, move, delete]),
    ]);

    final entries = await panel.resources.row("First").operations.open();

    // Delete holds, so it is heard as the outcome it states.
    expect(entries, [
      "Open",
      "Inspect",
      "Duplicate",
      "Move to",
      "Delete this resource and what it owns?",
    ]);
  });

  testWidgets("the inspector offers the operations declared as buttons", (
    tester,
  ) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(books: [first, second]),
      operations(const [reveal, move, delete]),
    ]);

    await panel.resources.row("First").select();

    // Delete holds, so it is heard as the outcome it states.
    const heardDelete = "Delete this resource and what it owns?";
    expect(panel.inspector.operations, ["Open", "Duplicate", heardDelete]);
    expect(panel.inspector.isEnabled(heardDelete), isTrue);
  });

  final openings = <String, Future<void> Function(PanelDriver panel)>{
    "a double click": (panel) => panel.resources.row("First").open(),
    "the Open menu entry": (panel) =>
        panel.resources.row("First").operations.choose("Open"),
    "the primary keyboard action": (panel) async {
      await panel.resources.row("First").select();
      await panel.pressPrimary(LogicalKeyboardKey.enter);
    },
  };
  for (final MapEntry(key: gesture, value: openWith) in openings.entries) {
    testWidgets("$gesture opens the resource's surface", (tester) async {
      final panel = await tester.pumpPanel([
        signedIn(ada, organization: acme),
        realm(books: [first, second]),
        operations(const [reveal, move, delete]),
      ]);

      await openWith(panel);

      expect(
        panel.path,
        "/organization/acme/realm/main/resource/${first.bookId.value}",
      );
    });
  }

  testWidgets("Inspect selects the resource and moves focus into the "
      "inspector without navigating", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(books: [first, second]),
      operations(const [reveal, move, delete]),
    ]);
    final home = panel.path;

    await panel.resources.row("First").operations.choose("Inspect");

    expect(panel.path, home);
    expect(panel.resources.selected, [first.bookId]);
    expect(panel.focused, "title");
  });

  testWidgets("Delete held on First deletes it and keeps Second", (
    tester,
  ) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(books: [first, second]),
      operations(const [reveal, move, delete]),
    ]);

    await panel.resources.row("First").select();
    await panel.holdKey(LogicalKeyboardKey.delete);

    await panel.eventually(
      () => expect(panel.resources.showing("First"), isFalse),
    );
    expect(panel.resources.showing("Second"), isTrue);
    expect(find.byType(AlertDialog), findsNothing);
    await panel.eventually(
      () => expect(
        panel.world.requireRealm.document.resource(first.bookId),
        isNull,
      ),
    );
  });

  testWidgets("Delete released early keeps First and never asks the Realm "
      "to prepare", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(books: [first, second]),
      operations(const [reveal, move, delete]),
    ]);

    await panel.resources.row("First").select();
    await panel.holdKey(LogicalKeyboardKey.delete, share: 0.4);

    expect(panel.resources.showing("First"), isTrue);
    expect(panel.world.requireRealm.prepares, 0);
  });

  testWidgets("Delete with two selected resources reads \"Delete 2 "
      "resources and what they own?\" before the hold", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(books: [first, second]),
      operations(const [reveal, move, delete]),
    ]);
    await panel.resources.row("First").select();
    await panel.resources.selectOnly([first.bookId, second.bookId]);

    expect(
      panel.holdHint("Delete 2 resources and what they own?"),
      "Destructive. Long press to confirm",
    );
  });

  testWidgets("an open menu keeps its resource when the selection changes", (
    tester,
  ) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(books: [first, second]),
      operations(const [reveal, move, delete]),
    ]);

    final menu = await panel.resources.row("First").contextMenu();
    await panel.resources.selectOnly([second.bookId]);
    await menu.choose("Open");

    expect(
      panel.path,
      "/organization/acme/realm/main/resource/${first.bookId.value}",
    );
  });

  testWidgets("a disabled operation shows its reason and does nothing", (
    tester,
  ) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(books: [first, second]),
      operations(const [
        RealmOperation.duplicate(disabledBecause: "The book is unavailable"),
        delete,
      ]),
    ]);
    const entry = "Duplicate (The book is unavailable)";

    final menu = await panel.resources.row("First").contextMenu();
    expect(menu.entries, contains(entry));
    expect(menu.isEnabled(entry), isFalse);
    final before = panel.world.requireRealm.document;
    await menu.choose(entry);

    expect(panel.world.requireRealm.document, same(before));
    expect(
      panel.path,
      isNot("/organization/acme/realm/main/resource/${first.bookId.value}"),
    );
  });

  testWidgets("a screen reader selects a Book in the Library and its long "
      "press on Delete deletes it", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(books: [first, second]),
      operations(const [reveal, move, delete]),
    ]);
    await panel.openSurface(libraryId);

    await panel.activateWithScreenReader("First");

    expect(
      semanticsButton("First").getSemanticsData().flagsCollection.isSelected,
      Tristate.isTrue,
    );
    expect(panel.resources.selected, [first.bookId]);
    await panel.longPressWithScreenReader(
      "Delete this resource and what it owns?",
    );
    await panel.eventually(
      () => expect(panel.resources.showing("First"), isFalse),
    );
    expect(panel.resources.showing("Second"), isTrue);
  });

  testWidgets("a screen reader selects a Tag on the tags graph", (
    tester,
  ) async {
    final legend = tag("Legend");
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(tags: [legend, tag("Myth")]),
    ]);
    await panel.openSurface(taxonomyId);

    await panel.activateWithScreenReader("Legend");

    expect(
      semanticsButton("Legend").getSemanticsData().flagsCollection.isSelected,
      Tristate.isTrue,
    );
    expect(panel.resources.selected, [legend.tagId]);
  });
}
