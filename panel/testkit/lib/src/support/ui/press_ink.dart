import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// How a button's press splash looks right now.
extension PressInkReading on WidgetTester {
  /// The splash of the one button [button] finds, or null when it shows none.
  PressInk? inkOf(Finder button) {
    final paints = find.descendant(
      of: button,
      matching: find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.painter is PressInk,
      ),
    );
    if (paints.evaluate().isEmpty) return null;
    final ink = widget<CustomPaint>(paints.first).painter! as PressInk;
    return ink.opacity > 0 ? ink : null;
  }
}
