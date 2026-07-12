import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/widgets/generic/components/floating_button.dart";

import "../../../test_utils.dart";

void main() {
  testWidgets("invokes async and changes FAB icon to spinner while running", (
    tester,
  ) async {
    final completer = Completer<void>();
    var invoked = 0;

    await tester.pumpTestApp(
      child: Center(
        child: FloatingButton(
          icon: const Icon(Icons.add),
          onPressed: () async {
            invoked++;
            await completer.future;
            invoked++;
          },
          child: const SizedBox.expand(child: Center(child: Text("Content"))),
        ),
      ),
    );

    expect(invoked, 0);
    expect(find.byType(Icon), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.tap(find.byType(FloatingActionButton));

    await tester.pumpUntil(() {
      expect(invoked, 1);
      expect(find.byType(Icon), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text("Content"), findsOneWidget);
    });

    completer.complete();

    await tester.pumpUntil(() {
      expect(invoked, 2);
      expect(find.byType(Icon), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text("Content"), findsOneWidget);
    });
  });

  testWidgets("shows snackbar and tooltip on failure", (tester) async {
    await tester.pumpTestApp(
      child: Center(
        child: FloatingButton(
          icon: const Icon(Icons.add),
          onPressed: () {
            throw Exception("Boom");
          },
          child: const SizedBox.expand(child: Center(child: Text("Content"))),
        ),
      ),
    );

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
  });
}
