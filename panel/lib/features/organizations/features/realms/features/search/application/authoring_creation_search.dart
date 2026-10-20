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
    required skir.TypeDefinitionId type,
    required skir.TypeSelection configuration,
    required String label,
    skir.TypeDisplay? display,
    @Default(SearchQueryContext.empty) SearchQueryContext query,
    String? disabledReason,
  }) = _AuthoringCreationOption;

  const AuthoringCreationOption._();

  String get id => "$configuration";
}

/// Lists catalog creation options without allocating resources. The command
/// resolves destination constraints when invoked, stages through the shared
/// creation owner, and returns navigation as a host effect after admission.
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
    for (final type in catalog.creatableTypes) {
      final configuration = catalog.beginSelection(type);
      if (!_query.matchesCreationType(catalog, configuration)) continue;
      final label = catalog.typeSelectionName(configuration);
      if (term.isNotEmpty && !label.toLowerCase().contains(term)) continue;
      options.add(
        AuthoringCreationOption(
          type: type,
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
              type: option.type,
              configuration: option.configuration,
            ),
            creationContext: option.query.creationContext(
              document: ref.read(realmEditingProvider(scope)).document,
              configuration: option.configuration,
              preferredResources: ambientCreationResources(
                ref,
                scope,
                ref.read(realmEditingProvider(scope)).document,
              ),
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
