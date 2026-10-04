import "dart:async";

import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

const authoringResourceSearchResultType = SearchResultType(
  id: "authoring.resource",
  rowRendererId: "authored.presentation.subject",
  label: "Resource",
);

final class AuthoringSearchResultPayload {
  const AuthoringSearchResultPayload({
    required this.hit,
    required this.catalog,
  });

  final skir.AuthoringSearchHit hit;
  final CheckedEditorCatalog catalog;

  skir.ResourceId get id => hit.resource;
  skir.ResourceDefinitionId get definition => hit.definition;
  skir.PresentationSubject get subject => hit.subject;
  skir.PortableValue get context => hit.context;
  skir.TypeSelection get configuration => hit.subject.content.configuration;

  String get title =>
      subject.descriptor.authoredString ??
      subject.content.authoredField("name")?.authoredString ??
      id.value;
}

final class RealmAuthoringSearchSource
    implements SearchSource, SearchSelectorCompletionSource {
  RealmAuthoringSearchSource({
    required this.ref,
    required this.organizationId,
    required this.realmId,
    this.contextResource,
    this.target,
    this.contexts = const [],
    this.definitionFilter,
  });

  final Ref ref;
  final skir.RecordId organizationId;
  final skir.RecordId realmId;
  final skir.ResourceId? contextResource;
  final skir.NamedTypeUse? target;
  final List<skir.ResourceId> contexts;
  final Set<skir.ResourceDefinitionId>? definitionFilter;

  final _snapshots = StreamController<SearchSourceSnapshot>.broadcast(
    sync: true,
  );
  var _revision = 0;
  var _disposed = false;

  @override
  Stream<SearchSourceSnapshot> get snapshots => _snapshots.stream;

  @override
  List<QuerySelectorDefinition> get selectors => const [];

  @override
  void initialize(SearchQueryContext context) => search(context);

  @override
  void search(SearchQueryContext context) {
    if (_disposed) return;
    final revision = ++_revision;
    _snapshots.add(SearchSourceSnapshot.loading());
    unawaited(_search(context, revision));
  }

  Future<void> _search(SearchQueryContext query, int revision) async {
    try {
      final access = ref.readAuthoringSession();
      final snapshot = access.state.snapshot;
      final catalog = access.state.catalog;
      if (snapshot == null || catalog == null) {
        throw StateError("Realm authoring is not ready");
      }
      final requestedDefinitions = definitionFilter;
      final roots = catalog.snapshot.resourceDefinitions
          .where(
            (definition) =>
                requestedDefinitions == null ||
                requestedDefinitions.isEmpty ||
                requestedDefinitions.contains(definition.id),
          )
          .map((definition) => definition.root)
          .toList(growable: false);
      final response = await access.notifier.search(
        skir.SearchAuthoringRequest(
          generation: snapshot.generation,
          snapshot: snapshot.snapshot,
          query: encodeRealmSearchQuery(query),
          roots: roots,
          contexts: contexts.isNotEmpty ? contexts : [?contextResource],
          target: target,
          facets: _validationFacets(query),
        ),
      );
      if (_disposed || revision != _revision) return;
      _publish(response, catalog);
    } on Object catch (error) {
      if (_disposed || revision != _revision) return;
      _publishError(["Realm search failed: $error"]);
    }
  }

  List<skir.SearchFacetRequest> _validationFacets(SearchQueryContext query) {
    final values = <String, List<String>>{};
    for (final selector in query.selectors) {
      final value = selector.value;
      if (value == null) continue;
      values.putIfAbsent(selector.selectorId, () => []).add(value);
    }
    return [
      for (final entry in values.entries)
        skir.SearchFacetRequest(
          facetId: skir.SearchFacetId(value: entry.key),
          partial: null,
          validate: entry.value,
        ),
    ];
  }

  void _publish(
    skir.SearchAuthoringResponse response,
    CheckedEditorCatalog catalog,
  ) {
    switch (response) {
      case skir.SearchAuthoringResponse_successWrapper(:final value):
        final payloads = [
          for (final hit in value.hits)
            AuthoringSearchResultPayload(hit: hit, catalog: catalog),
        ];
        _snapshots.add(
          SearchSourceSnapshot.ready(
            nodes: [
              for (final payload in payloads)
                SearchNode.result(
                  result: SearchResult(
                    id: "${payload.definition.value}:${payload.id.value}",
                    type: authoringResourceSearchResultType,
                    payload: payload,
                    title: payload.title,
                  ),
                ),
            ],
            errorSummaries: [
              for (final diagnostic in value.diagnostics)
                SearchErrorSummary(
                  id: "realm.authoring.${diagnostic.code}",
                  message: diagnostic.message,
                  severity: SearchErrorSeverity.error,
                  sourceLabel: "Realm",
                ),
            ],
            selectorValidations: [
              for (final facet in value.facets)
                for (final accepted in facet.accepted)
                  SearchSelectorValidation(
                    selectorId: facet.facetId.value,
                    value: accepted,
                    status: SearchSelectorValidationStatus.accepted,
                  ),
              for (final facet in value.facets)
                for (final rejected in facet.rejected)
                  SearchSelectorValidation(
                    selectorId: facet.facetId.value,
                    value: rejected,
                    status: SearchSelectorValidationStatus.rejected,
                  ),
            ],
          ),
        );
      case skir.SearchAuthoringResponse_invalidWrapper(:final value):
        _publishError(
          value.diagnostics.map((diagnostic) => diagnostic.message).toList(),
        );
      case skir.SearchAuthoringResponse_catalogChangedWrapper():
        _publishError(const ["The Realm editor catalog changed"]);
      case skir.SearchAuthoringResponse_internalErrorWrapper():
        _publishError(const ["Realm could not complete the search"]);
      case skir.SearchAuthoringResponse_unknown():
        _publishError(const ["Realm returned an unknown search response"]);
    }
  }

  void _publishError(List<String> messages) {
    _snapshots.add(
      SearchSourceSnapshot.error(
        errorSummaries: [
          for (final item in messages.indexed)
            SearchErrorSummary(
              id: "realm.authoring.response.${item.$1}",
              message: item.$2,
              severity: SearchErrorSeverity.error,
              sourceLabel: "Realm",
            ),
        ],
      ),
    );
  }

  @override
  Future<SearchPreviewRequestResult> preview(SearchPreviewRequest request) =>
      Future.value(
        const SearchPreviewRequestResult.error(
          message: "Authoring resources do not provide a separate preview",
        ),
      );

  @override
  Future<SearchSelectorCompletionResult> completeSelector(
    SearchSelectorCompletionRequest request,
  ) async => const SearchSelectorCompletionResult();

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _revision++;
    unawaited(_snapshots.close());
  }
}
