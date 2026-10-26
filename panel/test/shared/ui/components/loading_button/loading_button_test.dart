import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  for (final variant in LoadingVariant.values) {
    group("LoadingButton.${variant.name}", () {
      testWidgets("invokes async and shows spinner while running", (
        tester,
      ) async {
        final completer = Completer<void>();
        var invoked = 0;

        await tester.pumpTestApp(
          child: Center(
            child: LoadingButton(
              variant: variant,
              child: const Text("Go"),
              onPressed: () async {
                invoked++;
                await completer.future;
                invoked++;
              },
            ),
          ),
        );

        expect(invoked, 0);
        expect(find.text("Go"), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);

        await tester.tap(find.byType(InkWell));
        await _showsLoading(tester, () => invoked, 1, loading: true);

        completer.complete();

        await _showsLoading(tester, () => invoked, 2, loading: false);
      });

      testWidgets("shows snackbar and tooltip on failure", (tester) async {
        await tester.pumpTestApp(
          child: Center(
            child: LoadingButton(
              variant: variant,
              child: const Text("Fail"),
              onPressed: () {
                throw Exception("Boom");
              },
            ),
          ),
        );

        await tester.tap(find.byType(InkWell));

        await tester.pumpAndSettle();

        expect(find.byType(SnackBar), findsOneWidget);
      });

      testWidgets(
        "with icon invokes async and changes icon to spinner while running",
        (tester) async {
          final completer = Completer<void>();
          var invoked = 0;
          await tester.pumpTestApp(
            child: Center(
              child: LoadingButton.icon(
                variant: variant,
                icon: Icon(Icons.add),
                label: const Text("Go"),
                onPressed: () async {
                  invoked++;
                  await completer.future;
                  invoked++;
                },
              ),
            ),
          );

          expect(invoked, 0);
          expect(find.text("Go"), findsOneWidget);
          expect(find.byType(Icon), findsOneWidget);
          expect(find.byType(CircularProgressIndicator), findsNothing);
          await tester.tap(find.byType(InkWell));

          await tester.eventually(() {
            expect(invoked, 1);
            expect(find.text("Go"), findsOneWidget);
            expect(find.byType(Icon), findsNothing);
            expect(find.byType(CircularProgressIndicator), findsOneWidget);
          });

          completer.complete();

          await tester.eventually(() {
            expect(invoked, 2);
            expect(find.text("Go"), findsOneWidget);
            expect(find.byType(Icon), findsOneWidget);
            expect(find.byType(CircularProgressIndicator), findsNothing);
          });
        },
      );

      testWidgets("with icon shows snackbar and tooltip on failure", (
        tester,
      ) async {
        await tester.pumpTestApp(
          child: Center(
            child: LoadingButton(
              variant: variant,
              child: const Text("Fail"),
              onPressed: () {
                throw Exception("Boom");
              },
            ),
          ),
        );

        await tester.tap(find.byType(InkWell));

        await tester.pumpAndSettle();

        expect(find.byType(SnackBar), findsOneWidget);
      });
    });
  }

  group("LoadingButtonController", () {
    testWidgets("can programmatically trigger button press", (tester) async {
      final completer = Completer<void>();
      var invoked = 0;
      final controller = LoadingButtonController();

      await tester.pumpTestApp(
        child: Center(
          child: LoadingButton(
            controller: controller,
            child: const Text("Go"),
            onPressed: () async {
              invoked++;
              await completer.future;
              invoked++;
            },
          ),
        ),
      );

      expect(invoked, 0);
      expect(find.text("Go"), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      final triggered = controller.trigger();
      expect(triggered, true);

      await _showsLoading(tester, () => invoked, 1, loading: true);

      completer.complete();

      await _showsLoading(tester, () => invoked, 2, loading: false);
    });

    testWidgets("returns false when button is disabled", (tester) async {
      final controller = LoadingButtonController();

      await tester.pumpTestApp(
        child: Center(
          child: LoadingButton(
            controller: controller,
            onPressed: null,
            child: const Text("Disabled"),
          ),
        ),
      );

      await tester.pump();
      final triggered = controller.trigger();
      expect(triggered, false);
    });

    testWidgets("returns false when button is loading", (tester) async {
      final completer = Completer<void>();
      var invoked = 0;
      final controller = LoadingButtonController();

      await tester.pumpTestApp(
        child: Center(
          child: LoadingButton(
            controller: controller,
            child: const Text("Loading"),
            onPressed: () async {
              invoked++;
              await completer.future;
            },
          ),
        ),
      );

      controller.trigger();

      await tester.eventually(() {
        expect(invoked, 1);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      final triggeredWhileLoading = controller.trigger();
      expect(triggeredWhileLoading, false);

      completer.complete();
      await tester.pumpAndSettle();
    });

    testWidgets("works with icon variant", (tester) async {
      var invoked = false;
      final controller = LoadingButtonController();

      await tester.pumpTestApp(
        child: Center(
          child: LoadingButton.icon(
            controller: controller,
            icon: Icon(Icons.add),
            onPressed: () async {
              invoked = true;
            },
            label: const Text("Add"),
          ),
        ),
      );

      final triggered = controller.trigger();
      expect(triggered, true);

      await tester.pumpAndSettle();
      expect(invoked, true);
    });

    testWidgets("handles errors when triggered programmatically", (
      tester,
    ) async {
      final controller = LoadingButtonController();

      await tester.pumpTestApp(
        child: Center(
          child: LoadingButton(
            controller: controller,
            child: const Text("Fail"),
            onPressed: () {
              throw Exception("Boom");
            },
          ),
        ),
      );

      controller.trigger();

      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets("exposes state properties", (tester) async {
      final completer = Completer<void>();
      final controller = LoadingButtonController();

      await tester.pumpTestApp(
        child: Center(
          child: LoadingButton(
            controller: controller,
            child: const Text("Test"),
            onPressed: () async {
              await completer.future;
            },
          ),
        ),
      );

      expect(controller.isLoading, false);
      expect(controller.lastError, null);
      expect(controller.canTrigger, true);

      controller.trigger();
      await tester.pump();

      expect(controller.isLoading, true);
      expect(controller.canTrigger, false);

      completer.complete();
      await tester.pumpAndSettle();

      expect(controller.isLoading, false);
      expect(controller.canTrigger, true);
    });
  });
}

/// Waits until the button ran [expected] times and shows its spinner when
/// [loading], or its label otherwise.
Future<void> _showsLoading(
  WidgetTester tester,
  int Function() invoked,
  int expected, {
  required bool loading,
}) => tester.eventually(() {
  expect(invoked(), expected);
  expect(
    find.byType(CircularProgressIndicator),
    loading ? findsOneWidget : findsNothing,
  );
  expect(find.text("Go"), loading ? findsNothing : findsOneWidget);
});
