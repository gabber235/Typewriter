import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  for (final variant in LoadingVariant.values) {
    for (final shape in LoadingButtonShape.values) {
      group("LoadingButton.${variant.name} with a ${shape.name}", () {
        testWidgets("runs the action once and shows a spinner while it runs", (
          tester,
        ) async {
          final completer = Completer<void>();
          final steps = <int>[];
          final panel = await tester.showComponent(
            shape.button(
              variant: variant,
              label: "Go",
              onPressed: () async {
                steps.add(1);
                await completer.future;
                steps.add(2);
              },
            ),
          );
          expect(panel.says("Loading"), isFalse);

          await tester.tap(find.text("Go"));
          await panel.eventually(() {
            expect(steps, [1]);
            expect(panel.says("Loading"), isTrue);
            // The plain button swaps its label for the spinner; the icon
            // button keeps its label and swaps its icon.
            expect(panel.says("Go"), shape == LoadingButtonShape.icon);
            expect(panel.says("Add"), isFalse);
          });

          await tester.tap(find.bySemanticsLabel(RegExp("Loading")));
          expect(steps, [1]);

          completer.complete();
          await panel.eventually(() {
            expect(steps, [1, 2]);
            expect(panel.says("Loading"), isFalse);
            expect(panel.says("Go"), isTrue);
            expect(panel.says("Add"), shape == LoadingButtonShape.icon);
          });
        });

        testWidgets("shows a failure in a snackbar and a tooltip", (
          tester,
        ) async {
          final panel = await tester.showComponent(
            shape.button(
              variant: variant,
              label: "Fail",
              onPressed: () => throw Exception("Boom"),
            ),
          );

          await panel.tapOn(find.text("Fail"));

          expect(find.text("Exception: Boom"), findsOneWidget);
          expect(find.tooltip("Exception: Boom"), findsOneWidget);
        });
      });
    }
  }

  group("LoadingButtonController", () {
    for (final shape in LoadingButtonShape.values) {
      testWidgets("triggers a button with a ${shape.name} like a press", (
        tester,
      ) async {
        final completer = Completer<void>();
        final steps = <int>[];
        final controller = LoadingButtonController();
        final panel = await tester.showComponent(
          shape.button(
            controller: controller,
            label: "Go",
            onPressed: () async {
              steps.add(1);
              await completer.future;
              steps.add(2);
            },
          ),
        );

        expect(controller.trigger(), isTrue);
        await panel.eventually(() {
          expect(steps, [1]);
          expect(panel.says("Loading"), isTrue);
        });

        completer.complete();
        await panel.eventually(() {
          expect(steps, [1, 2]);
          expect(panel.says("Loading"), isFalse);
        });
      });
    }

    testWidgets("refuses to trigger a disabled button", (tester) async {
      final controller = LoadingButtonController();
      await tester.showComponent(
        LoadingButtonShape.label.button(
          controller: controller,
          label: "Disabled",
          onPressed: null,
        ),
      );

      expect(controller.trigger(), isFalse);
    });

    testWidgets("refuses to trigger a button that is still running", (
      tester,
    ) async {
      final completer = Completer<void>();
      final steps = <int>[];
      final controller = LoadingButtonController();
      final panel = await tester.showComponent(
        LoadingButtonShape.label.button(
          controller: controller,
          label: "Go",
          onPressed: () async {
            steps.add(1);
            await completer.future;
            steps.add(2);
          },
        ),
      );

      controller.trigger();
      await panel.eventually(() => expect(panel.says("Loading"), isTrue));

      expect(controller.trigger(), isFalse);
      expect(steps, [1]);

      completer.complete();
      await panel.settle();
    });

    testWidgets("shows a failure of a triggered action", (tester) async {
      final controller = LoadingButtonController();
      final panel = await tester.showComponent(
        LoadingButtonShape.label.button(
          controller: controller,
          label: "Fail",
          onPressed: () => throw Exception("Boom"),
        ),
      );

      controller.trigger();
      await panel.settle();

      expect(find.text("Exception: Boom"), findsOneWidget);
      expect(controller.lastError, "Exception: Boom");
    });

    testWidgets("reports whether the button is running", (tester) async {
      final completer = Completer<void>();
      final controller = LoadingButtonController();
      final panel = await tester.showComponent(
        LoadingButtonShape.label.button(
          controller: controller,
          label: "Test",
          onPressed: () => completer.future,
        ),
      );
      expect(controller.isLoading, isFalse);
      expect(controller.canTrigger, isTrue);

      controller.trigger();
      await tester.pump();

      expect(controller.isLoading, isTrue);
      expect(controller.canTrigger, isFalse);

      completer.complete();
      await panel.settle();

      expect(controller.isLoading, isFalse);
      expect(controller.canTrigger, isTrue);
    });
  });
}
