import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  final first = book("First");

  for (final (state, traits, runs) in [
    ("online", <Trait>[], 1),
    ("offline", [realmHostStopped], 0),
  ]) {
    testWidgets("a mode shortcut ${runs == 0 ? "does nothing" : "runs"} "
        "while the Realm is $state", (tester) async {
      final mode = CountingMode();
      final panel = await tester.pumpPanel([
        signedIn(ada, organization: acme),
        realm(books: [first]),
        ...traits,
      ]);
      panel.container
          .read(currentInteractionModeProvider.notifier)
          .setMode(mode);
      await panel.settle();

      await panel.press(LogicalKeyboardKey.keyR);

      expect(mode.runs, runs);
    });
  }
}
