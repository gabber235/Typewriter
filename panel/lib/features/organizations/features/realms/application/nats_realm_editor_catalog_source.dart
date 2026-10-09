import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

final class NatsRealmEditorCatalogSource {
  const NatsRealmEditorCatalogSource(this.ref);

  final Ref ref;

  Future<skir.EditorCatalogWireSnapshot> fetch(
    RealmEditorCatalogRoute route, {
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
    final responses = ref
        .watchProjection<
          skir.CatalogFetchResult,
          skir.CatalogFetchResult,
          skir.CatalogFetchResult
        >(
          subject: route.fetchSubject,
          eventSubject: route.fetchUpdateSubject(transferId),
          requestBytes: skir.CatalogFetchRequest.serializer.toBytes(request),
          responseSerializer: skir.CatalogFetchResult.serializer,
          eventSerializer: skir.CatalogFetchResult.serializer,
          snapshot: (response) => response,
          reduce: (_, event) => event,
          delivery: const ProjectionDelivery.ephemeral(),
          reconciliation: const ProjectionReconciliation.latest(),
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
    RealmEditorCatalogRoute route,
  ) => ref.watchProjection(
    subject: route.invalidationRequestSubject,
    eventSubject: route.invalidationSubject,
    requestBytes: skir.WatchEditorCatalogRequest.serializer.toBytes(
      skir.WatchEditorCatalogRequest(),
    ),
    responseSerializer: skir.CatalogInvalidated.serializer,
    eventSerializer: skir.CatalogInvalidated.serializer,
    snapshot: (response) => response,
    reduce: (_, event) => event,
    delivery: const ProjectionDelivery.ephemeral(),
    reconciliation: const ProjectionReconciliation.latest(),
  );

  Future<skir.PreparedValue> prepareValue(
    RealmEditorCatalogRoute route,
    skir.ValuePreparationRequest request,
  ) async {
    final response = await ref.requestSkir(
      route.address.request("editor.creation.prepare"),
      skir.ValuePreparationRequest.serializer.toBytes(request),
      skir.PrepareValueResult.serializer,
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
