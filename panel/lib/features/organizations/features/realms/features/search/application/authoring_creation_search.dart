import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "authoring_creation_search.freezed.dart";

const authoringCreationSearchResultType = SearchResultType(
  id: "authoring.creation",
  rowRendererId: "authoring.creation",
  label: "Create Resource",
);

const createAuthoringResourceCommandId = SearchCommandId(
  "authoring.resource.create",
);

@freezed
abstract class AuthoringCreationOption with _$AuthoringCreationOption {
  const factory AuthoringCreationOption({
    required skir.ResourceDefinitionId definition,
    required skir.TypeSelection configuration,
    required String label,
    skir.TypeDisplay? display,
    @Default(SearchQueryContext.empty) SearchQueryContext query,
    String? disabledReason,
  }) = _AuthoringCreationOption;

  const AuthoringCreationOption._();

  String get id => "${definition.value}:$configuration";
}

final class AuthoringCreationSearchSource implements SearchSource {
  AuthoringCreationSearchSource(this.ref);

  final Ref ref;
  final _snapshots = StreamController<SearchSourceSnapshot>.broadcast(
    sync: true,
  );
  SearchQueryContext _query = SearchQueryContext.empty;
  var _disposed = false;
  ProviderSubscription<AsyncValue<AuthoringDocument>>? _working;

  @override
  Stream<SearchSourceSnapshot> get snapshots => _snapshots.stream;

  @override
  List<QuerySelectorDefinition> get selectors => authoringCreationSelectors;

  @override
  void initialize(SearchQueryContext context) {
    _working = ref.listen(
      selectedWorkingAuthoringDocumentProvider,
      (_, _) => _publish(),
    );
    search(context);
  }

  @override
  void search(SearchQueryContext context) {
    _query = context;
    _publish();
  }

  void _publish() {
    if (_disposed) return;
    final document = ref.read(selectedWorkingAuthoringDocumentProvider).value;
    if (document == null) {
      _snapshots.add(SearchSourceSnapshot.loading());
      return;
    }
    final catalog = document.catalog;
    final term = _query.normalizedQuery.trim().toLowerCase();
    final options = <AuthoringCreationOption>[];
    for (final definition in catalog.snapshot.resourceDefinitions) {
      final root = catalog.beginSelection(definition.root);
      for (final configuration in catalog.concreteRecordSelections(root)) {
        if (!_query.matchesCreationType(catalog, configuration)) continue;
        final label = catalog.typeSelectionName(configuration);
        if (term.isNotEmpty && !label.toLowerCase().contains(term)) continue;
        options.add(
          AuthoringCreationOption(
            definition: definition.id,
            configuration: configuration,
            label: label,
            display: catalog.selectionDisplay(configuration),
            query: _query,
            disabledReason: configuration is skir.TypeSelection_completeWrapper
                ? null
                : "This type requires concrete type arguments",
          ),
        );
      }
    }
    options.sort((left, right) => left.label.compareTo(right.label));
    _snapshots.add(
      SearchSourceSnapshot.ready(
        nodes: [
          if (options.isNotEmpty)
            SearchNode.section(
              id: "authoring.creation",
              title: "Create Resource",
              children: [
                for (final option in options.take(20))
                  SearchNode.result(
                    result: SearchResult(
                      id: option.id,
                      type: authoringCreationSearchResultType,
                      payload: option,
                      title: option.label,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Future<SearchPreviewRequestResult> preview(
    SearchPreviewRequest request,
  ) async => const SearchPreviewRequestResult.error(
    message: "Creation options do not provide a separate preview",
  );

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _working?.close();
    unawaited(_snapshots.close());
  }
}

SearchCommand createAuthoringResourceCommand({
  required Ref ref,
  required AuthoringScope scope,
}) => SearchCommand.single<AuthoringCreationOption>(
  id: createAuthoringResourceCommandId,
  presentation: const SearchCommandPresentation(label: "Create"),
  matcher: const SearchResultMatcher(authoringCreationSearchResultType),
  evaluate: (option, _) => option.disabledReason == null
      ? const SearchCommandState.enabled()
      : SearchCommandState.disabled(option.disabledReason!),
  execute: (execution, option, target) async {
    final intent = ref.read(resourceCreationProvider(scope)).beginNavigation();
    final created = await execution.prompts.show(
      (context) => ref
          .read(resourceCreationProvider(scope))
          .create(
            context: context,
            request: ResourceCreationRequest(
              definition: option.definition,
              configuration: option.configuration,
            ),
            creationContext: option.query.creationContext(
              document: ref.read(realmEditingProvider(scope)).document,
              configuration: option.configuration,
              preferredResources: <skir.ResourceId>{
                ...ref
                    .read(selectionProvider)
                    .whereType<AuthoringResourceIdentifier>()
                    .where((resource) => resource.scope == scope)
                    .map((resource) => resource.resourceId),
                ?ref.read(pageIdProvider),
                ?ref.read(bookIdProvider),
              }.toList(),
            ),
          ),
    );
    if (created == null) return const SearchCommandResult.cancelled();
    return SearchCommandResult.completed(
      hostEffects: [
        RevealCreatedAuthoringResourceEffect(resource: created, intent: intent),
      ],
    );
  },
);
