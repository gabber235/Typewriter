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
      subject.content.authoredField("title")?.authoredString ??
      id.value;
}

final class RealmAuthoringSearchSource implements SearchSource {
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
  skir.SearchAuthoringResponse? _response;
  CheckedEditorCatalog? _catalog;
  ProviderSubscription<AsyncValue<AuthoringDocument>>? _working;

  @override
  Stream<SearchSourceSnapshot> get snapshots => _snapshots.stream;

  @override
  List<QuerySelectorDefinition> get selectors => const [];

  @override
  void initialize(SearchQueryContext context) {
    final scope = AuthoringScope(
      organizationId: organizationId,
      realmId: realmId,
    );
    _working = ref.listen(workingAuthoringDocumentProvider(scope), (_, next) {
      final response = _response;
      final catalog = _catalog;
      if (!_disposed && response != null && catalog != null) {
        _publish(response, catalog);
      }
    });
    search(context);
  }

  @override
  void search(SearchQueryContext context) {
    if (_disposed) return;
    final revision = ++_revision;
    _response = null;
    _catalog = null;
    _snapshots.add(SearchSourceSnapshot.loading());
    unawaited(_search(context, revision));
  }

  Future<void> _search(SearchQueryContext query, int revision) async {
    try {
      final scope = AuthoringScope(
        organizationId: organizationId,
        realmId: realmId,
      );
      final document = ref
          .read(workingAuthoringDocumentProvider(scope))
          .requireValue;
      final catalog = document.catalog;
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
      final response = await ref
          .read(authoredResourceCommandsProvider(scope))
          .search(
            skir.SearchAuthoringRequest(
              generation: document.generation,
              query: encodeRealmSearchQuery(query).normalizedQuery,
              roots: roots,
              contexts: contexts.isNotEmpty ? contexts : [?contextResource],
              target: target,
            ),
          );
      if (_disposed || revision != _revision) return;
      _response = response;
      _catalog = catalog;
      _publish(response, catalog);
    } on Object catch (error) {
      if (_disposed || revision != _revision) return;
      _publishError(["Realm search failed: $error"]);
    }
  }

  void _publish(
    skir.SearchAuthoringResponse response,
    CheckedEditorCatalog catalog,
  ) {
    final scope = AuthoringScope(
      organizationId: organizationId,
      realmId: realmId,
    );
    final working = ref.read(workingAuthoringDocumentProvider(scope)).value;
    switch (response) {
      case skir.SearchAuthoringResponse_successWrapper(:final value):
        if (value.generation != working?.generation ||
            catalog.snapshot.generation != working?.generation) {
          _publishError(const ["The Realm editor catalog changed"]);
          return;
        }
        final payloads = [
          for (final hit in value.hits)
            if (working?.entry(hit.resource) != null)
              AuthoringSearchResultPayload(
                hit: skir.AuthoringSearchHit(
                  resource: hit.resource,
                  definition: hit.definition,
                  subject: skir.PresentationSubject(
                    resource: hit.resource,
                    definition: hit.definition,
                    content: working!.resource(hit.resource)!,
                    descriptor: skir.DataValue.unfilled,
                  ),
                  context: hit.context,
                ),
                catalog: working.catalog,
              ),
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
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _revision++;
    _working?.close();
    unawaited(_snapshots.close());
  }
}
