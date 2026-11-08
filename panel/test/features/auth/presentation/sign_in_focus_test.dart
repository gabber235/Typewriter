import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("Sign in opens focused", (tester) async {
    final panel = await tester.pumpPanel(
      const [],
      at: const PanelLocation.route(AuthRoute()),
    );
    expect(panel.hasFocusOn("Sign in"), isTrue);
  });

  testWidgets("organizations open on the first organization and Tab reaches "
      "the footer after the page's forms", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
    ], at: const PanelLocation.route(IndexRoute()));
    expect(panel.focused, contains("Acme"));
    final order = await panel.tabOrder(limit: 12);
    expect(order, containsAllInOrder(["Join", "Create", "Support", "Docs"]));
  });
}
