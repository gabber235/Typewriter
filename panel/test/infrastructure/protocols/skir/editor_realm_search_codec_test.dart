import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/search.dart"
    as wire;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  final codec = SkirRealmPresentationSearchCodec(
    SkirEditorCodec(TypeRegistry(const TypeCatalog([]))),
  );

  test("serializes the complete query and selector expression", () {
    const category = SearchParsedSelector(
      selectorId: "category",
      key: "category:",
      value: "beneficial",
    );
    const world = SearchParsedSelector(
      selectorId: "world",
      key: "world:",
      value: "overworld",
    );
    const query = SearchQueryContext(
      normalizedQuery: "speed",
      selectors: [category, world],
      selectorExpression: SearchSelectorBinaryExpression(
        operator: SearchSelectorOperator.and,
        left: SearchSelectorLeafExpression(category),
        right: SearchSelectorNotExpression(SearchSelectorLeafExpression(world)),
      ),
    );
    const request = RealmPresentationSearchRequest(
      subscriptionId: "search:1",
      generation: CatalogGeneration("generation"),
      capabilityId: CapabilityId("capability"),
      payload: StringValue("server"),
      resultType: StringType(),
      query: query,
    );

    final encoded = codec.encodeRequest(request).valueOrNull!;
    final bytes = wire.RealmPresentationSearchRequest.serializer.toBytes(
      encoded,
    );
    final decoded = wire.RealmPresentationSearchRequest.serializer.fromBytes(
      bytes,
    );

    expect(decoded.subscriptionId, "search:1");
    expect(decoded.generation.value, "generation");
    expect(decoded.capabilityId.value, "capability");
    expect(decoded.query.normalizedQuery, "speed");
    expect(decoded.query.selectors, hasLength(2));
    expect(decoded.query.selectors.first.selectorId, "category");
    final expression = decoded.query.selectorExpression;
    expect(expression, isA<wire.RealmSearchSelectorExpression_binaryWrapper>());
    final binary =
        (expression! as wire.RealmSearchSelectorExpression_binaryWrapper).value;
    expect(binary.operator_, wire.RealmSearchSelectorOperator.and);
    expect(
      binary.left,
      isA<wire.RealmSearchSelectorExpression_selectorWrapper>(),
    );
    expect(binary.right, isA<wire.RealmSearchSelectorExpression_notWrapper>());
  });

  test("decodes explicit unavailable updates", () {
    final update = codec.decodeUpdate(
      wire.RealmPresentationSearchUpdate.createUnavailable(
        subscriptionId: "search:2",
        diagnostics: [
          const TypeDiagnostic(
            code: TypeDiagnosticCode.invalidPresentation,
            message: "Search handler is unavailable",
          ).encodeWire(
            SkirEditorCodec(TypeRegistry(const TypeCatalog([]))).pathCodec,
          ),
        ],
      ),
    );

    expect(update, isA<RealmPresentationSearchUnavailableUpdate>());
    final unavailable = update as RealmPresentationSearchUnavailableUpdate;
    expect(unavailable.subscriptionId, "search:2");
    expect(
      unavailable.diagnostics.single.message,
      "Search handler is unavailable",
    );
  });
}
