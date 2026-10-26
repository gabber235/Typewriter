import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/drivers/component_driver.dart";
import "package:typewriter_testkit/src/drivers/semantics.dart";

/// The inspector: the selected resources' fields and operations.
final class InspectorDriver extends ComponentDriver {
  InspectorDriver(super.tester);

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

  /// Whether the operation button [label] can be pressed.
  bool isEnabled(String label) => _button(label).isEnabled;

  /// Presses the operation button [label].
  Future<void> run(String label) async {
    await tester.tapAt(_button(label).screenRect.center);
    await settle();
  }
}
