import "dart:async";

import "package:flutter_test/flutter_test.dart";
import "package:http/testing.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("factory persists and restores typed presentation results", () async {
    final persistence = MemoryPresentationSearchHistoryPersistence();
    final first = _Harness(persistence);
    addTearDown(first.dispose);

    first.source.initialize();
    first.source.search(_emptyQuery);
    await _settle();
    final selected = first.snapshots.last.nodes
        .walk()
        .whereType<SearchResultNode>()
        .last
        .result;
    final payload = selected.payload as PresentationSearchResultPayload;

    first.selections.add(
      PresentationSearchSelectionEvent(
        result: selected,
        historyNamespace: payload.providerKey,
      ),
    );
    await _settle();

    expect(first.snapshots.last.nodes.first, isA<SearchSectionNode>());
    expect(
      (first.snapshots.last.nodes.first as SearchSectionNode).title,
      "Recent",
    );

    final second = _Harness(persistence);
    addTearDown(second.dispose);
    second.source.initialize();
    second.source.search(_emptyQuery);
    await _settle();

    final section = second.snapshots.last.nodes.first as SearchSectionNode;
    final restored = section.children.single as SearchResultNode;
    final restoredPayload =
        restored.result.payload as PresentationSearchResultPayload;
    expect(section.title, "Recent");
    expect(restored.result.id, "Beta");
    expect(restoredPayload.selectedValue, const StringValue("Beta"));
    expect(
      restoredPayload.expressions.bindings.bindings[_resultBindingId]?.value,
      const StringValue("Beta"),
    );
  });

  test("missing provider definitions discard stored results", () async {
    final persistence = MemoryPresentationSearchHistoryPersistence();
    final first = _Harness(persistence);
    addTearDown(first.dispose);
    first.source.initialize();
    first.source.search(_emptyQuery);
    await _settle();
    final selected = first.snapshots.last.nodes
        .walk()
        .whereType<SearchResultNode>()
        .last
        .result;
    first.selections.add(
      PresentationSearchSelectionEvent(
        result: selected,
        historyNamespace:
            (selected.payload as PresentationSearchResultPayload).providerKey,
      ),
    );
    await _settle();

    final storage = PresentationSearchHistoryStorage(
      namespace: "test",
      expressions: _expressions,
      registry: _registry,
      persistence: persistence,
    );
    final restored = await storage.loadValidResults(key: "values", capacity: 5);

    expect(restored, isEmpty);
  });
}

const _queryBindingId = BindingId(1);
const _resultBindingId = BindingId(2);
const _emptyQuery = SearchQueryContext(normalizedQuery: "", selectors: []);
const _expressions = ExpressionContext(bindings: BindingEnvironment({}));
final _registry = TypeRegistry(const TypeCatalog([]));

final class _Harness {
  _Harness(PresentationSearchHistoryPersistence persistence)
    : storage = PresentationSearchHistoryStorage(
        namespace: "test",
        expressions: _expressions,
        registry: _registry,
        persistence: persistence,
      ) {
    source = PresentationSearchSourceFactory(
      client: MockClient((_) async => throw UnimplementedError()),
      expressions: _expressions,
      registry: _registry,
      budget: const ExpressionBudget(),
      queryBindingId: _queryBindingId,
      selections: selections.stream,
      historyStorage: storage,
    ).build(_provider());
    subscription = source.snapshots.listen(snapshots.add);
  }

  final PresentationSearchHistoryStorage storage;
  final selections =
      StreamController<PresentationSearchSelectionEvent>.broadcast(sync: true);
  final snapshots = <SearchSourceSnapshot>[];
  late final SearchSource source;
  late final StreamSubscription<SearchSourceSnapshot> subscription;

  Future<void> dispose() async {
    source.dispose();
    await subscription.cancel();
    await selections.close();
  }
}

SearchProvider _provider() {
  const result = TypedExpression(
    resultType: StringType(),
    expression: BindingExpression(
      BindingReference(bindingId: _resultBindingId),
    ),
  );
  return SearchProvider.staticValues(
    values: const ListValue([
      StringValue("Alpha"),
      StringValue("Beta"),
    ]).asLiteral(const ListType(element: StringType())),
    result: const SearchResultMapping(
      bindingId: _resultBindingId,
      key: result,
      selectedValue: result,
      presentation: PresentationNode(
        id: "result",
        element: TextElement(result),
      ),
    ),
  ).withHistory(key: "values", label: "Recent".asStringLiteral, capacity: 5);
}

Future<void> _settle() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}
