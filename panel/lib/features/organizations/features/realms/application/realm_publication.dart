import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/features/organizations/features/realms/application/nats_realm_publication_source.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;

part "realm_publication.g.dart";

@Riverpod(keepAlive: true)
RealmPublicationSource realmPublicationSource(
  Ref ref,
  skir.RecordId organizationId,
  skir.RecordId realmId,
) => NatsRealmPublicationSource(
  ref: ref,
  organizationId: organizationId,
  realmId: realmId,
);

@riverpod
class RealmPublication extends _$RealmPublication {
  skir.PublicationId? _publishing;
  late RealmPublicationSource _source;

  @override
  Stream<skir.PublicationAttempt?> build(
    skir.RecordId organizationId,
    skir.RecordId realmId,
  ) async* {
    _source = ref.watch(
      realmPublicationSourceProvider(organizationId, realmId),
    );
    _publishing = null;
    await for (final attempt in _source.watch()) {
      if (_isTerminal(attempt.state) &&
          _publishing?.value == attempt.id.value) {
        _publishing = null;
      }
      yield attempt.id.value.isEmpty ? null : attempt;
    }
  }

  Future<skir.PublicationResult> publish({
    required skir.PublicationId id,
    required skir.AuthoringSnapshot authored,
  }) async {
    final current = state.value;
    if (_publishing != null || (current != null && _isPending(current.state))) {
      return skir.PublicationResult.publishing;
    }
    _publishing = id;
    final request = skir.PublicationAttempt(
      id: id,
      capture: authored.snapshot,
      catalog: authored.generation,
      engineInputs: skir.EngineImplementationInputs.defaultInstance,
      state: skir.PublicationState.checking,
    );
    try {
      final result = await _source.publish(request);
      if (result != skir.PublicationResult.publishing &&
          _publishing?.value == id.value) {
        _publishing = null;
      }
      return result;
    } on Object {
      if (_publishing?.value == id.value) _publishing = null;
      rethrow;
    }
  }
}

bool _isPending(skir.PublicationState state) =>
    state == skir.PublicationState.checking ||
    state == skir.PublicationState.compiling ||
    state == skir.PublicationState.activating;

bool _isTerminal(skir.PublicationState state) =>
    state == skir.PublicationState.complete ||
    state == skir.PublicationState.interrupted ||
    state is skir.PublicationState_blockedWrapper;
