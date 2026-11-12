import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/core/pump_panel.dart";
import "package:typewriter_testkit/src/core/stage.dart";
import "package:typewriter_testkit/src/core/trait.dart";
import "package:typewriter_testkit/src/drivers/panel_driver.dart";

/// A table row's keyboard shortcuts, mounted alone with keyboard focus inside
/// the row, as when the user moved there with the arrow keys.
final class FocusedRowDriver {
  FocusedRowDriver._(this.panel, this.invoked);

  /// The panel the row is mounted in, for dialogs the shortcuts open.
  final PanelDriver panel;

  /// The names of the row callbacks the pressed keys invoked, in order.
  final List<String> invoked;

  /// Presses [key], with Shift held when [shifted].
  Future<void> press(LogicalKeyboardKey key, {bool shifted = false}) =>
      shifted ? panel.pressShifted(key) : panel.press(key);
}

/// Mounting a table row's shortcuts for a keyboard test.
extension PumpFocusedRow on WidgetTester {
  /// Pumps the row [build] returns over a world built from [traits], with
  /// focus on the row's content.
  ///
  /// [build] receives the content to wrap and `record`, which turns a
  /// callback name into a callback that remembers it was invoked, such as
  /// `onSelectAll: record("select all")`.
  Future<FocusedRowDriver> pumpFocusedRow(
    List<Trait> traits,
    Widget Function(Widget content, VoidCallback Function(String) record) build,
  ) async {
    final invoked = <String>[];
    final focus = FocusNode();
    addTearDown(focus.dispose);
    final panel = await pumpPanel(
      traits,
      at: PanelLocation.component(
        build(
          Focus(focusNode: focus, child: const SizedBox.square(dimension: 20)),
          (name) =>
              () => invoked.add(name),
        ),
      ),
    );
    focus.requestFocus();
    await panel.settle();
    return FocusedRowDriver._(panel, invoked);
  }
}

/// How a test names [key] pressed with Shift held when [shifted], such as
/// `Shift+Space`.
String keyName(LogicalKeyboardKey key, {bool shifted = false}) =>
    "${shifted ? "Shift+" : ""}${key.keyLabel}";
