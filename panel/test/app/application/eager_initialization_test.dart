import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

const _ready = PanelLocation.component(Text("Startup ready"));

void main() {
  for (final (dependency, failure) in [
    (StartupDependency.telemetry, "The trace exporter is unreachable"),
    (StartupDependency.credentials, "The credential endpoint is unreachable"),
    (
      StartupDependency.identityProvider,
      "The identity provider is unreachable",
    ),
  ]) {
    testWidgets("Retry recovers an unreachable ${dependency.name} at startup", (
      tester,
    ) async {
      final panel = await tester.pumpPanel([
        signedIn(ada),
        unreachableAtStartup(dependency),
      ], at: _ready);

      expect(panel.shows("Startup ready"), isFalse);
      expect(find.textContaining(failure), findsOneWidget);

      await panel.tapOn(panel.labeled("Retry"));

      expect(panel.shows("Startup ready"), isTrue);
      expect(panel.world.session.user, ada);
    });
  }

  testWidgets("a repeated startup failure remains retryable without sign out", (
    tester,
  ) async {
    final panel = await tester.pumpPanel([
      signedIn(ada),
      unreachableAtStartup(StartupDependency.identityProvider, times: 3),
    ], at: _ready);

    for (var attempt = 0; attempt < 2; attempt++) {
      await panel.tapOn(panel.labeled("Retry"));
      expect(
        find.textContaining("The identity provider is unreachable"),
        findsOneWidget,
      );
      expect(panel.shows("Startup ready"), isFalse);
      expect(panel.world.session.user, ada);
    }
    await panel.tapOn(panel.labeled("Retry"));
    expect(panel.shows("Startup ready"), isTrue);
  });
}
