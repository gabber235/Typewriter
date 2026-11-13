import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/core/pump_panel.dart";
import "package:typewriter_testkit/src/core/stage.dart";
import "package:typewriter_testkit/src/drivers/component_driver.dart";
import "package:typewriter_testkit/src/drivers/panel_driver.dart";
import "package:typewriter_testkit/src/drivers/semantics.dart";

/// The inspector: the selected resources' fields and operations.
final class InspectorDriver extends ComponentDriver {
  InspectorDriver(super.tester);

  /// The inspector panes on screen that have room to show something.
  List<Rect> get panes => [
    for (final pane in semanticsLabeled(InspectorScaffold.semanticsLabel))
      if (pane.screenRect case final rect when !rect.isEmpty) rect,
  ];

  /// Where the one open inspector pane is on screen.
  Rect get rect => switch (panes) {
    [final pane] => pane,
    final panes => throw TestFailure(
      "Expected one open inspector, found ${panes.length}",
    ),
  };

  /// Drags the open inspector by [offset] from its top edge, the way a
  /// phone user pulls its sheet up.
  Future<void> pull(Offset offset) async {
    final pane = rect;
    await tester.dragFrom(pane.topCenter + const Offset(0, 8), offset);
    await settle();
  }

  /// The heading [text] the inspector shows, such as the title of the
  /// selected item.
  Finder heading(String text) => find.text(text, findRichText: true);

  /// Expects the heading [text] to lie whole inside the open inspector and
  /// nothing to have overflowed.
  void expectHeadingInside(String text) {
    final pane = rect;
    final shown = tester.getRect(heading(text));
    expect(pane.contains(shown.topLeft), isTrue, reason: "$shown in $pane");
    expect(pane.contains(shown.bottomRight - const Offset(1, 1)), isTrue);
    expect(tester.takeException(), isNull);
  }

  /// Moves keyboard focus into the inspector by clicking its heading [text].
  Future<void> focusHeading(String text) => tapOn(heading(text));

  /// Whether an inspector pane is open.
  bool get isOpen => panes.isNotEmpty;

  /// The texts the open inspector shows, in reading order.
  List<String> get texts => [
    for (final node in semanticsLabeled(
      InspectorScaffold.semanticsLabel,
    ).expand((pane) => pane.descendants))
      if (node.spoken.isNotEmpty) node.spoken,
  ];

  /// The buttons the inspector lists under its Operations heading.
  List<SemanticsNode> get _buttons {
    final heading = semanticsLabeled("Operations").lastOrNull;
    final section = heading?.parent;
    if (heading == null || section == null) {
      throw TestFailure("The inspector shows no operations");
    }
    final buttons = <SemanticsNode>[];
    var below = false;
    section.visitChildren((child) {
      if (identical(child, heading)) {
        below = true;
      } else if (below) {
        buttons.addAll(
          [child, ...child.descendants].where((node) => node.isButton),
        );
      }
      return true;
    });
    return buttons;
  }

  SemanticsNode _button(String label) =>
      _buttons.firstWhereOrNull((button) => button.spoken == label) ??
      (throw TestFailure(
        "The inspector offers no operation $label; it offers $operations",
      ));

  /// The operations the inspector offers as buttons, in reading order.
  List<String> get operations => [for (final button in _buttons) button.spoken];

  /// The operations in the sections the inspector's divider lines split
  /// them into.
  List<List<String>> get operationSections => splitAtSeparators(_buttons);

  /// How the operation button labeled [label] stands out: its face, which
  /// only its look shows. A held button is heard as its outcome line, so
  /// this takes the label it shows.
  ButtonFace faceOf(String label) {
    final buttons = find
        .descendant(
          of: find.byType(InspectorOperations),
          matching: find.byWidgetPredicate(
            (widget) => widget is Button && widget.label == label,
          ),
        )
        .evaluate()
        .map((element) => element.widget as Button)
        .toList();
    return switch (buttons) {
      [final button] => button.face,
      _ => throw TestFailure(
        "Expected one button labeled $label, found ${buttons.length}",
      ),
    };
  }

  /// Whether the operation button [label] can be pressed.
  bool isEnabled(String label) => _button(label).isEnabled;

  /// Presses the operation button [label].
  Future<void> run(String label) async {
    await tester.tapAt(_button(label).screenRect.center);
    await settle();
  }
}

/// An inspector beside a page on a desktop.
extension PumpDesktopInspector on WidgetTester {
  /// Pumps an [InspectorScaffold] of 1600 by 800 pixels showing [page]
  /// beside the inspector.
  Future<PanelDriver> pumpDesktopInspector({
    Widget page = const SizedBox.expand(),
  }) => pumpPanel(
    const [],
    at: PanelLocation.component(
      SizedBox(width: 1600, height: 800, child: InspectorScaffold(child: page)),
    ),
  );
}
