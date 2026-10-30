import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("routed pages show no debug banner", (tester) async {
    await tester.pumpPanel([signedIn(ada, organization: acme)]);

    expect(find.byType(CheckedModeBanner), findsNothing);
  });

  for (final (name, startup) in [
    ("while startup resolves", startupPending),
    ("after startup failed", unreachableAtStartup(StartupDependency.telemetry)),
  ]) {
    testWidgets("the startup screen shows no debug banner $name", (
      tester,
    ) async {
      await tester.pumpPanel([signedIn(ada), startup]);

      expect(find.byType(CheckedModeBanner), findsNothing);
    });
  }
}
