import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

/// How long an edit waits before the panel saves it.
const _autosave = Duration(milliseconds: 250);

void main() {
  final original = book("Original");

  testWidgets("a successful save never shows as an inbox issue while its "
      "reply is pending", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(books: [original]),
      heldSaves,
    ]);
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
    await panel.settleInbox();
    expect(panel.inboxShowsIssues, isFalse);

    panel.world.requireRealm.saves.single.confirm();
    await panel.settleInbox();

    expect(panel.inboxShowsIssues, isFalse);
    expect(issues, everyElement(0));
  });

  testWidgets("an edit made while a save is in flight is saved next", (
    tester,
  ) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(books: [original]),
      heldSaves,
    ]);
    await panel.openSurface(original.bookId);
    List<RealmSave> saves() => panel.world.requireRealm.saves;
    await panel.field("title").enter("Draft");
    await tester.pump(_autosave);
    await panel.settle();

    await panel.field("title").enter("Later");
    await tester.pump(_autosave);
    await panel.settle();
    await tester.pump(_autosave);
    expect(saves(), hasLength(1));

    saves().single.confirm();
    await panel.settle();
    expect(panel.field("title").value, "Later");

    await tester.pump(_autosave);
    await panel.settle();
    expect(saves(), hasLength(2));
  });

  testWidgets("an edit made while the Realm is away is saved once it "
      "returns, while the panel stays connected", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(books: [original]),
    ]);
    final saved = panel.world.requireRealm;
    await panel.openSurface(original.bookId);

    saved.goAway();
    await panel.field("title").enter("After the outage");
    await tester.pump(_autosave);
    await panel.settle();
    expect(saved.saves, isEmpty);

    saved.returns();
    await tester.pump(const Duration(seconds: 10));
    await panel.settle();

    expect(
      saved.document
          .resource(original.bookId)
          ?.authoredField("title")
          ?.authoredString,
      "After the outage",
    );
    expect(panel.shows("Needs attention"), isFalse);
  });

  testWidgets("a save that could not be prepared shows why and is not sent "
      "again on its own", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(books: [original]),
    ]);
    final saved = panel.world.requireRealm
      ..unpreparable = "The request could not be prepared";
    await panel.openSurface(original.bookId);

    await panel.field("title").enter("Draft");
    await tester.pump(_autosave);
    await panel.settle();
    saved.unpreparable = null;
    await tester.pump(const Duration(seconds: 30));
    await panel.settle();

    expect(saved.saves, isEmpty);
    expect(
      find.textContaining("The request could not be prepared"),
      findsWidgets,
    );
  });

  testWidgets("a save whose reply was lost is resent without showing an "
      "inbox issue", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(books: [original]),
      heldSaves,
    ]);
    final saved = panel.world.requireRealm;
    await panel.openSurface(original.bookId);
    final issues = <int>[];
    final subscription = panel.container.listen(
      realmInboxProvider(saved.scope),
      (_, next) => issues.add(next.issues.length),
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    await panel.field("title").enter("Draft");
    await tester.pump(_autosave);
    await panel.settle();

    saved.saves.single.loseReply(TimeoutException("No answer in time"));
    await panel.settleInbox();
    expect(panel.inboxShowsIssues, isFalse);

    await tester.pump(const Duration(seconds: 1));
    await tester.eventually(() => expect(saved.saves, hasLength(2)));
    saved.saves.last.confirm();
    await panel.settleInbox();

    expect(panel.field("title").value, "Draft");
    expect(
      saved.document
          .resource(original.bookId)
          ?.authoredField("title")
          ?.authoredString,
      "Draft",
    );
    expect(issues, everyElement(0));
  });

  testWidgets("Retry request on an unanswered Apply settles it from the "
      "reply", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(books: [original]),
      heldSaves,
    ]);
    final saved = panel.world.requireRealm;
    final form = (await panel.openEditing()).form(original.bookId)
      ..setText(
        "Title",
        authoredFieldLocation(original.bookId, ["title"]),
        "Applied",
      );
    unawaited(form.save());
    await tester.eventually(() => expect(saved.saves, hasLength(1)));

    saved.saves.single.loseReply(TimeoutException("No answer in time"));
    await panel.settleInbox();
    await tester.tap(find.textContaining(RegExp(r"^\d+ issues?$")));
    await panel.settle();
    await panel.tapOn(find.text("Retry request").first);
    await tester.eventually(() => expect(saved.saves, hasLength(2)));
    saved.saves.last.confirm();
    await panel.settleInbox();

    expect(panel.inboxShowsIssues, isFalse);
    expect(form.hasSubmittedWork, isFalse);
    expect(form.dirty, isFalse);
  });

  testWidgets("Retry captured request in the activity on an unanswered "
      "Apply settles it from the reply", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(books: [original]),
      heldSaves,
    ]);
    final saved = panel.world.requireRealm;
    await panel.openSurface(original.bookId);
    final editing = await panel.openEditing();
    final applied = editing.setText(
      "Title",
      authoredFieldLocation(original.bookId, ["title"]),
      "Applied",
      policy: EditorCommitPolicy.applyResource,
    ) as EditStaged;
    unawaited(editing.workspace.save(applied.group));
    await tester.eventually(() => expect(saved.saves, hasLength(1)));

    saved.saves.single.loseReply(TimeoutException("No answer in time"));
    await panel.settle();
    // Outside a Realm the app bar shows the save activity instead of the inbox.
    await panel.follow(
      OrganizationRoute(organizationId: acme.organizationId.id),
    );
    await panel.activity.open("Needs attention");
    // The resend shows progress until the held Realm answers, so the panel
    // cannot settle before then.
    await tester.tap(find.text("Retry captured request"));
    await tester.eventually(() => expect(saved.saves, hasLength(2)));
    saved.saves.last.confirm();
    await panel.settle();

    expect(panel.shows("Needs attention"), isFalse);
    expect(editing.workspace.hasSubmittedWork(applied.group), isFalse);
    expect(
      saved.document
          .resource(original.bookId)
          ?.authoredField("title")
          ?.authoredString,
      "Applied",
    );
  });
}
