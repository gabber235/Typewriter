import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("a taller child grows the size over time", (tester) async {
    await tester.showComponent(const MotionSizeStage(height: 20));
    await tester.showComponent(
      const MotionSizeStage(height: 80),
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 40));

    final growing = tester.getSize(find.byType(MotionSize)).height;
    expect(growing, greaterThan(20));
    expect(growing, lessThan(80));

    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(MotionSize)).height, 80);
  });

  testWidgets("with reduced motion a taller child lands at once", (
    tester,
  ) async {
    await tester.showComponent(
      const MotionSizeStage(height: 20, reduced: true),
    );
    await tester.showComponent(
      const MotionSizeStage(height: 80, reduced: true),
      settle: false,
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(MotionSize)).height, 80);
  });

  testWidgets("typed text stays when reduced motion turns on and off", (
    tester,
  ) async {
    const field = TextField();
    await tester.showComponent(const MotionSizeStage(height: 40, child: field));
    await tester.enterText(find.byType(TextField), "kept");

    for (final reduced in [true, false]) {
      await tester.showComponent(
        MotionSizeStage(height: 40, reduced: reduced, child: field),
      );

      expect(find.text("kept"), findsOneWidget, reason: "reduced: $reduced");
    }
  });
}
