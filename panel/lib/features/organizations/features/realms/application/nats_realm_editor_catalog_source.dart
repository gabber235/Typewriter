import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "nats_realm_editor_catalog_source.g.dart";

@riverpod
Stream<skir.CatalogInvalidated> realmCatalogInvalidations(
  Ref ref,
  skir.RecordId organizationId,
  skir.RecordId realmId,
) =>
    NatsRealmEditorCatalogSource(ref)
        .watchInvalidations(organizationId, realmId);

@riverpod
Future<skir.EditorCatalog> realmCatalogTransfer(
  Ref ref,
  skir.RecordId organizationId,
  skir.RecordId realmId,
  String fetchId,
) => NatsRealmEditorCatalogSource(ref).fetch(organizationId, realmId);

/// Fetches catalogs and delegates value preparation through current Realm routes.
///
/// Each fetch is cancelled with its provider. The source stores no catalog
/// cache. [prepareStep] preserves resumable preparation outcomes;
/// [prepareValue] also exposes partial content for callers that handle unfinished
/// values directly and therefore does not imply initialization reached ready.
final class NatsRealmEditorCatalogSource {
  const NatsRealmEditorCatalogSource(this.ref);

  final Ref ref;

  Future<skir.EditorCatalog> fetch(
    skir.RecordId organizationId,
    skir.RecordId realmId, {
    skir.CatalogGeneration? expectedGeneration,
  }) async {
    final disposed = Completer<void>();
    ref.onDispose(() {
      if (!disposed.isCompleted) disposed.complete();
    });
    final transport = SkirMutationClient(
      () => ref.read(natsProvider),
      () => ref.read(panelTelemetryProvider.future),
    );
    final operation = skir.CatalogFetchRequest(
      expectedGeneration: expectedGeneration,
    ).operation(organizationId: organizationId, realmId: realmId);
    final response = await transport.request(
      operation.subject,
      operation.requestBytes,
      operation.responseSerializer,
      cancelled: disposed.future,
    );
    return switch (response) {
      skir.CatalogFetchResult_catalogWrapper(:final value) => value,
      skir.CatalogFetchResult_generationChangedErrorWrapper(:final value) =>
        throw CatalogGenerationChanged(value),
      _ => throw ApiException.internalServerError(),
    };
  }

  Stream<skir.CatalogInvalidated> watchInvalidations(
    skir.RecordId organizationId,
    skir.RecordId realmId,
  ) => skir.WatchEditorCatalogRequest().watch(
    ref,
    organizationId: organizationId,
    realmId: realmId,
    snapshot: (response) => response,
    reduce: (_, event) => event,
    reconciliation: const ProjectionReconciliation.latest(),
  );

  Future<skir.PreparedValue> prepareValue(
    skir.RecordId organizationId,
    skir.RecordId realmId,
    skir.ValuePreparationRequest request,
  ) async => switch (await prepareStep(
    organizationId,
    realmId,
    skir.PreparationOperation.wrapStart(request),
  )) {
    skir.PreparationStep_readyWrapper(:final value) => value,
    skir.PreparationStep_needsInputWrapper(:final value) => skir.PreparedValue(
      content: value.content,
      findings: value.findings,
    ),
    skir.PreparationStep_unavailableWrapper(:final value) => skir.PreparedValue(
      content: value.content,
      findings: value.findings,
    ),
    skir.PreparationStep_unknown() => throw ApiException.internalServerError(),
  };

  Future<skir.PreparationStep> prepareStep(
    skir.RecordId organizationId,
    skir.RecordId realmId,
    skir.PreparationOperation operation,
  ) async {
    final response = await ref.requestSkir(
      operation.operation(organizationId: organizationId, realmId: realmId),
    );
    return switch (response) {
      skir.PrepareValueResult_preparedWrapper(:final value) => value,
      skir.PrepareValueResult_catalogChangedWrapper(:final value) =>
        throw CatalogGenerationChanged(value),
      _ => throw ApiException.internalServerError(),
    };
  }
}

final class CatalogGenerationChanged implements Exception {
  const CatalogGenerationChanged(this.actual);

  final skir.CatalogGeneration actual;
}
