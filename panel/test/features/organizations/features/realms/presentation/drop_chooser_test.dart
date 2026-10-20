import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../../../support/test_utils.dart";

void main() {
  testWidgets("arrow keys move between offers where the platform does not", (
    tester,
  ) async {
    final offers = [
      DropOffer.link(
        location: skir.ValueLocation(
          resource: skir.ResourceId(value: "page:one"),
          path: editorRootPath.field("links"),
        ),
      ),
      DropOffer.regroup(field: editorRootPath.field("group"), value: "a"),
      DropOffer.regroup(field: editorRootPath.field("group"), value: "b"),
    ];
    final chosen = <DropOffer?>[];
    await tester.pumpTestApp(
      // Web platform defaults bind arrow keys to scrolling, never to focus
      // traversal.
      child: Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.arrowDown):
              DoNothingAndStopPropagationIntent(),
          SingleActivator(LogicalKeyboardKey.arrowUp):
              DoNothingAndStopPropagationIntent(),
        },
        child: Center(
          child: DropChooser(offers: offers, onChoose: chosen.add),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(chosen, [offers[1]]);
  });
}
