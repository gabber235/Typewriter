import "dart:typed_data";

import "package:flutter_test/flutter_test.dart";
import "package:riverpod/riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../../../support/provider_test_utils.dart";

const _graphSubject =
    "service.to.realm1.organization.org1.realm.editor.authoring.graph.query";
const _statusSubject =
    "service.to.realm1.organization.org1.realm.editor.authoring.compiled.status.query";
const _batchSubject =
    "service.to.realm1.organization.org1.realm.editor.authoring.batch.apply";
const _eventSubject =
    "service.from.realm1.organization.org1.realm.editor.authoring.changed";

final _librarySelection = authoringDefinitionSelection(
  key: "library",
  definitions: const [
    CoreResourceDefinitionIds.book,
    CoreResourceDefinitionIds.tag,
  ],
);

void main() {
  test("buffers startup events and recovers sequence gaps", () async {
    final harness = _Harness();
    var sequence = 1;
    var title = "Initial";
    var emitDuringFirstSnapshot = true;
    harness.nats.registerHandler(_graphSubject, (_) {
      if (emitDuringFirstSnapshot) {
        emitDuringFirstSnapshot = false;
        harness.emit(_change(2, title: "Buffered"));
      }
      return _snapshot(sequence, title: title);
    });

    final provider = authoringSessionProvider(_org, _realm);
    final subscription = harness.container.listen(provider, (_, _) {});
    final lease = harness.container
        .read(provider.notifier)
        .acquire(_librarySelection);
    await lease.ready;
    await waitForProvider(
      harness.container,
      provider,
      (state) => state.sequence == 2,
      description: "buffered startup event",
    );
    expect(
      _name(harness.container.read(provider).resources[_book]),
      "Buffered",
    );

    sequence = 3;
    title = "Recovered";
    harness.emit(_change(4, title: "After gap"));
    await waitForProvider(
      harness.container,
      provider,
      (state) => state.sequence == 4,
      description: "gap recovery",
    );
    expect(
      _name(harness.container.read(provider).resources[_book]),
      "After gap",
    );

    lease.release();
    subscription.close();
    await harness.dispose();
  });

  test("conflict refresh preserves a newer authoring event", () async {
    final harness = _Harness();
    var sequence = 1;
    var title = "Initial";
    harness.nats.registerHandler(
      _graphSubject,
      (_) => _snapshot(sequence, title: title),
    );
    harness.nats.registerHandler(_batchSubject, (_) {
      sequence = 2;
      title = "Newer event";
      harness.emit(_change(sequence, title: title));
      return skir.ApplyAuthoringBatchResponse.serializer.toBytes(
        skir.ApplyAuthoringBatchResponse.createConflict(conflicts: const []),
      );
    });

    final provider = authoringSessionProvider(_org, _realm);
    final subscription = harness.container.listen(provider, (_, _) {});
    final lease = harness.container
        .read(provider.notifier)
        .acquire(_librarySelection);
    await lease.ready;
    final response = await harness.container.read(provider.notifier).apply([
      skir.AuthoringOperation.createDelete(
        id: _book,
        base: _resource("Initial"),
      ),
    ]);

    expect(response, isA<skir.ApplyAuthoringBatchResponse_conflictWrapper>());
    expect(harness.container.read(provider).sequence, 2);
    expect(
      _name(harness.container.read(provider).resources[_book]),
      "Newer event",
    );

    lease.release();
    subscription.close();
    await harness.dispose();
  });

  test(
    "applies a covered event without refreshing the leased selection",
    () async {
      final harness = _Harness();
      harness.nats.registerHandler(
        _graphSubject,
        (_) => _snapshot(1, title: "Initial", completeLibrary: true),
      );

      final provider = authoringSessionProvider(_org, _realm);
      final subscription = harness.container.listen(provider, (_, _) {});
      final lease = harness.container
          .read(provider.notifier)
          .acquire(_librarySelection);
      await lease.ready;
      final graphRequests = harness.nats.requests
          .where((request) => request.subject == _graphSubject)
          .length;

      harness.emit(_change(2, title: "Changed"));
      await waitForProvider(
        harness.container,
        provider,
        (state) => state.sequence == 2,
        description: "covered authoring event",
      );
      await Future<void>.delayed(Duration.zero);

      expect(
        harness.nats.requests
            .where((request) => request.subject == _graphSubject)
            .length,
        graphRequests,
      );

      lease.release();
      subscription.close();
      await harness.dispose();
    },
  );

  test("rejects selection key collisions", () async {
    final harness = _Harness();
    harness.nats.registerHandler(
      _graphSubject,
      (_) => _snapshot(1, title: "Initial"),
    );
    final provider = authoringSessionProvider(_org, _realm);
    final subscription = harness.container.listen(provider, (_, _) {});
    final first = harness.container
        .read(provider.notifier)
        .acquire(_librarySelection);
    await first.ready;
    expect(
      () => harness.container
          .read(provider.notifier)
          .acquire(
            skir.GraphSelection(
              key: _librarySelection.key,
              seed: skir.ResourceSeed.createScan(
                filter: skir.ResourceFilter(
                  definitions: [CoreResourceDefinitionIds.page.toWire()],
                  assignableTo: null,
                ),
              ),
              steps: const [],
            ),
          ),
      throwsStateError,
    );
    first.release();
    subscription.close();
    await harness.dispose();
  });
}

final _org = recordId("organization:org1");
final _realm = recordId("service:realm1");
final _book = skir.ResourceId(value: "book1");
final _wireCodec = SkirEditorCodec(TypeRegistry(const TypeCatalog([])));
final _bookType = ResolvedTypeRef(
  id: DeclaredTypeId("11111111111111111111111111111111"),
  revision: 1,
);

Uint8List _snapshot(
  int sequence, {
  required String title,
  bool completeLibrary = false,
}) => skir.QueryAuthoringGraphResponse.serializer.toBytes(
  skir.QueryAuthoringGraphResponse.createSuccess(
    generation: skir.CatalogGeneration(value: "1"),
    sequence: sequence,
    resources: [_resource(title)],
    edges: const [],
    selections: completeLibrary
        ? [
            skir.GraphSelectionResult(
              key: _librarySelection.key,
              resourceIds: [_book],
              edgeIds: const [],
              missingIds: const [],
              incompatibleIds: const [],
            ),
          ]
        : const [],
    diagnostics: const [],
    presentations: const [],
  ),
);

skir.AuthoringChanged _change(int sequence, {required String title}) =>
    skir.AuthoringChanged(
      generation: skir.CatalogGeneration(value: "1"),
      sequence: sequence,
      batchId: "batch:$sequence",
      resources: [skir.AuthoringResourceChange.wrapUpsert(_resource(title))],
      edges: const [],
      presentations: const [],
      compilationImpact: const [],
    );

skir.AuthoringResource _resource(String title) => skir.AuthoringResource(
  id: _book,
  definition: CoreResourceDefinitionIds.book.toWire(),
  content: skir.TypedValueEnvelope(
    rootType: _wireCodec.encodeType(_bookType).valueOrNull!,
    rootValue: _wireCodec.encodeValue(StringValue(title)).valueOrNull!,
  ),
);

String? _name(skir.AuthoringResource? resource) => resource == null
    ? null
    : _wireCodec
          .decodeValue(resource.content.rootValue)
          .valueOrNull
          ?.asStringOrNull;

final class _Harness {
  _Harness() {
    nats.registerHandler(
      _statusSubject,
      (_) => skir.QueryCompiledResourceStatusResponse.serializer.toBytes(
        skir.QueryCompiledResourceStatusResponse.createSuccess(
          statuses: const [],
        ),
      ),
    );
    container = ProviderContainer.test(
      overrides: [
        natsProvider.overrideWithValue(nats),
        organizationIdProvider.overrideWithValue(_org),
        realmIdProvider.overrideWithValue(_realm),
        realmEditorCatalogProvider.overrideWithValue(
          AsyncData(
            RealmEditorCatalogState.ready(
              RealmEditorCatalogSnapshot(
                catalog: const TypeCatalog([]),
                generation: const CatalogGeneration("1"),
              ),
            ),
          ),
        ),
        panelTelemetryProvider.overrideWithValue(
          const AsyncData(NoopPanelTelemetry()),
        ),
      ],
    );
  }

  final FakeNatsClient nats = FakeNatsClient();
  late final ProviderContainer container;

  void emit(skir.AuthoringChanged change) {
    nats.emitMessageOnSubject(
      _eventSubject,
      skir.AuthoringChanged.serializer.toBytes(change),
    );
  }

  Future<void> dispose() async {
    container.dispose();
    await nats.dispose();
  }
}
