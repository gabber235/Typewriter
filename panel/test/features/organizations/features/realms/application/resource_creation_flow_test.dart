import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../../../support/test_utils.dart";

void main() {
  testWidgets(
    "a page with a new Book in the single Library is created in one edit",
    (tester) async {
      final fixture = ResourceCreationFixture.library();
      final document = fixture.libraryDocument();
      final harness = _Harness(
        document,
        fixture.request("Page"),
        const CreationContext(),
      );
      await harness.mount(tester);
      await tester.tap(find.text("Begin creation"));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Create Book"));
      await tester.pumpAndSettle();

      expect(harness.error, isNull);
      // The Book joins the only Library without a question.
      expect(find.byType(SearchModal), findsNothing);
      final created = harness.workspace!.document;
      expect(created.entries, hasLength(3));
      expect(created.links, hasLength(2));
      final page = created.resource(harness.request.id)!;
      final book = page.authoredField("book")!.authoredLink!.target.resource;
      expect(
        created
            .resource(book)!
            .authoredField("library")!
            .authoredLink!
            .target
            .resource,
        fixture.library,
      );
      expect(
        created
            .resource(fixture.library)!
            .authoredField("books")!
            .authoredItems,
        hasLength(1),
      );
      final edit = harness.transport.requests.single.edit;
      expect(
        edit.intents.whereType<skir.EditIntent_createResourceWrapper>(),
        hasLength(2),
      );
      _capture(
        catalog: document.catalog.snapshot,
        seed: fixture.librarySeed().prepare(),
        edit: edit,
      );
    },
  );

  testWidgets(
    "an owner back reference the Realm leaves empty still joins the single "
    "owner",
    (tester) async {
      final fixture = ResourceCreationFixture.library();
      final document = fixture.libraryDocument();
      // A nullable back reference prepares as null instead of asking.
      skir.PreparationStep prepare(skir.PreparationOperation operation) =>
          switch (fixturePreparationStep(document, operation)) {
            skir.PreparationStep_needsInputWrapper(:final value) =>
              skir.PreparationStep.wrapReady(
                skir.PreparedValue(
                  content: skir.PreparedContent.wrapRecord(
                    switch ((value.content
                            as skir.PreparedContent_recordWrapper)
                        .value
                        .replaceAt(
                          editorRootPath.field("library"),
                          skir.DataValue.null_,
                        )) {
                      PortablePathValue(:final value) => value,
                      PortablePathUnavailable(:final message) =>
                        throw StateError(message),
                    },
                  ),
                  findings: const [],
                ),
              ),
            final step => step,
          };
      final harness = _Harness(
        document,
        fixture.request("Book"),
        const CreationContext(),
        prepare: prepare,
      );
      await harness.mount(tester);
      await tester.tap(find.text("Begin creation"));
      await tester.pumpAndSettle();

      expect(harness.error, isNull);
      expect(find.byType(SearchModal), findsNothing);
      final created = harness.workspace!.document;
      expect(
        created
            .resource(harness.request.id)!
            .authoredField("library")!
            .authoredLink!
            .target
            .resource,
        fixture.library,
      );
      expect(created.relations.parents[harness.request.id], [fixture.library]);
    },
  );

  testWidgets(
    "a type owned only from the owner side asks for its owner and joins it",
    (tester) async {
      final fixture = ResourceCreationFixture();
      final other = skir.ResourceId(value: "store:other");
      final harness = _Harness(
        fixture.withStores(fixture.document(), [other]),
        fixture.request("Book"),
        const CreationContext(),
      );
      await harness.mount(tester);
      await tester.tap(find.text("Begin creation"));
      await tester.pumpAndSettle();

      expect(harness.error, isNull);
      expect(find.byType(AuthoredResourceSearchResult), findsNWidgets(2));
      await tester.tap(find.byType(AuthoredResourceSearchResult).first);
      await tester.pumpAndSettle();

      expect(harness.error, isNull);
      final owners =
          harness.workspace!.document.relations.parents[harness.request.id];
      expect(owners, hasLength(1));
      expect([fixture.store, other], contains(owners!.single));
    },
  );

  testWidgets(
    "a type owned only from the owner side joins the owner its creation names",
    (tester) async {
      final fixture = ResourceCreationFixture();
      final other = skir.ResourceId(value: "store:other");
      final document = fixture.withStores(fixture.document(), [other]);
      final harness = _Harness(
        document,
        fixture.request("Book"),
        ownerCreationContext(
          document,
          skir.ValueLocation(
            resource: other,
            path: editorRootPath.field("ownedBook"),
          ),
        ),
      );
      await harness.mount(tester);
      await tester.tap(find.text("Begin creation"));
      await tester.pumpAndSettle();

      expect(harness.error, isNull);
      expect(find.byType(SearchModal), findsNothing);
      expect(
        harness.workspace!.document.relations.parents[harness.request.id],
        [other],
      );
    },
  );

  testWidgets(
    "a compatible current page satisfies the required reference without a picker",
    (tester) async {
      final fixture = ResourceCreationFixture();
      final document = fixture.document(existing: true);
      final harness = _Harness(
        document,
        fixture.request("Entry"),
        CreationContext(preferredResources: [fixture.page]),
      );
      await harness.mount(tester);
      await tester.tap(find.text("Begin creation"));
      await tester.pumpAndSettle();
      expect(harness.error, isNull);
      expect(harness.created?.resourceId, harness.request.id);
      expect(find.byType(SearchModal), findsNothing);
      final entry = harness.workspace!.document.resource(harness.request.id)!;
      expect(
        entry.authoredField("page")?.authoredLink?.target.resource,
        fixture.page,
      );
      expect(
        harness.workspace!.document
            .resource(fixture.page)!
            .authoredField("elements")!
            .authoredItems,
        hasLength(1),
      );
      expect(harness.transport.requests, hasLength(1));
    },
  );

  testWidgets(
    "a scope naming two Books asks between exactly those, ignoring ambient preference",
    (tester) async {
      final fixture = ResourceCreationFixture.library();
      final first = skir.ResourceId(value: "book:first");
      final other = skir.ResourceId(value: "book:other");
      final document = fixture.withBooks(fixture.libraryDocument(), [
        first,
        other,
      ]);
      final page = fixture.request("Page");
      final pageBook = document.catalog.ownershipRelations
          .singleWhere(
            (ownership) => ownership.member.resource.definition == page.type,
          )
          .member
          .id;
      final harness = _Harness(
        document,
        page,
        CreationContext(
          constraints: [
            CreationReferenceConstraint(
              route: [pageBook],
              targets: {first, other},
            ),
          ],
          preferredResources: [first],
        ),
      );
      await harness.mount(tester);
      await tester.tap(find.text("Begin creation"));
      await tester.pumpAndSettle();

      expect(harness.error, isNull);
      expect(find.byType(AuthoredResourceSearchResult), findsNWidgets(2));
      expect(find.text("Create Book"), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(harness.created, isNull);
    },
  );

  testWidgets("missing page and Book are created with the entry in one edit", (
    tester,
  ) async {
    final fixture = ResourceCreationFixture();
    final harness = _Harness(
      fixture.document(),
      fixture.request("Entry"),
      const CreationContext(),
    );
    await harness.mount(tester);
    await tester.tap(find.text("Begin creation"));
    await tester.pumpAndSettle();
    expect(harness.workspace!.document.entries.keys, [fixture.store]);
    await tester.tap(find.text("Create Page"));
    await tester.pumpAndSettle();
    expect(harness.workspace!.document.entries.keys, [fixture.store]);
    await tester.tap(find.text("Create Book"));
    await tester.pumpAndSettle();
    expect(harness.error, isNull);
    expect(harness.created?.resourceId, harness.request.id);
    final document = harness.workspace!.document;
    // Every created resource also joins the single store.
    expect(document.entries, hasLength(4));
    expect(_authoredLinks(document), hasLength(2));
    expect(document.relations.children[fixture.store], hasLength(3));
    expect(harness.transport.requests, hasLength(1));
    expect(
      harness.transport.requests.single.edit.intents
          .whereType<skir.EditIntent_createResourceWrapper>(),
      hasLength(3),
    );
    final entry = document.resource(harness.request.id)!;
    final page = document.resource(
      entry.authoredField("page")!.authoredLink!.target.resource,
    )!;
    final book = document.resource(
      page.authoredField("book")!.authoredLink!.target.resource,
    )!;
    expect(book.authoredField("pages")!.authoredItems, hasLength(1));
    expect(page.authoredField("elements")!.authoredItems, hasLength(1));
  });

  testWidgets(
    "Escape during nested Book selection leaves no admitted resources",
    (tester) async {
      final fixture = ResourceCreationFixture();
      final harness = _Harness(
        fixture.document(),
        fixture.request("Entry"),
        const CreationContext(),
      );
      await harness.mount(tester);
      await tester.tap(find.text("Begin creation"));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Create Page"));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(harness.error, isNull);
      expect(harness.created, isNull);
      expect(harness.workspace!.document.entries.keys, [fixture.store]);
      expect(harness.workspace!.hasPendingWork, isFalse);
      expect(harness.transport.requests, isEmpty);
    },
  );

  testWidgets(
    "keyboard Back changes the parent choice without pending resources",
    (tester) async {
      final fixture = ResourceCreationFixture();
      final harness = _Harness(
        fixture.document(existing: true),
        fixture.request("Entry"),
        const CreationContext(),
      );
      await harness.mount(tester);
      await tester.tap(find.text("Begin creation"));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), "Page");
      await tester.pumpAndSettle();
      await tester.tap(find.text("Create Page"));
      await tester.pumpAndSettle();
      expect(find.byType(BackButton), findsOneWidget);
      for (var attempt = 0; attempt < 12; attempt++) {
        if (FocusManager.instance.primaryFocus?.context
                ?.findAncestorWidgetOfExactType<BackButton>() !=
            null) {
          break;
        }
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pumpAndSettle();
      }
      expect(
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<BackButton>(),
        isNotNull,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(BackButton), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        "Page",
      );
      await tester.tap(
        find
            .ancestor(
              of: find.text("Page"),
              matching: find.byType(SearchResultCard),
            )
            .first,
      );
      await tester.pumpAndSettle();
      expect(harness.error, isNull);
      expect(harness.created?.resourceId, harness.request.id);
      expect(harness.workspace!.document.entries, hasLength(4));
      expect(
        harness.workspace!.document
            .resource(harness.request.id)!
            .authoredField("page")!
            .authoredLink!
            .target
            .resource,
        fixture.page,
      );
      expect(
        harness.transport.requests.single.edit.intents
            .whereType<skir.EditIntent_createResourceWrapper>(),
        hasLength(1),
      );
      expect(
        harness.preparations
            .whereType<skir.PreparationOperation_startWrapper>()
            .where(
              (operation) =>
                  operation.value.target ==
                  skir.PreparationTarget.wrapRecord(
                    harness.request.configuration,
                  ),
            ),
        hasLength(1),
      );
    },
  );

  testWidgets("an ordinary required reference can create its target", (
    tester,
  ) async {
    final fixture = ResourceCreationFixture();
    final harness = _Harness(
      fixture.document(),
      fixture.request("Report"),
      const CreationContext(),
    );
    await harness.mount(tester);
    await tester.tap(find.text("Begin creation"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Create Book"));
    await tester.pumpAndSettle();
    expect(harness.error, isNull);
    expect(harness.workspace!.document.entries, hasLength(3));
    expect(
      _authoredLinks(harness.workspace!.document).single.contract.value,
      "review",
    );
    expect(harness.transport.requests, hasLength(1));
  });

  testWidgets("a pending ancestor closes an ordinary reference cycle", (
    tester,
  ) async {
    final fixture = ResourceCreationFixture();
    final harness = _Harness(
      fixture.document(),
      fixture.request("A"),
      const CreationContext(),
    );
    await harness.mount(tester);
    await tester.tap(find.text("Begin creation"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Create B"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("A"));
    await tester.pumpAndSettle();
    expect(harness.error, isNull);
    final document = harness.workspace!.document;
    expect(document.entries, hasLength(3));
    expect(_authoredLinks(document), hasLength(1));
    final a = document.resource(harness.request.id)!;
    final b = document.resource(
      a.authoredField("b")!.authoredLink!.target.resource,
    )!;
    expect(
      b.authoredField("a")!.authoredLink!.target.resource,
      harness.request.id,
    );
    expect(harness.transport.requests, hasLength(1));
    expect(
      harness.transport.requests.single.edit.intents
          .whereType<skir.EditIntent_connectRelationWrapper>()
          .where(
            (intent) =>
                !intent.value.source.id.endpoint.value.startsWith("owns"),
          ),
      hasLength(1),
    );
  });

  testWidgets(
    "a selected concrete form resolves its nested required reference",
    (tester) async {
      final fixture = ResourceCreationFixture(abstractReport: true);
      final harness = _Harness(
        fixture.document(),
        fixture.request("Report"),
        const CreationContext(),
      );
      await harness.mount(tester);
      await tester.tap(find.text("Begin creation"));
      await tester.pumpAndSettle();
      await tester.tap(find.text("EmailDelivery"));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Create Book"));
      await tester.pumpAndSettle();
      expect(harness.error, isNull);
      expect(harness.created?.resourceId, harness.request.id);
      final document = harness.workspace!.document;
      final payload = document
          .resource(harness.request.id)!
          .authoredField("payload")!;
      final recipient = payload.authoredField("recipient")!.authoredLink!;
      expect(document.resource(recipient.target.resource), isNotNull);
      expect(document.entries, hasLength(3));
      expect(_authoredLinks(document), hasLength(1));
      expect(harness.transport.requests, hasLength(1));
    },
  );
}

/// The links of [document] besides the store ownership every creation adds.
Iterable<skir.LinkProjection> _authoredLinks(AuthoringDocument document) =>
    document.links.where((link) => !link.contract.value.startsWith("owns"));

final class _Harness {
  _Harness(this.document, this.request, this.context, {this.prepare})
    : transport = ScriptedAuthoringTransport(AsyncData(document));

  /// Replaces the fixture preparation, as a Realm with other value rules
  /// would answer.
  final skir.PreparationStep Function(skir.PreparationOperation)? prepare;
  final AuthoringDocument document;
  final ResourceCreationRequest request;
  final CreationContext context;
  final ScriptedAuthoringTransport transport;
  final preparations = <skir.PreparationOperation>[];
  RealmEditing? workspace;
  AuthoringResourceIdentifier? created;
  Object? error;

  Future<void> mount(WidgetTester tester) async {
    addTearDown(transport.dispose);
    final scope = AuthoringScope(
      organizationId: skir.recordId("organization:test"),
      realmId: skir.recordId("realm:test"),
    );
    await tester.pumpTestApp(
      overrides: [
        organizationIdProvider.overrideWith((_) => scope.organizationId),
        realmIdProvider.overrideWith((_) => scope.realmId),
        ...authoringFixtureOverrides(
          document: document,
          transport: transport,
          commands: fixtureAuthoringCommands(
            transport,
            prepareStep: (operation) async {
              preparations.add(operation);
              return prepare?.call(operation) ??
                  fixturePreparationStep(document, operation);
            },
          ),
        ),
      ],
      child: Consumer(
        builder: (context, ref, _) => Scaffold(
          body: FilledButton(
            onPressed: () async {
              workspace = ref.read(realmEditingProvider(scope));
              try {
                created = await ref
                    .read(resourceCreationProvider(scope))
                    .create(
                      context: context,
                      request: request,
                      creationContext: this.context,
                    );
              } on Object catch (caught) {
                error = caught;
              }
            },
            child: const Text("Begin creation"),
          ),
        ),
      ),
    );
  }
}

/// Writes the captured creation for Realm's PanelCreationCommitTest when
/// TYPEWRITER_CREATION_FIXTURE_DIR names a directory, such as
/// services/runtime/realm/src/test/resources/creation.
void _capture({
  required skir.EditorCatalog catalog,
  required skir.PreparedEdit seed,
  required skir.PreparedEdit edit,
}) {
  final directory = Platform.environment["TYPEWRITER_CREATION_FIXTURE_DIR"];
  if (directory == null || directory.isEmpty) return;
  for (final (name, bytes) in [
    ("catalog.skir", skir.EditorCatalog.serializer.toBytes(catalog)),
    ("seed.skir", skir.PreparedEdit.serializer.toBytes(seed)),
    ("edit.skir", skir.PreparedEdit.serializer.toBytes(edit)),
  ]) {
    File("$directory/$name").writeAsBytesSync(bytes);
  }
}
