// Translates realm presentation search requests and live updates.
//
// Search execution belongs to the realm, while the panel owns query input
// and rendering. This boundary carries typed payloads into that remote
// owner and converts snapshot or unavailable updates into domain states that
// preserve diagnostics and subscription identity.
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/search.dart"
    as wire;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as wire_type;
import "package:typewriter_panel/typewriter_panel.dart";

/// Encodes search requests and decodes realm search updates.
final class SkirRealmPresentationSearchCodec {
  const SkirRealmPresentationSearchCodec(this.editor);

  final SkirEditorCodec editor;

  /// Encodes a typed search request for the realm owner.
  TypeResult<wire.RealmPresentationSearchRequest> encodeRequest(
    RealmPresentationSearchRequest request,
  ) {
    final payload = editor.encodeValue(request.payload);
    final resultType = editor.typeCodec.encodeExpression(request.resultType);
    final diagnostics = [...payload.diagnostics, ...resultType.diagnostics];

    if (request.subscriptionId.isEmpty) {
      diagnostics.add(
        _realmSearchDiagnostic("Search subscription ID is empty"),
      );
    }

    if (diagnostics.isNotEmpty) {
      return TypeResult.failure(diagnostics);
    }

    return TypeResult.success(
      wire.RealmPresentationSearchRequest(
        subscriptionId: request.subscriptionId,
        generation: wire_type.CatalogGeneration(
          value: request.generation.value,
        ),
        capabilityId: wire_type.CapabilityId(value: request.capabilityId.value),
        payload: payload.valueOrNull!,
        resultType: resultType.valueOrNull!,
        query: _encodeQuery(request.query),
      ),
    );
  }

  /// Decodes a snapshot or unavailable update without losing diagnostics.
  RealmPresentationSearchUpdate decodeUpdate(
    wire.RealmPresentationSearchUpdate update,
  ) => switch (update) {
    wire.RealmPresentationSearchUpdate_snapshotWrapper(:final value) =>
      _decodeSnapshot(value),
    wire.RealmPresentationSearchUpdate_unavailableWrapper(:final value) =>
      RealmPresentationSearchUpdate.unavailable(
        subscriptionId: value.subscriptionId,
        diagnostics: value.diagnostics
            .map((item) => item.decodeWire(editor.pathCodec))
            .toList(growable: false),
      ),
    wire.RealmPresentationSearchUpdate_unknown() =>
      RealmPresentationSearchUpdate.unavailable(
        subscriptionId: "unknown",
        diagnostics: [
          _realmSearchDiagnostic("Realm returned an unknown search update"),
        ],
      ),
  };

  wire.RealmSearchQuery _encodeQuery(SearchQueryContext query) =>
      encodeRealmSearchQuery(query);

  RealmPresentationSearchUpdate _decodeSnapshot(
    wire.RealmPresentationSearchSnapshot snapshot,
  ) {
    final values = snapshot.values.map(editor.decodeValue).toList();
    final diagnostics = [
      ...snapshot.diagnostics.map((item) => item.decodeWire(editor.pathCodec)),
      ...values.expand((item) => item.diagnostics),
    ];
    return RealmPresentationSearchUpdate.snapshot(
      subscriptionId: snapshot.subscriptionId,
      status: switch (snapshot.status) {
        wire.RealmPresentationSearchStatus.loading =>
          SearchSourceStatus.loading,
        wire.RealmPresentationSearchStatus.ready => SearchSourceStatus.ready,
        wire.RealmPresentationSearchStatus.error ||
        wire.RealmPresentationSearchStatus_unknown() =>
          SearchSourceStatus.error,
      },
      values: values.map((item) => item.valueOrNull).nonNulls.toList(),
      guidance: snapshot.guidance.toList(growable: false),
      diagnostics: diagnostics,
    );
  }
}

TypeDiagnostic _realmSearchDiagnostic(String message) => TypeDiagnostic(
  code: TypeDiagnosticCode.invalidPresentation,
  message: message,
  pathPresent: false,
);
