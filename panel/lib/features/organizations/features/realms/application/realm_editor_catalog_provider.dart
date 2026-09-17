// Providers bind the selected organization and realm to one catalog cache. The
// cache exists only while the realm connection gate is online. Commands and
// searches built from the active snapshot share its catalog generation.
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "realm_editor_catalog_provider.g.dart";

/// Provides the replaceable catalog transport boundary.
@Riverpod(keepAlive: true)
RealmEditorCatalogSource realmEditorCatalogSource(Ref ref) =>
    NatsRealmEditorCatalogSource(ref);

/// Owns the catalog cache while the selected realm is online.
///
/// A null value is deliberate when selection or connectivity is absent. This
/// prevents stale realm subscriptions from surviving a route or connection
/// change.
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

/// Exposes catalog state, including explicit reasons for missing selection or
/// connection. Consumers should watch this stream instead of creating a cache.
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

/// Retains one root type as demand on the shared catalog cache.
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
  ref.watch(
    realmEditorCatalogLeaseProvider(
      RealmEditorCatalogRequest(types: {rootType}),
    ),
  );
  return cache.states;
}

/// Acquires a provider owned lease for merged catalog demand.
@riverpod
RealmEditorCatalogLease? realmEditorCatalogLease(
  Ref ref,
  RealmEditorCatalogRequest request,
) {
  final cache = ref.watch(realmEditorCatalogCacheProvider);
  if (cache == null) return null;
  final lease = cache.acquire(request);
  ref.onDispose(lease.close);
  return lease;
}

/// Builds the editor runtime from one coherent catalog generation.
///
/// Command and search transports share the same decoded registry and
/// generation. When the catalog becomes unavailable, no runtime is exposed;
/// when it changes, Riverpod rebuilds the runtime rather than mixing versions.
final activeRealmEditorRuntimeProvider = Provider<EditorRealmRuntime?>((ref) {
  final organizationId = ref.watch(organizationIdProvider);
  final realmId = ref.watch(realmIdProvider);
  final snapshot = ref.watch(realmEditorCatalogProvider).value?.snapshot;
  final cache = ref.watch(realmEditorCatalogCacheProvider);
  if (organizationId == null ||
      realmId == null ||
      snapshot == null ||
      cache == null) {
    return null;
  }
  final registry = TypeRegistry(
    bootstrapTypeCatalog(snapshot.catalog.definitions),
  );

  final commandTransport = NatsRealmCapabilityTransport(
    ref: ref,
    organizationId: organizationId,
    realmId: realmId,
    generation: snapshot.generation,
    registry: registry,
    reload: cache.refresh,
  );
  final searchTransport = NatsRealmPresentationSearchTransport(
    ref: ref,
    organizationId: organizationId,
    realmId: realmId,
    registry: registry,
  );
  return EditorRealmRuntime(
    executeAction: (action, context) => _executeRealmAction(
      action: action,
      context: context,
      snapshot: snapshot,
      registry: registry,
      transport: commandTransport,
    ),
    searchSourceBuilder:
        ({
          required provider,
          required queryBindingId,
          required expressions,
          required registry,
          required budget,
          required providerKey,
        }) {
          final definition = snapshot.capabilities[provider.capabilityId];
          if (definition is! SearchCapabilityDefinition) {
            return UnavailableRealmPresentationSearchSource(provider: provider);
          }
          return RealmPresentationSearchSource(
            provider: provider,
            generation: snapshot.generation,
            payloadType: NamedType(definition.requestType),
            resultType: NamedType(definition.resultType),
            transport: searchTransport.watch,
            queryBindingId: queryBindingId,
            expressions: expressions,
            registry: registry,
            budget: budget,
            providerKey: providerKey,
          );
        },
  );
});

/// Evaluates and validates a command before crossing into realm transport.
/// Reload bypasses payload validation because it is a local control action.
Future<RealmCommandResult> _executeRealmAction({
  required RealmAction action,
  required ExpressionContext context,
  required RealmEditorCatalogSnapshot snapshot,
  required TypeRegistry registry,
  required NatsRealmCapabilityTransport transport,
}) async {
  if (action is ReloadRealmAction) {
    return transport.execute(action, null);
  }
  final command = action as InvokeRealmCommandAction;
  final definition = snapshot.capabilities[command.capabilityId];
  if (definition is! CommandCapabilityDefinition) {
    return RealmCommandResult.unavailable([
      const TypeDiagnostic(
        code: TypeDiagnosticCode.invalidPresentation,
        message: "Realm command capability is unknown",
      ),
    ]);
  }
  final payload = command.payload.evaluate(context, registry: registry);
  if (payload case TypeFailure(:final diagnostics)) {
    return RealmCommandResult.invalid(diagnostics);
  }

  final diagnostics = payload.valueOrNull!.validateAgainst(
    NamedType(definition.requestType),
    registry: registry,
  );
  if (diagnostics.isNotEmpty) {
    return RealmCommandResult.invalid(diagnostics);
  }
  return transport.execute(action, payload.valueOrNull);
}

/// Returns page definitions from the latest complete realm catalog.
@riverpod
AsyncValue<List<RealmPageDefinition>> realmPageDefinitions(Ref ref) => ref
    .watch(realmEditorCatalogProvider)
    .whenData(
      (state) =>
          state.snapshot?.pageCatalog.definitions.values.toList(
            growable: false,
          ) ??
          const [],
    );

/// Returns discovered definitions that the realm permits and exposes while
/// preserving catalog loading and failure states for asynchronous consumers.
@riverpod
Future<List<ElementDefinition>> availableElementDefinitionsFuture(
  Ref ref,
) async {
  final state = await ref.watch(realmEditorCatalogProvider.future);
  final snapshot = state.snapshot;
  if (snapshot == null) return const [];
  return snapshot.elements.values
      .where((entry) => entry.eligible && entry.available)
      .map((entry) => entry.definition.toElementDefinition())
      .toList(growable: false);
}

/// Returns the latest available element definitions for synchronous consumers.
@riverpod
List<ElementDefinition> availableElementDefinitions(Ref ref) {
  return ref.watch(availableElementDefinitionsFutureProvider).value ?? const [];
}

/// Resolves an element and verifies its presentation dependencies before use.
extension RealmEditorCatalogElementResolution
    on AsyncValue<RealmEditorCatalogState> {
  AsyncValue<T> resolveElement<T>(
    ElementDefinition definition,
    T Function(TypeCatalog catalog, List<PresentationDefinition> presentations)
    create,
  ) {
    if (mapUnready<T>() case final value?) {
      return value;
    }
    final state = requireValue;
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
    final availablePresentationIds = {
      ...builtinPresentationDefinitions().map((definition) => definition.id),
      ...snapshot.presentations.keys,
    };

    final missingPresentationIds = {
      for (final type in catalog.definitions)
        ...[
          ?type.defaultPresentationId,
          ...type.namedPresentations.values,
        ].where((id) => !availablePresentationIds.contains(id)),
    };
    if (missingPresentationIds.isNotEmpty) {
      final missingPresentationNames =
          missingPresentationIds
              .map((id) => "${id.namespace}/${id.name}")
              .toList()
            ..sort();
      return AsyncValue.error(
        ElementDefinitionException([
          TypeDiagnostic(
            code: TypeDiagnosticCode.invalidPresentation,
            message:
                "Realm catalog omitted required presentations: "
                "${missingPresentationNames.join(", ")}",
            pathPresent: false,
          ),
        ]),
        StackTrace.current,
      );
    }
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
    return AsyncValue.data(
      create(catalog, snapshot.presentations.values.toList()),
    );
  }
}
