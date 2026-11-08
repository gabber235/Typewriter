import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  final dennis = joinRequest("dennis", name: "Dennis");
  final erin = joinRequest("erin", name: "Erin");

  testWidgets("the join requests page opens on the first request", (
    tester,
  ) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      membershipService(joinRequests: [dennis, erin]),
    ], at: membersPage(const JoinRequestsRoute()));
    expect(panel.focused, contains("Dennis"));
  });

  testWidgets("declining Dennis by keys focuses Erin", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      membershipService(joinRequests: [dennis, erin]),
    ], at: membersPage(const JoinRequestsRoute()));
    await panel.press(LogicalKeyboardKey.delete);
    // The dialog until the hold replaces it.
    await panel.press(LogicalKeyboardKey.enter);
    await panel.eventually(() => expect(panel.focused, contains("Erin")));
  });

  testWidgets("accepting Dennis by keys focuses Erin", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      membershipService(roles: [role("Editor")], joinRequests: [dennis, erin]),
    ], at: membersPage(const JoinRequestsRoute()));
    await panel.press(LogicalKeyboardKey.keyA);
    await panel.tapOn(find.text("Editor"));
    await panel.activateWithKeyboard(find.text("Confirm & Add Member"));
    await panel.eventually(() => expect(panel.focused, contains("Erin")));
  });
}
