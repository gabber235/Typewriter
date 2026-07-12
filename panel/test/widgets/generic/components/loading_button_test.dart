import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/widgets/generic/components/loading_button.dart";

import "../../../test_utils.dart";

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
        await tester.pumpUntil(() {
          expect(invoked, 1);
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
          expect(find.text("Go"), findsNothing);
        });

        completer.complete();

        await tester.pumpUntil(() {
          expect(invoked, 2);
          expect(find.byType(CircularProgressIndicator), findsNothing);
          expect(find.text("Go"), findsOneWidget);
        });
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

          await tester.pumpUntil(() {
            expect(invoked, 1);
            expect(find.text("Go"), findsOneWidget);
            expect(find.byType(Icon), findsNothing);
            expect(find.byType(CircularProgressIndicator), findsOneWidget);
          });

          completer.complete();

          await tester.pumpUntil(() {
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

      await tester.pumpUntil(() {
        expect(invoked, 1);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text("Go"), findsNothing);
      });

      completer.complete();

      await tester.pumpUntil(() {
        expect(invoked, 2);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text("Go"), findsOneWidget);
      });
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

      await tester.pumpUntil(() {
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
