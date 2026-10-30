import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("an offline subject shows how long ago it was last seen, "
      "kept current as time passes", (tester) async {
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        StatusIndicator(
          isOnline: false,
          lastSeen: clock.now().subtract(
            const Duration(minutes: 5, seconds: 5),
          ),
        ),
      ),
    );
    expect(panel.shows("5m ago"), isTrue);

    await tester.pump(const Duration(minutes: 1));
    await panel.settle();

    expect(panel.shows("6m ago"), isTrue);
  });

  testWidgets("an online subject reads as online", (tester) async {
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        StatusIndicator(isOnline: true, lastSeen: clock.now()),
      ),
    );

    expect(panel.shows("Online"), isTrue);
  });
}
