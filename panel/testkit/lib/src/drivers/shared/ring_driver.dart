import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// The panel's one focus ring, as the user sees it.
final class RingDriver {
  RingDriver(this.tester);

  final WidgetTester tester;

  Finder get _ring => find.byKey(Ring.ringKey);

  /// Whether the ring is on screen.
  bool get visible => _ring.evaluate().isNotEmpty;

  /// The rect the ring surrounds on screen.
  Rect get rect {
    _expectVisible();
    final width = tester.element(_ring).shapes.ringWidth;
    return tester.getRect(_ring).deflate(width);
  }

  /// The colour the ring is drawn in.
  Color get color {
    _expectVisible();
    final decoration =
        tester.widget<DecoratedBox>(_ring).decoration as BoxDecoration;
    return (decoration.border! as Border).top.color;
  }

  void _expectVisible() {
    if (!visible) throw TestFailure("No focus ring is on screen");
  }
}
