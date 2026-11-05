import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  for (final variant in LoadingIconButtonStyle.values) {
    group("LoadingIconButton.${variant.name}", () {
      testWidgets("shows a spinner while the action is running", (
        tester,
      ) async {
        final completer = Completer<void>();
        var invocations = 0;
        final panel = await tester.showComponent(
          variant.button(
            icon: const Icon(Icons.add, semanticLabel: "Add"),
            onPressed: () async {
              invocations++;
              await completer.future;
              invocations++;
            },
          ),
        );

        await tester.tap(panel.labeled("Add"));
        await panel.eventually(() {
          expect(invocations, 1);
          expect(panel.shows("Loading"), isTrue);
          expect(panel.shows("Add"), isFalse);
        });

        await tester.tap(panel.labeled("Loading"));
        expect(invocations, 1);

        completer.complete();
        await panel.eventually(() {
          expect(invocations, 2);
          expect(panel.shows("Loading"), isFalse);
          expect(panel.shows("Add"), isTrue);
        });
      });

      testWidgets("shows a snackbar and tooltip on failure", (tester) async {
        final panel = await tester.showComponent(
          variant.button(
            icon: const Icon(Icons.warning, semanticLabel: "Warn"),
            onPressed: () => throw Exception("Boom"),
          ),
        );

        await panel.tapOn(panel.labeled("Warn"));

        expect(find.text("Exception: Boom"), findsOneWidget);
        expect(find.tooltip("Exception: Boom"), findsOneWidget);
      });
    });
  }

  testWidgets("supports programmatic triggering", (tester) async {
    final completer = Completer<void>();
    final controller = LoadingButtonController();
    var invoked = false;
    final panel = await tester.showComponent(
      LoadingIconButton(
        controller: controller,
        icon: const Icon(Icons.save, semanticLabel: "Save"),
        onPressed: () async {
          invoked = true;
          await completer.future;
        },
      ),
    );

    expect(controller.trigger(), true);
    await panel.eventually(() {
      expect(invoked, true);
      expect(panel.shows("Loading"), isTrue);
    });
    expect(controller.trigger(), false);

    completer.complete();
    await panel.settle();

    expect(panel.shows("Save"), isTrue);
  });
}
