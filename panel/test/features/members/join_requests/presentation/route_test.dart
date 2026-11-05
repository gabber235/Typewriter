import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("the join requests page is headed Join Requests", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      membership(),
    ], at: membersPage(const JoinRequestsRoute()));

    expect(panel.headings, contains("Join Requests"));
    expect(find.text("No join requests"), findsOneWidget);
  });

  testWidgets("join requests show loading, not the empty state, before they "
      "arrive", (tester) async {
    // Reduced motion keeps the placeholders still, so the panel settles.
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      membership(joinRequests: null),
    ], at: membersPage(const JoinRequestsRoute()));

    expect(panel.shows("Loading join requests"), isTrue);
    expect(find.text("No join requests"), findsNothing);
  });
}
