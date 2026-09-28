import "package:flutter/foundation.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:rxdart/rxdart.dart";
import "package:searchlight/searchlight.dart" hide SearchResult;
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

const realmSearchResultType = SearchResultType(
  id: "realm",
  rowRendererId: "realm",
  label: "Realm",
);

final class RealmsSearchSource(
  final ValueListenable<AsyncValue<List<TopologyRealm>>> realms,
) implements SearchSource {
  final _snapshotsController = BehaviorSubject<SearchSourceSnapshot>.seeded(
    SearchSourceSnapshot.loading(),
  );

  late final _searchRefresher = SearchRefresher(
    [realms],
    search,
    onChange: _updateIndex,
  );

  final _index = Searchlight.create(
    schema: Schema({"name": TypedField(.string)}),
  );

  Map<String, TopologyRealm> get realmMap {
    return {
      for (final realm in realms.value.value ?? <TopologyRealm>[])
        realm.realmId.toSurrealQl(): realm,
    };
  }

  @override
  Stream<SearchSourceSnapshot> get snapshots => _snapshotsController.stream;

  @override
  List<QuerySelectorDefinition> get selectors => const [];

  @override
  void initialize(SearchQueryContext context) {
    _searchRefresher.initialize(context);
    _updateIndex();
    search(context);
  }

  void _updateIndex() {
    final realms = realmMap;
    final toRemove = _index.externalIdsMap.values.toSet().difference(
      realms.keys.toSet(),
    );
    _index.removeMultiple(toRemove.toList());
    _index.upsertMultiple(
      realms.entries
          .map(
            (entry) => {
              "id": entry.key,
              "name": entry.value.realmId.toSurrealQl(),
            },
          )
          .toList(),
    );
  }

  @override
  void search(SearchQueryContext context) {
    _searchRefresher.search(context);

    final loading = this.realms.value.isLoading;
    final realms = realmMap;

    SearchResult createSearchResult(SearchHit hit) {
      if (realms[hit.id] case final realm?) {
        final realmId = realm.realmId.toSurrealQl();
        return SearchResult(
          id: realmId,
          type: realmSearchResultType,
          payload: realm,
          title: realmId,
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
      if (this.realms.value case AsyncError(:final error))
        SearchErrorSummary(
          id: "realms_search_error",
          message: error.toString(),
          severity: SearchErrorSeverity.error,
          sourceLabel: "Realms",
        ),
    ];

    final nodes = [
      if (hits.isNotEmpty)
        SearchNode.section(id: "realms", title: "Realms", children: hits),
    ];

    _snapshotsController.add(
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
  ) async => const SearchPreviewRequestResult.error(
    message: "Realm results do not provide a separate preview",
  );

  @override
  void dispose() {
    _searchRefresher.dispose();
    _index.dispose();
    _snapshotsController.close();
  }
}
