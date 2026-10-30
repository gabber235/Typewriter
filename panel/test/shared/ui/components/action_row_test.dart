import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets(
    "an action in the row shows progress until it finishes and runs once",
    (tester) async {
      final finish = Completer<void>();
      var runs = 0;
      final panel = await tester.pumpPanel(
        const [],
        at: PanelLocation.component(
          ActionSurface([
            numberedAction(
              0,
              onInvoke: (_) {
                runs++;
                return finish.future;
              },
            ),
          ]),
        ),
      );

      await tester.tap(find.text("Action 0"));
      await tester.pump();

      // The spinner's label joins the action's own in what the user hears.
      expect(find.bySemanticsLabel(RegExp("Loading")), findsOneWidget);

      await tester.tap(find.text("Action 0"), warnIfMissed: false);
      await tester.pump();
      finish.complete();
      await panel.settle();

      expect(find.bySemanticsLabel(RegExp("Loading")), findsNothing);
      expect(runs, 1);
    },
  );
}
