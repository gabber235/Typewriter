import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/compiled_sdk_controls.stories.dart";

import "support/stories.dart";

void main() {
  for (final width in ["280", "400"]) {
    testWidgets("a $width wide Book inspector offers Iconify and SVG icons", (
      tester,
    ) async {
      final panel = await tester.pumpStory(
        compiledBookUseCase,
        knobs: {"Inspector width": width},
      );

      expect(panel.shows("Iconify"), isTrue);
      expect(panel.shows("SVG"), isTrue);
      expect(panel.shows("Iconify identifier"), isFalse);
    });
  }

  testWidgets("searching icons chooses the one the user picks", (tester) async {
    final panel = await tester.pumpStory(compiledBookUseCase);

    await tester.tapInStory(
      find.byKey(const ValueKey("authored_search_summary")),
    );
    await tester.tapInStory(find.text("mdi:account").last);

    expect(panel.shows("mdi:account"), isTrue);
  });

  testWidgets("Escape closes the icon search and keeps the chosen icon", (
    tester,
  ) async {
    final panel = await tester.pumpStory(compiledBookUseCase);
    await tester.tapInStory(
      find.byKey(const ValueKey("authored_search_summary")),
    );
    await tester.tapInStory(find.text("mdi:home").last);

    await tester.tapInStory(
      find.byKey(const ValueKey("authored_search_summary")),
    );
    await panel.press(LogicalKeyboardKey.arrowDown);
    await panel.press(LogicalKeyboardKey.escape);

    expect(panel.shows("mdi:home"), isTrue);
  });

  testWidgets("an SVG icon takes its source as text", (tester) async {
    final panel = await tester.pumpStory(compiledBookUseCase);
    const svg =
        '<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="9"/></svg>';

    await panel.tapOn(find.text("SVG"));
    final source = panel.fieldAt(visibleFieldValues().length - 1);
    await source.enter(svg);

    expect(source.value, svg);
    expect(panel.shows("Iconify identifier"), isFalse);
  });

  testWidgets("a Placement lays X and Y out side by side and keeps an exact "
      "write", (tester) async {
    final panel = await tester.pumpStory(
      compiledPlacementUseCase,
      knobs: {"Placement width": "340"},
    );
    final x = panel.field("X");
    final y = panel.field("Y");
    expect(x.rect.width, closeTo(y.rect.width, 0.01));
    expect(y.rect.left, greaterThan(x.rect.left));

    await x.type("42");
    await panel.press(LogicalKeyboardKey.escape);

    expect(x.value, "42");
    expect(y.value, "0");
  });

  testWidgets("a Tag edits its nested Placement once", (tester) async {
    final panel = await tester.pumpStory(
      compiledTagUseCase,
      knobs: {"Tag width": "340"},
    );

    await panel.field("Y").enter("13");

    expect(panel.field("Y").value, "13");
    expect(panel.field("X").value, "0");
  });
}
