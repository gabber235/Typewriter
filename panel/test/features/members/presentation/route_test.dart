import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  final member = skir.OrganizationMember(
    userId: skir.recordId("user:grace"),
    name: "Grace",
    email: "grace@typewriter.test",
    avatarUrl: null,
    roles: const [],
    joinedAt: DateTime.utc(2025),
  );

  testWidgets("the members section opens on the current members", (
    tester,
  ) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      membership(members: [member]),
    ], at: membersPage());

    expect(panel.path, "/organization/acme/members");
    expect(panel.headings, contains("Members"));
    expect(find.text("Grace"), findsOneWidget);
  });

  for (final (name, size) in [
    ("narrow", const Size(400, 900)),
    ("wide", desktopWindow),
  ]) {
    testWidgets("a $name window shows members loading while none arrived", (
      tester,
    ) async {
      // Reduced motion keeps the placeholders still, so the panel settles.
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final panel = await tester.pumpPanel([
        signedIn(ada, organization: acme),
        membership(members: null),
        window(size),
      ], at: membersPage());

      expect(panel.shows("Loading members"), isTrue);
      expect(find.text("Grace"), findsNothing);
    });
  }
}
