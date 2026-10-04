import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/features/organizations/features/realms/application/realm_service_address.dart";
import "package:typewriter_panel/infrastructure/messaging/skir_nats.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/search.dart"
    as search;

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

  Stream<search.RealmPresentationSearchUpdate> watch(
    search.RealmPresentationSearchRequest request,
  ) async* {
    try {
      yield* ref.watchRequest(
        subject: _address.request("editor.presentation.search"),
        listenSubject: _address.event("editor.presentation.search"),
        requestBytes: search.RealmPresentationSearchRequest.serializer.toBytes(
          request,
        ),
        serializer: search.RealmPresentationSearchUpdate.serializer,
        transformer: (_, update) => update,
      );
    } finally {
      await ref.requestSkir(
        _address.request("editor.presentation.search.cancel"),
        search.CancelRealmPresentationSearchRequest.serializer.toBytes(
          search.CancelRealmPresentationSearchRequest(
            subscriptionId: request.subscriptionId,
          ),
        ),
        search.CancelRealmPresentationSearchResult.serializer,
      );
    }
  }
}
