import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("voluntary sign out waits for protected work confirmation", (
    tester,
  ) async {
    final panel = await tester.pumpPanel([
      signedIn(ada),
    ], at: const PanelLocation.component(SignOutButton()));
    panel.container.read(localWorkProvider.notifier).register(UnsavedWork());
    await panel.settle();

    await panel.tapOn(find.text("Sign out"));
    expect(panel.dialog.showing("Leave this work session?"), isTrue);
    await panel.dialog.choose("Stay", message: "Leave this work session?");
    expect(panel.world.session.user, ada);

    await panel.tapOn(find.text("Sign out"));
    await panel.dialog.choose("Leave", message: "Leave this work session?");
    expect(panel.world.session.user, isNull);
  });
}
