import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

final class NatsRealmPresentationSearchTransport {
  const NatsRealmPresentationSearchTransport({
    required this.ref,
    required this.organizationId,
    required this.realmId,
  });

  final Ref ref;
  final skir.RecordId organizationId;
  final skir.RecordId realmId;

  RealmServiceAddress get _address =>
      RealmServiceAddress(organizationId: organizationId, realmId: realmId);

  Stream<skir.RealmPresentationSearchUpdate> watch(
    skir.RealmPresentationSearchRequest request,
  ) async* {
    try {
      yield* ref.watchProjection<
        skir.RealmPresentationSearchUpdate,
        skir.RealmPresentationSearchUpdate,
        skir.RealmPresentationSearchUpdate
      >(
        subject: _address.request("editor.presentation.search"),
        eventSubject: _address.event("editor.presentation.search"),
        requestBytes: skir.RealmPresentationSearchRequest.serializer.toBytes(
          request,
        ),
        responseSerializer: skir.RealmPresentationSearchUpdate.serializer,
        eventSerializer: skir.RealmPresentationSearchUpdate.serializer,
        snapshot: (update) => update,
        reduce: (_, update) => update,
        delivery: const ProjectionDelivery.ephemeral(),
        reconciliation: const ProjectionReconciliation.latest(),
      );
    } finally {
      await ref.requestSkir(
        _address.request("editor.presentation.search.cancel"),
        skir.CancelRealmPresentationSearchRequest.serializer.toBytes(
          skir.CancelRealmPresentationSearchRequest(
            subscriptionId: request.subscriptionId,
          ),
        ),
        skir.CancelRealmPresentationSearchResult.serializer,
      );
    }
  }
}
