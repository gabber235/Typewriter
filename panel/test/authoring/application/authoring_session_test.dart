import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../support/catalog_fixture.dart";
import "../../support/provider_test_utils.dart";

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
    final checked = CheckedEditorCatalog(
      testCatalogSnapshot(generation: _generation),
    );
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
        testCatalogSnapshot(
          generation: skir.CatalogGeneration(value: "replacement"),
        ),
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
  test("a replaced connection rebinds the authoring watch", () async {
    final harness = _Harness();
    final replacement = FakeNatsClient();
    var queries = 0;
    for (final client in [harness.nats, replacement]) {
      client.registerHandler(_catalogSubject, (_) => _catalogResponse());
    }
    // Queries use the session transport; only the change watch follows the
    // replaced connection.
    harness.nats.registerHandler(_snapshotSubject, (_) {
      queries++;
      return _snapshotResponse(_snapshot("Initial", 1));
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
      final beforeReplacement = queries;
      (harness.container.read(natsProvider.notifier) as FakeNats).connection =
          replacement;
      // Rebinding invalidates the session, which refreshes its snapshot.
      await _waitUntil(() => queries > beforeReplacement);
      await pumpEventQueue();
      final beforeChange = queries;
      replacement.emitMessageOnSubject(
        _eventSubject,
        skir.AuthoringChanged.serializer.toBytes(
          skir.AuthoringChanged(generation: _generation),
        ),
      );
      await _waitUntil(() => queries > beforeChange);
    } finally {
      subscription.close();
      await harness.dispose();
      await replacement.dispose();
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
    confirmedObservation: skir.AuthoringObservationId(value: "fixture:saved"),
    generation: generation ?? _generation,
    resources: [skir.AuthoringResource(id: _resourceId, content: content)],
    links: const [],
    findings: const [],
  );
}

Uint8List _snapshotResponse(skir.AuthoringState snapshot) => skir
    .QueryAuthoringStateResponse
    .serializer
    .toBytes(skir.QueryAuthoringStateResponse.wrapState(snapshot));

Uint8List _catalogResponse({skir.CatalogGeneration? generation}) =>
    skir.CatalogFetchResult.serializer.toBytes(
      skir.CatalogFetchResult.wrapCatalog(
        testCatalogSnapshot(generation: generation ?? _generation),
      ),
    );

final class _Harness {
  _Harness() {
    session = ResourceSession(
      SkirMutationClient(() => nats, () async => const NoopPanelTelemetry()),
      null,
    );
    container = ProviderContainer.test(
      overrides: [
        natsProvider.overrideWith(() => FakeNats(nats)),
        resourceSessionProvider.overrideWithValue(session),
        organizationIdProvider.overrideWithValue(_organization),
        realmIdProvider.overrideWithValue(_realm),
        panelTelemetryProvider.overrideWithValue(
          const AsyncData(NoopPanelTelemetry()),
        ),
      ],
    );
  }

  final FakeNatsClient nats = FakeNatsClient();
  late final ResourceSession session;
  late final ProviderContainer container;

  void emit() => nats.emitMessageOnSubject(
    _eventSubject,
    skir.AuthoringChanged.serializer.toBytes(
      skir.AuthoringChanged(generation: _generation),
    ),
  );
  Future<void> dispose() async {
    container.dispose();
    session.end();
    await nats.dispose();
  }
}
