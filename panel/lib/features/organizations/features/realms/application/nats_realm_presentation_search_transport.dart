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

  Stream<skir.RealmPresentationSearchUpdate> watch(
    skir.RealmPresentationSearchRequest request,
  ) async* {
    try {
      yield* request.watch(
        ref,
        organizationId: organizationId,
        realmId: realmId,
        snapshot: (update) => update,
        reduce: (_, update) => update,
        reconciliation: const ProjectionReconciliation.latest(),
      );
    } finally {
      await ref.requestSkir(
        skir.CancelRealmPresentationSearchRequest(
          subscriptionId: request.subscriptionId,
        ).operation(organizationId: organizationId, realmId: realmId),
      );
    }
  }
}
