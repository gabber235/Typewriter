import "package:flutter/foundation.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:rxdart/rxdart.dart";
import "package:searchlight/searchlight.dart" hide SearchResult;
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

const organizationSearchResultType = SearchResultType(
  id: "organization",
  rowRendererId: "organization",
  label: "Organization",
);

const createOrganizationSearchResultType = SearchResultType(
  id: "create_organization",
  rowRendererId: "create_organization",
  label: "Create Organization",
);

final class OrganizationsSearchSource(
  final ValueListenable<AsyncValue<List<OrganizationData>>> organizations,
) implements SearchSource {
  final _snapshotsController = BehaviorSubject<SearchSourceSnapshot>.seeded(
    SearchSourceSnapshot.loading(),
  );

  late final _searchRefresher = SearchRefresher(
    [organizations],
    search,
    onChange: _updateIndex,
  );

  final _index = Searchlight.create(
    schema: Schema({"name": TypedField(.string)}),
  );

  Map<String, OrganizationData> get orgs {
    return {
      for (final org in organizations.value.value ?? <OrganizationData>[])
        org.organizationId.toSurrealQl(): org,
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

    _index.insert({
      "id": createOrganizationSearchResultType.id,
      "name": createOrganizationSearchResultType.label,
    });

    search(context);
  }

  void _updateIndex() {
    final organizations = orgs;
    final toRemove = _index.externalIdsMap.values.toSet().difference(
      organizations.keys.toSet(),
    );
    _index.removeMultiple(toRemove.toList());
    _index.upsertMultiple(
      organizations.entries
          .map((e) => {"id": e.key, "name": e.value.name})
          .toList(),
    );
  }

  @override
  void search(SearchQueryContext context) {
    _searchRefresher.search(context);

    final loading = this.organizations.value.isLoading;

    final organizations = orgs;

    SearchResult createSearchResult(SearchHit hit) {
      if (hit.id == createOrganizationSearchResultType.id) {
        return SearchResult(
          id: hit.id,
          type: createOrganizationSearchResultType,
          title: createOrganizationSearchResultType.label,
          payload: {},
        );
      }

      if (organizations[hit.id] case final org?) {
        return SearchResult(
          id: org.organizationId.toSurrealQl(),
          type: organizationSearchResultType,
          payload: org,
          title: org.name,
          isStale: loading,
        );
      }

      throw Exception("Unknown hit id: ${hit.id}");
    }

    final result = _index.search(term: context.normalizedQuery, limit: 10);
    final hits = result.hits
        .map(createSearchResult)
        .map((r) => SearchNode.result(result: r))
        .toList();

    final errors = [
      if (this.organizations.value case AsyncError(:final error))
        SearchErrorSummary(
          id: "organizations_search_error",
          message: error.toString(),
          severity: SearchErrorSeverity.error,
          sourceLabel: "Organizations",
        ),
    ];

    final nodes = [
      if (hits.isNotEmpty)
        SearchNode.section(
          id: "organizations",
          title: "Organizations",
          children: hits,
        ),
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
  Future<SearchPreviewRequestResult> preview(SearchPreviewRequest request) {
    // TODO: implement preview
    throw UnimplementedError();
  }

  @override
  void dispose() {
    _searchRefresher.dispose();
    _index.dispose();
  }
}
