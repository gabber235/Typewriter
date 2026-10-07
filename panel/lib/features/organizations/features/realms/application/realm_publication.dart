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
  bool _publishing = false;
  late RealmPublicationSource _source;

  @override
  Stream<skir.PublicationReport?> build(
    skir.RecordId organizationId,
    skir.RecordId realmId,
  ) async* {
    _source = ref.watch(
      realmPublicationSourceProvider(organizationId, realmId),
    );
    _publishing = false;
    await for (final attempt in _source.watch()) {
      yield attempt.id.value.isEmpty ? null : attempt;
    }
  }

  Future<skir.PublicationResult> publish() async {
    final current = state.value;
    if (_publishing || (current != null && _isPending(current.state)))
      return skir.PublicationResult.publishing;
    _publishing = true;
    try {
      return await _source.publish();
    } finally {
      _publishing = false;
    }
  }
}

bool _isPending(skir.PublicationState state) =>
    state == skir.PublicationState.checking ||
    state == skir.PublicationState.compiling ||
    state == skir.PublicationState.activating;
