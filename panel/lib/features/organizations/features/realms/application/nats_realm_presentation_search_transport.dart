import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/search.dart"
    as wire;
import "package:typewriter_panel/typewriter_panel.dart";

final class NatsRealmPresentationSearchTransport {
  const NatsRealmPresentationSearchTransport({
    required this.ref,
    required this.organizationId,
    required this.realmId,
    required this.registry,
  });

  final Ref ref;
  final skir.RecordId organizationId;
  final skir.RecordId realmId;
  final TypeRegistry registry;

  RealmServiceAddress get _address =>
      RealmServiceAddress(organizationId: organizationId, realmId: realmId);

  String get _requestSubject => _address.request("editor.presentation.search");

  String get _updateSubject => _address.event("editor.presentation.search");

  String get _cancelSubject =>
      _address.request("editor.presentation.search.cancel");

  Stream<RealmPresentationSearchUpdate> watch(
    RealmPresentationSearchRequest request,
  ) async* {
    final codec = SkirRealmPresentationSearchCodec(SkirEditorCodec(registry));
    final encoded = codec.encodeRequest(request);
    if (encoded case TypeFailure(:final diagnostics)) {
      yield RealmPresentationSearchUpdate.unavailable(
        subscriptionId: request.subscriptionId,
        diagnostics: diagnostics,
      );
      return;
    }
    try {
      yield* ref.watchRequest(
        subject: _requestSubject,
        listenSubject: _updateSubject,
        requestBytes: wire.RealmPresentationSearchRequest.serializer.toBytes(
          encoded.valueOrNull!,
        ),
        serializer: wire.RealmPresentationSearchUpdate.serializer,
        transformer: (_, update) => codec.decodeUpdate(update),
      );
    } finally {
      await ref.requestSkir(
        _cancelSubject,
        wire.CancelRealmPresentationSearchRequest.serializer.toBytes(
          wire.CancelRealmPresentationSearchRequest(
            subscriptionId: request.subscriptionId,
          ),
        ),
        wire.CancelRealmPresentationSearchResult.serializer,
      );
    }
  }
}
