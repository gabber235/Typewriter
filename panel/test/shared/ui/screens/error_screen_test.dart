import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("a startup failure shows its error centered in the window", (
    tester,
  ) async {
    final panel = await tester.pumpPanel([
      signedIn(ada),
      unreachableAtStartup(StartupDependency.telemetry),
    ], at: const PanelLocation.component(Text("Startup ready")));

    final middle = panel.world.window.width / 2;
    expect(
      tester.getCenter(find.text(ErrorScreen.defaultTitle)).dx,
      moreOrLessEquals(middle, epsilon: 1),
    );
    expect(
      tester.getCenter(panel.labeled("Retry")).dx,
      moreOrLessEquals(middle, epsilon: 1),
    );
  });

  for (final (name, screen) in [
    ("full", const ErrorScreen(message: "The Realm did not answer")),
    (
      "small",
      const ErrorScreen.small(title: "", message: "The Realm did not answer"),
    ),
  ]) {
    testWidgets("an untitled $name error always shows the default title", (
      tester,
    ) async {
      final panel = await tester.pumpPanel(
        const [],
        at: PanelLocation.component(screen),
      );

      expect(panel.shows(ErrorScreen.defaultTitle), isTrue);
    });
  }
}
