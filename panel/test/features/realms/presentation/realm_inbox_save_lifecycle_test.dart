import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

/// How long an edit waits before the panel saves it.
const _autosave = Duration(milliseconds: 250);

void main() {
  final original = book("Original");

  testWidgets("a successful save never shows as an inbox issue while its "
      "saved values refresh", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(books: [original]),
      heldSaves,
    ]);
    final refreshes = panel.world.requireRealm.holdRefreshes();
    await panel.openSurface(original.bookId);
    final issues = <int>[];
    final subscription = panel.container.listen(
      realmInboxProvider(panel.world.requireRealm.scope),
      (_, next) => issues.add(next.issues.length),
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    await panel.field("title").enter("Draft");
    await tester.pump(_autosave);
    await panel.settle();
    panel.world.requireRealm.saves.single.confirm();
    await panel.settle();
    await panel.settleInbox();
    expect(refreshes, hasLength(1));
    expect(panel.inboxShowsIssues, isFalse);

    refreshes.single.complete(
      realmDocument(books: [original.copyWith(title: "Draft")]),
    );
    await panel.settleInbox();

    expect(panel.inboxShowsIssues, isFalse);
    expect(issues, everyElement(0));
  });

  testWidgets("an edit made while saved values refresh is saved next", (
    tester,
  ) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(books: [original]),
      heldSaves,
    ]);
    final refreshes = panel.world.requireRealm.holdRefreshes();
    await panel.openSurface(original.bookId);
    List<RealmSave> saves() => panel.world.requireRealm.saves;
    await panel.field("title").enter("Draft");
    await tester.pump(_autosave);
    await panel.settle();
    saves().single.confirm();
    await panel.settle();

    await panel.field("title").enter("Later");
    await tester.pump(_autosave);
    await panel.settle();
    await tester.pump(_autosave);
    expect(saves(), hasLength(1));

    refreshes.single.complete(
      realmDocument(books: [original.copyWith(title: "Draft")]),
    );
    await panel.settle();
    expect(panel.field("title").value, "Later");

    await tester.pump(_autosave);
    await panel.settle();
    expect(saves(), hasLength(2));
  });

  testWidgets("an edit after saved values return is saved, although the "
      "refresh after an earlier save failed", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(books: [original]),
      heldSaves,
    ]);
    final saved = panel.world.requireRealm;
    final refreshes = saved.holdRefreshes();
    await panel.openSurface(original.bookId);
    await panel.field("title").enter("Draft");
    await tester.pump(_autosave);
    await panel.settle();
    saved.saves.single.confirm();
    await panel.settle();
    refreshes.single.completeError(StateError("The connection dropped"));
    await panel.settle();

    saved.remoteChange((_) {});
    await panel.settle();
    for (final refresh in refreshes.skip(1)) {
      refresh.complete(saved.document);
    }
    await panel.settle();
    await panel.field("title").enter("Later");
    await tester.pump(_autosave);
    await panel.settle();

    expect(saved.saves, hasLength(2));
    expect(find.textContaining("later edits remain local"), findsNothing);
  });

  testWidgets("a failed refresh stays an inbox issue until a retry reads the "
      "saved values, without saving again", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(books: [original]),
      heldSaves,
    ]);
    final refreshes = panel.world.requireRealm.holdRefreshes();
    await panel.openSurface(original.bookId);
    await panel.field("title").enter("Draft");
    await tester.pump(_autosave);
    await panel.settle();
    panel.world.requireRealm.saves.single.confirm();
    await panel.settle();

    refreshes.single.completeError(
      StateError("Saved values could not be refreshed"),
    );
    await panel.settleInbox();
    expect(panel.shows("1 issue"), isTrue);

    await tester.tap(find.text("1 issue"));
    await panel.settle();
    await panel.tapOn(find.text("Retry").first);
    expect(refreshes, hasLength(2));
    refreshes.last.complete(
      realmDocument(books: [original.copyWith(title: "Draft")]),
    );
    await panel.settleInbox();

    expect(panel.world.requireRealm.saves, hasLength(1));
    expect(panel.shows("1 issue"), isFalse);
  });
}
