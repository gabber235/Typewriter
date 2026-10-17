import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../../../support/test_utils.dart";

void main() {
  testWidgets("page identity remains visible when issues consume row space", (
    tester,
  ) async {
    for (final width in [200.0, 160.0, 120.0]) {
      await tester.pumpTestApp(
        child: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width,
              child: const PageNavigationLabel(
                name: "Recording verification",
                issues: [
                  ResourceIssue(
                    current: true,
                    diagnostic: PortablePresentationDiagnostic(
                      code: "unfinished_value",
                      message: "A required value is unfinished.",
                      severity: skir.DiagnosticSeverity.error,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final label = find.text("Recording verification");
      expect(label, findsOneWidget);
      expect(tester.getSize(label).width, greaterThan(0));
      expect(
        tester.getSize(find.byType(PageNavigationLabel)).height,
        lessThanOrEqualTo(36),
      );
      expect(find.byType(ResourceIssueBadge), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text("1"), findsOneWidget);
    }
  });

  testWidgets("healthy navigation has no issue indicator", (tester) async {
    await tester.pumpTestApp(
      child: const Scaffold(
        body: SizedBox(width: 200, child: PageNavigationLabel(name: "Harbor")),
      ),
    );
    expect(find.text("Harbor"), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsNothing);
    expect(find.text("1"), findsNothing);
  });
}
