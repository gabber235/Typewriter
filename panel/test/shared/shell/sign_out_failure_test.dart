import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

const _failureMessage = "Could not sign out. Please try again.";
final _failure = StateError("sign out failed");

void main() {
  testWidgets("SignOutButton surfaces one sign out failure", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada),
    ], at: PanelLocation.component(const SignOutButton()));
    panel.world.session.signOutFailure = _failure;

    await panel.tapOn(find.text("Sign out"));

    expect(find.text(_failureMessage), findsOneWidget);
    expect(tester.takeException(), same(_failure));
    expect(panel.world.session.user, ada);
  });

  testWidgets("UserMenu surfaces one sign out failure", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada),
    ], at: PanelLocation.component(const UserMenu()));
    panel.world.session.signOutFailure = _failure;

    await panel.tapOn(find.text(ada.name));
    await panel.tapOn(find.text("Logout"));

    expect(find.text(_failureMessage), findsOneWidget);
    expect(tester.takeException(), same(_failure));
    expect(panel.world.session.user, ada);
  });
}
