import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/drivers/component_driver.dart";

/// How a user asks for a component's context menu.
enum ContextGesture {
  /// A secondary mouse click.
  secondaryClick,

  /// A long press on a touch screen.
  longPress,

  /// A click with Control held, the context click on Apple platforms.
  controlClick,
}

/// One selectable item, found by the label the user reads on it.
///
/// Every item the panel lets users select, inspect and act on behaves the
/// same way, so feature drivers extend this one.
class SelectableDriver extends ComponentDriver {
  SelectableDriver(super.tester, this.label);

  final String label;

  Finder get _item => labeled(label).first;

  /// Where the item is on screen.
  Rect get rect => tester.getRect(_item);

  /// Toggles the item's selection with a click.
  Future<void> select() => tapOn(_item);

  /// Opens the item with a double click.
  Future<void> open() async {
    await tester.tap(_item);
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tap(_item);
    await settle();
  }

  /// Asks for the item's context menu with [gesture].
  ///
  /// The menu may open later, once the item resolved; read it from
  /// [ContextMenuDriver].
  Future<ContextMenuDriver> contextMenu({
    ContextGesture gesture = ContextGesture.secondaryClick,
  }) async {
    switch (gesture) {
      case ContextGesture.secondaryClick:
        await tester.tap(_item, buttons: kSecondaryMouseButton);
      case ContextGesture.longPress:
        await tester.longPress(_item);
      case ContextGesture.controlClick:
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.tap(_item);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    }
    await settle();
    return ContextMenuDriver(tester);
  }
}
