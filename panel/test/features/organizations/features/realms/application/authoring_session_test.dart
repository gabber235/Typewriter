import "dart:async";
import "dart:typed_data";

import "package:crypto/crypto.dart";
import "package:flutter_test/flutter_test.dart";
import "package:riverpod/riverpod.dart";
import "package:skir_client/skir_client.dart" show ByteString;
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/infrastructure/messaging/nats.dart";

import "../../../../../support/provider_test_utils.dart";

const _catalogSubject =
    "service.to.realm1.organization.org1.realm.editor.catalog.fetch";
const _snapshotSubject =
    "service.to.realm1.organization.org1.realm.editor.authoring.snapshot.query";
const _eventSubject =
    "service.from.realm1.organization.org1.realm.editor.authoring.changed";
const _catalogInvalidationRequestSubject =
    "service.to.realm1.organization.org1.realm.editor.catalog.invalidate";
const _catalogInvalidationEventSubject =
    "service.from.realm1.organization.org1.realm.editor.catalog.invalidate";

void main() {
  test("snapshot state exposes one coherent authored view", () {
    final catalog = CheckedEditorCatalog(_catalog());
    final state = AuthoringSessionState(
      snapshot: _snapshot("Initial", 1),
      catalog: catalog,
    );

    expect(state.generation, _generation);
    expect(state.snapshotId, skir.SnapshotId(value: "realm:1"));
    expect(
      state.resources[_resourceId]?.content.fields.single.value,
      skir.DataValue.wrapStringValue("Initial"),
    );
    expect(state.links, isEmpty);
    expect(state.catalog, same(catalog));
    expect(state.draft?.generation, _generation);
    expect(state.draft?.catalog, same(catalog));
  });

  test("draft is unavailable when snapshot and catalog differ", () {
    final source = _catalog(
      generation: skir.CatalogGeneration(value: "catalog:2"),
    );
    final state = AuthoringSessionState(
      snapshot: _snapshot("Initial", 1),
      catalog: CheckedEditorCatalog(source),
    );

    expect(state.draft, isNull);
  });

  test(
    "an accepted change applies atomically without a full refresh",
    () async {
      final harness = _Harness();
      harness.nats
        ..registerHandler(_catalogSubject, (_) => _catalogResponse())
        ..registerHandler(
          _catalogInvalidationRequestSubject,
          (_) => skir.CatalogInvalidated.serializer.toBytes(
            skir.CatalogInvalidated(generation: _generation),
          ),
        )
        ..registerHandler(
          _snapshotSubject,
          (_) => _snapshotResponse(_snapshot("Initial", 1)),
        );

      final provider = authoringSessionProvider(_organization, _realm);
      final subscription = harness.container.listen(provider, (_, _) {});
      await waitForProvider(
        harness.container,
        provider,
        (state) => state.snapshotId == skir.SnapshotId(value: "realm:1"),
        description: "initial authored snapshot",
      );

      harness.emit(_changed(previous: 1, revision: 2, title: "Changed"));
      await waitForProvider(
        harness.container,
        provider,
        (state) => state.snapshotId == skir.SnapshotId(value: "realm:2"),
        description: "refreshed authored snapshot",
      );

      expect(
        harness.container
            .read(provider)
            .resources[_resourceId]
            ?.content
            .fields
            .single
            .value,
        skir.DataValue.wrapStringValue("Changed"),
      );
      expect(
        harness.nats.requests.where(
          (request) => request.subject == _snapshotSubject,
        ),
        hasLength(1),
      );
      expect(
        harness.nats.requests.where(
          (request) => request.subject == _catalogSubject,
        ),
        hasLength(1),
      );

      subscription.close();
      await harness.dispose();
    },
  );

  test(
    "resource adoption waits for the matching change notification",
    () async {
      final harness = _Harness();
      harness.nats
        ..registerHandler(_catalogSubject, (_) => _catalogResponse())
        ..registerHandler(
          _catalogInvalidationRequestSubject,
          (_) => skir.CatalogInvalidated.serializer.toBytes(
            skir.CatalogInvalidated(generation: _generation),
          ),
        )
        ..registerHandler(
          _snapshotSubject,
          (_) => _snapshotResponse(_snapshot("Initial", 1)),
        );

      final provider = authoringSessionProvider(_organization, _realm);
      final subscription = harness.container.listen(provider, (_, _) {});
      await waitForProvider(
        harness.container,
        provider,
        (state) => state.snapshotId == skir.SnapshotId(value: "realm:1"),
        description: "initial authored snapshot",
      );
      final created = skir.ResourceId(value: "book:created");
      final waiting = harness.container
          .read(provider.notifier)
          .awaitResource(created);
      var completed = false;
      unawaited(waiting.then((_) => completed = true));
      await harness.container.pump();
      expect(completed, isFalse);

      harness.emit(
        _changed(previous: 1, revision: 2, title: "Created", resource: created),
      );

      final adopted = await waiting;
      expect(adopted.id, created);
      expect(
        adopted.content.fields.single.value,
        skir.DataValue.wrapStringValue("Created"),
      );

      subscription.close();
      await harness.dispose();
    },
  );

  test("resource adoption reports a session refresh failure", () async {
    final harness = _Harness();
    var snapshotRequests = 0;
    harness.nats
      ..registerHandler(_catalogSubject, (_) => _catalogResponse())
      ..registerHandler(
        _catalogInvalidationRequestSubject,
        (_) => skir.CatalogInvalidated.serializer.toBytes(
          skir.CatalogInvalidated(generation: _generation),
        ),
      )
      ..registerHandler(_snapshotSubject, (_) {
        snapshotRequests++;
        if (snapshotRequests > 1) throw StateError("snapshot failed");
        return _snapshotResponse(_snapshot("Initial", 1));
      });

    final provider = authoringSessionProvider(_organization, _realm);
    final subscription = harness.container.listen(provider, (_, _) {});
    await waitForProvider(
      harness.container,
      provider,
      (state) => state.snapshotId == skir.SnapshotId(value: "realm:1"),
      description: "initial authored snapshot",
    );
    final notifier = harness.container.read(provider.notifier);
    final waiting = notifier.awaitResource(
      skir.ResourceId(value: "book:missing"),
    );

    await expectLater(notifier.refresh(), throwsA(isA<StateError>()));
    await expectLater(waiting, throwsA(isA<StateError>()));

    subscription.close();
    await harness.dispose();
  });

  test("resource adoption ends when its session is disposed", () async {
    final harness = _Harness();
    harness.nats
      ..registerHandler(_catalogSubject, (_) => _catalogResponse())
      ..registerHandler(
        _catalogInvalidationRequestSubject,
        (_) => skir.CatalogInvalidated.serializer.toBytes(
          skir.CatalogInvalidated(generation: _generation),
        ),
      )
      ..registerHandler(
        _snapshotSubject,
        (_) => _snapshotResponse(_snapshot("Initial", 1)),
      );

    final provider = authoringSessionProvider(_organization, _realm);
    final subscription = harness.container.listen(provider, (_, _) {});
    await waitForProvider(
      harness.container,
      provider,
      (state) => state.snapshotId == skir.SnapshotId(value: "realm:1"),
      description: "initial authored snapshot",
    );
    final waiting = harness.container
        .read(provider.notifier)
        .awaitResource(skir.ResourceId(value: "book:missing"));

    subscription.close();
    await harness.container.pump();

    await expectLater(waiting, throwsA(isA<StateError>()));
    await harness.dispose();
  });

  test("exact snapshot adoption is available after its notification", () async {
    final harness = _Harness();
    harness.nats
      ..registerHandler(_catalogSubject, (_) => _catalogResponse())
      ..registerHandler(
        _catalogInvalidationRequestSubject,
        (_) => skir.CatalogInvalidated.serializer.toBytes(
          skir.CatalogInvalidated(generation: _generation),
        ),
      )
      ..registerHandler(
        _snapshotSubject,
        (_) => _snapshotResponse(_snapshot("Initial", 1)),
      );
    final provider = authoringSessionProvider(_organization, _realm);
    final subscription = harness.container.listen(provider, (_, _) {});
    await waitForProvider(
      harness.container,
      provider,
      (state) => state.snapshotId == skir.SnapshotId(value: "realm:1"),
      description: "initial authored snapshot",
    );

    harness.emit(_changed(previous: 1, revision: 2, title: "Adopted"));
    await waitForProvider(
      harness.container,
      provider,
      (state) => state.snapshotId == skir.SnapshotId(value: "realm:2"),
      description: "exact adopted snapshot",
    );
    final adopted = await harness.container
        .read(provider.notifier)
        .awaitSnapshot(skir.SnapshotId(value: "realm:2"));

    expect(adopted.snapshot, skir.SnapshotId(value: "realm:2"));
    subscription.close();
    await harness.dispose();
  });

  test("snapshot recovery reports a skipped commit receipt", () async {
    final harness = _Harness();
    var revision = 1;
    harness.nats
      ..registerHandler(_catalogSubject, (_) => _catalogResponse())
      ..registerHandler(
        _catalogInvalidationRequestSubject,
        (_) => skir.CatalogInvalidated.serializer.toBytes(
          skir.CatalogInvalidated(generation: _generation),
        ),
      )
      ..registerHandler(
        _snapshotSubject,
        (_) => _snapshotResponse(_snapshot("Snapshot $revision", revision)),
      );
    final provider = authoringSessionProvider(_organization, _realm);
    final subscription = harness.container.listen(provider, (_, _) {});
    await waitForProvider(
      harness.container,
      provider,
      (state) => state.snapshotId == skir.SnapshotId(value: "realm:1"),
      description: "initial authored snapshot",
    );
    final notifier = harness.container.read(provider.notifier);
    final recovery = notifier.snapshotRecoveryRevision;
    final waiting = notifier.awaitSnapshot(
      skir.SnapshotId(value: "realm:2"),
      sinceRecovery: recovery,
    );

    revision = 3;
    await notifier.refresh();

    await expectLater(waiting, throwsA(isA<StateError>()));
    subscription.close();
    await harness.dispose();
  });

  test("a detached dirty autosave is reclaimed on Realm reentry", () async {
    final harness = _Harness();
    harness.nats
      ..registerHandler(_catalogSubject, (_) => _catalogResponse())
      ..registerHandler(
        _catalogInvalidationRequestSubject,
        (_) => skir.CatalogInvalidated.serializer.toBytes(
          skir.CatalogInvalidated(generation: _generation),
        ),
      )
      ..registerHandler(
        _snapshotSubject,
        (_) => _snapshotResponse(_snapshot("Initial", 1)),
      );
    final provider = authoringSessionProvider(_organization, _realm);
    final first = harness.container.listen(provider, (_, _) {});
    final state = await waitForProvider(
      harness.container,
      provider,
      (state) => state.draft != null,
      description: "initial authored draft",
    );
    final notifier = harness.container.read(provider.notifier);
    final baseline = state.draft!;
    final staged = baseline.fork()
      ..set(
        skir.ValueLocation(
          resource: _resourceId,
          path: skir.ValuePath(
            segments: [skir.PathSegment.createField(name: "title")],
          ),
        ),
        skir.DataValue.wrapStringValue("Retained"),
      );
    final autosave = notifier.openAutosave(
      resource: _resourceId,
      baseline: baseline,
      policy: EditorCommitPolicy.applyResource,
    )
      ..stage(staged)
      ..detach();
    first.close();
    await harness.container.pump();

    final second = harness.container.listen(provider, (_, _) {});
    final reclaimed = harness.container
        .read(provider.notifier)
        .openAutosave(
          resource: _resourceId,
          baseline: harness.container.read(provider).draft!,
          policy: EditorCommitPolicy.applyResource,
        );

    expect(reclaimed, same(autosave));
    expect(
      reclaimed.draft.resource(_resourceId)?.fields.single.value.authoredString,
      "Retained",
    );
    reclaimed
      ..discard(harness.container.read(provider).draft!)
      ..detach();
    second.close();
    await harness.dispose();
  });

  test(
    "leaving and reentering a Realm starts a fresh authoring session",
    () async {
      final harness = _Harness();
      var revision = 0;
      harness.nats
        ..registerHandler(_catalogSubject, (_) => _catalogResponse())
        ..registerHandler(
          _catalogInvalidationRequestSubject,
          (_) => skir.CatalogInvalidated.serializer.toBytes(
            skir.CatalogInvalidated(generation: _generation),
          ),
        )
        ..registerHandler(_snapshotSubject, (_) {
          revision++;
          return _snapshotResponse(_snapshot("Visit $revision", revision));
        });

      final provider = authoringSessionProvider(_organization, _realm);
      final first = harness.container.listen(provider, (_, _) {});
      await waitForProvider(
        harness.container,
        provider,
        (state) => state.snapshotId == skir.SnapshotId(value: "realm:1"),
        description: "first Realm visit",
      );

      first.close();
      await harness.container.pump();

      final second = harness.container.listen(provider, (_, _) {});
      final reentered = await waitForProvider(
        harness.container,
        provider,
        (state) => state.snapshotId == skir.SnapshotId(value: "realm:2"),
        description: "same Realm reentry",
      );

      expect(reentered.failure, isNull);
      expect(
        harness.nats.requests.where(
          (request) => request.subject == _snapshotSubject,
        ),
        hasLength(2),
      );
      expect(
        harness.nats.subscriptionSubjects.where(
          (subject) => subject == _eventSubject,
        ),
        hasLength(1),
      );

      second.close();
      await harness.dispose();
    },
  );

  test(
    "an active route replaces its repository when the resource owner changes",
    () async {
      final harness = _Harness();
      final releaseFirstSnapshot = Completer<void>();
      var request = 0;
      harness.nats
        ..registerHandler(_catalogSubject, (_) => _catalogResponse())
        ..registerHandler(
          _catalogInvalidationRequestSubject,
          (_) => skir.CatalogInvalidated.serializer.toBytes(
            skir.CatalogInvalidated(generation: _generation),
          ),
        )
        ..registerHandler(_snapshotSubject, (_) async {
          final currentRequest = ++request;
          if (currentRequest == 1) {
            await releaseFirstSnapshot.future;
          }
          return _snapshotResponse(
            _snapshot("Owner $currentRequest", currentRequest),
          );
        });

      final provider = authoringSessionProvider(_organization, _realm);
      final subscription = harness.container.listen(provider, (_, _) {});
      while (request < 1) {
        await Future<void>.delayed(Duration.zero);
      }
      final notifier = harness.container.read(provider.notifier);
      final firstRepository = notifier.repository;

      harness.container.invalidate(resourceRepositoriesProvider);
      await harness.container.pump();
      final replaced = await waitForProvider(
        harness.container,
        provider,
        (state) => state.snapshotId == skir.SnapshotId(value: "realm:2"),
        description: "snapshot from the replacement resource owner",
      );

      expect(harness.container.read(provider.notifier), same(notifier));
      expect(notifier.repository, isNot(same(firstRepository)));
      expect(replaced.failure, isNull);
      releaseFirstSnapshot.complete();
      await harness.container.pump();
      expect(
        harness.container.read(provider).snapshotId,
        skir.SnapshotId(value: "realm:2"),
      );
      expect(harness.container.read(provider).failure, isNull);
      expect(
        harness.nats.subscriptionSubjects.where(
          (subject) => subject == _eventSubject,
        ),
        hasLength(1),
      );

      subscription.close();
      await harness.dispose();
    },
  );

  test("a gap during refresh queues another snapshot fetch", () async {
    final harness = _Harness();
    final releaseSecond = Completer<void>();
    var request = 0;
    harness.nats
      ..registerHandler(_catalogSubject, (_) => _catalogResponse())
      ..registerHandler(
        _catalogInvalidationRequestSubject,
        (_) => skir.CatalogInvalidated.serializer.toBytes(
          skir.CatalogInvalidated(generation: _generation),
        ),
      )
      ..registerHandler(_snapshotSubject, (_) async {
        request++;
        if (request == 2) await releaseSecond.future;
        return _snapshotResponse(_snapshot("Title $request", request));
      });

    final provider = authoringSessionProvider(_organization, _realm);
    final subscription = harness.container.listen(provider, (_, _) {});
    await waitForProvider(
      harness.container,
      provider,
      (state) => state.snapshotId == skir.SnapshotId(value: "realm:1"),
      description: "initial authored snapshot",
    );

    harness.emit(_changed(previous: 0, revision: 2));
    while (request < 2) {
      await Future<void>.delayed(Duration.zero);
    }
    harness.emit(_changed(previous: 99, revision: 3));
    releaseSecond.complete();

    await waitForProvider(
      harness.container,
      provider,
      (state) => state.snapshotId == skir.SnapshotId(value: "realm:3"),
      description: "queued authored snapshot",
    );
    expect(request, 3);

    subscription.close();
    await harness.dispose();
  });

  test(
    "catalog replacement preserves an edited draft for verified rebase",
    () async {
      final harness = _Harness();
      var generation = _generation;
      var revision = 1;
      harness.nats
        ..registerHandler(
          _catalogSubject,
          (_) => _catalogResponse(generation: generation),
        )
        ..registerHandler(
          _catalogInvalidationRequestSubject,
          (_) => skir.CatalogInvalidated.serializer.toBytes(
            skir.CatalogInvalidated(generation: generation),
          ),
        )
        ..registerHandler(_snapshotSubject, (_) {
          return _snapshotResponse(
            _snapshot("Server value", revision, generation: generation),
          );
        });

      final provider = authoringSessionProvider(_organization, _realm);
      final subscription = harness.container.listen(provider, (_, _) {});
      await waitForProvider(
        harness.container,
        provider,
        (state) => state.snapshotId == skir.SnapshotId(value: "realm:1"),
        description: "initial authored snapshot",
      );

      final edited = harness.container.read(provider).draft!
        ..set(
          skir.ValueLocation(
            resource: _resourceId,
            path: skir.ValuePath(
              segments: [skir.PathSegment.createField(name: "title")],
            ),
          ),
          skir.DataValue.wrapStringValue("Pending value"),
        );

      generation = skir.CatalogGeneration(value: "catalog:2");
      revision = 2;
      harness.nats.emitMessageOnSubject(
        _catalogInvalidationEventSubject,
        skir.CatalogInvalidated.serializer.toBytes(
          skir.CatalogInvalidated(generation: generation),
        ),
      );
      final latest = await waitForProvider(
        harness.container,
        provider,
        (state) => state.generation == generation,
        description: "replacement catalog and authored snapshot",
      );

      final rebased = edited.rebaseOnto(latest.draft!);
      expect(rebased, isA<AuthoredDraftRebased>());
      expect(
        (rebased as AuthoredDraftRebased).draft
            .resource(_resourceId)
            ?.fields
            .single
            .value,
        skir.DataValue.wrapStringValue("Pending value"),
      );
      expect(
        harness.nats.requests.where(
          (request) => request.subject == _catalogSubject,
        ),
        hasLength(2),
      );

      subscription.close();
      await harness.dispose();
    },
  );
}

final _organization = recordId("organization:org1");
final _realm = recordId("service:realm1");
final _generation = skir.CatalogGeneration(value: "catalog:1");
final _resourceId = skir.ResourceId(value: "book:1");
final _definition = skir.ResourceDefinitionId(value: "typewriter.book");

skir.AuthoringSnapshot _snapshot(
  String title,
  int revision, {
  skir.CatalogGeneration? generation,
}) {
  final content = skir.AuthoringRecord(
    configuration: skir.TypeSelection.unknown,
    fields: [
      skir.FieldValue(
        name: "title",
        value: skir.DataValue.wrapStringValue(title),
      ),
    ],
  );
  return skir.AuthoringSnapshot(
    snapshot: skir.SnapshotId(value: "realm:$revision"),
    generation: generation ?? _generation,
    resources: [
      skir.AuthoringResource(
        id: _resourceId,
        definition: _definition,
        content: content,
      ),
    ],
    links: const [],
    findings: const [],
    observations: const [],
    absentInputToken: skir.InputToken(value: "absent"),
    findingsToken: _findings(revision),
  );
}

Uint8List _snapshotResponse(skir.AuthoringSnapshot snapshot) {
  final encoded = skir.AuthoringSnapshot.serializer.toBytes(snapshot);
  return skir.QueryAuthoringSnapshotResponse.serializer.toBytes(
    skir.QueryAuthoringSnapshotResponse.wrapChunk(
      skir.AuthoringSnapshotTransferChunk(
        generation: snapshot.generation,
        snapshot: snapshot.snapshot,
        transfer: _transfer("snapshot_${snapshot.snapshot.value}", encoded),
      ),
    ),
  );
}

Uint8List _catalogResponse({skir.CatalogGeneration? generation}) {
  final catalog = _catalog(generation: generation ?? _generation);
  final encoded = skir.EditorCatalogWireSnapshot.serializer.toBytes(catalog);
  return skir.CatalogFetchResult.serializer.toBytes(
    skir.CatalogFetchResult.wrapChunk(
      skir.CatalogTransferChunk(
        generation: catalog.generation,
        transfer: _transfer("catalog_transfer", encoded),
      ),
    ),
  );
}

skir.EditorCatalogWireSnapshot _catalog({skir.CatalogGeneration? generation}) =>
    skir.EditorCatalogWireSnapshot(
      generation: generation ?? _generation,
      types: const [],
      relations: const [],
      resourceDefinitions: const [],
      presentations: const [],
      presentationMaterials: const [],
      configuration: const [],
      diagnostics: const [],
      initialization: const [],
      endpointBindings: const [],
      capabilities: const [],
      recommendations: const [],
      roleFallbacks: const [],
    );

skir.AuthoringChanged _changed({
  required int previous,
  required int revision,
  String? title,
  skir.ResourceId? resource,
}) => skir.AuthoringChanged(
  previousSnapshot: skir.SnapshotId(value: "realm:$previous"),
  snapshot: skir.SnapshotId(value: "realm:$revision"),
  generation: _generation,
  batch: skir.BatchId(value: "batch:$revision"),
  resources: [
    if (title != null)
      skir.AuthoringResourceChange.wrapUpsert(
        skir.AuthoringResource(
          id: resource ?? _resourceId,
          definition: _definition,
          content: skir.AuthoringRecord(
            configuration: skir.TypeSelection.unknown,
            fields: [
              skir.FieldValue(
                name: "title",
                value: skir.DataValue.wrapStringValue(title),
              ),
            ],
          ),
        ),
      ),
  ],
  relations: skir.RelationProjectionDelta(
    removals: const [],
    created: const [],
    metadataChanged: const [],
  ),
  previousFindings: _findings(previous),
  findingsToken: _findings(revision),
  findings: null,
  changedObservations: const [],
);

skir.FindingsToken _findings(int revision) =>
    skir.FindingsToken(value: "findings:$revision");

skir.BoundedTransferChunk _transfer(String id, Uint8List encoded) =>
    skir.BoundedTransferChunk(
      transferId: id,
      index: 0,
      chunkCount: 1,
      encodedSize: encoded.length,
      sha256: sha256.convert(encoded).toString(),
      payload: ByteString.copy(encoded),
    );

final class _Harness {
  _Harness() {
    container = ProviderContainer.test(
      overrides: [
        natsProvider.overrideWithValue(nats),
        organizationIdProvider.overrideWithValue(_organization),
        realmIdProvider.overrideWithValue(_realm),
        panelTelemetryProvider.overrideWithValue(
          const AsyncData(NoopPanelTelemetry()),
        ),
      ],
    );
  }

  final FakeNatsClient nats = FakeNatsClient();
  late final ProviderContainer container;

  void emit(skir.AuthoringChanged change) {
    final encoded = skir.AuthoringChanged.serializer.toBytes(change);
    nats.emitMessageOnSubject(
      _eventSubject,
      skir.AuthoringChangedTransferResult.serializer.toBytes(
        skir.AuthoringChangedTransferResult.wrapChunk(
          skir.AuthoringChangedTransferChunk(
            generation: change.generation,
            previousSnapshot: change.previousSnapshot,
            snapshot: change.snapshot,
            previousFindings: change.previousFindings,
            findingsToken: change.findingsToken,
            transfer: _transfer("change_${change.batch.value}", encoded),
          ),
        ),
      ),
    );
  }

  Future<void> dispose() async {
    container.dispose();
    await nats.dispose();
  }
}
