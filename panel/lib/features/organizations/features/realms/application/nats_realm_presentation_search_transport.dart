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

  String get _requestSubject =>
      "service.to.${realmId.id}.organization.${organizationId.id}.realm.editor.presentation.search";

  String get _updateSubject =>
      "service.from.${realmId.id}.organization.${organizationId.id}.realm.editor.presentation.search";

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
    yield* ref.watchRequest(
      subject: _requestSubject,
      listenSubject: _updateSubject,
      requestBytes: wire.RealmPresentationSearchRequest.serializer.toBytes(
        encoded.valueOrNull!,
      ),
      serializer: wire.RealmPresentationSearchUpdate.serializer,
      transformer: (_, update) => codec.decodeUpdate(update),
    );
  }
}
