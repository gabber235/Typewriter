import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/search.dart"
    as wire;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as wire_type;
import "package:typewriter_panel/typewriter_panel.dart";

final class SkirRealmPresentationSearchCodec {
  const SkirRealmPresentationSearchCodec(this.editor);

  final SkirEditorCodec editor;

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
      wire.RealmSearchQuery(
        normalizedQuery: query.normalizedQuery,
        selectors: query.selectors.map(_encodeSelector),
        selectorExpression: query.selectorExpression == null
            ? null
            : _encodeSelectorExpression(query.selectorExpression!),
      );

  wire.RealmSearchSelector _encodeSelector(SearchParsedSelector selector) =>
      wire.RealmSearchSelector(
        selectorId: selector.selectorId,
        key: selector.key,
        value: selector.value,
      );

  wire.RealmSearchSelectorExpression _encodeSelectorExpression(
    SearchSelectorExpression expression,
  ) => switch (expression) {
    SearchSelectorLeafExpression(:final selector) =>
      wire.RealmSearchSelectorExpression.wrapSelector(
        _encodeSelector(selector),
      ),
    SearchSelectorBinaryExpression(
      :final operator,
      :final left,
      :final right,
    ) =>
      wire.RealmSearchSelectorExpression.createBinary(
        operator_: operator == SearchSelectorOperator.and
            ? wire.RealmSearchSelectorOperator.and
            : wire.RealmSearchSelectorOperator.or,
        left: _encodeSelectorExpression(left),
        right: _encodeSelectorExpression(right),
      ),
    SearchSelectorNotExpression(:final expression) =>
      wire.RealmSearchSelectorExpression.createNot(
        expression: _encodeSelectorExpression(expression),
      ),
  };

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
