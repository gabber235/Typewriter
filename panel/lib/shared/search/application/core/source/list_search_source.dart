import "package:typewriter_panel/typewriter_panel.dart";

/// Searches the items of one live list, such as the members of the selected
/// organization, by the words [termsOf] gives each item.
///
/// Results appear only once the person types, under one section titled
/// [title], each carrying its item as payload. Only a list that is loaded and
/// current gives results: a list that failed or reloads after its scope
/// changed gives none, so the items of a scope the person cannot read never
/// appear. A failure is reported under [title].
final class ListSearchSource<T extends Object> implements SearchSource {
  ListSearchSource({
    required this.items,
    required this.type,
    required this.title,
    required this.idOf,
    required this.titleOf,
    required this.termsOf,
    this.subtitleOf,
    this.limit = 10,
  });

  final ValueListenable<AsyncValue<List<T>>> items;
  final SearchResultType type;

  /// The section title, which also names the source of a failure.
  final String title;
  final String Function(T item) idOf;
  final String Function(T item) titleOf;

  /// The words the item is found by, its title among them.
  final List<String> Function(T item) termsOf;
  final String? Function(T item)? subtitleOf;

  /// The most results one search shows.
  final int limit;

  final _snapshots = BehaviorSubject<SearchSourceSnapshot>.seeded(
    SearchSourceSnapshot.loading(),
  );

  late final _refresher = SearchRefresher(
    [items],
    search,
    onChange: _updateIndex,
  );

  final _index = Searchlight.create(
    schema: Schema({"text": TypedField(.string)}),
  );

  Map<String, T> get _items {
    final value = items.value;
    if (value.hasError || value.isReloading) return const {};
    return {for (final item in value.value ?? <T>[]) idOf(item): item};
  }

  @override
  Stream<SearchSourceSnapshot> get snapshots => _snapshots.stream;

  @override
  List<QuerySelectorDefinition> get selectors => const [];

  @override
  void initialize(SearchQueryContext context) {
    _refresher.initialize(context);
    _updateIndex();
    search(context);
  }

  void _updateIndex() {
    final byId = _items;
    final gone = _index.externalIdsMap.values.toSet().difference(
      byId.keys.toSet(),
    );
    _index.removeMultiple(gone.toList());
    _index.upsertMultiple([
      for (final MapEntry(:key, :value) in byId.entries)
        {"id": key, "text": termsOf(value).join(" ")},
    ]);
  }

  @override
  void search(SearchQueryContext context) {
    _refresher.search(context);
    final value = items.value;
    final loading = value.isLoading;
    final byId = _items;
    final hits = context.normalizedQuery.isEmpty
        ? const <SearchNode>[]
        : [
            for (final hit
                in _index
                    .search(term: context.normalizedQuery, limit: limit)
                    .hits)
              if (byId[hit.id] case final item?)
                SearchNode.result(
                  result: SearchResult(
                    id: "${type.id}:${hit.id}",
                    type: type,
                    payload: item,
                    title: titleOf(item),
                    subtitle: subtitleOf?.call(item),
                    isStale: loading,
                  ),
                ),
          ];
    final errors = [
      if (value case AsyncError(:final error))
        SearchErrorSummary(
          id: "${type.id}_search_error",
          message: error.toString(),
          severity: SearchErrorSeverity.error,
          sourceLabel: title,
        ),
    ];
    _snapshots.add(
      SearchSourceSnapshot(
        status: errors.isNotEmpty
            ? SearchSourceStatus.error
            : (loading ? SearchSourceStatus.loading : SearchSourceStatus.ready),
        nodes: [
          if (hits.isNotEmpty)
            SearchNode.section(id: type.id, title: title, children: hits),
        ],
        errorSummaries: errors,
      ),
    );
  }

  @override
  Future<SearchPreviewRequestResult> preview(
    SearchPreviewRequest request,
  ) async => SearchPreviewRequestResult.error(
    message: "$title results do not provide a separate preview",
  );

  @override
  void dispose() {
    _refresher.dispose();
    _index.dispose();
    _snapshots.close();
  }
}
