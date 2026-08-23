import "package:freezed_annotation/freezed_annotation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "page_element_type_policy.freezed.dart";
part "page_element_type_policy.g.dart";

@freezed
abstract class PageElementTypePolicy with _$PageElementTypePolicy {
  const factory PageElementTypePolicy({
    required Map<PageType, ResolvedTypeRef> acceptedTypes,
  }) = _PageElementTypePolicy;

  const PageElementTypePolicy._();

  ResolvedTypeRef acceptedType(PageType pageType) => acceptedTypes[pageType]!;
}

@freezed
sealed class PageElementTypesState with _$PageElementTypesState {
  const factory PageElementTypesState.loading() = PageElementTypesLoading;

  const factory PageElementTypesState.ready(Set<ResolvedTypeRef> types) =
      PageElementTypesReady;

  const factory PageElementTypesState.unavailable(
    List<TypeDiagnostic> diagnostics,
  ) = PageElementTypesUnavailable;
}

@Riverpod(keepAlive: true)
PageElementTypePolicy pageElementTypePolicy(Ref ref) => PageElementTypePolicy(
  acceptedTypes: {
    PageType.sequence: "TriggerEntry"._typewriterEntryType,
    PageType.static: "StaticEntry"._typewriterEntryType,
    PageType.scene: "CinematicEntry"._typewriterEntryType,
    PageType.manifest: "ManifestEntry"._typewriterEntryType,
  },
);

@riverpod
Stream<PageElementTypesState> pageElementTypes(Ref ref, PageType pageType) {
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
  final target = ref
      .watch(pageElementTypePolicyProvider)
      .acceptedType(pageType);
  final query = RealmEditorSubtypeQuery(
    id: "page:${pageType.name}:elements",
    target: target,
  );
  cache.request(
    RealmEditorCatalogRequest(types: {target}, subtypeQueries: {query}),
  );
  return cache.states.map((state) => state._pageElementTypes(query.id));
}

extension on RealmEditorCatalogState {
  PageElementTypesState _pageElementTypes(String queryId) {
    final current = snapshot;
    final result = current?.subtypeResults[queryId];
    if (result != null) {
      final registry = TypeRegistry(current!.catalog);
      final concrete = result.matches.where((reference) {
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

extension on String {
  ResolvedTypeRef get _typewriterEntryType => ResolvedTypeRef(
    id: QualifiedTypeId(namespace: "typewriter/v1", name: this),
    revision: 1,
  );
}
