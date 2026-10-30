import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

const _catalogSubject =
    "service.to.realm1.organization.acme.realm.editor.catalog.fetch";
const _snapshotSubject =
    "service.to.realm1.organization.acme.realm.editor.authoring.state.query";
const _eventSubject =
    "service.from.realm1.organization.acme.realm.editor.authoring.changed";
const _catalogWatchSubject =
    "service.to.realm1.organization.acme.realm.editor.catalog.invalidate";
const _catalogInvalidationEventSubject =
    "service.from.realm1.organization.acme.realm.editor.catalog.invalidate";

void main() {
  late World world;
  setUp(() {
    world = testWorld([signedIn(ada, organization: acme)]);
    // The Realm last announced the catalog the panel starts with.
    world.nats.registerHandler(
      _catalogWatchSubject,
      (_) => skir.WatchEditorCatalogResponse.serializer.toBytes(
        skir.WatchEditorCatalogResponse.createInvalidated(
          generation: _generation,
        ),
      ),
    );
  });

  final session = authoringSessionProvider(_scope.organizationId, _realm);

  test(
    "initial fetch failure remains observable without a readiness future",
    () async {
      world.nats.registerHandler(
        _catalogSubject,
        (_) => throw StateError("Catalog offline"),
      );
      await world.whenSignedIn();
      world.keepOpen(session);

      final state = await world.container.eventually(
        session,
        (state) => state.failure != null,
        description: "initial catalog failure",
      );

      expect(state.confirmedDocument, isNull);
      expect(state.refreshing, isFalse);
    },
  );

  test(
    "hints fetch current state and missed hints recover after reconnect",
    () async {
      var title = "Initial";
      world.nats
        ..registerHandler(
          _catalogSubject,
          (_) => libraryCatalog(generation: _generation).fetchReply,
        )
        ..registerHandler(
          _snapshotSubject,
          (_) => realmDocument(
            books: [_book.copyWith(title: title)],
            catalog: libraryCatalog(generation: _generation),
          ).stateReply,
        );
      await world.whenSignedIn();
      world.keepOpen(session);
      await world.container.eventually(
        session,
        (state) =>
            state.resources[_book.bookId]?.content
                .authoredField("title")
                ?.authoredString ==
            "Initial",
        description: "initial state",
      );

      title = "Changed";
      world.nats.connection.emitMessageOnSubject(
        _eventSubject,
        skir.AuthoringChanged.serializer.toBytes(
          skir.AuthoringChanged(generation: _generation),
        ),
      );
      await world.container.eventually(
        session,
        (state) =>
            state.resources[_book.bookId]?.content
                .authoredField("title")
                ?.authoredString ==
            "Changed",
        description: "state after hint",
      );

      title = "Missed hint";
      world.nats.disconnect();
      await pumpEventQueue();
      world.nats.reconnect();

      await world.container.eventually(
        session,
        (state) =>
            state.resources[_book.bookId]?.content
                .authoredField("title")
                ?.authoredString ==
            "Missed hint",
        description: "reconnected current state",
      );
    },
  );

  test("a hint during an active query schedules a fresh query", () async {
    final delayed = Completer<Uint8List>();
    var requests = 0;
    world.nats
      ..registerHandler(
        _catalogSubject,
        (_) => libraryCatalog(generation: _generation).fetchReply,
      )
      ..registerHandler(_snapshotSubject, (_) {
        requests++;
        return requests == 2
            ? delayed.future
            : realmDocument(
                books: [
                  _book.copyWith(title: requests > 2 ? "Newest" : "Initial"),
                ],
                catalog: libraryCatalog(generation: _generation),
              ).stateReply;
      });
    await world.whenSignedIn();
    world.keepOpen(session);
    await world.container.eventually(
      session,
      (state) =>
          state.resources[_book.bookId]?.content
              .authoredField("title")
              ?.authoredString ==
          "Initial",
      description: "initial state",
    );
    world.nats.connection.emitMessageOnSubject(
      _eventSubject,
      skir.AuthoringChanged.serializer.toBytes(
        skir.AuthoringChanged(generation: _generation),
      ),
    );
    await eventually(() => expect(requests, 2));
    world.nats.connection.emitMessageOnSubject(
      _eventSubject,
      skir.AuthoringChanged.serializer.toBytes(
        skir.AuthoringChanged(generation: _generation),
      ),
    );
    delayed.complete(
      realmDocument(
        books: [_book.copyWith(title: "Intermediate")],
        catalog: libraryCatalog(generation: _generation),
      ).stateReply,
    );

    await world.container.eventually(
      session,
      (state) =>
          state.resources[_book.bookId]?.content
              .authoredField("title")
              ?.authoredString ==
          "Newest",
      description: "query queued by hint",
    );
    expect(requests, 3);
  });

  test("after the connection is replaced, a change announced on the new "
      "connection shows its state", () async {
    var title = "Initial";
    world.nats
      ..registerHandler(
        _catalogSubject,
        (_) => libraryCatalog(generation: _generation).fetchReply,
      )
      ..registerHandler(
        _snapshotSubject,
        (_) => realmDocument(
          books: [_book.copyWith(title: title)],
          catalog: libraryCatalog(generation: _generation),
        ).stateReply,
      );
    await world.whenSignedIn();
    world.keepOpen(session);
    await world.container.eventually(
      session,
      (state) =>
          state.resources[_book.bookId]?.content
              .authoredField("title")
              ?.authoredString ==
          "Initial",
      description: "initial state",
    );
    final before = world.nats.connection;

    await world.container.read(natsProvider.notifier).retry();
    expect(world.nats.connection, isNot(same(before)));
    await pumpEventQueue();
    title = "After replacement";
    world.nats.connection.emitMessageOnSubject(
      _eventSubject,
      skir.AuthoringChanged.serializer.toBytes(
        skir.AuthoringChanged(generation: _generation),
      ),
    );

    await world.container.eventually(
      session,
      (state) =>
          state.resources[_book.bookId]?.content
              .authoredField("title")
              ?.authoredString ==
          "After replacement",
      description: "state announced on the replaced connection",
    );
  });

  test("a catalog change refetches the catalog, retries the state once and "
      "shows the new state", () async {
    var generation = _generation;
    final replacement = skir.CatalogGeneration(value: "replacement");
    var catalogFetches = 0;
    var stateQueries = 0;
    world.nats
      ..registerHandler(_catalogSubject, (_) {
        catalogFetches++;
        return libraryCatalog(generation: generation).fetchReply;
      })
      ..registerHandler(_snapshotSubject, (request) {
        stateQueries++;
        final query = skir.QueryAuthoringStateRequest.serializer.fromBytes(
          request,
        );
        if (query.generation != generation) {
          return skir.QueryAuthoringStateResponse.serializer.toBytes(
            skir.QueryAuthoringStateResponse.createCatalogChangedError(
              actualGeneration: generation,
            ),
          );
        }
        return realmDocument(
          books: [_book.copyWith(title: "Current")],
          catalog: libraryCatalog(generation: generation),
        ).stateReply;
      });
    await world.whenSignedIn();
    world.keepOpen(session);
    await world.container.eventually(
      session,
      (state) =>
          state.resources[_book.bookId]?.content
              .authoredField("title")
              ?.authoredString ==
          "Current",
      description: "initial state",
    );
    final fetchesBefore = catalogFetches;
    final queriesBefore = stateQueries;

    // The Realm moved to a new catalog without announcing it, so the panel
    // learns of it only from the state query.
    generation = replacement;
    world.nats.connection.emitMessageOnSubject(
      _eventSubject,
      skir.AuthoringChanged.serializer.toBytes(
        skir.AuthoringChanged(generation: _generation),
      ),
    );

    final state = await world.container.eventually(
      session,
      (state) => state.generation == replacement,
      description: "state of the new catalog",
    );
    expect(
      state.resources[_book.bookId]?.content
          .authoredField("title")
          ?.authoredString,
      "Current",
    );
    expect(catalogFetches, fetchesBefore + 1);
    expect(stateQueries, queriesBefore + 2);
  });

  test("catalog invalidation refetches matching state and keeps the staged "
      "edit pending", () async {
    var generation = _generation;
    world.nats
      ..registerHandler(
        _catalogSubject,
        (_) => libraryCatalog(generation: generation).fetchReply,
      )
      ..registerHandler(
        _snapshotSubject,
        (_) => realmDocument(
          books: [_book.copyWith(title: "Initial")],
          catalog: libraryCatalog(generation: generation),
        ).stateReply,
      );
    await world.whenSignedIn();
    world.keepOpen(session);
    await world.container.eventually(
      session,
      (state) => state.confirmedDocument != null,
      description: "initial document",
    );
    final editing = world.container.read(realmEditingProvider(_scope));
    final subscription = world.container.listen(
      realmEditingProvider(_scope),
      (_, _) {},
    );
    world.addCleanup(subscription.close);
    final staged = editing.edit(
      label: "Rename",
      policy: EditorCommitPolicy.applyResource,
      apply: (edit) =>
          edit.set(_titleLocation, skir.DataValue.wrapStringValue("Local")),
    );
    expect(staged, isA<EditStaged>());

    generation = skir.CatalogGeneration(value: "replacement");
    world.nats.connection.emitMessageOnSubject(
      _catalogInvalidationEventSubject,
      skir.CatalogInvalidated.serializer.toBytes(
        skir.CatalogInvalidated(generation: generation),
      ),
    );
    await world.container.eventually(
      session,
      (state) =>
          state.generation == generation && state.confirmedDocument != null,
      description: "matching replacement catalog",
    );

    await eventually(
      () => expect(
        editing.state.groups[(staged as EditStaged).group]?.phase,
        isA<EditGroupContractChanged<AuthoringDocument>>(),
      ),
    );
    expect(editing.hasPendingWork, isTrue);
    expect(
      (editing.document.read(
        _titleLocation,
      ) as PortablePathValue<skir.DataValue>).value,
      skir.DataValue.wrapStringValue("Local"),
    );
  });
}

final _realm = skir.recordId("service:realm1");
final _scope = AuthoringScope(
  organizationId: acme.organizationId,
  realmId: _realm,
);
final _generation = skir.CatalogGeneration(value: "catalog:1");
final _book = book("Quest");
final _titleLocation = skir.ValueLocation(
  resource: _book.bookId,
  path: editorRootPath.field("title"),
);
