import "dart:async";

import "package:flutter/foundation.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:rxdart/rxdart.dart";
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
    required this.root,
    required this.label,
  });

  final ResourceDefinitionId definition;
  final ResolvedTypeRef root;
  final String label;

  String get id => "${definition.value}:$root";
}

/// Lists resource types that do not require an ownership attachment.
final class AuthoringCreationSearchSource implements SearchSource {
  AuthoringCreationSearchSource(this.catalog, {this.field});

  final ValueListenable<AsyncValue<RealmEditorCatalogState>> catalog;
  final ValueListenable<AsyncValue<RealmRelationField>>? field;
  final _snapshots = BehaviorSubject<SearchSourceSnapshot>.seeded(.loading());
  late final _refresher = SearchRefresher(
    [catalog, ?field],
    search,
    onChange: _publish,
  );
  SearchQueryContext _query = SearchQueryContext.empty;
  var _disposed = false;

  List<AuthoringCreationOption> get _options {
    final snapshot = catalog.value.value?.snapshot;
    if (snapshot == null) return const [];
    final selectedField = field?.value.value;
    if (field != null && selectedField == null) return const [];
    final registry = TypeRegistry(snapshot.catalog);
    return [
      for (final type in snapshot.catalog.definitions)
        if (type.kind == NominalTypeKind.concrete)
          if (snapshot.resourceDefinitionFor(type.id) case final definition?)
            if (selectedField != null &&
                    selectedField.accepts(type.id, registry) ||
                selectedField == null &&
                    !snapshot.relations.values.any(
                      (relation) =>
                          relation.families.contains("resource.ownership") &&
                          NamedType(type.id).isStructurallyAssignableTo(
                            NamedType(relation.target),
                            registry,
                          ),
                    ))
              AuthoringCreationOption(
                definition: definition.id,
                root: type.id,
                label:
                    snapshot.pageCatalog.definitions[type.id]?.name ??
                    snapshot.elements.values
                        .where((entry) => entry.definition.type == type.id)
                        .firstOrNull
                        ?.definition
                        .name ??
                    type.id.toString(),
              ),
    ];
  }

  @override
  Stream<SearchSourceSnapshot> get snapshots => _snapshots.stream;

  @override
  List<QuerySelectorDefinition> get selectors => const [];

  @override
  void initialize(SearchQueryContext context) {
    _refresher.initialize(context);
    search(context);
  }

  @override
  void search(SearchQueryContext context) {
    _query = context;
    _refresher.search(context);
    _publish();
  }

  void _publish() {
    if (_disposed) return;
    final term = _query.normalizedQuery.trim().toLowerCase();
    final options = _options
        .where(
          (option) => term.isEmpty || option.label.toLowerCase().contains(term),
        )
        .take(20)
        .toList(growable: false);
    final error = catalog.value.error ?? field?.value.error;
    _snapshots.add(
      SearchSourceSnapshot(
        status: error != null
            ? SearchSourceStatus.error
            : catalog.value.isLoading || field?.value.isLoading == true
            ? SearchSourceStatus.loading
            : SearchSourceStatus.ready,
        nodes: options.isEmpty
            ? const []
            : [
                SearchNode.section(
                  id: "authoring.creation",
                  title: "Create Resource",
                  children: [
                    for (final option in options)
                      SearchNode.result(
                        result: SearchResult(
                          id: option.id,
                          type: authoringCreationSearchResultType,
                          payload: option,
                          title: option.label,
                          subtitle: option.root.id.toString(),
                          isStale: catalog.value.isLoading,
                        ),
                      ),
                  ],
                ),
              ],
        errorSummaries: error == null
            ? const []
            : [
                SearchErrorSummary(
                  id: "authoring.creation.catalog",
                  message: error.toString(),
                  severity: SearchErrorSeverity.error,
                  sourceLabel: "Realm",
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
    _refresher.dispose();
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
                  title: "Create ${option.label}",
                  concreteRoot: option.root,
                ),
              ),
        );
        if (created == null) return const SearchCommandResult.cancelled();
        final organizationId = ref.read(organizationIdProvider);
        final realmId = ref.read(realmIdProvider);
        if (organizationId == null || realmId == null) {
          return const SearchCommandResult.failed(
            message: "The selected realm changed while creating the resource",
          );
        }
        return SearchCommandResult.completed(
          hostEffects: [
            OpenAuthoringResourceEffect(
              organizationId: organizationId,
              realmId: realmId,
              resourceId: created.id,
              definition: created.definition,
              ownerPath: const [],
              rootType: option.root,
            ),
          ],
        );
      },
    );
