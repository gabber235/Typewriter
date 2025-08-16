import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/widgets/generic/components/loading_button.dart";

import "../../../test_utils.dart";

void main() {
  for (final variant in LoadingVariant.values) {
    group("LoadingButton.${variant.name}", () {
      testWidgets("invokes async and shows spinner while running",
          (tester) async {
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
      });

      testWidgets("with icon shows snackbar and tooltip on failure",
          (tester) async {
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
}
