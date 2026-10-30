import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  final first = book("First");

  // A book has no workspace, so its page shows the inspection, with its
  // title field, in the main area instead of a side inspector; it must
  // still show only once.
  testWidgets("an opened resource page shows its inspection once", (
    tester,
  ) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(books: [first]),
    ]);
    await panel.resources.row("First").open();
    await panel.eventually(
      () => expect(panel.path, endsWith("resource/${first.bookId.value}")),
    );

    await panel.resources.selectOnly([first.bookId]);

    expect(find.text("title"), findsOneWidget);
  });

  testWidgets("the services page shows one inspector for a selection", (
    tester,
  ) async {
    final panel = await tester.pumpPanel(
      [
        signedIn(ada, organization: acme),
        realm(books: [first]),
      ],
      at: PanelLocation.route(
        OrganizationRoute(
          organizationId: acme.organizationId.id,
          children: [const ServicesRoute()],
        ),
      ),
    );

    await panel.resources.selectOnly([first.bookId]);

    expect(panel.inspector.panes, hasLength(1));
    expect(find.text("title"), findsOneWidget);
  });
}
