// Providers bind the selected organization and realm to one catalog cache. The
// cache exists only while the realm connection gate is online. Commands and
// searches built from the active snapshot share its catalog generation.
import "dart:async";

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

/// Owns the catalog cache while the selected realm is online. Connection
/// resolution remains pending instead of publishing a disconnected cache.
@riverpod
Future<RealmEditorCatalogCache?> realmEditorCatalogCache(Ref ref) async {
  final organizationId = ref.watch(organizationIdProvider);
  final realmId = ref.watch(realmIdProvider);
  if (organizationId == null || realmId == null) {
    return null;
  }
  final connection = await ref.watch(realmConnectionProvider.future);
  if (!ref.mounted) return null;
  if (connection != RealmConnectionState.online) return null;
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

/// A request owns its cache lease and publishes only snapshots fetched with
/// enough coverage. Cache loading remains Riverpod loading; cache failure is a
/// typed Riverpod error and can recover on a later cache update.
@riverpod
class RealmCatalog extends _$RealmCatalog {
  @override
  Future<RealmEditorCatalogSnapshot> build(
    RealmEditorCatalogRequest request,
  ) async {
    final cache = await ref.watch(realmEditorCatalogCacheProvider.future);
    if (!ref.mounted) throw StateError("Catalog read was disposed");
    if (cache == null) {
      throw RealmCatalogUnavailableException([
        realmEditorCatalogUnavailableDiagnostic(
          "Select a connected realm to load the editor catalog",
        ),
      ]);
    }
    final first = Completer<RealmEditorCatalogSnapshot>();
    void fail(Object error, StackTrace stackTrace) {
      if (!first.isCompleted) {
        first.completeError(error, stackTrace);
      } else if (ref.mounted) {
        state = AsyncError(error, stackTrace);
      }
    }

    final lease = cache.acquire(request);
    final subscription = cache.states.listen((event) {
      if (!ref.mounted) return;
      switch (event) {
        case RealmEditorCatalogLoading():
          if (first.isCompleted) state = const AsyncLoading();
        case RealmEditorCatalogReady(:final value):
          if (!cache.covers(value, request)) return;
          if (!first.isCompleted) {
            first.complete(value);
          } else {
            state = AsyncData(value);
          }
        case RealmEditorCatalogUnavailable(:final diagnostics):
          fail(
            RealmCatalogUnavailableException(diagnostics),
            StackTrace.current,
          );
      }
    }, onError: fail);
    ref.onDispose(() {
      unawaited(subscription.cancel());
      lease.close();
    });
    return first.future;
  }
}

/// The full catalog read uses the same readiness contract as scoped reads.
@riverpod
Future<RealmEditorCatalogSnapshot> realmEditorCatalog(Ref ref) =>
    ref.watch(realmCatalogProvider(const RealmEditorCatalogRequest()).future);

@riverpod
Future<RealmEditorCatalogSnapshot> realmEditorCatalogForType(
  Ref ref,
  ResolvedTypeRef rootType,
) => ref.watch(
  realmCatalogProvider(RealmEditorCatalogRequest(types: {rootType})).future,
);

final class RealmCatalogUnavailableException implements Exception {
  const RealmCatalogUnavailableException(this.diagnostics);
  final List<TypeDiagnostic> diagnostics;

  @override
  String toString() => diagnostics.map((item) => item.message).join("; ");
}

/// Commands must not use Riverpod's retained value while a catalog refresh or
/// failure is in progress. Views may still render that prior value read only.
extension CurrentRealmCatalog on AsyncValue<RealmEditorCatalogSnapshot> {
  RealmEditorCatalogSnapshot? get currentCatalog =>
      isLoading || hasError ? null : value;

  RealmEditorCatalogSnapshot requireCurrentCatalog() {
    ensureReady();
    return requireValue;
  }
}

typedef AuthoringReadView = ({
  RealmEditorCatalogSnapshot catalog,
  AuthoringSessionState session,
});

/// Acquires catalog demand and graph selections as one authoring read. The
/// returned view is sequenced and uses the catalog's exact generation; a
/// pending graph or catalog is never interpreted as an empty collection.
extension AuthoringRead on Ref {
  Future<AuthoringReadView> readAuthoringView({
    required skir.RecordId organizationId,
    required skir.RecordId realmId,
    required RealmEditorCatalogRequest request,
    required Iterable<skir.GraphSelection> Function(
      RealmEditorCatalogSnapshot catalog,
    )
    selections,
  }) async {
    final catalog = await watch(realmCatalogProvider(request).future);
    final leases = [
      for (final selection in selections(catalog))
        watch(
          authoringSelectionLeaseProvider(organizationId, realmId, selection),
        ),
    ];
    await Future.wait(leases.map((lease) => lease.ready));
    final session =
        await streamed(authoringSessionProvider(organizationId, realmId))
            .firstWhere(
              (value) =>
                  value.sequence != null &&
                  value.generation?.value == catalog.generation.value,
            );
    return (catalog: catalog, session: session);
  }
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
  final catalogState = ref.watch(realmEditorCatalogProvider);
  final snapshot = catalogState.currentCatalog;
  final cacheState = ref.watch(realmEditorCatalogCacheProvider);
  final cache = cacheState.isLoading ? null : cacheState.value;
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
AsyncValue<List<RealmTypeEntry>> realmPageDefinitions(Ref ref) {
  final catalog = ref.watch(realmEditorCatalogProvider);
  if (catalog.isLoading) return const AsyncLoading();
  if (catalog.mapUnready<List<RealmTypeEntry>>() case final pending?) {
    return pending;
  }
  return AsyncData(
    catalog.requireValue.types.values
        .where(
          (entry) =>
              entry.editor != null &&
              entry.eligible &&
              catalog.requireValue.resourceDefinitionFor(entry.type)?.id ==
                  CoreResourceDefinitionIds.page,
        )
        .toList(growable: false),
  );
}

/// Returns discovered definitions that the realm permits and exposes while
/// preserving catalog loading and failure states for asynchronous consumers.
@riverpod
Future<List<ElementDefinition>> availableElementDefinitionsFuture(
  Ref ref,
) async {
  final snapshot = await ref.watch(realmEditorCatalogProvider.future);
  return snapshot.types.values
      .where(
        (entry) =>
            entry.eligible &&
            {
              CoreResourceDefinitionIds.element,
              CoreResourceDefinitionIds.cue,
            }.contains(snapshot.resourceDefinitionFor(entry.type)?.id),
      )
      .map((entry) => entry.toElementDefinition())
      .toList(growable: false);
}

/// Resolves an element and verifies its presentation dependencies before use.
extension RealmEditorCatalogElementResolution
    on AsyncValue<RealmEditorCatalogSnapshot> {
  AsyncValue<T> resolveElement<T>(
    ElementDefinition definition,
    T Function(TypeCatalog catalog, List<PresentationDefinition> presentations)
    create,
  ) {
    if (isLoading) return const AsyncValue.loading();
    if (mapUnready<T>() case final value?) {
      return value;
    }
    final snapshot = requireValue;
    final catalog = snapshot.catalog;
    final resolved = definition.resolve(TypeRegistry(catalog));
    if (resolved.valueOrNull == null) {
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
