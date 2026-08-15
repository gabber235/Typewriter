import "dart:async";
import "dart:convert";

import "package:flutter_test/flutter_test.dart";
import "package:http/http.dart" as http;
import "package:http/testing.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  final registry = TypeRegistry(const TypeCatalog([]));

  test(
    "ignores a stale request that completes after the latest request",
    () async {
      final requests = <String, Completer<http.Response>>{};
      final client = MockClient((request) {
        final query = request.url.queryParameters["query"]!;
        final completer = Completer<http.Response>();
        requests[query] = completer;
        return completer.future;
      });
      final source = _source(_provider(), client, registry);
      addTearDown(source.dispose);
      addTearDown(client.close);
      final snapshots = <SearchSourceSnapshot>[];
      final subscription = source.snapshots.listen(snapshots.add);
      addTearDown(subscription.cancel);

      source
        ..search(_query("first"))
        ..search(_query("second"));
      await _waitUntil(() => requests.length == 2);
      requests["second"]!.complete(_response("second"));
      await _waitUntil(
        () => snapshots.any(
          (snapshot) =>
              snapshot.status == SearchSourceStatus.ready &&
              _resultIds(snapshot).contains("second"),
        ),
      );
      requests["first"]!.complete(_response("first"));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final ready = snapshots
          .where((snapshot) => snapshot.status == SearchSourceStatus.ready)
          .toList();
      expect(ready, hasLength(1));
      expect(_resultIds(ready.single), ["second"]);
    },
  );

  test("reports timeout without accepting the delayed response", () async {
    final response = Completer<http.Response>();
    final client = MockClient((_) => response.future);
    final source = _source(
      _provider(timeout: const Duration(milliseconds: 10)),
      client,
      registry,
    );
    addTearDown(source.dispose);
    addTearDown(client.close);

    final snapshot = await _search(source, "slow");

    expect(snapshot.status, SearchSourceStatus.error);
    expect(snapshot.errorSummaries.single.message, "Search request timed out");
    response.complete(_response("late"));
  });

  test("rejects a redirect response that leaves HTTPS", () async {
    final redirectedRequest = http.Request(
      "GET",
      Uri.parse("http://api.example/search?query=value"),
    );
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({
          "items": ["value"],
        }),
        200,
        request: redirectedRequest,
      ),
    );
    final source = _source(_provider(), client, registry);
    addTearDown(source.dispose);
    addTearDown(client.close);

    final snapshot = await _search(source, "value");

    expect(snapshot.status, SearchSourceStatus.error);
    expect(
      snapshot.errorSummaries.single.message,
      "Search redirects must remain on HTTPS",
    );
  });

  test("reports unsuccessful HTTP responses", () async {
    final client = MockClient((_) async => http.Response("unavailable", 503));
    final source = _source(_provider(), client, registry);
    addTearDown(source.dispose);
    addTearDown(client.close);

    final snapshot = await _search(source, "value");

    expect(snapshot.status, SearchSourceStatus.error);
    expect(
      snapshot.errorSummaries.single.message,
      "Search request returned status 503",
    );
  });
}

const _queryBindingId = BindingId(10);
const _candidateBindingId = BindingId(20);

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
  Duration timeout = const Duration(seconds: 1),
}) => HttpJsonSearchProvider(
  uri: "https://api.example/search".asStringLiteral,
  parameters: [
    HttpQueryParameter(name: "query", value: _binding(_queryBindingId)),
  ],
  resultPath: r"$.items[*]",
  resultType: const StringType(),
  result: SearchResultMapping(
    bindingId: _candidateBindingId,
    key: _binding(_candidateBindingId),
    selectedValue: _binding(_candidateBindingId),
    presentation: PresentationNode(
      id: "result",
      element: TextElement(_binding(_candidateBindingId)),
    ),
  ),
  timeout: timeout,
);

TypedExpression _binding(BindingId id) => TypedExpression(
  resultType: const StringType(),
  expression: BindingExpression(BindingReference(bindingId: id)),
);

SearchQueryContext _query(String value) =>
    SearchQueryContext(normalizedQuery: value, selectors: const []);

Future<SearchSourceSnapshot> _search(
  HttpJsonPresentationSearchSource source,
  String query,
) {
  final terminal = source.snapshots.firstWhere(
    (snapshot) =>
        snapshot.status == SearchSourceStatus.ready ||
        snapshot.status == SearchSourceStatus.error,
  );
  source.search(_query(query));
  return terminal;
}

http.Response _response(String value) => http.Response(
  jsonEncode({
    "items": [value],
  }),
  200,
);

List<String> _resultIds(SearchSourceSnapshot snapshot) => snapshot.nodes
    .cast<SearchResultNode>()
    .map((node) => node.result.id)
    .toList();

Future<void> _waitUntil(bool Function() predicate) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    if (predicate()) return;
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  fail("Condition was not reached");
}
