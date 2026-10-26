import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  final first = book("First");
  final second = book("Second");
  const reveal = RealmOperation.duplicate();
  const move = RealmOperation.moveTo();
  const delete = RealmOperation.delete();

  Future<PanelDriver> pump(
    WidgetTester tester, {
    List<RealmOperation> offered = const [reveal, move, delete],
  }) => tester.pumpPanel([
    signedIn(ada, organization: acme),
    realm(books: [first, second]),
    operations(offered),
  ]);

  String resourcePath(Book book) =>
      "/organization/acme/realm/main/resource/${book.bookId.value}";

  testWidgets("menus lead with Open and Inspect, then list the operations by "
      "group", (tester) async {
    final panel = await pump(tester);

    final entries = await panel.resources.row("First").operations.open();

    expect(entries, ["Open", "Inspect", "Duplicate", "Move to", "Delete"]);
  });

  testWidgets("the inspector offers the operations declared as buttons", (
    tester,
  ) async {
    final panel = await pump(tester);

    await panel.resources.row("First").select();

    expect(panel.inspector.operations, ["Open", "Duplicate", "Delete"]);
    expect(panel.inspector.isEnabled("Delete"), isTrue);
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
      final panel = await pump(tester);

      await openWith(panel);

      expect(panel.path, resourcePath(first));
    });
  }

  testWidgets("Inspect selects the resource and moves focus into the "
      "inspector without navigating", (tester) async {
    final panel = await pump(tester);
    final home = panel.path;

    await panel.resources.row("First").operations.choose("Inspect");

    expect(panel.path, home);
    expect(panel.resources.selected, [first.bookId]);
    expect(panel.focused, "title");
  });

  testWidgets("the Delete key asks for the confirmation the Realm returns "
      "and deletes only once confirmed", (tester) async {
    final panel = await pump(tester);
    const question = "Delete the selected resources?";

    await panel.resources.row("First").select();
    await panel.press(LogicalKeyboardKey.delete);
    expect(panel.dialog.showing(question), isTrue);
    await panel.dialog.choose("Cancel", message: question);
    expect(panel.resources.showing("First"), isTrue);

    await panel.press(LogicalKeyboardKey.delete);
    await panel.dialog.choose("Delete", message: question);

    expect(panel.resources.showing("First"), isFalse);
    expect(panel.resources.showing("Second"), isTrue);
    await panel.eventually(
      () => expect(
        panel.world.requireRealm.document.resource(first.bookId),
        isNull,
      ),
    );
  });

  testWidgets("an open menu keeps its resource when the selection changes", (
    tester,
  ) async {
    final panel = await pump(tester);

    final menu = await panel.resources.row("First").contextMenu();
    await panel.resources.selectOnly([second.bookId]);
    await menu.choose("Open");

    expect(panel.path, resourcePath(first));
  });

  testWidgets("a disabled operation shows its reason and does nothing", (
    tester,
  ) async {
    final panel = await pump(
      tester,
      offered: const [
        RealmOperation.duplicate(disabledBecause: "The book is unavailable"),
        delete,
      ],
    );
    const entry = "Duplicate (The book is unavailable)";

    final menu = await panel.resources.row("First").contextMenu();
    expect(menu.entries, contains(entry));
    expect(menu.isEnabled(entry), isFalse);
    final before = panel.world.requireRealm.document;
    await menu.choose(entry);

    expect(panel.world.requireRealm.document, same(before));
    expect(panel.path, isNot(resourcePath(first)));
  });
}
