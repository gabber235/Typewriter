import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("the join codes page is headed Join Codes", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      membership(),
    ], at: membersPage(const JoinCodesRoute()));

    expect(panel.headings, contains("Join Codes"));
    expect(find.text("No active join codes"), findsOneWidget);
  });

  testWidgets("join codes show loading, not the empty state, before they "
      "arrive", (tester) async {
    // Reduced motion keeps the placeholders still, so the panel settles.
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      membership(joinCodes: null),
    ], at: membersPage(const JoinCodesRoute()));

    expect(panel.shows("Loading join codes"), isTrue);
    expect(find.text("No active join codes"), findsNothing);
  });
}
