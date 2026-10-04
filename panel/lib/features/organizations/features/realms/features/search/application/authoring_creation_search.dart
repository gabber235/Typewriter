import "dart:async";

import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

const authoringCreationSearchResultType = SearchResultType(
  id: "authoring.creation",
  rowRendererId: "authoring.creation",
  label: "Create Resource",
);

const createAuthoringResourceCommandId = SearchCommandId(
  "authoring.resource.create",
);

final class AuthoringCreationOption {
  const AuthoringCreationOption({
    required this.definition,
    required this.configuration,
    required this.label,
    this.display,
  });

  final skir.ResourceDefinitionId definition;
  final skir.TypeSelection configuration;
  final String label;
  final skir.TypeDisplay? display;

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

  @override
  Stream<SearchSourceSnapshot> get snapshots => _snapshots.stream;

  @override
  List<QuerySelectorDefinition> get selectors => const [];

  @override
  void initialize(SearchQueryContext context) => search(context);

  @override
  void search(SearchQueryContext context) {
    _query = context;
    _publish();
  }

  void _publish() {
    if (_disposed) return;
    final catalog = ref.readAuthoringSession().state.catalog;
    if (catalog == null) {
      _snapshots.add(SearchSourceSnapshot.loading());
      return;
    }
    final ownershipTargets = {
      for (final relation in catalog.snapshot.relations)
        if (relation.families.any(
          (family) => family.value == "resource.ownership",
        ))
          relation.second.resource.definition,
    };
    final term = _query.normalizedQuery.trim().toLowerCase();
    final options = <AuthoringCreationOption>[];
    for (final definition in catalog.snapshot.resourceDefinitions) {
      final configuration = catalog.beginSelection(definition.root);
      if (configuration == skir.TypeSelection.unknown) continue;
      final applications = catalog.nominalDefinitions(configuration);
      if (applications.any(ownershipTargets.contains)) continue;
      final label = catalog.typeSelectionName(configuration);
      if (term.isNotEmpty && !label.toLowerCase().contains(term)) continue;
      options.add(
        AuthoringCreationOption(
          definition: definition.id,
          configuration: configuration,
          label: label,
          display: catalog.selectionDisplay(configuration),
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
    unawaited(_snapshots.close());
  }
}

SearchCommand createAuthoringResourceCommand({required Ref ref}) =>
    SearchCommand.single<AuthoringCreationOption>(
      id: createAuthoringResourceCommandId,
      presentation: const SearchCommandPresentation(label: "Create"),
      matcher: const SearchResultMatcher(authoringCreationSearchResultType),
      execute: (execution, option, target) async {
        final created = await execution.prompts.show(
          (context) => ref
              .read(resourceCreationProvider)
              .create(
                context: context,
                request: ResourceCreationRequest(
                  definition: option.definition,
                  configuration: option.configuration,
                ),
              ),
        );
        if (created == null) return const SearchCommandResult.cancelled();
        final organizationId = ref.read(organizationIdProvider);
        final realmId = ref.read(realmIdProvider);
        if (organizationId == null || realmId == null) {
          return const SearchCommandResult.failed(
            message: "The selected Realm changed while creating the resource",
          );
        }
        final catalog = ref.readAuthoringSession().state.catalog;
        final navigationHandler = catalog?.snapshot.resourceDefinitions
            .where((definition) => definition.id == created.definition)
            .map((definition) => definition.navigationHandler)
            .firstOrNull;
        return SearchCommandResult.completed(
          hostEffects: [
            OpenAuthoringResourceEffect(
              organizationId: organizationId,
              realmId: realmId,
              resourceId: created.id,
              definition: created.definition,
              configuration: created.content.configuration,
              navigationHandler: navigationHandler,
            ),
          ],
        );
      },
    );
