import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  for (final face in ButtonFace.values.where(
    (face) => face != ButtonFace.bare,
  )) {
    group("a ${face.name} button", () {
      testWidgets("a busy button types its busy word and keeps its icon", (
        tester,
      ) async {
        final completer = Completer<void>();
        final panel = await tester.showComponent(
          busyButton(
            face,
            label: "Publish",
            busyLabel: "Publishing",
            onPressed: () => completer.future,
          ),
        );

        await tester.tap(find.byType(Button));
        await panel.eventually(() {
          expect(panel.says("Publishing"), isTrue);
          expect(find.byType(CircularProgressIndicator), findsNothing);
          expect(find.byIcon(Icons.add), findsOneWidget);
        });

        completer.complete();
        await panel.eventually(() => expect(panel.says("Publishing"), isFalse));
        expect(panel.says("Publish"), isTrue);
      });

      testWidgets(
        "a failing press shakes the button, which can be pressed again with the same label",
        (tester) async {
          var runs = 0;
          final panel = await tester.showComponent(
            busyButton(
              face,
              label: "Publish",
              busyLabel: "Publishing",
              onPressed: () async {
                runs++;
                throw Exception("The realm did not answer.");
              },
            ),
          );
          final rest = tester.getTopLeft(find.byType(ButtonContent)).dx;

          await tester.tap(find.byType(Button));
          final offsets = <double>[];
          for (var frame = 0; frame < 12; frame++) {
            await tester.pump(const Duration(milliseconds: 16));
            offsets.add(
              tester.getTopLeft(find.byType(ButtonContent)).dx - rest,
            );
          }
          expect(offsets.any((dx) => dx.abs() > 1), isTrue);

          await panel.settle();
          expect(tester.getTopLeft(find.byType(ButtonContent)).dx, rest);
          expect(panel.reads("Publish"), isTrue);

          await tester.tap(find.byType(Button));
          await panel.settle();
          expect(runs, 2);
        },
      );

      testWidgets(
        "with reduced motion a failing press keeps the button still",
        (tester) async {
          final panel = await tester.showComponent(
            ReducedMotion(
              child: busyButton(
                face,
                label: "Publish",
                busyLabel: "Publishing",
                onPressed: () => throw Exception("The realm did not answer."),
              ),
            ),
          );
          final rest = tester.getTopLeft(find.byType(ButtonContent)).dx;

          await tester.tap(find.byType(Button));
          for (var frame = 0; frame < 12; frame++) {
            await tester.pump(const Duration(milliseconds: 16));
            expect(tester.getTopLeft(find.byType(ButtonContent)).dx, rest);
          }
          await panel.settle();
        },
      );
    });
  }

  testWidgets("a failed press reports its error in plain words", (
    tester,
  ) async {
    final panel = await tester.showComponent(
      busyButton(
        ButtonFace.filled,
        label: "Publish",
        busyLabel: "Publishing",
        onPressed: () => throw Exception("The realm did not answer."),
      ),
    );

    await panel.tapOn(find.byType(Button));

    expect(panel.shows("Exception: The realm did not answer."), isTrue);
  });

  group("ButtonController", () {
    testWidgets("triggers a button like a press", (tester) async {
      final action = SteppedAction();
      final controller = ButtonController();
      final panel = await tester.showComponent(
        busyButton(
          ButtonFace.filled,
          controller: controller,
          onPressed: action.run,
        ),
      );

      expect(controller.trigger(), isTrue);
      await panel.eventually(() {
        expect(action.steps, [1]);
        expect(panel.says("Going"), isTrue);
      });

      action.finish();
      await panel.eventually(() {
        expect(action.steps, [1, 2]);
        expect(panel.says("Going"), isFalse);
      });
    });

    testWidgets("refuses to trigger a disabled button", (tester) async {
      final controller = ButtonController();
      await tester.showComponent(
        busyButton(
          ButtonFace.filled,
          controller: controller,
          label: "Disabled",
          busyLabel: "Disabling",
          onPressed: null,
        ),
      );

      expect(controller.trigger(), isFalse);
    });

    testWidgets("refuses to trigger a button that is still running", (
      tester,
    ) async {
      final action = SteppedAction();
      final controller = ButtonController();
      final panel = await tester.showComponent(
        busyButton(
          ButtonFace.filled,
          controller: controller,
          onPressed: action.run,
        ),
      );

      controller.trigger();
      await panel.eventually(() => expect(panel.says("Going"), isTrue));

      expect(controller.trigger(), isFalse);
      expect(action.steps, [1]);

      action.finish();
      await panel.settle();
    });

    testWidgets("counts every failure, the same one twice too", (tester) async {
      final controller = ButtonController();
      final panel = await tester.showComponent(
        busyButton(
          ButtonFace.filled,
          controller: controller,
          label: "Fail",
          busyLabel: "Failing",
          onPressed: () => throw Exception("Boom"),
        ),
      );

      controller.trigger();
      await panel.settle();
      controller.trigger();
      await panel.settle();

      expect(controller.lastError, "Exception: Boom");
      expect(controller.failures, 2);
    });

    testWidgets("reports whether the button is running", (tester) async {
      final completer = Completer<void>();
      final controller = ButtonController();
      final panel = await tester.showComponent(
        busyButton(
          ButtonFace.filled,
          controller: controller,
          label: "Test",
          busyLabel: "Testing",
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
