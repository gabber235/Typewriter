import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("dense card content fits a constrained grid cell", (
    tester,
  ) async {
    final panel = await tester.pumpPanel(
      const [],
      at: const PanelLocation.component(
        SizedBox(
          width: 180,
          height: 160,
          child: GridSelectableCard(
            title: "A service name that needs three lines",
            baseColor: Colors.blue,
            badgeLabel: "Custom",
            header: Icon(Icons.dns, size: 32),
            footer: StatusIndicator(isOnline: false),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(panel.shows("A service name that needs three lines"), isTrue);
    expect(panel.shows("Never"), isTrue);
  });

  testWidgets("selecting a card fades its fill in with ink, not at once", (
    tester,
  ) async {
    final panel = await tester.showComponent(
      const GridSelectableCard(title: "Realm", baseColor: Colors.blue),
    );
    final before = await panel.fillAt(find.text("Realm"));

    await tester.showComponent(
      const GridSelectableCard(
        title: "Realm",
        baseColor: Colors.blue,
        isSelected: true,
      ),
      settle: false,
    );
    await tester.pump(tester.settleTimeOf(MotionToken.ink) ~/ 3);
    final during = await panel.fillAt(find.text("Realm"));

    await panel.settle();
    final after = await panel.fillAt(find.text("Realm"));
    expect(during, isNot(before));
    expect(during, isNot(after));
  });
}
