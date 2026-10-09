import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/infrastructure/messaging/nats.dart";

import "../../../../../support/provider_test_utils.dart";

const _catalogSubject =
    "service.to.realm1.organization.org1.realm.editor.catalog.fetch";
const _snapshotSubject =
    "service.to.realm1.organization.org1.realm.editor.authoring.state.query";
const _eventSubject =
    "service.from.realm1.organization.org1.realm.editor.authoring.changed";
const _catalogInvalidationEventSubject =
    "service.from.realm1.organization.org1.realm.editor.catalog.invalidate";

void main() {
  test("current state exposes one coherent authored view", () {
    final checked = CheckedEditorCatalog(_catalog());
    final state = AuthoringSessionState(
      snapshot: _snapshot("Initial", 1),
      catalog: checked,
    );
    expect(state.generation, _generation);
    expect(_title(state), "Initial");
    expect(state.confirmedDocument?.catalog, same(checked));
    expect(state.links, isEmpty);
  });
  test("confirmed documents require a matching catalog", () {
    final state = AuthoringSessionState(
      snapshot: _snapshot("Initial", 1),
      catalog: CheckedEditorCatalog(
        _catalog(generation: skir.CatalogGeneration(value: "replacement")),
      ),
    );
    expect(state.confirmedDocument, isNull);
  });
  test(
    "initial fetch failure remains observable without a readiness future",
    () async {
      final harness = _Harness();
      harness.nats.registerHandler(
        _catalogSubject,
        (_) => throw StateError("Catalog offline"),
      );
      final provider = authoringSessionProvider(_organization, _realm);
      final subscription = harness.container.listen(provider, (_, _) {});
      try {
        final state = await waitForProvider(
          harness.container,
          provider,
          (state) => state.failure != null,
          description: "initial catalog failure",
        );
        expect(state.confirmedDocument, isNull);
        expect(state.refreshing, isFalse);
        expect(state.failure, isNotNull);
      } finally {
        subscription.close();
        await harness.dispose();
      }
    },
  );
  test(
    "hints fetch current state and missed hints recover after reconnect",
    () async {
      final harness = _Harness();
      var title = "Initial";
      harness.nats
        ..registerHandler(_catalogSubject, (_) => _catalogResponse())
        ..registerHandler(
          _snapshotSubject,
          (_) => _snapshotResponse(_snapshot(title, 1)),
        );
      final provider = authoringSessionProvider(_organization, _realm);
      final subscription = harness.container.listen(provider, (_, _) {});
      try {
        await waitForProvider(
          harness.container,
          provider,
          (state) => _title(state) == "Initial",
          description: "initial current state",
        );
        title = "Changed";
        harness.emit();
        await waitForProvider(
          harness.container,
          provider,
          (state) => _title(state) == "Changed",
          description: "state after hint",
        );
        title = "Missed hint";
        harness.nats.setConnectionState(
          const NatsReconnecting(
            NatsClientException(
              kind: NatsFailureKind.unavailable,
              message: "Disconnected",
            ),
          ),
        );
        await Future<void>.delayed(Duration.zero);
        harness.nats.setConnectionState(const NatsConnected());
        await waitForProvider(
          harness.container,
          provider,
          (state) => _title(state) == "Missed hint",
          description: "reconnected current state",
        );
        expect(
          harness.nats.requests
              .where((request) => request.subject == _snapshotSubject)
              .length,
          greaterThanOrEqualTo(3),
        );
      } finally {
        subscription.close();
        await harness.dispose();
      }
    },
  );
  test("a hint during an active query schedules a fresh query", () async {
    final harness = _Harness();
    final delayed = Completer<Uint8List>();
    var requests = 0;
    harness.nats
      ..registerHandler(_catalogSubject, (_) => _catalogResponse())
      ..registerHandler(_snapshotSubject, (_) {
        requests++;
        return requests == 2
            ? delayed.future
            : _snapshotResponse(
                _snapshot(requests > 2 ? "Newest" : "Initial", 1),
              );
      });
    final provider = authoringSessionProvider(_organization, _realm);
    final subscription = harness.container.listen(provider, (_, _) {});
    try {
      await waitForProvider(
        harness.container,
        provider,
        (state) => _title(state) == "Initial",
        description: "initial state",
      );
      harness.emit();
      await _waitUntil(() => requests == 2);
      harness.emit();
      delayed.complete(_snapshotResponse(_snapshot("Intermediate", 1)));
      await waitForProvider(
        harness.container,
        provider,
        (state) => _title(state) == "Newest",
        description: "query queued by hint",
      );
      expect(requests, 3);
    } finally {
      subscription.close();
      await harness.dispose();
    }
  });
  test("catalog invalidation refetches matching state and preserves the local draft", () async {
    final harness = _Harness();
    var generation = _generation;
    harness.nats
      ..registerHandler(
        _catalogSubject,
        (_) => _catalogResponse(generation: generation),
      )
      ..registerHandler(
        _snapshotSubject,
        (_) =>
            _snapshotResponse(_snapshot("Initial", 1, generation: generation)),
      );
    final provider = authoringSessionProvider(_organization, _realm);
    final subscription = harness.container.listen(provider, (_, _) {});
    try {
      final initial = await waitForProvider(
        harness.container,
        provider,
        (state) => state.confirmedDocument != null,
        description: "initial draft",
      );
      final local = AuthoringEdit.fromDocument(initial.confirmedDocument!)
        ..set(
          skir.ValueLocation(
            resource: _resourceId,
            path: skir.ValuePath(
              segments: [skir.PathSegment.createField(name: "title")],
            ),
          ),
          skir.DataValue.wrapStringValue("Local"),
        );
      generation = skir.CatalogGeneration(value: "replacement");
      harness.nats.emitMessageOnSubject(
        _catalogInvalidationEventSubject,
        skir.CatalogInvalidated.serializer.toBytes(
          skir.CatalogInvalidated(generation: generation),
        ),
      );
      final current = await waitForProvider(
        harness.container,
        provider,
        (state) =>
            state.generation == generation && state.confirmedDocument != null,
        description: "matching replacement catalog",
      );
      expect(
        local.resources[_resourceId]?.authoredField("title")?.authoredString,
        "Local",
      );
      expect(local.generation, isNot(current.confirmedDocument!.generation));
    } finally {
      subscription.close();
      await harness.dispose();
    }
  });
}

String? _title(AuthoringSessionState state) => state
    .resources[_resourceId]
    ?.content
    .authoredField("title")
    ?.authoredString;
Future<void> _waitUntil(bool Function() predicate) async {
  for (var attempt = 0; attempt < 100 && !predicate(); attempt++) {
    await Future<void>.delayed(Duration.zero);
  }
  expect(predicate(), isTrue);
}

final _organization = skir.recordId("organization:org1");
final _realm = skir.recordId("service:realm1");
final _generation = skir.CatalogGeneration(value: "catalog:1");
final _resourceId = skir.ResourceId(value: "book:1");
final _definition = skir.ResourceDefinitionId(value: "typewriter.book");

skir.AuthoringState _snapshot(
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
  return skir.AuthoringState(
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
  );
}

Uint8List _snapshotResponse(skir.AuthoringState snapshot) {
  final encoded = skir.AuthoringState.serializer.toBytes(snapshot);
  return skir.QueryAuthoringStateResponse.serializer.toBytes(
    skir.QueryAuthoringStateResponse.wrapChunk(
      skir.AuthoringStateTransferChunk(
        generation: snapshot.generation,
        transfer: _transfer("current_state", encoded),
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

skir.BoundedTransferChunk _transfer(String id, Uint8List encoded) =>
    skir.BoundedTransferChunk(
      transferId: id,
      index: 0,
      chunkCount: 1,
      encodedSize: encoded.length,
      sha256: sha256.convert(encoded).toString(),
      payload: skir.ByteString.copy(encoded),
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

  void emit() => nats.emitMessageOnSubject(
    _eventSubject,
    skir.AuthoringChanged.serializer.toBytes(
      skir.AuthoringChanged(generation: _generation),
    ),
  );
  Future<void> dispose() async {
    container.dispose();
    await nats.dispose();
  }
}
