import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("a separator draws one faint line across its parent, with room "
      "above and below", (tester) async {
    await tester.pumpPanel(
      const [],
      at: const PanelLocation.component(
        SizedBox(width: 200, child: Separator()),
      ),
    );

    final line = tester.widget<ColoredBox>(
      find.descendant(
        of: find.byType(Separator),
        matching: find.byType(ColoredBox),
      ),
    );
    final element = tester.element(find.byType(Separator));
    expect(line.color, element.colors.contentSecondary.withValues(alpha: 0.2));
    expect(tester.getSize(find.byType(ColoredBox).last).height, 1);
    expect(tester.getSize(find.byType(ColoredBox).last).width, 200);
    expect(
      tester.getSize(find.byType(Separator)).height,
      1 + 2 * element.spacing.space1,
    );
  });
}
