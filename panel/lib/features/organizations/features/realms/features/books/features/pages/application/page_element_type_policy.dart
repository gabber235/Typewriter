import "package:freezed_annotation/freezed_annotation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "page_element_type_policy.freezed.dart";
part "page_element_type_policy.g.dart";

@freezed
sealed class PageElementTypesState with _$PageElementTypesState {
  const factory PageElementTypesState.loading() = PageElementTypesLoading;

  const factory PageElementTypesState.ready(Set<ResolvedTypeRef> types) =
      PageElementTypesReady;

  const factory PageElementTypesState.unavailable(
    List<TypeDiagnostic> diagnostics,
  ) = PageElementTypesUnavailable;
}

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

extension on RealmEditorCatalogState {
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
