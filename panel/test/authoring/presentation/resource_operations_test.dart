import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  final first = book("First");
  final second = book("Second");
  const reveal = RealmOperation.duplicate();
  const move = RealmOperation.moveTo();
  const delete = RealmOperation.delete();

  testWidgets("menus lead with Open and Inspect, then list the operations in "
      "a section per group with a divider between sections", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(books: [first, second]),
      operations(const [reveal, move, delete]),
    ]);

    final sections = await panel.resources
        .row("First")
        .operations
        .openSections();

    // Delete holds, so it is heard as the outcome it states.
    expect(sections, [
      ["Open", "Inspect"],
      ["Duplicate"],
      ["Move to"],
      ["Delete this resource and what it owns?"],
    ]);
  });

  testWidgets("the inspector offers the operations declared as buttons in "
      "the sections of the menu", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(books: [first, second]),
      operations(const [reveal, move, delete]),
    ]);

    await panel.resources.row("First").select();

    // Delete holds, so it is heard as the outcome it states.
    const heardDelete = "Delete this resource and what it owns?";
    expect(panel.inspector.operationSections, [
      ["Open"],
      ["Duplicate"],
      [heardDelete],
    ]);
    expect(panel.inspector.isEnabled(heardDelete), isTrue);
  });

  testWidgets("operations sent out of order are listed by group, then order, "
      "in the menu and the inspector alike", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(books: [first, second]),
      operations(const [
        delete,
        RealmOperation("Tag", group: skir.OperationGroup.organize, order: 20),
        RealmOperation("Pin", group: skir.OperationGroup.organize, order: 10),
        reveal,
      ]),
    ]);
    const heardDelete = "Delete this resource and what it owns?";

    await panel.resources.row("First").select();
    final inspector = panel.inspector.operationSections;
    final menu = await panel.resources.row("First").operations.openSections();

    expect(menu, [
      ["Open", "Inspect"],
      ["Duplicate"],
      ["Pin", "Tag"],
      [heardDelete],
    ]);
    expect(inspector, [
      ["Open"],
      ["Duplicate"],
      ["Pin", "Tag"],
      [heardDelete],
    ]);
  });

  testWidgets("a second operation declared filled shows flat beside the "
      "first", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(books: [first, second]),
      operations(const [
        RealmOperation(
          "Duplicate",
          group: skir.OperationGroup.edit,
          emphasis: skir.OperationEmphasis.filled,
        ),
        delete,
      ]),
    ]);

    await panel.resources.row("First").select();

    expect(panel.inspector.faceOf("Duplicate"), ButtonFace.filled);
    expect(panel.inspector.faceOf("Delete"), ButtonFace.quiet);
  });

  testWidgets("Delete held by D lasts a permanent hold: kept just before it "
      "ends, deleted once it ends", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(books: [first, second]),
      operations(const [reveal, move, delete]),
    ]);
    await panel.resources.row("First").select();
    final permanent = panel.holdDurationOf(HoldWeight.permanent);

    await panel.keyDown(LogicalKeyboardKey.keyD);
    await panel.holdForTime(permanent - const Duration(milliseconds: 100));
    expect(panel.world.requireRealm.prepares, 0);
    await panel.holdForTime(const Duration(milliseconds: 150));
    await panel.keyUp(LogicalKeyboardKey.keyD);

    await panel.eventually(
      () => expect(panel.resources.showing("First"), isFalse),
    );
  });

  testWidgets("Delete held by the pointer on the inspector button lasts a "
      "permanent hold", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(books: [first, second]),
      operations(const [reveal, move, delete]),
    ]);
    await panel.resources.row("First").select();
    final permanent = panel.holdDurationOf(HoldWeight.permanent);

    final pointer = await panel.pressButton(
      "Delete this resource and what it owns?",
    );
    await panel.holdForTime(permanent - const Duration(milliseconds: 100));
    expect(panel.world.requireRealm.prepares, 0);
    await panel.holdForTime(const Duration(milliseconds: 150));
    await pointer.up();
    await panel.settle();

    await panel.eventually(
      () => expect(panel.resources.showing("First"), isFalse),
    );
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
