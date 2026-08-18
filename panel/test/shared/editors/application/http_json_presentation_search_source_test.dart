import "dart:convert";

import "package:flutter_test/flutter_test.dart";
import "package:http/http.dart" as http;
import "package:http/testing.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  final registry = TypeRegistry(const TypeCatalog([]));

  test("evaluates query parameters without sending credentials", () async {
    late http.Request captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response(
        jsonEncode({
          "items": ["mdi:account"],
        }),
        200,
      );
    });
    final provider = _provider(
      parameters: [
        HttpQueryParameter(
          name: "query",
          value: _binding(_queryBindingId).trim().lowerCase(),
        ),
        HttpQueryParameter(
          name: "empty",
          value: "".asStringLiteral,
          omitIfEmpty: true,
        ),
      ],
    );
    final source = _source(provider, client, registry);
    addTearDown(source.dispose);
    addTearDown(client.close);

    final snapshot = await _search(source, " Account ");

    expect(_resultIds(snapshot), ["mdi:account"]);
    expect(captured.method, "GET");
    expect(captured.url.scheme, "https");
    expect(captured.url.queryParameters["query"], "account");
    expect(captured.url.queryParameters.containsKey("empty"), isFalse);
    expect(captured.headers["Accept"], "application/json");
    expect(captured.headers.containsKey("Authorization"), isFalse);
    expect(captured.headers.containsKey("Cookie"), isFalse);
  });

  test("decodes JSONPath contexts for result expressions", () async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({
          "items": ["mdi:account"],
          "collections": {"mdi": "Material Design Icons"},
        }),
        200,
      ),
    );
    const collectionsType = MapType(key: StringType(), value: StringType());
    final provider = _provider(
      contextBindings: const [
        HttpJsonContextBinding(
          bindingId: _contextBindingId,
          path: r"$.collections",
          type: collectionsType,
        ),
      ],
      mapping: _mapping(
        selectedValue: TypedExpression(
          resultType: collectionsType,
          expression: BindingExpression(
            BindingReference(bindingId: _contextBindingId),
          ),
        ),
      ),
    );
    final source = _source(provider, client, registry);
    addTearDown(source.dispose);
    addTearDown(client.close);

    final snapshot = await _search(source, "account");

    final payload = _payload(snapshot.nodes.single);
    expect(
      payload.selectedValue,
      const MapValue([
        DataMapEntry(
          key: StringValue("mdi"),
          value: StringValue("Material Design Icons"),
        ),
      ]),
    );
    expect(
      payload.expressions.bindings
          .resolve(const BindingReference(bindingId: _contextBindingId))
          .valueOrNull
          ?.value,
      payload.selectedValue,
    );
  });

  test("retains valid candidates when another candidate is invalid", () async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({
          "items": ["valid", 7, "also-valid"],
        }),
        200,
      ),
    );
    final source = _source(_provider(), client, registry);
    addTearDown(source.dispose);
    addTearDown(client.close);

    final snapshot = await _search(source, "valid");

    expect(snapshot.status, SearchSourceStatus.ready);
    expect(_resultIds(snapshot), ["valid", "also-valid"]);
    expect(snapshot.errorSummaries, hasLength(1));
    expect(
      snapshot.errorSummaries.single.severity,
      SearchErrorSeverity.warning,
    );
    expect(snapshot.errorSummaries.single.sourceLabel, "http.test");
    expect(
      snapshot.errorSummaries.single.message,
      r"Expected a string at $, got an integer",
    );
  });

  test("rejects a non HTTPS provider before issuing a request", () async {
    var requested = false;
    final client = MockClient((_) async {
      requested = true;
      return http.Response("{}", 200);
    });
    final source = _source(
      _provider(uri: "http://api.example/search".asStringLiteral),
      client,
      registry,
    );
    addTearDown(source.dispose);
    addTearDown(client.close);

    final snapshot = await _search(source, "account");

    expect(requested, isFalse);
    expect(snapshot.status, SearchSourceStatus.error);
    expect(snapshot.errorSummaries.single.message, "Search URI must use HTTPS");
  });
}

const _queryBindingId = BindingId(10);
const _candidateBindingId = BindingId(20);
const _contextBindingId = BindingId(21);

HttpJsonPresentationSearchSource _source(
  HttpJsonSearchProvider provider,
  http.Client client,
  TypeRegistry registry,
) => HttpJsonPresentationSearchSource(
  provider: provider,
  client: client,
  expressions: const ExpressionContext(bindings: BindingEnvironment({})),
  registry: registry,
  budget: const ExpressionBudget(),
  queryBindingId: _queryBindingId,
  providerKey: "http.test",
);

HttpJsonSearchProvider _provider({
  TypedExpression? uri,
  List<HttpQueryParameter> parameters = const [],
  List<HttpJsonContextBinding> contextBindings = const [],
  SearchResultMapping? mapping,
  Duration timeout = const Duration(seconds: 1),
}) => HttpJsonSearchProvider(
  uri: uri ?? "https://api.example/search".asStringLiteral,
  parameters: parameters,
  resultPath: r"$.items[*]",
  resultType: const StringType(),
  result: mapping ?? _mapping(),
  contextBindings: contextBindings,
  timeout: timeout,
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

Future<SearchSourceSnapshot> _search(
  HttpJsonPresentationSearchSource source,
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

List<String> _resultIds(SearchSourceSnapshot snapshot) => snapshot.nodes
    .cast<SearchResultNode>()
    .map((node) => node.result.id)
    .toList();

PresentationSearchResultPayload _payload(SearchNode node) =>
    (node as SearchResultNode).result.payload
        as PresentationSearchResultPayload;
