import "dart:async";

import "package:flutter_test/flutter_test.dart";
import "package:riverpod/riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("publication retains its captured snapshot and rejects another pending request", () async {
    final source = _PublicationSource();
    final container = ProviderContainer.test(
      overrides: [
        realmPublicationSourceProvider(
          _organization,
          _realm,
        ).overrideWithValue(source),
      ],
    );
    final provider = realmPublicationProvider(_organization, _realm);
    final subscription = container.listen(provider, (_, _) {});
    await _waitUntil(() => source.hasListener);
    source.emit(skir.PublicationAttempt.defaultInstance);
    await _waitUntil(() => container.read(provider).hasValue);

    final notifier = container.read(provider.notifier);
    final first = await notifier.publish(
      id: skir.PublicationId(value: "publication:first"),
      authored: _snapshot("realm:1"),
    );
    final second = await notifier.publish(
      id: skir.PublicationId(value: "publication:second"),
      authored: _snapshot("realm:2"),
    );
    expect(first, skir.PublicationResult.publishing);
    expect(second, skir.PublicationResult.publishing);
    expect(source.requests, hasLength(1));
    expect(source.requests.single.capture.value, "realm:1");

    for (final state in [
      skir.PublicationState.checking,
      skir.PublicationState.compiling,
      skir.PublicationState.activating,
      skir.PublicationState.complete,
    ]) {
      source.emit(_attempt(state));
    }
    await _waitUntil(
      () =>
          container.read(provider).value?.state ==
          skir.PublicationState.complete,
    );
    expect(container.read(provider).value?.capture.value, "realm:1");

    await notifier.publish(
      id: skir.PublicationId(value: "publication:blocked"),
      authored: _snapshot("realm:2"),
    );
    source.emit(
      _attempt(
        skir.PublicationState.wrapBlocked([skir.Diagnostic.defaultInstance]),
        id: "publication:blocked",
        snapshot: "realm:2",
      ),
    );
    await _waitUntil(
      () =>
          container.read(provider).value?.state
              is skir.PublicationState_blockedWrapper,
    );
    final blocked =
        container.read(provider).value!.state
            as skir.PublicationState_blockedWrapper;
    expect(blocked.value, hasLength(1));
    expect(source.requests, hasLength(2));

    subscription.close();
    container.dispose();
    await source.close();
  });

  test(
    "an old terminal update cannot release a newer publication request",
    () async {
      final source = _PublicationSource();
      final container = ProviderContainer.test(
        overrides: [
          realmPublicationSourceProvider(
            _organization,
            _realm,
          ).overrideWithValue(source),
        ],
      );
      final provider = realmPublicationProvider(_organization, _realm);
      final subscription = container.listen(provider, (_, _) {});
      await _waitUntil(() => source.hasListener);
      source.emit(
        _attempt(
          skir.PublicationState.complete,
          id: "publication:old",
          snapshot: "realm:0",
        ),
      );
      await _waitUntil(() => container.read(provider).hasValue);

      final delayed = Completer<skir.PublicationResult>();
      source.nextResult = delayed.future;
      final notifier = container.read(provider.notifier);
      final first = notifier.publish(
        id: skir.PublicationId(value: "publication:new"),
        authored: _snapshot("realm:1"),
      );
      await _waitUntil(() => source.requests.length == 1);
      source.emit(
        _attempt(
          skir.PublicationState.complete,
          id: "publication:old",
          snapshot: "realm:0",
        ),
      );
      await Future<void>.delayed(Duration.zero);

      final second = await notifier.publish(
        id: skir.PublicationId(value: "publication:second"),
        authored: _snapshot("realm:2"),
      );
      expect(second, skir.PublicationResult.publishing);
      expect(source.requests, hasLength(1));

      delayed.complete(skir.PublicationResult.publishing);
      expect(await first, skir.PublicationResult.publishing);
      source.emit(
        _attempt(
          skir.PublicationState.complete,
          id: "publication:new",
          snapshot: "realm:1",
        ),
      );
      await _waitUntil(
        () => container.read(provider).value?.id.value == "publication:new",
      );

      subscription.close();
      container.dispose();
      await source.close();
    },
  );
}

final _organization = recordId("organization:org1");
final _realm = recordId("service:realm1");

skir.AuthoringSnapshot _snapshot(String id) => skir.AuthoringSnapshot(
  snapshot: skir.SnapshotId(value: id),
  generation: skir.CatalogGeneration(value: "catalog:1"),
  resources: const [],
  links: const [],
  findings: const [],
  observations: const [],
  absentInputToken: skir.InputToken(value: "absent"),
  findingsToken: skir.FindingsToken(value: "findings:empty"),
);

skir.PublicationAttempt _attempt(
  skir.PublicationState state, {
  String id = "publication:first",
  String snapshot = "realm:1",
}) => skir.PublicationAttempt(
  id: skir.PublicationId(value: id),
  capture: skir.SnapshotId(value: snapshot),
  catalog: skir.CatalogGeneration(value: "catalog:1"),
  engineInputs: skir.EngineImplementationInputs.defaultInstance,
  state: state,
);

final class _PublicationSource implements RealmPublicationSource {
  final controller = StreamController<skir.PublicationAttempt>.broadcast(
    sync: true,
  );
  final requests = <skir.PublicationAttempt>[];
  Future<skir.PublicationResult>? nextResult;

  bool get hasListener => controller.hasListener;

  void emit(skir.PublicationAttempt attempt) => controller.add(attempt);

  Future<void> close() => controller.close();

  @override
  Future<skir.PublicationResult> publish(
    skir.PublicationAttempt request,
  ) async {
    requests.add(request);
    return await (nextResult ??
        Future.value(skir.PublicationResult.publishing));
  }

  @override
  Stream<skir.PublicationAttempt> watch() => controller.stream;
}

Future<void> _waitUntil(bool Function() predicate) async {
  for (var index = 0; index < 100 && !predicate(); index++) {
    await Future<void>.delayed(Duration.zero);
  }
  expect(predicate(), isTrue);
}
