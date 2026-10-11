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
Future<skir.EditorCatalogWireSnapshot> realmCatalogTransfer(
  Ref ref,
  skir.RecordId organizationId,
  skir.RecordId realmId,
  String fetchId,
) => NatsRealmEditorCatalogSource(ref).fetch(organizationId, realmId);

final class NatsRealmEditorCatalogSource {
  const NatsRealmEditorCatalogSource(this.ref);

  final Ref ref;

  Future<skir.EditorCatalogWireSnapshot> fetch(
    skir.RecordId organizationId,
    skir.RecordId realmId, {
    skir.CatalogGeneration? expectedGeneration,
  }) async {
    final transferId = uuid.v4();
    final request = skir.CatalogFetchRequest(
      expectedGeneration: expectedGeneration,
      transferId: transferId,
    );
    final assembler = CatalogTransferAssembler();
    final disposed = Completer<void>();
    ref.onDispose(() {
      if (!disposed.isCompleted) disposed.complete();
    });
    final transport = SkirMutationClient(
      () => ref.read(natsProvider),
      () => ref.read(panelTelemetryProvider.future),
    );
    final responses = request.watch(
      transport,
      organizationId: organizationId,
      realmId: realmId,
    );
    return assembler.assemble(
      responses.map(
        (response) => switch (response) {
          skir.CatalogFetchResult_chunkWrapper(:final value) => value,
          skir.CatalogFetchResult_generationChangedWrapper(:final value) =>
            throw CatalogGenerationChanged(value),
          skir.CatalogFetchResult_unavailableWrapper(:final value) =>
            throw CatalogTransferUnavailable(value),
          _ => throw ApiException.internalServerError(),
        },
      ),
      cancelled: disposed.future,
    );
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
  ) async {
    final response = await ref.requestSkir(
      request.operation(organizationId: organizationId, realmId: realmId),
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

final class CatalogTransferUnavailable implements Exception {
  const CatalogTransferUnavailable(this.value);

  final skir.CatalogUnavailable value;

  @override
  String toString() =>
      "The editor catalog is ${value.encodedSize} bytes, above the ${value.maxEncodedSize} byte transfer limit";
}
