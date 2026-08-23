import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "realm_editor_catalog_provider.g.dart";

@Riverpod(keepAlive: true)
RealmEditorCatalogSource realmEditorCatalogSource(Ref ref) =>
    NatsRealmEditorCatalogSource(ref);

@riverpod
RealmEditorCatalogCache? realmEditorCatalogCache(Ref ref) {
  final organizationId = ref.watch(organizationIdProvider);
  final realmId = ref.watch(realmIdProvider);
  final connection = ref.watch(realmConnectionProvider).value;
  if (organizationId == null ||
      realmId == null ||
      connection != RealmConnectionState.online) {
    return null;
  }
  final cache = RealmEditorCatalogCache(
    source: ref.watch(realmEditorCatalogSourceProvider),
    route: RealmEditorCatalogRoute(
      organizationId: organizationId,
      realmId: realmId,
    ),
  );
  ref.onDispose(cache.dispose);
  cache.start();
  return cache;
}

@riverpod
Stream<RealmEditorCatalogState> realmEditorCatalog(Ref ref) {
  final organizationId = ref.watch(organizationIdProvider);
  final realmId = ref.watch(realmIdProvider);
  final connection = ref.watch(realmConnectionProvider).value;
  if (organizationId == null || realmId == null) {
    return Stream.value(
      RealmEditorCatalogUnavailable([
        realmEditorCatalogUnavailableDiagnostic(
          "Select an organization and realm to load the editor catalog",
        ),
      ]),
    );
  }
  if (connection != RealmConnectionState.online) {
    return Stream.value(
      RealmEditorCatalogUnavailable([
        realmEditorCatalogUnavailableDiagnostic(
          "The selected realm is not connected",
        ),
      ]),
    );
  }
  return ref.watch(realmEditorCatalogCacheProvider)!.states;
}

@riverpod
Stream<RealmEditorCatalogState> realmEditorCatalogForType(
  Ref ref,
  ResolvedTypeRef rootType,
) {
  final cache = ref.watch(realmEditorCatalogCacheProvider);
  if (cache == null) {
    return Stream.value(
      RealmEditorCatalogUnavailable([
        realmEditorCatalogUnavailableDiagnostic(
          "The element type catalogue is unavailable",
        ),
      ]),
    );
  }
  cache.request(RealmEditorCatalogRequest(types: {rootType}));
  return cache.states;
}

void requestRealmEditorCatalog(Ref ref, RealmEditorCatalogRequest request) =>
    ref.read(realmEditorCatalogCacheProvider)?.request(request);

@riverpod
List<ElementDefinition> availableElementDefinitions(Ref ref) {
  final state = ref.watch(realmEditorCatalogProvider).value;
  final snapshot = state?.snapshot;
  if (snapshot == null) return const [];
  return snapshot.elements.values
      .where((entry) => entry.eligible && entry.available)
      .map(
        (entry) => ElementDefinition(
          rootType: entry.definition.type,
          name: entry.definition.name,
          description: entry.definition.description,
          icon: entry.definition.icon,
          color: entry.definition.color,
        ),
      )
      .toList(growable: false);
}

extension RealmEditorCatalogElementResolution
    on AsyncValue<RealmEditorCatalogState> {
  AsyncValue<T> resolveElement<T>(
    ElementDefinition definition,
    T Function(TypeCatalog catalog) create,
  ) => when(
    data: (state) {
      final snapshot = state.snapshot;
      if (snapshot == null) {
        return switch (state) {
          RealmEditorCatalogUnavailable(:final diagnostics) => AsyncValue.error(
            ElementDefinitionException(diagnostics),
            StackTrace.current,
          ),
          _ => const AsyncValue.loading(),
        };
      }
      final catalog = bootstrapTypeCatalog(snapshot.catalog.definitions);
      final resolved = definition.resolve(TypeRegistry(catalog));
      if (resolved.valueOrNull == null) {
        if (state is RealmEditorCatalogLoading) {
          return const AsyncValue.loading();
        }
        return AsyncValue.error(
          ElementDefinitionException(resolved.diagnostics),
          StackTrace.current,
        );
      }
      return AsyncValue.data(create(catalog));
    },
    error: AsyncValue.error,
    loading: () => const AsyncValue.loading(),
  );
}
