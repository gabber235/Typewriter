import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

/// How long the inbox button collects changes before it shows them.
final _deadline = const CoalesceUpdates<RealmInboxStatus>().duration;

void main() {
  final first = book("First");

  testWidgets("a Realm's inbox shows its issues as soon as the Realm opens", (
    tester,
  ) async {
    final panel = await tester.pumpPanel(
      [
        signedIn(ada, organization: acme),
        realm(books: [first]),
      ],
      at: PanelLocation.route(
        OrganizationRoute(organizationId: acme.organizationId.id),
      ),
    );
    panel.world.requireRealm.publication.emit(
      publicationBlockedBy([
        "Missing title",
        "Missing icon",
        "Missing color",
      ], resource: "book:first"),
    );

    await panel.container
        .read(appRouterProvider)
        .navigate(const RealmRouteTree().realm(panel.world.requireRealm.scope));
    await panel.settle();

    expect(panel.shows("3 issues"), isTrue);
  });

  testWidgets("the inbox button opens the Realm's issues and Escape closes "
      "them", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(books: [first]),
    ]);
    await panel.reportPublication(
      publicationBlockedBy(["Missing title"], resource: "book:first"),
    );
    expect(panel.shows("1 issue"), isTrue);

    await tester.tap(find.text("1 issue"));
    await panel.settle();
    expect(panel.shows("Missing title"), isTrue);

    await panel.press(LogicalKeyboardKey.escape);
    expect(panel.shows("Missing title"), isFalse);
  });

  test("projection preserves attention priority across publication states", () {
    RealmInboxState withIssues(int issues) => RealmInboxState(
      publication: const RealmPublicationView.checking(),
      issues: [
        for (var i = 0; i < issues; i++)
          RealmInboxIssue.finding(
            ResourceIssue(
              current: true,
              diagnostic: PortablePresentationDiagnostic(
                code: "issue$i",
                message: "Problem $i",
                severity: skir.DiagnosticSeverity.error,
              ),
            ),
          ),
      ],
    );

    final ready =
        (readyPublicationStatus() as skir.PublicationStatus_readyWrapper).value;
    final variants = <RealmPublicationView, RealmInboxStatus>{
      RealmPublicationView.empty(
        skir.PublicationStatus_Empty(notices: const []),
      ): const RealmInboxStatus.quiet(),
      RealmPublicationView.current(
        skir.PublicationStatus_Current(
          selected: skir.PublicationId(value: "published"),
          notices: const [],
        ),
      ): const RealmInboxStatus.quiet(),
      RealmPublicationView.ready(
        ready,
        RealmPublishCommand(
          ready.candidate,
          () async => skir.PublishAuthoringResponse.noChanges,
        ),
      ): const RealmInboxStatus.ready(),
      RealmPublicationView.blocked(
        (blockedPublicationStatus() as skir.PublicationStatus_blockedWrapper)
            .value,
      ): const RealmInboxStatus.attention(
        0,
      ),
      const RealmPublicationView.checking(): const RealmInboxStatus.checking(),
      RealmPublicationView.publishing(
        skir.PublicationStatus_Publishing(
          publication: skir.PublicationId(value: "publishing"),
          phase: skir.PublicationActivationPhase.storing,
          releasing: ready.changes,
          next: skir.PublicationPendingReview.defaultInstance,
        ),
      ): const RealmInboxStatus.publishing(),
      const RealmPublicationView.requestActive():
          const RealmInboxStatus.publishing(),
      const RealmPublicationView.unavailable("Offline"):
          const RealmInboxStatus.attention(0),
      const RealmPublicationView.uncertain("Unknown"):
          const RealmInboxStatus.attention(0),
    };
    for (final entry in variants.entries) {
      final state = RealmInboxState(publication: entry.key);
      expect(state.buttonStatus, entry.value);
      expect(
        state.copyWith(issues: withIssues(2).issues).buttonStatus,
        const RealmInboxStatus.attention(2),
      );
    }
    final first = withIssues(2);
    final changedDetails = first.copyWith(
      issues: first.issues.reversed.toList(),
    );
    expect(first.buttonStatus, changedDetails.buttonStatus);
  });

  for (final reduced in [false, true]) {
    testWidgets("a burst of changes shows at once at the deadline and keeps "
        "the button usable${reduced ? ", with reduced motion" : ""}", (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: reduced);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final panel = await tester.pumpPanel([
        signedIn(ada, organization: acme),
        realm(books: [first]),
      ]);
      await panel.reportPublication(
        publicationBlockedBy(["Missing title"], resource: "book:first"),
      );
      final publication = panel.world.requireRealm.publication
        ..emit(
          publicationBlockedBy([
            "Missing title",
            "Missing icon",
          ], resource: "book:first"),
        );
      await tester.pump(_deadline ~/ 3);
      publication.emit(
        publicationBlockedBy([
          "Missing title",
          "Missing icon",
          "Missing color",
        ], resource: "book:first"),
      );
      await tester.pump(_deadline ~/ 3);
      expect(panel.shows("1 issue"), isTrue);
      expect(panel.shows("2 issues"), isFalse);

      await tester.pump(_deadline);
      await panel.settle();
      expect(panel.shows("3 issues"), isTrue);
      expect(panel.shows("1 issue"), isFalse);
      expect(panel.shows("2 issues"), isFalse);

      await tester.tap(find.text("3 issues"));
      await panel.settle();
      expect(panel.shows("Missing color"), isTrue);
    });
  }

  testWidgets("the open inbox shows new issues before its button does", (
    tester,
  ) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(books: [first]),
    ]);
    await panel.reportPublication(
      publicationBlockedBy(["Missing title"], resource: "book:first"),
    );
    await tester.tap(find.text("1 issue"));
    await panel.settle();

    panel.world.requireRealm.publication.emit(
      publicationBlockedBy([
        "Missing title",
        "Missing icon",
      ], resource: "book:first"),
    );
    await tester.pump();
    await tester.pump();

    expect(panel.shows("Missing title"), isTrue);
    expect(panel.shows("Missing icon"), isTrue);
    expect(panel.shows("1 issue"), isTrue);

    await tester.pump(_deadline);
    await panel.settle();
    expect(panel.shows("2 issues"), isTrue);
    expect(panel.shows("Missing icon"), isTrue);
  });
}
