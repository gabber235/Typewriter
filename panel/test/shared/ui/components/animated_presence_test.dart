import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_testkit/testing.dart";

final _grace = skir.OrganizationMember(
  userId: skir.recordId("user:grace"),
  name: "Grace",
  email: "grace@typewriter.test",
  avatarUrl: null,
  roles: const [],
  joinedAt: DateTime.utc(2025),
);

void main() {
  testWidgets(
    "the bulk bar arrives with a selection and its space is gone once the selection clears",
    (tester) async {
      await tester.pumpPanel([
        signedIn(ada, organization: acme),
        membership(members: [_grace]),
        window(desktopWindow),
      ], at: membersPage());
      final rowTop = tester.getRect(find.text("Grace")).top;

      await tester.tap(find.text("Grace"));
      await tester.pumpAndSettle();
      expect(find.text("Remove"), findsOneWidget);

      await tester.tap(find.text("Grace"));
      await tester.pumpAndSettle();
      expect(find.text("Remove"), findsNothing);
      expect(tester.getRect(find.text("Grace")).top, rowTop);
    },
  );
}
