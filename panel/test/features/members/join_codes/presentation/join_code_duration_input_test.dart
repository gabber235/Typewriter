import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("a join code duration under 1 hour is rejected and not used", (
    tester,
  ) async {
    final chosen = <Duration>[];
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        DurationInput(
          duration: const Duration(days: 7),
          onDurationChanged: chosen.add,
        ),
      ),
    );

    await panel.fieldAt(0).type("30m");

    expect(panel.shows("Duration must be at least 1 hour"), isTrue);
    expect(chosen, isEmpty);

    await panel.fieldAt(0).type("2h");

    expect(panel.shows("Duration must be at least 1 hour"), isFalse);
    expect(chosen.last, const Duration(hours: 2));
  });
}
