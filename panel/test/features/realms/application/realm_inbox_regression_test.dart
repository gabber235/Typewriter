import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

final _book = Book(
  bookId: skir.ResourceId(value: "book:inbox"),
  title: " ",
  icon: "mdi:book",
  color: Colors.blue,
  tagIds: const [],
);
final _title = skir.ValueLocation(
  resource: _book.bookId,
  path: editorRootPath.field("title"),
);

void main() {
  test(
    "a local finding and the same publication blocker produce one issue",
    () async {
      final inbox =
          await testWorld([
            signedIn(ada, organization: acme),
            realm(books: [_book]),
          ]).inboxReviewing(
            blockedPublication([
              realmDiagnostic("check:2", _title).publicationDetails,
            ]),
          );

      expect(inbox.issues, hasLength(1));
      expect(inbox.issues.single.primary, _title);
      expect(inbox.issues.single.message, "Text must not be blank");
      expect(
        inbox.issues.single.provenance,
        "Saved content. Blocks publication. Changed locally or awaiting evaluation",
      );
    },
  );

  for (final (name, location) in [
    (
      "different books",
      skir.ValueLocation(
        resource: skir.ResourceId(value: "book:other"),
        path: editorRootPath.field("title"),
      ),
    ),
    (
      "different fields",
      skir.ValueLocation(
        resource: _book.bookId,
        path: editorRootPath.field("description"),
      ),
    ),
  ]) {
    test("identical messages on $name remain separate issues", () async {
      final inbox =
          await testWorld([
            signedIn(ada, organization: acme),
            realm(books: [_book]),
          ]).inboxReviewing(
            blockedPublication([
              realmDiagnostic("check:1", _title).publicationDetails,
              realmDiagnostic("check:2", location).publicationDetails,
            ]),
          );

      expect(inbox.issues, hasLength(2));
      expect(
        inbox.issues.map((issue) => issue.primary),
        containsAll([_title, location]),
      );
    });
  }

  test(
    "different failures from the same rule at one field remain separate",
    () async {
      final inbox =
          await testWorld([
            signedIn(ada, organization: acme),
            realm(books: [_book]),
          ]).inboxReviewing(
            blockedPublication([
              realmDiagnostic(
                "check:1",
                _title,
                message: "Title is reserved",
              ).publicationDetails,
              realmDiagnostic(
                "check:2",
                _title,
                message: "Title is already used",
              ).publicationDetails,
            ]),
          );

      expect(inbox.issues, hasLength(2));
      expect(
        inbox.issues.map((issue) => issue.message),
        containsAll(["Title is reserved", "Title is already used"]),
      );
    },
  );

  for (final unavailable in [false, true]) {
    test(
      "${unavailable ? 'unavailable' : 'checking'} retains captured findings and failed checks",
      () async {
        final diagnostic = realmDiagnostic("captured", _title);
        final failed = realmDiagnostic(
          "failed",
          _title,
          message: "Check failed",
        );
        final findings = [
          findingSet(
            diagnostic,
            status: skir.FindingStatus.outdated,
            outcome: skir.CheckOutcome.wrapFailed([failed]),
          ),
        ];
        final status = unavailable
            ? skir.PublicationStatus.createUnavailable(
                baseline: skir.PublicationBaseline.initial,
                failure: skir.PublicationFailure.wrapEvaluationInterrupted(
                  "Interrupted",
                ),
                findings: findings,
              )
            : skir.PublicationStatus.createChecking(
                baseline: skir.PublicationBaseline.initial,
                findings: findings,
              );
        final inbox = await testWorld([
          signedIn(ada, organization: acme),
          realm(books: [_book]),
        ]).inboxReviewing(status);
        expect(
          inbox.issues.map((issue) => issue.message),
          unorderedEquals(["Text must not be blank", "Check failed"]),
        );
        expect(
          inbox.issues.every(
            (issue) =>
                issue.provenance ==
                "Saved content. Previous state, checking again",
          ),
          isTrue,
        );
      },
    );
  }

  final notices = [
    skir.PublicationNotice.wrapWarning(
      realmDiagnostic("warning", _title).publicationDetails,
    ),
    skir.PublicationNotice.wrapInformation(
      realmDiagnostic("info", _title).publicationDetails,
    ),
  ];
  final delta = skir.PublicationDelta(
    first: skir.PublicationChange.wrapRootAdded(publicationRoot("page")),
    additional: const [],
  );
  for (final status in [
    skir.PublicationStatus.createEmpty(notices: notices),
    skir.PublicationStatus.createCurrent(
      selected: skir.PublicationId(value: "selected"),
      notices: notices,
    ),
    skir.PublicationStatus.createReady(
      candidate: skir.PublicationCandidateId(value: "ready"),
      notices: notices,
      baseline: skir.PublicationBaseline.initial,
      changes: delta,
    ),
  ]) {
    test(
      "${status.kind.name} preserves notices without background findings",
      () async {
        final inbox = await testWorld([
          signedIn(ada, organization: acme),
          realm(books: [_book]),
        ]).inboxReviewing(status);
        expect(inbox.issues, hasLength(2));
        expect(
          inbox.issues.every(
            (issue) =>
                issue is RealmInboxFinding && !issue.finding.blocksPublication,
          ),
          isTrue,
        );
        expect(inbox.issues.map((issue) => issue.severity), [
          skir.DiagnosticSeverity.warning,
          skir.DiagnosticSeverity.information,
        ]);
      },
    );
  }

  test("a publication in progress shows the later assessment instead of the "
      "captured finding", () async {
    final status = skir.PublicationStatus.createPublishing(
      publication: skir.PublicationId(value: "publishing"),
      phase: skir.PublicationActivationPhase.storing,
      releasing: delta,
      next: skir.PublicationPendingReview(
        findings: [
          findingSet(
            realmDiagnostic("captured", _title, message: "Title was captured"),
          ),
        ],
        blockers: [
          skir.PublicationBlocker(
            details: realmDiagnostic(
              "assessed",
              _title,
              message: "Title is reserved",
            ).publicationDetails,
          ),
        ],
        notices: [
          skir.PublicationNotice.wrapWarning(
            realmDiagnostic(
              "warning",
              _title,
              message: "Title is long",
            ).publicationDetails,
          ),
        ],
        confirmedChanges: const [],
        pendingRoots: const [],
      ),
    );

    final inbox = await testWorld([
      signedIn(ada, organization: acme),
      realm(books: [_book]),
    ]).inboxReviewing(status);

    final shown = {
      for (final issue in inbox.issues.whereType<RealmInboxFinding>())
        issue.message: issue.finding.blocksPublication,
    };
    expect(shown["Title is reserved"], isTrue);
    expect(shown["Title is long"], isFalse);
    expect(shown, isNot(contains("Title was captured")));
    expect(
      inbox.issues.whereType<RealmInboxFinding>().where(
        (issue) => issue.finding.outdated,
      ),
      isEmpty,
    );
  });

  test("request and connection transitions project their retained review", () {
    final status = blockedPublication([
      realmDiagnostic("retained", _title).publicationDetails,
    ]);
    for (final view in [
      RealmPublicationView.checking(display: status),
      RealmPublicationView.unavailable("Offline", display: status),
      RealmPublicationView.requestActive(display: status),
      RealmPublicationView.uncertain("No reply", display: status),
    ]) {
      expect(view.projectSavedIssues(null).single.blocksPublication, isTrue);
      expect(view.projectSavedIssues(null).single.primary, _title);
    }
    expect(
      const RealmPublicationView.checking().projectSavedIssues(null),
      isEmpty,
    );
    expect(
      const RealmPublicationView.unavailable("Offline")
          .projectSavedIssues(null),
      isEmpty,
    );
  });

  group("revealing an issue", () {
    for (final (kind, surface) in [
      ("book", "book:inbox"),
      ("page", "page:inbox"),
      ("element", "page:inbox"),
      ("cue", "page:inbox"),
      ("tag", "library:taxonomy"),
    ]) {
      testWidgets("a $kind issue opens its nearest surface with the $kind "
          "selected, every time", (tester) async {
        final panel = await tester.pumpPanel(
          adaServing(ownerChainDocument(_book, id: "inbox")),
        );
        final scope = panel.world.requireRealm.scope;
        final resource = skir.ResourceId(value: "$kind:inbox");
        final location = skir.ValueLocation(
          resource: resource,
          path: editorRootPath.field(kind == "book" ? "title" : "name"),
        );

        for (var attempt = 0; attempt < 2; attempt++) {
          expect(
            await panel.container.read(
              openRealmInboxLocationProvider(scope, location).future,
            ),
            isTrue,
          );
          await panel.settle();
          expect(panel.routedResource, surface);
          expect(panel.resources.selected, [resource]);
        }
      });
    }

    testWidgets("a missing resource opens nothing and keeps the selection", (
      tester,
    ) async {
      final panel = await tester.pumpPanel(
        adaServing(realmDocument(books: [_book])),
      );
      final scope = panel.world.requireRealm.scope;
      final missing = skir.ResourceId(value: "book:missing");

      expect(
        await panel.container
            .read(realmSurfaceNavigationProvider)
            .open(scope, missing),
        isFalse,
      );
      expect(
        await panel.container
            .read(realmSurfaceNavigationProvider)
            .reveal(
              scope,
              skir.ValueLocation(resource: missing, path: editorRootPath),
            ),
        isFalse,
      );
      await panel.settle();

      expect(panel.routedResource, isNull);
      expect(panel.resources.selected, isEmpty);
    });

    testWidgets("inspecting another resource from a surface without a side "
        "inspector opens that resource's own surface", (tester) async {
      final panel = await tester.pumpPanel(
        adaServing(ownerChainDocument(_book, id: "inbox")),
      );
      await panel.openSurface(_book.bookId);
      final element = skir.ResourceId(value: "element:inbox");

      await panel.inspectForEditing(element);
      expect(panel.routedResource, element.value);
      expect(panel.resources.selected, [element]);
    });

    testWidgets("inspecting a resource beside a workspace keeps the route", (
      tester,
    ) async {
      final page = skir.ResourceId(value: "page:inbox");
      final panel = await tester.pumpPanel(
        adaServing(ownerChainDocument(_book, id: "inbox")),
      );
      await panel.openSurface(page);
      final element = skir.ResourceId(value: "element:inbox");

      await panel.inspectForEditing(element);

      expect(panel.routedResource, page.value);
      expect(panel.resources.selected, [element]);
    });

    testWidgets("an element without owners opens the Realm home with it "
        "selected", (tester) async {
      final panel = await tester.pumpPanel(
        adaServing(ownerChainDocument(_book, id: "inbox").copyWith(links: [])),
      );
      await panel.openSurface(_book.bookId);
      final element = skir.ResourceId(value: "element:inbox");

      expect(
        await panel.container
            .read(realmSurfaceNavigationProvider)
            .open(panel.world.requireRealm.scope, element),
        isTrue,
      );
      await panel.settle();

      expect(panel.routedResource, isNull);
      expect(panel.resources.selected, [element]);
    });

    testWidgets("a Book whose type no longer has a surface opens at the Realm "
        "home with it selected", (tester) async {
      final document = realmDocument(books: [_book]);
      final panel = await tester.pumpPanel(adaServing(document));
      await panel.openSurface(_book.bookId);
      final catalog = document.catalog.snapshot.toMutable()
        ..presentations = []
        ..presentationMaterials = [];
      panel.world.requireRealm.serve(
        document.copyWith(catalog: CheckedEditorCatalog(catalog.toFrozen())),
      );
      await panel.settle();

      expect(
        await panel.container
            .read(realmSurfaceNavigationProvider)
            .open(panel.world.requireRealm.scope, _book.bookId),
        isTrue,
      );
      await panel.settle();

      expect(panel.routedResource, isNull);
      expect(panel.resources.selected, [_book.bookId]);
    });

    testWidgets("a reveal requested before leaving the Realm does nothing "
        "once the user returns", (tester) async {
      final panel = await tester.pumpPanel(
        adaServing(realmDocument(books: [_book])),
      );
      final scope = panel.world.requireRealm.scope;
      panel.container.read(realmLocationRevealProvider(scope)).request(_title);
      await tester.pump(const Duration(milliseconds: 100));

      await panel.container
          .read(appRouterProvider)
          .navigate(OrganizationRoute(organizationId: acme.organizationId.id));
      await panel.settle();
      await panel.openSurface(_book.bookId);

      expect(panel.field("title").isFocused, isFalse);
    });

    for (final from in ["its surface", "the Realm home"]) {
      testWidgets("revealing a Book's field from $from focuses the field in "
          "view, again after focus moved away", (tester) async {
        final panel = await tester.pumpPanel(
          adaServing(realmDocument(books: [_book])),
        );
        final at = from == "its surface" ? _book.bookId : null;
        if (at != null) await panel.openSurface(at);
        final scope = panel.world.requireRealm.scope;

        expect(
          await panel.container
              .read(realmSurfaceNavigationProvider)
              .reveal(scope, _title),
          isTrue,
        );
        await panel.settle();
        expect(panel.field("title").isFocused, isTrue);
        expect(
          panel.field("title").rect.bottom,
          lessThan(desktopWindow.height),
        );

        await panel.press(LogicalKeyboardKey.escape);
        expect(
          await panel.container
              .read(realmSurfaceNavigationProvider)
              .reveal(scope, _title),
          isTrue,
        );
        await panel.settle();
        expect(panel.field("title").isFocused, isTrue);
        expect(panel.resources.selected, [_book.bookId]);
      });
    }
  });
}
