import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart" hide SearchController;
import "package:flutter_animate/flutter_animate.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:rxdart/rxdart.dart";
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

const _selectAuthoringCreationHostsCommandId = SearchCommandId(
  "authoring.resource.creation-hosts.select",
);

final class AuthoringCreationOption {
  const AuthoringCreationOption({
    required this.slot,
    required this.root,
    this.hosts = const [],
    this.partial,
    this.referenceOrigins = const [],
    this.ownerPath = const [],
  });

  final RealmAuthoringCreationSlot slot;
  final ResolvedTypeRef root;
  final List<skir.ResourceId> hosts;
  final DataValue? partial;
  final List<skir.ResourceId> referenceOrigins;
  final List<skir.ResourceId> ownerPath;

  String get id => "${slot.id.value}:$root";
  String get label =>
      slot.concreteRoots.length == 1 ? slot.label : "${slot.label} ($root)";
}

/// Exposes every Realm creation slot without resource family code.
final class AuthoringCreationSearchSource implements SearchSource {
  AuthoringCreationSearchSource(
    this.catalog, {
    this.hosts,
    this.partial,
    this.referenceOrigins = const [],
    this.ownerPath = const [],
  });

  final ValueListenable<AsyncValue<RealmEditorCatalogState>> catalog;
  final List<AuthoringCreationHost>? hosts;
  final DataValue? partial;
  final List<skir.ResourceId> referenceOrigins;
  final List<skir.ResourceId> ownerPath;
  final _snapshots = BehaviorSubject<SearchSourceSnapshot>.seeded(.loading());
  late final _refresher = SearchRefresher(
    [catalog],
    search,
    onChange: _publish,
  );
  SearchQueryContext _query = SearchQueryContext.empty;
  var _disposed = false;

  List<AuthoringCreationOption> get _options {
    final snapshot = catalog.value.value?.snapshot;
    if (snapshot == null) return const [];
    return [
      for (final slot in snapshot.creationSlots.values)
        if (hosts == null || slot.acceptsHosts(hosts!, snapshot))
          for (final root in slot.concreteRoots)
            AuthoringCreationOption(
              slot: slot,
              root: root,
              hosts:
                  hosts?.map((host) => host.id).toList(growable: false) ??
                  const [],
              partial: partial,
              referenceOrigins: referenceOrigins,
              ownerPath: ownerPath,
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
    final error = catalog.value.error;
    _snapshots.add(
      SearchSourceSnapshot(
        status: error != null
            ? SearchSourceStatus.error
            : catalog.value.isLoading
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
        final catalog = ref.read(realmEditorCatalogProvider).value?.snapshot;
        if (catalog == null) {
          return const SearchCommandResult.failed(
            message: "The Realm editor catalog is unavailable",
          );
        }
        final hosts = option.hosts.isNotEmpty
            ? option.hosts
            : await execution.prompts.show(
                (context) => option.slot.selectCreationHosts(
                  context: context,
                  ref: ref,
                  catalog: catalog,
                ),
              );
        if (hosts == null) return const SearchCommandResult.cancelled();
        final created = await execution.prompts.show(
          (context) => ref
              .read(resourceCreationProvider)
              .create(
                context: context,
                request: ResourceCreationRequest(
                  slot: option.slot.id,
                  title: "Create ${option.slot.label}",
                  concreteRoot: option.root,
                  hosts: hosts,
                  partial: option.partial,
                  referenceOrigins: option.referenceOrigins,
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
              ownerPath: option.ownerPath,
              rootType: option.root,
            ),
          ],
        );
      },
    );

final class AuthoringCreationHost {
  const AuthoringCreationHost({
    required this.id,
    required this.definition,
    required this.root,
  });

  final skir.ResourceId id;
  final ResourceDefinitionId definition;
  final ResolvedTypeRef root;
}

final class _CompleteAuthoringCreationHosts implements SearchHostEffect {
  const _CompleteAuthoringCreationHosts(this.hosts);

  final List<skir.ResourceId> hosts;
}

extension AuthoringCreationHostSelection on RealmAuthoringCreationSlot {
  Future<List<skir.ResourceId>?> selectCreationHosts({
    required BuildContext context,
    required Ref ref,
    required RealmEditorCatalogSnapshot catalog,
  }) {
    final hostPolicy = switch (this.context) {
      RealmStandaloneCreationContext() => null,
      RealmDeclaredRelationCreationContext(:final hosts, :final cardinality) =>
        (filter: hosts, cardinality: cardinality),
      RealmReferencePathCreationContext(:final hosts, :final cardinality) => (
        filter: hosts,
        cardinality: cardinality,
      ),
    };
    if (hostPolicy == null) return Future.value(const []);
    final organizationId = ref.read(organizationIdProvider);
    final realmId = ref.read(realmIdProvider);
    if (organizationId == null || realmId == null) return Future.value();
    final multiple =
        hostPolicy.cardinality == RealmCreationHostCardinality.oneOrMore;
    return showSearchModal<List<skir.ResourceId>>(
      context,
      (modalRef, modalContext) {
        final select = SearchCommand.batch<AuthoringSearchResultPayload>(
          id: _selectAuthoringCreationHostsCommandId,
          presentation: const SearchCommandPresentation(label: "Select"),
          matcher: const SearchResultMatcher(authoringResourceSearchResultType),
          evaluate: (values, target) => !multiple && values.length != 1
              ? const SearchCommandState.disabled(
                  "Select exactly one host resource",
                )
              : const SearchCommandState.enabled(),
          execute: (execution, values, target) async =>
              SearchCommandResult.completed(
                hostEffects: [
                  _CompleteAuthoringCreationHosts(
                    values.map((value) => value.id).toList(growable: false),
                  ),
                ],
              ),
        );
        return SearchContribution(
          session: SearchSession(
            source: RealmAuthoringSearchSource(
              ref: modalRef,
              organizationId: organizationId,
              realmId: realmId,
              assignableTo: hostPolicy.filter.assignableTo,
              definitionFilter: hostPolicy.filter.definitions,
            ).debounced(100.ms).cached(),
            interaction: SearchInteraction(
              activation: SearchActivation.command(
                resolve: (_) => _selectAuthoringCreationHostsCommandId,
                dependencies: const [],
              ),
              selectionMode: multiple
                  ? SearchSelectionMode.multiple
                  : SearchSelectionMode.single,
              commands: [select],
            ),
          ),
          hostEffectExecutors: [
            SearchHostEffectExecutor<_CompleteAuthoringCreationHosts>(
              (effect) => Navigator.of(modalContext).pop(effect.hosts),
            ),
          ],
        );
      },
      searchHint: "Search host resources",
      rowRenderers: {
        authoringResourceSearchResultType.id: (context) =>
            AuthoringSearchResultItem(
              payload: context.result.payload as AuthoringSearchResultPayload,
              focused: context.focused,
              selected: context.selected,
              loading: context.loading,
              onTap: context.onTap,
              shortcutActivator: context.shortcutActivator,
            ),
      },
    );
  }
}

extension RealmAuthoringCreationHostAcceptance on RealmAuthoringCreationSlot {
  bool acceptsHosts(
    List<AuthoringCreationHost> hosts,
    RealmEditorCatalogSnapshot catalog,
  ) {
    final context = this.context;
    if (context is RealmStandaloneCreationContext) return hosts.isEmpty;
    final (filter, cardinality) = switch (context) {
      RealmDeclaredRelationCreationContext(:final hosts, :final cardinality) =>
        (hosts, cardinality),
      RealmReferencePathCreationContext(:final hosts, :final cardinality) => (
        hosts,
        cardinality,
      ),
      RealmStandaloneCreationContext() => throw StateError(
        "Standalone creation was handled before host validation",
      ),
    };
    if (cardinality == RealmCreationHostCardinality.exactlyOne &&
        hosts.length != 1) {
      return false;
    }
    if (cardinality == RealmCreationHostCardinality.oneOrMore &&
        hosts.isEmpty) {
      return false;
    }
    final registry = TypeRegistry(catalog.catalog);
    return hosts.every(
      (host) =>
          (filter.definitions.isEmpty ||
              filter.definitions.contains(host.definition)) &&
          (filter.assignableTo == null ||
              NamedType(host.root)
                  .isStructurallyAssignableTo(filter.assignableTo!, registry)),
    );
  }
}
