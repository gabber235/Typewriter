import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("a running action shows progress until it finishes", (
    tester,
  ) async {
    final completer = Completer<void>();
    var finished = false;
    final panel = await tester.showComponent(
      FloatingButton(
        icon: const Icon(Icons.add),
        onPressed: () async {
          await completer.future;
          finished = true;
        },
        child: const SizedBox.expand(child: Center(child: Text("Content"))),
      ),
    );
    expect(panel.shows("In progress"), isFalse);

    await tester.tap(find.byIcon(Icons.add));

    await panel.eventually(() {
      expect(panel.shows("In progress"), isTrue);
      expect(find.byIcon(Icons.add), findsNothing);
      expect(panel.shows("Content"), isTrue);
    });

    completer.complete();
    await panel.eventually(() {
      expect(finished, isTrue);
      expect(panel.shows("In progress"), isFalse);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });
  });

  testWidgets("a failed action reports its error in a snackbar and tooltip", (
    tester,
  ) async {
    final panel = await tester.showComponent(
      FloatingButton(
        icon: const Icon(Icons.add),
        onPressed: () => throw Exception("Boom"),
        child: const SizedBox.expand(child: Center(child: Text("Content"))),
      ),
    );

    await tester.tap(find.byIcon(Icons.add));
    await panel.settle();

    expect(find.textContaining("Boom"), findsOneWidget);
    expect(find.tooltip(RegExp("Boom")), findsOneWidget);
  });
}
