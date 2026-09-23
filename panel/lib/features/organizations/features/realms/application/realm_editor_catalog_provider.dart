// Providers bind the selected organization and realm to one catalog cache. The
// cache exists only while the realm connection gate is online. Commands and
// searches built from the active snapshot share its catalog generation.
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
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
  final localWork = ref.watch(localWorkProvider);
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
  final registry = TypeRegistry(snapshot.catalog);

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
    actions: RealmActionCapabilities(
      execute: (action, context) => _executeRealmAction(
        action: action,
        context: context,
        snapshot: snapshot,
        registry: registry,
        transport: commandTransport,
      ),
    ),
    presentationSearch: RealmPresentationSearchCapabilities(
      source:
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
              return UnavailableRealmPresentationSearchSource(
                provider: provider,
              );
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
    ),
    references: ReferenceAuthoringCapabilities(
      search: ({required target, required origins, required registry}) =>
          RealmAuthoringSearchSource(
            ref: ref,
            organizationId: organizationId,
            realmId: realmId,
            referenceTarget: target,
            referenceOrigins: origins,
            typeRegistry: registry,
          ),
      resolve: ({required target, required ids, required registry}) =>
          resolveAuthoringReferences(
            ref: ref,
            organizationId: organizationId,
            realmId: realmId,
            target: target,
            ids: ids,
            registry: registry,
          ),
      eligibility: ReferenceEligibilityEvaluator(
        version: (snapshot.generation, localWork),
        evaluate: (evaluation) => _checkReferenceEligibility(
          ref: ref,
          organizationId: organizationId,
          realmId: realmId,
          evaluation: evaluation,
        ),
      ),
      policies: ReferenceCandidatePolicyRegistry(const {}),
    ),
  );
});

Future<ReferenceCandidateDecision> _checkReferenceEligibility({
  required Ref ref,
  required skir.RecordId organizationId,
  required skir.RecordId realmId,
  required ReferenceEligibilityEvaluation evaluation,
}) async {
  final targets = _eligibilityTargets(
    evaluation.context.owner,
    evaluation.context.path,
  ).toList();
  if (targets.isEmpty) {
    return const ReferenceCandidateDecision.unavailable(
      ReferencePolicyIssue(
        code: "reference.eligibility.owner_unavailable",
        message: "The edited resource is unavailable",
      ),
    );
  }
  final proposals = <skir.AuthoringOperation>[];
  CatalogGeneration? generation;
  final proposedIds = <skir.ResourceId>{};
  for (final target in targets) {
    final source = target.source;
    final snapshot = source.snapshot;
    final resource = source.resource;
    if (snapshot is! TypedAuthoringSnapshot ||
        resource is! AuthoringEditorResource) {
      return const ReferenceCandidateDecision.unavailable(
        ReferencePolicyIssue(
          code: "reference.eligibility.resource_unavailable",
          message: "The edited resource cannot be previewed",
        ),
      );
    }
    final typedSnapshot = snapshot! as TypedAuthoringSnapshot;
    if (!resource.repository.isScopedTo(organizationId, realmId)) {
      return const ReferenceCandidateDecision.unavailable(
        ReferencePolicyIssue(
          code: "reference.eligibility.realm_mismatch",
          message: "The edited resource belongs to another Realm",
        ),
      );
    }
    generation ??= typedSnapshot.codec.catalog.generation;
    if (generation != typedSnapshot.codec.catalog.generation) {
      return const ReferenceCandidateDecision.unavailable(
        ReferencePolicyIssue(
          code: "reference.eligibility.catalog_mismatch",
          message: "The edited resources use different catalogs",
        ),
      );
    }
    final mutation = evaluation.structuralMutation == null
        ? null
        : _mutationAt(evaluation.structuralMutation!, target.path);
    final commit = source.previewCommit(
      target.path,
      evaluation.proposedValue,
      structuralMutation: mutation,
    );
    proposals.add(typedSnapshot.encodePreviewCommit(commit));
    proposedIds.add(resource.id);
  }
  final drafts = <skir.AuthoringOperation>[];
  for (final editor in ref.read(localWorkControllerProvider).resources.values) {
    final source = editor.source;
    if (!source.hasWork || source.editedPaths.isEmpty) continue;
    final snapshot = source.snapshot;
    final resource = source.resource;
    if (snapshot is! TypedAuthoringSnapshot ||
        resource is! AuthoringEditorResource ||
        !resource.repository.isScopedTo(organizationId, realmId) ||
        proposedIds.contains(resource.id)) {
      continue;
    }
    final typedSnapshot = snapshot! as TypedAuthoringSnapshot;
    if (typedSnapshot.codec.catalog.generation != generation) {
      return const ReferenceCandidateDecision.unavailable(
        ReferencePolicyIssue(
          code: "reference.eligibility.draft_catalog_mismatch",
          message: "A related draft uses another editor catalog",
        ),
      );
    }
    drafts.add(
      typedSnapshot.encodePreviewCommit(
        source.captureCommit(source.editedPaths),
      ),
    );
  }
  final repository = ref
      .read(resourceRepositoriesProvider)
      .authoring(organizationId, realmId);
  final result = await repository.preview(
    generation: generation!,
    operations: [...drafts, ...proposals],
  );
  return switch (result) {
    skir.PreviewAuthoringBatchResponse_validWrapper() =>
      const ReferenceCandidateDecision.allowed(),
    skir.PreviewAuthoringBatchResponse_conflictWrapper(:final value) =>
      ReferenceCandidateDecision.rejected(
        ReferencePolicyIssue(
          code: "reference.conflict",
          message: value.conflicts.isEmpty
              ? "The reference conflicts with current authoring state"
              : "The reference conflicts at ${value.conflicts.first.path}",
        ),
      ),
    skir.PreviewAuthoringBatchResponse_invalidWrapper(:final value) =>
      ReferenceCandidateDecision.rejected(
        ReferencePolicyIssue(
          code: value.diagnostics.firstOrNull?.code ?? "reference.rejected",
          message:
              value.diagnostics.firstOrNull?.message ??
              "The reference is not eligible",
        ),
      ),
    skir.PreviewAuthoringBatchResponse_catalogChangedWrapper() =>
      const ReferenceCandidateDecision.unavailable(
        ReferencePolicyIssue(
          code: "reference.catalog_changed",
          message: "The editor catalog changed",
        ),
      ),
    skir.PreviewAuthoringBatchResponse_internalErrorWrapper() =>
      const ReferenceCandidateDecision.unavailable(
        ReferencePolicyIssue(
          code: "reference.preview_unavailable",
          message: "The Realm could not validate the reference",
        ),
      ),
    _ => const ReferenceCandidateDecision.unavailable(
      ReferencePolicyIssue(
        code: "reference.preview_unknown",
        message: "The Realm returned an unknown reference preview result",
      ),
    ),
  };
}

Iterable<({TransactionalEditorSource source, DataPath path})>
_eligibilityTargets(EditOwner? owner, DataPath path) sync* {
  if (owner == null) return;
  if (owner case ProjectedEditOwner(:final owner, path: final prefix)) {
    yield* _eligibilityTargets(owner, prefix.followedBy(path));
    return;
  }
  if (owner case MultiEditOwner(:final owners)) {
    for (final child in owners) {
      yield* _eligibilityTargets(child, path);
    }
    return;
  }
  if (owner case final TransactionalEditorSource source) {
    yield (source: source, path: path);
  }
}

EditorStructuralMutation _mutationAt(
  EditorStructuralMutation mutation,
  DataPath path,
) => switch (mutation) {
  EditorSetValue(:final value) => EditorSetValue(path, value),
  EditorInsertListItems(:final index, :final values) => EditorInsertListItems(
    path,
    index,
    values,
  ),
  EditorRemoveListItems(:final index, :final count) => EditorRemoveListItems(
    path,
    index,
    count,
  ),
  EditorReorderListItems(
    :final sourceIndex,
    :final count,
    :final destinationIndex,
  ) =>
    EditorReorderListItems(path, sourceIndex, count, destinationIndex),
  EditorDuplicateListItems(
    :final sourceIndex,
    :final count,
    :final destinationIndex,
  ) =>
    EditorDuplicateListItems(path, sourceIndex, count, destinationIndex),
  EditorPutMapEntries(:final entries) => EditorPutMapEntries(path, entries),
  EditorRemoveMapEntries(:final keys) => EditorRemoveMapEntries(path, keys),
  EditorReplaceConcreteType(:final concreteType, :final value) =>
    EditorReplaceConcreteType(path, concreteType, value),
};

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
    final catalog = snapshot.catalog;
    final availablePresentationIds = {...snapshot.presentations.keys};

    final missingPresentationIds = {
      for (final type in catalog.definitions)
        ...[
          ?type.defaultPresentationId,
          ...type.namedPresentations.values,
          ...type.rolePresentations.values,
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
