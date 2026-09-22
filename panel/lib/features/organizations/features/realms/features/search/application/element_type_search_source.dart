import "dart:async";

import "package:flutter/foundation.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:rxdart/rxdart.dart";
import "package:typewriter_panel/typewriter_panel.dart";

const elementTypeSearchResultType = SearchResultType(
  id: "authoring.element_type",
  rowRendererId: "authoring.element_type",
  label: "Element Type",
);

/// Lists element definitions that can be added through primary search.
final class ElementTypeSearchSource implements SearchSource {
  ElementTypeSearchSource({
    required this.definitions,
    this.querySelectors = const [],
  });

  final ValueListenable<AsyncValue<List<ElementDefinition>>> definitions;
  final List<QuerySelectorDefinition> querySelectors;

  final _snapshots = BehaviorSubject<SearchSourceSnapshot>.seeded(
    SearchSourceSnapshot.loading(),
  );
  var _disposed = false;

  late final _searchRefresher = SearchRefresher([definitions], search);

  @override
  Stream<SearchSourceSnapshot> get snapshots => _snapshots.stream;

  @override
  List<QuerySelectorDefinition> get selectors => querySelectors;

  @override
  void initialize(SearchQueryContext context) {
    _searchRefresher.initialize(context);
    search(context);
  }

  @override
  void search(SearchQueryContext context) {
    if (_disposed) return;
    _searchRefresher.search(context);

    final query = context.terms.join(" ").trim().toLowerCase();
    final loading = definitions.value.isLoading;
    final results = (definitions.value.value ?? const <ElementDefinition>[])
        .where((definition) => _matches(definition, query))
        .map(
          (definition) => SearchNode.result(
            result: SearchResult(
              id:
                  "element_type:${definition.typeId.uuid}:"
                  "${definition.rootType.revision}",
              type: elementTypeSearchResultType,
              payload: definition,
              title: definition.name,
              subtitle: definition.description,
              isStale: loading,
            ),
          ),
        )
        .toList(growable: false);

    final errors = [
      if (definitions.value case AsyncError(:final error))
        SearchErrorSummary(
          id: "element_types_search_error",
          message: error.toString(),
          severity: SearchErrorSeverity.error,
          sourceLabel: "Element Types",
        ),
    ];

    _snapshots.add(
      SearchSourceSnapshot(
        status: errors.isNotEmpty
            ? SearchSourceStatus.error
            : (loading ? SearchSourceStatus.loading : SearchSourceStatus.ready),
        nodes: results.isEmpty
            ? const []
            : [
                SearchNode.section(
                  id: "element_types",
                  title: "Add Element",
                  children: results,
                ),
              ],
        errorSummaries: errors,
      ),
    );
  }

  bool _matches(ElementDefinition definition, String query) {
    if (query.isEmpty) return true;
    return [
      definition.name,
      definition.description,
      definition.qualifiedName,
    ].any((value) => value.toLowerCase().contains(query));
  }

  @override
  Future<SearchPreviewRequestResult> preview(
    SearchPreviewRequest request,
  ) async {
    return const SearchPreviewRequestResult.error(
      message: "Element types do not provide a preview yet",
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _searchRefresher.dispose();
    unawaited(_snapshots.close());
  }
}
