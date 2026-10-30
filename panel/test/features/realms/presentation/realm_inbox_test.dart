import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  test("local findings retain every resource target for inbox navigation", () {
    final owner = skir.ResourceId(value: "owner");
    final primary = skir.ValueLocation(
      resource: owner,
      path: editorRootPath.field("name"),
    );
    final related = skir.ValueLocation(
      resource: owner,
      path: editorRootPath.field("title"),
    );
    final issue = RealmInboxIssue.finding(
      ResourceIssue(
        current: true,
        diagnostic: PortablePresentationDiagnostic(
          code: "related",
          message: "Names must agree",
          severity: skir.DiagnosticSeverity.error,
          targets: [
            PortableDiagnosticTarget.binding(
              skir.BindingRef(
                bindingId: skir.ExpressionBindingId(value: "external"),
                path: editorRootPath,
              ),
            ),
            PortableDiagnosticTarget.value(primary),
            PortableDiagnosticTarget.value(related),
          ],
        ),
      ),
    );
    expect(issue.primary, primary);
    expect(issue.related, [related]);
  });

  final first = book("First");

  testWidgets(
    "Shift+P opens a blocked inbox, but not while typing in a field",
    (tester) async {
      final panel = await tester.pumpPanel([
        signedIn(ada, organization: acme),
        realm(books: [first]),
      ]);
      await panel.openSurface(first.bookId);
      panel.world.requireRealm.publication.emit(blockedPublicationStatus());
      await panel.settle();

      await panel.pressShifted(LogicalKeyboardKey.keyP);
      expect(panel.shows("Publish blocked"), isTrue);
      await panel.press(LogicalKeyboardKey.escape);
      expect(panel.shows("Publish blocked"), isFalse);

      await panel.field("title").focus();
      await panel.pressShifted(LogicalKeyboardKey.keyP);

      expect(panel.shows("Publish blocked"), isFalse);
      expect(panel.field("title").isFocused, isTrue);
    },
  );

  for (final blocked in [false, true]) {
    testWidgets(
      "the publish shortcut ${blocked ? "does nothing once the "
                "Realm stops being ready" : "publishes a ready Realm"}",
      (tester) async {
        final panel = await tester.pumpPanel([
          signedIn(ada, organization: acme),
          realm(books: [first]),
        ]);
        await panel.openSurface(first.bookId);
        panel.world.requireRealm.publication.emit(readyPublicationStatus());
        await panel.settle();
        final publication = panel.world.requireRealm.publication
          ..send = () async => const SubmissionResult.confirmed(
            skir.PublishAuthoringResponse.noChanges,
          );
        await panel.pressShifted(LogicalKeyboardKey.keyP);
        expect(find.text("Publish"), findsWidgets);

        if (blocked) {
          publication.emit(blockedPublicationStatus());
          await panel.settle();
        }
        await panel.pressPrimary(LogicalKeyboardKey.enter);

        expect(publication.candidates, hasLength(blocked ? 0 : 1));
        if (blocked) expect(find.text("Publish"), findsNothing);
      },
    );
  }

  testWidgets("saved work reaches the inbox after the panel replaced its "
      "connection", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(books: [first]),
    ]);
    await panel.openSurface(first.bookId);
    await panel.settleInbox();
    expect(panel.shows("Review changes"), isFalse);

    await panel.container.read(natsProvider.notifier).retry();
    await panel.reportPublication(readyPublicationStatus());

    expect(panel.shows("Review changes"), isTrue);
    await panel.pressShifted(LogicalKeyboardKey.keyP);
    expect(find.text("Publish"), findsWidgets);
  });

  testWidgets("a removed resource is named as it was published", (
    tester,
  ) async {
    final removed = book("The Lost Map");
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(books: [first]),
    ]);
    await panel.openSurface(first.bookId);
    await panel.reportPublication(
      removalPublicationStatus(
        removed.bookId,
        published: realmDocument(books: [removed]).resource(removed.bookId),
      ),
    );

    await panel.pressShifted(LogicalKeyboardKey.keyP);

    expect(panel.shows("The Lost Map"), isTrue);
    expect(panel.shows("Removed resource"), isFalse);
  });

  testWidgets("a refused publish tells the user why", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(books: [first]),
    ]);
    await panel.openSurface(first.bookId);
    panel.world.requireRealm.publication.emit(readyPublicationStatus());
    await panel.settle();
    panel.world.requireRealm.publication.send = () async =>
        const SubmissionResult.rejected(
          message: "The Realm refused to publish",
        );
    await panel.pressShifted(LogicalKeyboardKey.keyP);

    await panel.tapOn(find.text("Publish").first);

    expect(find.textContaining("The Realm refused to publish"), findsWidgets);
  });
}
