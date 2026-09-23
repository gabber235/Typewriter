import "dart:async";

import "package:flutter/foundation.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:rxdart/rxdart.dart";
import "package:searchlight/searchlight.dart" hide SearchResult;
import "package:typewriter_panel/typewriter_panel.dart";

const pageTypeSearchResultType = SearchResultType(
  id: "authoring.page_kind",
  rowRendererId: "authoring.page_kind",
  label: "Page Kind",
);

/// Lists page types available in the active realm catalog.
final class PageTypeSearchSource implements SearchSource {
  PageTypeSearchSource({
    required this.definitions,
    this.querySelectors = const [],
  });

  final ValueListenable<AsyncValue<List<RealmPageDefinition>>> definitions;
  final List<QuerySelectorDefinition> querySelectors;
  final _snapshots = BehaviorSubject<SearchSourceSnapshot>.seeded(.loading());
  var _disposed = false;

  late final _searchRefresher = SearchRefresher(
    [definitions],
    search,
    onChange: _updateIndex,
  );

  final _index = Searchlight.create(
    schema: Schema({
      "name": TypedField(.string),
      "description": TypedField(.string),
      "type": TypedField(.string),
    }),
  );

  Map<String, RealmPageDefinition> get definitionMap {
    return {
      for (final definition
          in definitions.value.value ?? <RealmPageDefinition>[])
        definition.id: definition,
    };
  }

  @override
  Stream<SearchSourceSnapshot> get snapshots => _snapshots.stream;

  @override
  List<QuerySelectorDefinition> get selectors => querySelectors;

  @override
  void initialize(SearchQueryContext context) {
    _searchRefresher.initialize(context);
    _updateIndex();
    search(context);
  }

  void _updateIndex() {
    final definitions = definitionMap;
    final toRemove = _index.externalIdsMap.values.toSet().difference(
      definitions.keys.toSet(),
    );

    _index.removeMultiple(toRemove.toList());
    _index.upsertMultiple(
      definitions.entries
          .map(
            (entry) => {
              "id": entry.key,
              "name": entry.value.name,
              "description": entry.value.description ?? "",
              "type": entry.value.type.toString(),
            },
          )
          .toList(),
    );
  }

  @override
  void search(SearchQueryContext context) {
    if (_disposed) return;

    _searchRefresher.search(context);

    final loading = definitions.value.isLoading;
    final definitionMap = this.definitionMap;

    SearchResult createSearchResult(SearchHit hit) {
      if (definitionMap[hit.id] case final definition?) {
        return SearchResult(
          id: hit.id,
          type: pageTypeSearchResultType,
          payload: definition,
          title: definition.name,
          subtitle: definition.description,
          isStale: loading,
        );
      }

      throw Exception("Unknown hit id: ${hit.id}");
    }

    final result = _index.search(term: context.normalizedQuery, limit: 10);
    final hits = result.hits
        .map(createSearchResult)
        .map((result) => SearchNode.result(result: result))
        .toList();

    final errors = [
      if (definitions.value case AsyncError(:final error))
        SearchErrorSummary(
          id: "page_types_search_error",
          message: error.toString(),
          severity: SearchErrorSeverity.error,
          sourceLabel: "Page Kinds",
        ),
    ];

    final nodes = [
      if (hits.isNotEmpty)
        SearchNode.section(
          id: "page_types",
          title: "Create Page",
          children: hits,
        ),
    ];

    _snapshots.add(
      SearchSourceSnapshot(
        status: errors.isNotEmpty
            ? SearchSourceStatus.error
            : (loading ? SearchSourceStatus.loading : SearchSourceStatus.ready),
        nodes: nodes,
        errorSummaries: errors,
      ),
    );
  }

  @override
  Future<SearchPreviewRequestResult> preview(
    SearchPreviewRequest request,
  ) async {
    return const SearchPreviewRequestResult.error(
      message: "Page types do not provide a preview yet",
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _searchRefresher.dispose();
    _index.dispose();
    unawaited(_snapshots.close());
  }
}
