import "package:freezed_annotation/freezed_annotation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "page_element_type_policy.freezed.dart";
part "page_element_type_policy.g.dart";

/// Availability of the concrete element types permitted by a page kind.
///
/// Loading and unavailable states are deliberate UI outcomes. Consumers must
/// not infer that an empty ready set means catalog failure.
@freezed
sealed class PageElementTypesState with _$PageElementTypesState {
  /// The catalog or subtype queries have not completed.
  const factory PageElementTypesState.loading() = PageElementTypesLoading;

  /// The page kind's roots and concrete descendants are available.
  const factory PageElementTypesState.ready(Set<ResolvedTypeRef> types) =
      PageElementTypesReady;

  /// The catalog cannot establish a safe element type policy.
  const factory PageElementTypesState.unavailable(
    List<TypeDiagnostic> diagnostics,
  ) = PageElementTypesUnavailable;
}

/// Initial placement supported when creating a top level entry on a page.
enum PageEntryCreationPlacement { graph, timelineTrack }

/// Concrete element types that can be created as top level entries.
@freezed
abstract class PageEntryCreationPolicy with _$PageEntryCreationPolicy {
  const factory PageEntryCreationPolicy({
    required PageEntryCreationPlacement placement,
    required Set<ResolvedTypeRef> types,
    @Default([]) List<RealmPageAuthoringRuleRef> authoringRules,
  }) = _PageEntryCreationPolicy;

  const PageEntryCreationPolicy._();

  bool accepts(ResolvedTypeRef type) => types.contains(type);
}

/// Resolves the concrete element types allowed by [pageKind].
///
/// Page catalog definitions provide graph node types or timeline track,
/// segment, and keyframe roots. The realm catalog lease supplies subtype
/// results, and abstract matches are removed before the ready state is emitted.
/// Catalog failure remains visible so editor consumers can disable creation and
/// show diagnostics instead of treating incomplete data as permission.
@riverpod
Stream<PageElementTypesState> pageElementTypes(Ref ref, PageKindRef pageKind) {
  final cache = ref.watch(realmEditorCatalogCacheProvider);
  if (cache == null) {
    return Stream.value(
      PageElementTypesUnavailable([
        realmEditorCatalogUnavailableDiagnostic(
          "The page element type catalogue is unavailable",
        ),
      ]),
    );
  }
  final state = ref.watch(realmEditorCatalogProvider).value;
  final definition = state?.snapshot?.pageCatalog.definitions[pageKind];
  if (definition == null) {
    return Stream.value(
      PageElementTypesUnavailable([
        realmEditorCatalogUnavailableDiagnostic(
          "The page kind is unavailable in the active catalog",
        ),
      ]),
    );
  }
  final roots = switch (definition.editor) {
    RealmGraphPageEditor(:final nodeTypes) => nodeTypes,
    RealmTimelinePageEditor(
      :final trackTypes,
      :final segmentTypes,
      :final keyframeTypes,
    ) =>
      [...trackTypes, ...segmentTypes, ...keyframeTypes],
  };

  final queries = [
    for (final root in roots.indexed)
      RealmEditorSubtypeQuery(
        id: "page:${pageKind.id}:${pageKind.revision}:${root.$1}",
        target: root.$2,
      ),
  ];
  ref.watch(
    realmEditorCatalogLeaseProvider(
      RealmEditorCatalogRequest(
        types: roots.toSet(),
        subtypeQueries: queries.toSet(),
      ),
    ),
  );
  return cache.states.map(
    (state) => state._pageElementTypes(roots, queries.map((query) => query.id)),
  );
}

/// Resolves the concrete types that can be created directly on [pageKind].
///
/// Timeline segment and keyframe types are deliberately excluded. They need a
/// parent timeline entry and therefore cannot be created from page selection
/// alone.
@riverpod
AsyncValue<PageEntryCreationPolicy> pageEntryCreationPolicy(
  Ref ref,
  PageKindRef pageKind,
) {
  final elementTypes = ref.watch(pageElementTypesProvider(pageKind));
  if (elementTypes.mapUnready<PageEntryCreationPolicy>() case final value?) {
    return value;
  }
  final state = elementTypes.requireValue;
  switch (state) {
    case PageElementTypesLoading():
      return const AsyncLoading();
    case PageElementTypesUnavailable(:final diagnostics):
      return AsyncError(
        ApiException.badRequest(
          diagnostics.map((diagnostic) => diagnostic.message).join("; "),
        ),
        StackTrace.current,
      );
    case PageElementTypesReady(:final types):
      final catalog = ref.watch(realmEditorCatalogProvider);
      if (catalog.mapUnready<PageEntryCreationPolicy>() case final value?) {
        return value;
      }
      final snapshot = catalog.requireValue.snapshot;
      final definition = snapshot?.pageCatalog.definitions[pageKind];
      if (snapshot == null || definition == null) {
        return AsyncError(
          ApiException.badRequest("The page kind is unavailable"),
          StackTrace.current,
        );
      }
      return AsyncData(_entryCreationPolicy(definition, snapshot, types));
  }
}

/// Resolves the live entry creation policy for one page identity.
///
/// Page metadata changes may select a different page kind. Keeping that
/// indirection in a provider lets consumers observe policy changes without
/// rebuilding their own lifecycle owner.
@riverpod
AsyncValue<PageEntryCreationPolicy> pageEntryCreationPolicyForPage(
  Ref ref,
  skir.RecordId pageId,
) {
  final page = ref.watch(projectedPageProvider(pageId));
  if (page.mapUnready<PageEntryCreationPolicy>() case final value?) {
    return value;
  }
  return ref.watch(pageEntryCreationPolicyProvider(page.requireValue.kind));
}

/// Maps page kinds that can directly create [elementType] to their policy.
@riverpod
AsyncValue<Map<PageKindRef, PageEntryCreationPolicy>> compatiblePageEntryKinds(
  Ref ref,
  ResolvedTypeRef elementType,
) {
  final policies = ref.watch(pageEntryCreationPoliciesProvider);
  if (policies.mapUnready<Map<PageKindRef, PageEntryCreationPolicy>>()
      case final value?) {
    return value;
  }
  return AsyncData(
    Map.unmodifiable(
      Map.fromEntries(
        policies.requireValue.entries.where(
          (entry) => entry.value.accepts(elementType),
        ),
      ),
    ),
  );
}

/// Resolves the live entry creation policy for every available page kind.
@riverpod
AsyncValue<Map<PageKindRef, PageEntryCreationPolicy>> pageEntryCreationPolicies(
  Ref ref,
) {
  final definitions = ref.watch(realmPageDefinitionsProvider);
  if (definitions.mapUnready<Map<PageKindRef, PageEntryCreationPolicy>>()
      case final value?) {
    return value;
  }

  final policies = {
    for (final definition in definitions.requireValue)
      definition.kind: ref.watch(
        pageEntryCreationPolicyProvider(definition.kind),
      ),
  };
  final resolved = <PageKindRef, PageEntryCreationPolicy>{};
  for (final MapEntry(key: kind, value: policy) in policies.entries) {
    if (policy.mapUnready<Map<PageKindRef, PageEntryCreationPolicy>>()
        case final value?) {
      return value;
    }
    resolved[kind] = policy.requireValue;
  }
  return AsyncData(Map.unmodifiable(resolved));
}

PageEntryCreationPolicy _entryCreationPolicy(
  RealmPageDefinition definition,
  RealmEditorCatalogSnapshot snapshot,
  Set<ResolvedTypeRef> allConcreteTypes,
) {
  final (placement, roots) = switch (definition.editor) {
    RealmGraphPageEditor(:final nodeTypes) => (
      PageEntryCreationPlacement.graph,
      nodeTypes,
    ),
    RealmTimelinePageEditor(:final trackTypes) => (
      PageEntryCreationPlacement.timelineTrack,
      trackTypes,
    ),
  };
  final types = {
    ...roots,
    for (final root in roots.indexed)
      ...?snapshot
          .subtypeResults["page:${definition.kind.id}:${definition.kind.revision}:${root.$1}"]
          ?.matches,
  }.where(allConcreteTypes.contains).toSet();
  return PageEntryCreationPolicy(
    placement: placement,
    types: types,
    authoringRules: definition.authoringRules,
  );
}

extension on RealmEditorCatalogState {
  /// Maps the current catalog observation to the page kind policy state.
  PageElementTypesState _pageElementTypes(
    Iterable<ResolvedTypeRef> roots,
    Iterable<String> queryIds,
  ) {
    final current = snapshot;
    final results = queryIds
        .map((id) => current?.subtypeResults[id])
        .whereType<RealmEditorSubtypeResult>()
        .toList();
    if (current != null && results.length == queryIds.length) {
      final registry = TypeRegistry(current.catalog);
      final concrete = [...roots, ...results.expand((result) => result.matches)]
          .where((reference) {
            final resolved = registry.resolveExact(reference).valueOrNull;
            return resolved?.isConcrete ?? false;
          });
      return PageElementTypesReady(concrete.toSet());
    }
    return switch (this) {
      RealmEditorCatalogUnavailable(:final diagnostics) =>
        PageElementTypesUnavailable(diagnostics),
      _ => const PageElementTypesLoading(),
    };
  }
}
