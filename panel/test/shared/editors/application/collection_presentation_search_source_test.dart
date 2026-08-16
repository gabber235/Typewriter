import "dart:async";

import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test(
    "maps locally searched collection rows without exposing raw keys",
    () async {
      const rowBinding = BindingId(7);
      final registry = TypeRegistry(const TypeCatalog([]));
      final collection = LocalPresentationCollectionSource(
        id: const PresentationCollectionSourceId("elements"),
        schema: const PresentationCollectionSchema(
          rowType: StringType(),
          keyType: StringType(),
          rowBindingId: rowBinding,
          key: TypedExpression(
            resultType: StringType(),
            expression: BindingExpression(
              BindingReference(bindingId: rowBinding),
            ),
          ),
        ),
        rows: const [StringValue("Entry"), StringValue("Segment cue")],
        registry: registry,
        searchPredicate: (row, query) => (row as StringValue).value
            .toLowerCase()
            .contains(query.normalizedQuery),
      );
      final source = CollectionPresentationSearchSource(
        provider: _provider,
        source: collection,
        expressions: const ExpressionContext(bindings: BindingEnvironment({})),
        registry: registry,
        budget: const ExpressionBudget(),
        queryBindingId: const BindingId(9),
        providerKey: "collection.test",
      );
      addTearDown(source.dispose);
      final terminal = source.snapshots.firstWhere(
        (snapshot) => snapshot.status == SearchSourceStatus.ready,
      );

      source.search(
        const SearchQueryContext(normalizedQuery: "segment", selectors: []),
      );
      final snapshot = await terminal;

      final result = snapshot.nodes.single as SearchResultNode;
      expect(result.result.id, "Segment cue");
      expect(result.result.title, "Segment cue");
      expect(
        (result.result.payload as PresentationSearchResultPayload)
            .selectedValue,
        const StringValue("Segment cue"),
      );
    },
  );

  test("ignores delayed emissions from a superseded query", () async {
    final collection = _DelayedCollectionSource();
    final source = CollectionPresentationSearchSource(
      provider: _provider,
      source: collection,
      expressions: const ExpressionContext(bindings: BindingEnvironment({})),
      registry: _registry,
      budget: const ExpressionBudget(),
      queryBindingId: const BindingId(9),
      providerKey: "collection.delayed",
    );
    final snapshots = <SearchSourceSnapshot>[];
    final subscription = source.snapshots.listen(snapshots.add);

    source
      ..search(_query("old"))
      ..search(_query("new"));
    collection
      ..emit("old", _snapshot("Old result"))
      ..emit("new", _snapshot("New result"));

    final ready = snapshots
        .where((snapshot) => snapshot.status == SearchSourceStatus.ready)
        .toList();
    expect(ready, hasLength(1));
    expect(
      (ready.single.nodes.single as SearchResultNode).result.title,
      "New result",
    );

    collection.completeCancellations();
    await subscription.cancel();
    source.dispose();
  });

  test("evaluates collection filters in the result binding scope", () async {
    const rowBinding = BindingId(7);
    final collection = LocalPresentationCollectionSource(
      id: const PresentationCollectionSourceId("elements"),
      schema: const PresentationCollectionSchema(
        rowType: BooleanType(),
        keyType: BooleanType(),
        rowBindingId: rowBinding,
        key: TypedExpression(
          resultType: BooleanType(),
          expression: BindingExpression(
            BindingReference(bindingId: rowBinding),
          ),
        ),
      ),
      rows: const [BooleanValue(false), BooleanValue(true)],
      registry: _registry,
    );
    final source = CollectionPresentationSearchSource(
      provider: _filteredProvider,
      source: collection,
      expressions: const ExpressionContext(bindings: BindingEnvironment({})),
      registry: _registry,
      budget: const ExpressionBudget(),
      queryBindingId: const BindingId(9),
      providerKey: "collection.filtered",
    );
    addTearDown(source.dispose);
    final terminal = source.snapshots.firstWhere(
      (snapshot) => snapshot.status == SearchSourceStatus.ready,
    );

    source.search(_query(""));
    final snapshot = await terminal;

    expect(snapshot.errorSummaries, isEmpty);
    expect(snapshot.nodes, hasLength(1));
    expect(
      (snapshot.nodes.single as SearchResultNode).result.payload,
      isA<PresentationSearchResultPayload>().having(
        (payload) => payload.selectedValue,
        "selectedValue",
        const BooleanValue(true),
      ),
    );
  });
}

const _resultBinding = BindingId(8);
final _registry = TypeRegistry(const TypeCatalog([]));

const _provider = CollectionSearchProvider(
  sourceId: PresentationCollectionSourceId("elements"),
  result: SearchResultMapping(
    bindingId: _resultBinding,
    key: TypedExpression(
      resultType: StringType(),
      expression: BindingExpression(
        BindingReference(bindingId: _resultBinding),
      ),
    ),
    selectedValue: TypedExpression(
      resultType: StringType(),
      expression: BindingExpression(
        BindingReference(bindingId: _resultBinding),
      ),
    ),
    label: TypedExpression(
      resultType: StringType(),
      expression: BindingExpression(
        BindingReference(bindingId: _resultBinding),
      ),
    ),
    presentation: PresentationNode(
      id: "result",
      element: TextElement(
        TypedExpression(
          resultType: StringType(),
          expression: BindingExpression(
            BindingReference(bindingId: _resultBinding),
          ),
        ),
      ),
    ),
  ),
);

const _booleanResultExpression = TypedExpression(
  resultType: BooleanType(),
  expression: BindingExpression(BindingReference(bindingId: _resultBinding)),
);

const _filteredProvider = CollectionSearchProvider(
  sourceId: PresentationCollectionSourceId("elements"),
  result: SearchResultMapping(
    bindingId: _resultBinding,
    key: _booleanResultExpression,
    selectedValue: _booleanResultExpression,
    presentation: PresentationNode(
      id: "result",
      element: TextElement(
        TypedExpression(
          resultType: StringType(),
          expression: LiteralExpression(StringValue("Selectable")),
        ),
      ),
    ),
  ),
  where: _booleanResultExpression,
);

SearchQueryContext _query(String value) =>
    SearchQueryContext(normalizedQuery: value, selectors: const []);

PresentationCollectionSnapshot _snapshot(String value) =>
    PresentationCollectionSnapshot(
      rows: [
        PresentationCollectionRow(
          key: StringValue(value),
          value: StringValue(value),
        ),
      ],
    );

final class _DelayedCollectionSource implements PresentationCollectionSource {
  final _streams = <String, _DelayedSnapshotStream>{};

  @override
  PresentationCollectionSourceId get id =>
      const PresentationCollectionSourceId("elements");

  @override
  PresentationCollectionSchema get schema => const PresentationCollectionSchema(
    rowType: StringType(),
    keyType: StringType(),
    rowBindingId: BindingId(7),
    key: TypedExpression(
      resultType: StringType(),
      expression: BindingExpression(BindingReference(bindingId: BindingId(7))),
    ),
  );

  @override
  Stream<PresentationCollectionSnapshot> watch(
    PresentationCollectionQuery query,
  ) {
    final search = query as PresentationCollectionSearch;
    return _streams.putIfAbsent(
      search.query.normalizedQuery,
      _DelayedSnapshotStream.new,
    );
  }

  void emit(String query, PresentationCollectionSnapshot snapshot) {
    _streams[query]?.emit(snapshot);
  }

  void completeCancellations() {
    for (final stream in _streams.values) {
      stream.completeCancellation();
    }
  }
}

final class _DelayedSnapshotStream
    extends Stream<PresentationCollectionSnapshot> {
  _DelayedSnapshotSubscription? _subscription;

  @override
  StreamSubscription<PresentationCollectionSnapshot> listen(
    void Function(PresentationCollectionSnapshot event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _subscription = _DelayedSnapshotSubscription(onData);
  }

  void emit(PresentationCollectionSnapshot snapshot) {
    _subscription?.emit(snapshot);
  }

  void completeCancellation() => _subscription?.completeCancellation();
}

final class _DelayedSnapshotSubscription
    implements StreamSubscription<PresentationCollectionSnapshot> {
  _DelayedSnapshotSubscription(this._onData);

  void Function(PresentationCollectionSnapshot event)? _onData;
  final _cancellation = Completer<void>();
  bool _cancelled = false;
  bool _paused = false;

  void emit(PresentationCollectionSnapshot snapshot) {
    if (!_cancelled && !_paused) _onData?.call(snapshot);
  }

  void completeCancellation() {
    if (!_cancellation.isCompleted) _cancellation.complete();
  }

  @override
  Future<void> cancel() async {
    await _cancellation.future;
    _cancelled = true;
  }

  @override
  bool get isPaused => _paused;

  @override
  void onData(void Function(PresentationCollectionSnapshot data)? handleData) {
    _onData = handleData;
  }

  @override
  void onDone(void Function()? handleDone) {}

  @override
  void onError(Function? handleError) {}

  @override
  void pause([Future<void>? resumeSignal]) {
    _paused = true;
    resumeSignal?.whenComplete(resume);
  }

  @override
  void resume() => _paused = false;

  @override
  Future<E> asFuture<E>([E? futureValue]) => Completer<E>().future;
}
