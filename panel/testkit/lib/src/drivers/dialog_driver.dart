import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/drivers/component_driver.dart";
import "package:typewriter_testkit/src/drivers/semantics.dart";

/// The dialog in front of the panel, found by the message it shows.
final class DialogDriver extends ComponentDriver {
  DialogDriver(super.tester);

  /// Whether a dialog shows [message].
  bool showing(String message) => _dialog(message) != null;

  SemanticsNode? _dialog(String message) {
    final nodes = find.semantics
        .byPredicate((node) => node.spoken.contains(message))
        .evaluate();
    return nodes.isEmpty ? null : nodes.last.route;
  }

  /// Chooses the button [label] of the dialog showing [message].
  Future<void> choose(String label, {required String message}) async {
    final dialog =
        _dialog(message) ?? (throw TestFailure("No dialog shows \"$message\""));
    await tester.tapAt(dialog.button(label).screenRect.center);
    await settle();
  }
}
