import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/drivers/component_driver.dart";
import "package:typewriter_testkit/src/drivers/inspector_driver.dart";
import "package:typewriter_testkit/src/drivers/panel_driver.dart";
import "package:typewriter_testkit/src/drivers/semantics.dart";
import "package:typewriter_testkit/src/drivers/shared/selectable_driver.dart";

/// The services page: the graph of services, hosts and the runtimes they run.
///
/// Each card reads as its kind, its name and its status, such as
/// `Paper host, Paper Eu, Active`.
final class ServicesDriver extends ComponentDriver {
  ServicesDriver(super.tester);

  List<SemanticsNode> get _cards => [
    for (final node
        in find.semantics
            .byPredicate((node) => node.isButton && node.spoken.contains(", "))
            .evaluate())
      if (node.spoken.split(", ").length == 3) node,
  ];

  /// The cards the graph shows, each read as kind, name and status.
  List<String> get cards => [for (final card in _cards) card.spoken];

  /// The card of the [kind] named [name], such as `card("Realm", "Paper Eu")`.
  SelectableDriver card(String kind, String name) {
    final matches = [
      for (final card in cards)
        if (card.startsWith("$kind, $name, ")) card,
    ];
    if (matches.isEmpty) {
      throw TestFailure(
        "The graph shows no $kind named $name; it shows $cards",
      );
    }
    return SelectableDriver(tester, matches.first);
  }

  /// The status the card of the [kind] named [name] reads.
  String statusOf(String kind, String name) =>
      card(kind, name).label.split(", ").last;
}

/// The services page of the panel.
extension ServicesOnPanel on PanelDriver {
  /// The services graph of the open organization.
  ServicesDriver get services => ServicesDriver(tester);
}

/// Inspector controls that are not text: check boxes and selects.
extension InspectorChoices on InspectorDriver {
  SemanticsNode _control(String label, bool Function(SemanticsNode) kind) =>
      find.semantics
          .byPredicate((node) => node.spoken.startsWith(label) && kind(node))
          .evaluate()
          .firstOrNull ??
      (throw TestFailure("The inspector has no control $label"));

  SemanticsNode _checkbox(String label) => _control(
    label,
    (node) =>
        node.getSemanticsData().flagsCollection.isChecked != CheckedState.none,
  );

  /// Whether the check box [label] is checked.
  bool isChecked(String label) =>
      _checkbox(label).getSemanticsData().flagsCollection.isChecked ==
      CheckedState.isTrue;

  /// Checks or clears the check box [label], the way activating it does.
  Future<void> toggle(String label) async {
    final checkbox = _checkbox(label);
    tester.semantics.tap(
      find.semantics.byPredicate((node) => identical(node, checkbox)),
    );
    await settle();
  }
}
