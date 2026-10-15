import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../../../support/publication.dart";
import "../../../../../support/test_utils.dart";

final _scope = AuthoringScope(
  organizationId: skir.recordId("organization:inbox"),
  realmId: skir.recordId("service:inbox"),
);
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
final _refProvider = Provider<Ref>((ref) => ref);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    "the same saved finding and publication blocker produce one issue",
    () async {
      final inbox = await _inbox(
        saved: _diagnostic("check:1", _title),
        blocker: _diagnostic("check:2", _title),
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
      final inbox = await _inbox(
        blocker: _diagnostic("check:1", _title),
        additional: [_diagnostic("check:2", location)],
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
      final inbox = await _inbox(
        blocker: _diagnostic("check:1", _title, message: "Title is reserved"),
        additional: [
          _diagnostic("check:2", _title, message: "Title is already used"),
        ],
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
        final diagnostic = _diagnostic("captured", _title);
        final failed = _diagnostic("failed", _title, message: "Check failed");
        final findings = [
          _finding(
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
        final inbox = await _inbox(
          status: status,
          saved: _diagnostic("unrelated", _title),
        );
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
      _details(_diagnostic("warning", _title)),
    ),
    skir.PublicationNotice.wrapInformation(
      _details(_diagnostic("info", _title)),
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
        final inbox = await _inbox(
          status: status,
          saved: _diagnostic("old", _title),
        );
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

  test("publishing uses the classified later assessment once", () async {
    final diagnostic = _diagnostic("captured", _title);
    final status = skir.PublicationStatus.createPublishing(
      publication: skir.PublicationId(value: "publishing"),
      phase: skir.PublicationActivationPhase.storing,
      releasing: delta,
      next: skir.PublicationPendingReview(
        findings: [_finding(diagnostic)],
        blockers: [
          skir.PublicationBlocker(
            details: _details(_diagnostic("assessed", _title)),
          ),
        ],
        notices: notices.take(1),
        confirmedChanges: const [],
        pendingRoots: const [],
      ),
    );
    final inbox = await _inbox(status: status, saved: diagnostic);
    expect(inbox.issues, hasLength(2));
    expect(
      inbox.issues.whereType<RealmInboxFinding>().where(
        (issue) => issue.finding.blocksPublication,
      ),
      hasLength(1),
    );
    expect(
      inbox.issues.whereType<RealmInboxFinding>().where(
        (issue) => issue.finding.outdated,
      ),
      isEmpty,
    );
  });

  test("request and connection transitions project their retained review", () {
    final status = _blocked([_diagnostic("retained", _title)]);
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

  testWidgets("a book issue navigates to its Realm Library", (tester) async {
    final fixture = _navigation();

    expect(
      await fixture.container.read(
        openRealmInboxLocationProvider(_scope, _title).future,
      ),
      isTrue,
    );
    await tester.pump(Duration.zero);
    final destination = fixture.router.destinations.single;
    expect(destination, isA<OrganizationRoute>());
    final organization = destination as OrganizationRoute;
    expect(organization.args!.organizationId, _scope.organizationId.id);
    final realm = organization.initialChildren!.single as RealmRoute;
    expect(realm.args!.realmId, _scope.realmId.id);
    expect(realm.initialChildren!.single, isA<LibraryRoute>());
  });

  testWidgets("a book issue selects its book for inspection", (tester) async {
    final fixture = _navigation();

    await fixture.container.read(
      openRealmInboxLocationProvider(_scope, _title).future,
    );
    await tester.pump(Duration.zero);

    expect(fixture.container.read(selectionProvider), [
      AuthoringResourceIdentifier.inScope(_scope, _book.bookId),
    ]);
  });

  test(
    "an inbox reveal survives disposal scheduling during navigation",
    () async {
      final fixture = _navigation();
      final navigation = Completer<void>();
      fixture.router.pendingNavigation = navigation;
      final provider = openRealmInboxLocationProvider(_scope, _title);
      final opened = fixture.container.read(provider.future);
      await fixture.container.pump();
      expect(fixture.container.exists(provider), isTrue);
      navigation.complete();
      expect(await opened, isTrue);
      expect(fixture.container.read(selectionProvider), [
        AuthoringResourceIdentifier.inScope(_scope, _book.bookId),
      ]);
      await fixture.container.pump();
      expect(fixture.container.exists(provider), isFalse);
    },
  );

  test(
    "a failed inbox reveal releases its operation without selecting",
    () async {
      final fixture = _navigation();
      final navigation = Completer<void>();
      fixture.router.pendingNavigation = navigation;
      final provider = openRealmInboxLocationProvider(_scope, _title);
      final opened = fixture.container.read(provider.future);
      final failure = expectLater(opened, throwsStateError);
      await fixture.container.pump();
      expect(fixture.container.exists(provider), isTrue);
      navigation.completeError(StateError("Navigation failed"));
      await failure;
      expect(fixture.container.read(selectionProvider), isEmpty);
      await fixture.container.pump();
      expect(fixture.container.exists(provider), isFalse);
    },
  );

  testWidgets("ordinary book opening still opens the page editor", (
    tester,
  ) async {
    final fixture = _navigation();
    final resource = fixture.document.entry(_book.bookId)!;

    final opened = await fixture.container
        .read(authoringResourceNavigationRegistryProvider)
        .open(
          fixture.container.read(_refProvider),
          AuthoringResourceIdentifier.inScope(_scope, resource.id),
        );
    await tester.pump(Duration.zero);

    expect(opened, isTrue);
    final destination = fixture.router.destinations.single;
    expect(destination, isA<BookRoute>());
    final book = destination as BookRoute;
    expect(book.args!.organizationId, _scope.organizationId.id);
    expect(book.args!.realmId, _scope.realmId.id);
    expect(book.args!.bookId, _book.bookId.id);
  });

  for (final kind in ["page", "element", "cue", "tag"]) {
    testWidgets("$kind reveal uses its editing surface and remains selected", (
      tester,
    ) async {
      final fixture = _navigation(document: _navigationDocument());
      final id = skir.ResourceId(value: "$kind:inbox");
      final location = skir.ValueLocation(
        resource: id,
        path: editorRootPath.field("name"),
      );
      final registry = fixture.container.read(
        authoringResourceNavigationRegistryProvider,
      );
      final ref = fixture.container.read(_refProvider);
      final resource = AuthoringResourceIdentifier.inScope(_scope, id);
      expect(registry.canOpen(ref, resource), isTrue);
      for (var attempt = 0; attempt < 2; attempt++) {
        expect(await registry.reveal(ref, _scope, location), isTrue);
        await tester.pump(Duration.zero);
        expect(fixture.container.read(selectionProvider), [resource]);
      }
      final destination = fixture.router.destinations.last;
      if (kind == "tag") {
        final realm =
            (destination as OrganizationRoute).initialChildren!.single
                as RealmRoute;
        expect(realm.initialChildren!.single, isA<TagsRoute>());
      } else {
        final book = destination as BookRoute;
        expect(book.args!.bookId, _book.bookId.id);
        expect(
          (book.initialChildren!.single as RouteRoute).args!.pageId,
          "page:inbox",
        );
      }
    });

    testWidgets(
      "ordinary $kind opening retains its destination and selection",
      (tester) async {
        final fixture = _navigation(document: _navigationDocument());
        final resource = AuthoringResourceIdentifier.inScope(
          _scope,
          skir.ResourceId(value: "$kind:inbox"),
        );
        expect(
          await fixture.container
              .read(authoringResourceNavigationRegistryProvider)
              .open(fixture.container.read(_refProvider), resource),
          isTrue,
        );
        await tester.pump(Duration.zero);
        if (kind == "tag") {
          final realm =
              (fixture.router.destinations.single as OrganizationRoute)
                      .initialChildren!
                      .single
                  as RealmRoute;
          expect(realm.initialChildren!.single, isA<TagsRoute>());
        } else {
          final book = fixture.router.destinations.single as BookRoute;
          expect(book.args!.bookId, _book.bookId.id);
          expect(
            (book.initialChildren!.single as RouteRoute).args!.pageId,
            "page:inbox",
          );
        }
        expect(
          fixture.container.read(selectionProvider),
          kind == "page" ? isEmpty : [resource],
        );
      },
    );
  }

  for (final kind in [
    "generic",
    "unknown",
    "missing resource",
    "missing definition",
    "missing adapter",
    "loading",
  ]) {
    testWidgets(
      "$kind is unsupported without navigation or selection changes",
      (tester) async {
        var document = fixtureAuthoringDocument(books: [_book]);
        if (kind == "missing resource") {
          document = document.copyWith(entries: {});
        }
        if (kind == "generic" ||
            kind == "unknown" ||
            kind == "missing definition") {
          final catalog = document.catalog.snapshot.toMutable();
          catalog.resourceDefinitions = kind == "missing definition"
              ? []
              : [
                  skir.AuthoringResourceDefinition(
                    id: document.entries.values.single.definition,
                    root: catalog.resourceDefinitions.first.root.toFrozen(),
                    navigationHandler: kind == "generic"
                        ? skir.AuthoringNavigationHandler.generic
                        : skir.AuthoringNavigationHandler.unknown,
                  ).toMutable(),
                ];
          document = document.copyWith(
            catalog: CheckedEditorCatalog(catalog.toFrozen()),
          );
        }
        final fixture = _navigation(
          document: document,
          registry: kind == "missing adapter"
              ? AuthoringResourceNavigationRegistry({})
              : null,
          loading: kind == "loading",
        );
        final registry = fixture.container.read(
          authoringResourceNavigationRegistryProvider,
        );
        final ref = fixture.container.read(_refProvider);
        final resource = AuthoringResourceIdentifier.inScope(
          _scope,
          _book.bookId,
        );
        expect(registry.canOpen(ref, resource), isFalse);
        expect(await registry.open(ref, resource), isFalse);
        expect(await registry.reveal(ref, _scope, _title), isFalse);
        expect(fixture.router.destinations, isEmpty);
        expect(fixture.container.read(selectionProvider), isEmpty);
        await tester.pump(Duration.zero);
      },
    );
  }

  for (final kind in ["page", "element"]) {
    for (final malformed in [false, true]) {
      testWidgets(
        "$kind with ${malformed ? 'absent' : 'missing'} ownership fails before navigating",
        (tester) async {
          var document = _navigationDocument();
          document = malformed
              ? document.copyWith(
                  entries: {...document.entries}..remove(_book.bookId),
                )
              : document.copyWith(links: []);
          final fixture = _navigation(document: document);
          final location = skir.ValueLocation(
            resource: skir.ResourceId(value: "$kind:inbox"),
            path: editorRootPath,
          );
          await expectLater(
            fixture.container
                .read(authoringResourceNavigationRegistryProvider)
                .reveal(fixture.container.read(_refProvider), _scope, location),
            throwsStateError,
          );
          expect(fixture.router.destinations, isEmpty);
          expect(fixture.container.read(selectionProvider), isEmpty);
          await tester.pump(Duration.zero);
        },
      );
    }
  }

  testWidgets("dispatch reads the current catalog after it changes", (
    tester,
  ) async {
    final document = fixtureAuthoringDocument(books: [_book]);
    final transport = ScriptedAuthoringTransport(AsyncData(document));
    addTearDown(transport.dispose);
    final fixture = _navigation(document: document, transport: transport);
    final registry = fixture.container.read(
      authoringResourceNavigationRegistryProvider,
    );
    final ref = fixture.container.read(_refProvider);
    final resource = AuthoringResourceIdentifier.inScope(_scope, _book.bookId);
    expect(registry.canOpen(ref, resource), isTrue);
    final catalog = document.catalog.snapshot.toMutable()
      ..resourceDefinitions = [];
    transport.publish(
      AsyncData(
        document.copyWith(catalog: CheckedEditorCatalog(catalog.toFrozen())),
      ),
    );
    await tester.pump(Duration.zero);
    expect(registry.canOpen(ref, resource), isFalse);
    expect(await registry.reveal(ref, _scope, _title), isFalse);
    expect(fixture.router.destinations, isEmpty);
    await tester.pump(Duration.zero);
  });

  testWidgets("leaving a Realm releases its pending reveal", (tester) async {
    final selected = ValueNotifier<AuthoringScope?>(_scope);
    addTearDown(selected.dispose);
    await tester.pumpTestApp(
      child: const SizedBox(),
      overrides: [
        selectedAuthoringScopeProvider.overrideWith((ref) {
          selected.addListener(ref.invalidateSelf);
          ref.onDispose(() => selected.removeListener(ref.invalidateSelf));
          return selected.value;
        }),
      ],
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(RealmNavigationBoundary)),
    );
    final controller = container.read(realmLocationRevealProvider(_scope))
      ..request(_title);
    await tester.pump(const Duration(milliseconds: 100));
    expect(container.exists(realmLocationRevealProvider(_scope)), isTrue);
    selected.value = null;
    await tester.pumpAndSettle();
    expect(container.exists(realmLocationRevealProvider(_scope)), isFalse);
    selected.value = _scope;
    await tester.pumpAndSettle();
    expect(
      container.read(realmLocationRevealProvider(_scope)),
      isNot(same(controller)),
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  });

  for (final delayed in [false, true]) {
    testWidgets(
      "book reveal focuses its ${delayed ? 'delayed' : 'mounted'} inspector and survives repeated clicks",
      (tester) async {
        final fixture = _navigation(retainReveal: false);
        final show = ValueNotifier(!delayed);
        addTearDown(show.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: fixture.container,
            child: testApp(
              child: Scaffold(
                body: ValueListenableBuilder(
                  valueListenable: show,
                  builder: (context, visible, child) => visible
                      ? Consumer(
                          builder: (context, ref, child) =>
                              SingleChildScrollView(
                                child: Column(
                                  children: [
                                    const SizedBox(height: 900),
                                    AuthoredResourceInspection(
                                      resource: _book.bookId,
                                      workspace: ref.watch(
                                        realmEditingProvider(_scope),
                                      ),
                                      commands: ref.watch(
                                        authoredResourceCommandsProvider(
                                          _scope,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                        )
                      : const SizedBox(),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final registry = fixture.container.read(
          authoringResourceNavigationRegistryProvider,
        );
        final ref = fixture.container.read(_refProvider);
        expect(await registry.reveal(ref, _scope, _title), isTrue);
        if (delayed) {
          await tester.pump(const Duration(milliseconds: 100));
          show.value = true;
        }
        await tester.pumpAndSettle();
        final field = find.descendant(
          of: find.byType(AuthoredResourceInspection),
          matching: find.byType(EditableText),
        );
        expect(field, findsOneWidget);
        expect(
          tester.widget<EditableText>(field).focusNode.hasFocus ||
              tester
                  .widget<EditableText>(field)
                  .focusNode
                  .ancestors
                  .any((node) => node.hasPrimaryFocus),
          isTrue,
        );
        expect(tester.getRect(field).top, lessThan(600));
        tester.widget<EditableText>(field).focusNode.unfocus();
        expect(await registry.reveal(ref, _scope, _title), isTrue);
        await tester.pumpAndSettle();
        expect(
          tester.widget<EditableText>(field).focusNode.hasFocus ||
              tester
                  .widget<EditableText>(field)
                  .focusNode
                  .ancestors
                  .any((node) => node.hasPrimaryFocus),
          isTrue,
        );
        expect(fixture.container.read(selectionProvider), [
          AuthoringResourceIdentifier.inScope(_scope, _book.bookId),
        ]);
        show.value = false;
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump(Duration.zero);
      },
    );
  }
}

skir.Diagnostic _diagnostic(
  String id,
  skir.ValueLocation location, {
  String message = "Text must not be blank",
}) => skir.Diagnostic(
  id: skir.DiagnosticId(value: id),
  origin: skir.RuleOrigin.defaultInstance,
  code: "realm.check",
  message: message,
  severity: skir.DiagnosticSeverity.error,
  primary: location,
  related: const [],
);

skir.PublicationDiagnosticDetails _details(skir.Diagnostic diagnostic) =>
    skir.PublicationDiagnosticDetails(
      evidence: null,
      id: diagnostic.id,
      origin: diagnostic.origin,
      code: diagnostic.code,
      message: diagnostic.message,
      primary: diagnostic.primary,
      related: diagnostic.related,
    );

skir.PublicationStatus _blocked(List<skir.Diagnostic> diagnostics) =>
    skir.PublicationStatus.createBlocked(
      notices: const [],
      baseline: skir.PublicationBaseline.initial,
      blockers: skir.PublicationBlockers(
        first: skir.PublicationBlocker(details: _details(diagnostics.first)),
        additional: [
          for (final diagnostic in diagnostics.skip(1))
            skir.PublicationBlocker(details: _details(diagnostic)),
        ],
      ),
      confirmedChanges: const [],
      pendingRoots: const [],
    );

skir.FindingSet _finding(
  skir.Diagnostic diagnostic, {
  skir.FindingStatus status = skir.FindingStatus.current,
  skir.CheckOutcome outcome = skir.CheckOutcome.finished,
}) => skir.FindingSet(
  ticket: skir.CheckTicket(
    instance: skir.CheckInstanceId(
      rule: skir.RuleId(origin: diagnostic.origin, localIndex: 0),
      location: diagnostic.primary!,
    ),
    incarnation: "test",
    execution: skir.CheckExecutionId(value: "execution:1"),
    catalog: fixtureAuthoringDocument().catalog.snapshot.generation,
  ),
  expectations: const [],
  outcome: outcome,
  findings: [diagnostic],
  status: status,
);

Future<RealmInboxState> _inbox({
  skir.Diagnostic? saved,
  skir.Diagnostic? blocker,
  List<skir.Diagnostic> additional = const [],
  skir.PublicationStatus? status,
}) async {
  final document = fixtureAuthoringDocument(books: [_book]);
  final publication = TestPublicationRepository(_scope);
  addTearDown(publication.close);
  final review = status ?? _blocked([blocker!, ...additional]);
  publication.emit(review);
  final container = ProviderContainer.test(
    overrides: [
      ...authoringFixtureOverrides(scope: _scope, document: document),
      authoringSessionProvider(
        _scope.organizationId,
        _scope.realmId,
      ).overrideWithValue(
        AuthoringSessionState(
          snapshot: skir.AuthoringState(
            generation: document.catalog.snapshot.generation,
            resources: const [],
            links: const [],
            findings: [if (saved != null) _finding(saved)],
          ),
        ),
      ),
      realmPublicationRepositoryProvider(
        _scope.organizationId,
        _scope.realmId,
      ).overrideWithValue(publication),
    ],
  );
  final subscription = container.listen(realmInboxProvider(_scope), (_, _) {});
  addTearDown(subscription.close);
  await waitForPublication(
    () =>
        container.read(realmInboxProvider(_scope)).publication.review == review,
  );
  return container.read(realmInboxProvider(_scope));
}

({
  ProviderContainer container,
  _RecordingRouter router,
  AuthoringDocument document,
})
_navigation({
  AuthoringDocument? document,
  AuthoringResourceNavigationRegistry? registry,
  bool loading = false,
  bool retainReveal = true,
  ScriptedAuthoringTransport? transport,
}) {
  document ??= fixtureAuthoringDocument(books: [_book]);
  final access = RouteAccessCoordinator(
    authentication: AuthenticationRouteAccess(),
    organizations: OrganizationRouteAccess(),
  );
  addTearDown(access.dispose);
  final router = _RecordingRouter(
    access,
    WorkSessionLossController(
      () =>
          LocalWorkScope(userId: "test", organizationId: _scope.organizationId),
      () => false,
    ),
  );
  addTearDown(router.dispose);
  final publication = TestPublicationRepository(_scope);
  addTearDown(publication.close);
  final container = ProviderContainer.test(
    overrides: [
      ...authoringFixtureOverrides(
        scope: _scope,
        document: document,
        transport: transport,
      ),
      if (transport == null)
        workingAuthoringDocumentProvider(_scope).overrideWith(
          (ref) => loading ? const AsyncLoading() : AsyncData(document!),
        ),
      realmPublicationRepositoryProvider(
        _scope.organizationId,
        _scope.realmId,
      ).overrideWithValue(publication),
      appRouterProvider.overrideWithValue(router),
      if (registry != null)
        authoringResourceNavigationRegistryProvider.overrideWithValue(registry),
    ],
  );
  final observation = container.listen(
    workingAuthoringDocumentProvider(_scope),
    (_, _) {},
  );
  addTearDown(observation.close);
  final selection = container.listen(selectionProvider, (_, _) {});
  addTearDown(selection.close);
  if (retainReveal) {
    final reveal = container.listen(
      realmLocationRevealProvider(_scope),
      (_, _) {},
    );
    addTearDown(reveal.close);
  }
  return (container: container, router: router, document: document);
}

final class _RecordingRouter extends AppRouter {
  _RecordingRouter(super.access, super.workSessionLoss);

  final destinations = <PageRouteInfo>[];
  Completer<void>? pendingNavigation;

  @override
  Future<dynamic> navigate(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
  }) async {
    destinations.add(route);
    await pendingNavigation?.future;
  }
}

AuthoringDocument _navigationDocument() {
  final page = Page(
    pageId: skir.ResourceId(value: "page:inbox"),
    bookId: _book.bookId,
    name: "Page",
    configuration: skir.TypeSelection.unknown,
    chapter: "",
    priority: 0,
  );
  final tag = Tag(
    tagId: skir.ResourceId(value: "tag:inbox"),
    name: "Tag",
    color: Colors.blue,
    parentIds: const [],
    placement: const GraphPlacement(x: 0, y: 0, width: 1, height: 1),
  );
  final document = fixtureAuthoringDocument(
    books: [_book],
    pages: [page],
    tags: [tag],
  );
  final catalog = document.catalog.snapshot.toMutable();
  final definitions = document.catalog.snapshot.resourceDefinitions.toList();
  final relations = document.catalog.snapshot.relations.toList();
  final entries = {...document.entries};
  final links = [...document.links];
  final pageEntry = document.entry(page.pageId)!;
  final owner = document.catalog.snapshot.relations.singleWhere(
    (relation) => relation.id.value == "fixture.book.pages",
  );
  for (final kind in ["element", "cue"]) {
    final definition = skir.ResourceDefinitionId(value: "typewriter.$kind");
    final id = skir.ResourceId(value: "$kind:inbox");
    definitions.add(
      skir.AuthoringResourceDefinition(
        id: definition,
        root: owner.second.resource.definition,
        navigationHandler: skir.AuthoringNavigationHandler.pageElement,
      ),
    );
    final relation = skir.RelationId(value: "fixture.page.$kind");
    relations.add(
      skir.RelationContract(
        id: relation,
        first: skir.EndpointDefinition(
          id: skir.EndpointId(value: "${relation.value}.first"),
          slot: skir.EndpointSlot.first,
          resource: owner.second.resource,
          cardinality: skir.EndpointCardinality.one,
          onDelete: skir.RelationDeletePolicy.cascade,
        ),
        second: skir.EndpointDefinition(
          id: skir.EndpointId(value: "${relation.value}.second"),
          slot: skir.EndpointSlot.second,
          resource: owner.second.resource,
          cardinality: skir.EndpointCardinality.many,
          onDelete: skir.RelationDeletePolicy.clear,
        ),
        families: owner.families,
      ),
    );
    entries[id] = skir.AuthoringResource(
      id: id,
      definition: definition,
      content: pageEntry.content,
    );
    links.add(
      skir.LinkProjection(
        contract: relation,
        first: page.pageId,
        second: id,
        firstLocation: editorRootPath.field(kind),
        secondLocation: null,
      ),
    );
  }
  catalog
    ..resourceDefinitions = definitions
    ..relations = relations;
  return document.copyWith(
    catalog: CheckedEditorCatalog(catalog.toFrozen()),
    entries: entries,
    links: links,
  );
}
