import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  final registry = TypeRegistry(const TypeCatalog([]));

  test("maps static candidates with the active query context", () async {
    final provider = StaticSearchProvider(
      values: _values(["first", "second"]),
      result: _mapping(selectedValue: _binding(_queryBindingId)),
    );
    final source = _source(provider, registry);
    addTearDown(source.dispose);

    final snapshot = await _search(source, "needle");

    expect(snapshot.status, SearchSourceStatus.ready);
    expect(_resultIds(snapshot), ["first", "second"]);
    final payload = _payload(snapshot.nodes.first);
    expect(payload.selectedValue, const StringValue("needle"));
    expect(payload.providerKey, "static.test");
    expect(
      payload.expressions.bindings
          .resolve(const BindingReference(bindingId: _candidateBindingId))
          .valueOrNull
          ?.value,
      const StringValue("first"),
    );
  });

  test("retains valid candidates when another mapping is invalid", () async {
    final source = _source(
      StaticSearchProvider(values: _values(["valid", ""]), result: _mapping()),
      registry,
    );
    addTearDown(source.dispose);

    final snapshot = await _search(source, "");

    expect(_resultIds(snapshot), ["valid"]);
    expect(snapshot.errorSummaries, hasLength(1));
    expect(
      snapshot.errorSummaries.single.severity,
      SearchErrorSeverity.warning,
    );
    expect(
      snapshot.errorSummaries.single.message,
      "Search result keys must not be empty",
    );
  });

  test(
    "binds parsed selector values and exposes selector definitions",
    () async {
      const selectorBindingId = BindingId(33);
      final provider = StaticSearchProvider(
        values: _values(["speed"]),
        selectors: [
          SearchSelectorDefinition.keyValue(
            id: "category",
            key: "category:",
            valueBindingId: selectorBindingId,
            values: SearchSelectorValues.enumeration(["beneficial", "harmful"]),
          ),
        ],
        result: _mapping(selectedValue: _binding(selectorBindingId)),
      );
      final source = _source(provider, registry);
      addTearDown(source.dispose);
      final selectors = await source.selectors.first;
      final terminal = source.snapshots.firstWhere(
        (snapshot) => snapshot.status == SearchSourceStatus.ready,
      );

      source.search(
        const SearchQueryContext(
          normalizedQuery: "speed",
          selectors: [
            SearchParsedSelector(
              selectorId: "category",
              key: "category:",
              value: "beneficial",
            ),
          ],
        ),
      );
      final snapshot = await terminal;

      expect(selectors.single, isA<KeyValueSelectorDefinition>());
      final definition = selectors.single as KeyValueSelectorDefinition;
      expect(definition.key, "category:");
      expect(definition.multiplicity, QueryMultiplicity.single);
      expect(
        _payload(snapshot.nodes.single).selectedValue,
        const StringValue("beneficial"),
      );
    },
  );

  test("reports a values expression that is not a list", () async {
    final source = _source(
      StaticSearchProvider(
        values: "invalid".asStringLiteral,
        result: _mapping(),
      ),
      registry,
    );
    addTearDown(source.dispose);

    final snapshot = await _search(source, "");

    expect(snapshot.status, SearchSourceStatus.error);
    expect(
      snapshot.errorSummaries.single.message,
      "Static search values must evaluate to a list",
    );
  });
}

const _queryBindingId = BindingId(10);
const _candidateBindingId = BindingId(20);

StaticPresentationSearchSource _source(
  StaticSearchProvider provider,
  TypeRegistry registry,
) => StaticPresentationSearchSource(
  provider: provider,
  expressions: const ExpressionContext(bindings: BindingEnvironment({})),
  registry: registry,
  budget: const ExpressionBudget(),
  queryBindingId: _queryBindingId,
  providerKey: "static.test",
);

Future<SearchSourceSnapshot> _search(
  StaticPresentationSearchSource source,
  String query,
) {
  final terminal = source.snapshots.firstWhere(
    (snapshot) =>
        snapshot.status == SearchSourceStatus.ready ||
        snapshot.status == SearchSourceStatus.error,
  );
  source.search(
    SearchQueryContext(normalizedQuery: query, selectors: const []),
  );
  return terminal;
}

TypedExpression _values(List<String> values) => TypedExpression(
  resultType: const ListType(element: StringType()),
  expression: LiteralExpression(
    ListValue(values.map(StringValue.new).toList()),
  ),
);

SearchResultMapping _mapping({TypedExpression? selectedValue}) =>
    SearchResultMapping(
      bindingId: _candidateBindingId,
      key: _binding(_candidateBindingId),
      selectedValue: selectedValue ?? _binding(_candidateBindingId),
      presentation: PresentationNode(
        id: "result",
        element: TextElement(_binding(_candidateBindingId)),
      ),
    );

TypedExpression _binding(BindingId id) => TypedExpression(
  resultType: const StringType(),
  expression: BindingExpression(BindingReference(bindingId: id)),
);

List<String> _resultIds(SearchSourceSnapshot snapshot) => snapshot.nodes
    .cast<SearchResultNode>()
    .map((node) => node.result.id)
    .toList();

PresentationSearchResultPayload _payload(SearchNode node) =>
    (node as SearchResultNode).result.payload
        as PresentationSearchResultPayload;
