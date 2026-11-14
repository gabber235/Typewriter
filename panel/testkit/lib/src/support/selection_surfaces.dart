import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

/// A panel surface of three selectables, for the tests that hold every
/// surface to one selection model.
final class SelectionSurfaceCase {
  const SelectionSurfaceCase._({
    required this.name,
    required this.items,
    required this.forward,
    required this._open,
    required this._item,
  });

  /// What the surface is, for test names.
  final String name;

  /// The names its items show, in visible order.
  final List<String> items;

  /// The arrow that moves focus from the first item to the second.
  final LogicalKeyboardKey forward;

  /// The arrow that moves focus from the second item back to the first.
  LogicalKeyboardKey get back => switch (forward) {
    LogicalKeyboardKey.arrowRight => LogicalKeyboardKey.arrowLeft,
    _ => LogicalKeyboardKey.arrowUp,
  };

  final Future<PanelDriver> Function(WidgetTester tester) _open;
  final SelectableDriver Function(PanelDriver panel, String item) _item;

  /// Shows the surface, with focus on its first item.
  Future<PanelDriver> open(WidgetTester tester) async {
    final panel = await _open(tester);
    await panel.eventually(() => expect(panel.focused, contains(items.first)));
    return panel;
  }

  /// The item showing [name].
  SelectableDriver item(PanelDriver panel, String name) => _item(panel, name);

  /// The items the panel marks selected, in visible order.
  List<String> selectedIn(PanelDriver panel) => [
    for (final name in items)
      if (item(panel, name).isMarkedSelected) name,
  ];

  /// The items showing the check of select mode, in visible order.
  List<String> checkedIn(PanelDriver panel) => [
    for (final name in items)
      if (item(panel, name).showsCheck) name,
  ];

  /// The Library's list of Books.
  static final library = SelectionSurfaceCase._(
    name: "the Library's Books",
    items: const ["Atlas", "Mosaic", "Zebra"],
    forward: LogicalKeyboardKey.arrowRight,
    open: (tester) async {
      final panel = await tester.pumpPanel([
        signedIn(ada, organization: acme),
        realm(books: [book("Atlas"), book("Mosaic"), book("Zebra")]),
      ]);
      await panel.openSurface(libraryId);
      return panel;
    },
    item: (panel, name) => panel.resources.row(name),
  );

  /// The services graph's cards.
  static final services = SelectionSurfaceCase._(
    name: "the services graph",
    items: const ["Alpha", "Beta", "Gamma"],
    forward: LogicalKeyboardKey.arrowRight,
    open: (tester) => tester.pumpPanel([
      signedIn(ada, organization: acme),
      servicesService(
        services: [
          for (final name in ["alpha", "beta", "gamma"])
            service(
              name,
              name: name,
              role: skir.ServiceRole.createCustom(name: name, version: "1.0.0"),
              organization: acme.organizationId,
              createdAt: DateTime.utc(2026, 8, 20),
            ),
        ],
      ),
    ]),
    item: (panel, name) {
      final card = panel.services.cards.firstWhere(
        (card) => card.contains(", $name, "),
        orElse: () => throw TestFailure(
          "The graph shows no card named $name; it shows "
          "${panel.services.cards}",
        ),
      );
      return SelectableDriver(panel.tester, card);
    },
  );

  /// Every surface held to the selection model.
  static final all = [library, services];

  @override
  String toString() => name;
}
