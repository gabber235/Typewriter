import "package:typewriter_panel/typewriter_panel.dart";

/// Searches the items of one live list, such as the members of the selected
/// organization, by the words [termsOf] gives each item.
///
/// Results show under one section titled [title], each carrying its item as
/// payload, of the type [typeOf] gives it (else [type]). [fixed] items are
/// always searchable beside the list, such as a command to create one more.
/// Results appear only once the person types, unless [listsWithoutQuery].
///
/// By default only a list that is loaded and current gives results: a list
/// that failed or reloads after its scope changed gives none, so the items of
/// a scope the person cannot read never appear. With [retainsStale], the
/// items a list last held stay listed, marked stale while it loads, for a
/// list whose scope never changes under it. A failure is reported under
/// [title] either way.
final class ListSearchSource<T extends Object> implements SearchSource {
  ListSearchSource({
    required this.items,
    required this.type,
    required this.title,
    required this.idOf,
    required this.titleOf,
    required this.termsOf,
    String? sectionId,
    this.typeOf,
    this.subtitleOf,
    this.fixed = const [],
    this.listsWithoutQuery = false,
    this.retainsStale = false,
    this.limit = 10,
  }) : sectionId = sectionId ?? type.id;

  final ValueListenable<AsyncValue<List<T>>> items;
  final SearchResultType type;

  /// The section title, which also names the source of a failure.
  final String title;

  /// The id of the section the results show under; [type]'s id by default.
  final String sectionId;

  /// The id of the item, which its result carries.
  final String Function(T item) idOf;
  final String Function(T item) titleOf;

  /// The words the item is found by, its title among them.
  final List<String> Function(T item) termsOf;
  final SearchResultType Function(T item)? typeOf;
  final String? Function(T item)? subtitleOf;

  /// Items searchable whatever state the list is in, never stale.
  final List<T> fixed;

  /// Whether an empty query lists the items too.
  final bool listsWithoutQuery;

  /// Whether the items a list last held stay listed while it loads again or
  /// after it failed.
  final bool retainsStale;

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

  late final _fixed = {for (final item in fixed) idOf(item): item};

  Map<String, T> get _listed {
    final value = items.value;
    if (!retainsStale && (value.hasError || value.isReloading)) {
      return const {};
    }
    return {for (final item in value.value ?? <T>[]) idOf(item): item};
  }

  @override
  Stream<SearchSourceSnapshot> get snapshots => _snapshots.stream;

  @override
  List<QuerySelectorDefinition> get selectors => const [];

  @override
  void initialize(SearchQueryContext context) {
    _refresher.initialize(context);
    _index.upsertMultiple(_documents(_fixed));
    _updateIndex();
    search(context);
  }

  List<Map<String, Object>> _documents(Map<String, T> items) => [
    for (final MapEntry(:key, :value) in items.entries)
      {"id": key, "text": termsOf(value).join(" ")},
  ];

  void _updateIndex() {
    final listed = _listed;
    final gone = _index.externalIdsMap.values.toSet().difference({
      ...listed.keys,
      ..._fixed.keys,
    });
    _index.removeMultiple(gone.toList());
    _index.upsertMultiple(_documents(listed));
  }

  @override
  void search(SearchQueryContext context) {
    _refresher.search(context);
    final value = items.value;
    final loading = value.isLoading;
    final listed = _listed;
    final hits = context.normalizedQuery.isEmpty && !listsWithoutQuery
        ? const <SearchNode>[]
        : [
            for (final hit
                in _index
                    .search(term: context.normalizedQuery, limit: limit)
                    .hits)
              if (_fixed[hit.id] ?? listed[hit.id] case final item?)
                SearchNode.result(
                  result: SearchResult(
                    id: hit.id,
                    type: typeOf?.call(item) ?? type,
                    payload: item,
                    title: titleOf(item),
                    subtitle: subtitleOf?.call(item),
                    isStale: loading && !_fixed.containsKey(hit.id),
                  ),
                ),
          ];
    final errors = [
      if (value case AsyncError(:final error))
        SearchErrorSummary(
          id: "${sectionId}_search_error",
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
            SearchNode.section(id: sectionId, title: title, children: hits),
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
