import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Reading a [SelectionCheck] on screen.
extension SelectionCheckReading on WidgetTester {
  /// The fill of the only [SelectionCheck] on screen, as painted now.
  Color get selectionCheckFill {
    final box = widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(SelectionCheck),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    return (box.decoration as BoxDecoration).color!;
  }
}
