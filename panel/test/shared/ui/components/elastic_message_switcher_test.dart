import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("a new message replaces the old one after a transition", (
    tester,
  ) async {
    final panel = await tester.showComponent(
      const ElasticMessageSwitcher(
        child: Text("First", key: ValueKey("First")),
      ),
    );
    expect(panel.shows("First"), isTrue);

    await tester.showComponent(
      const ElasticMessageSwitcher(
        child: Text("Second", key: ValueKey("Second")),
      ),
      settle: false,
    );
    expect(panel.shows("First"), isTrue);
    expect(panel.shows("Second"), isTrue);

    await tester.pump(
      tester.settleTimeOf(MotionToken.listOut) +
          const Duration(milliseconds: 20),
    );
    expect(panel.shows("First"), isFalse);
    expect(panel.shows("Second"), isTrue);
  });

  testWidgets("a removed message leaves after a transition", (tester) async {
    final panel = await tester.showComponent(
      const ElasticMessageSwitcher(
        child: Text("Message", key: ValueKey("Message")),
      ),
    );

    await tester.showComponent(
      const ElasticMessageSwitcher(child: null),
      settle: false,
    );
    expect(panel.shows("Message"), isTrue);

    await tester.pump(
      tester.settleTimeOf(MotionToken.listOut) +
          const Duration(milliseconds: 20),
    );
    expect(panel.shows("Message"), isFalse);
  });
}
