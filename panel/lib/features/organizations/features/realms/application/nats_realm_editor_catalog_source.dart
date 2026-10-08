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
        .watchRequest<skir.CatalogFetchResult, skir.CatalogFetchResult>(
          subject: route.fetchSubject,
          listenSubject: route.fetchUpdateSubject(transferId),
          requestBytes: skir.CatalogFetchRequest.serializer.toBytes(request),
          serializer: skir.CatalogFetchResult.serializer,
          transformer: (_, response) => response,
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
  ) => ref.watchRequest(
    subject: route.invalidationRequestSubject,
    listenSubject: route.invalidationSubject,
    requestBytes: skir.WatchEditorCatalogRequest.serializer.toBytes(
      skir.WatchEditorCatalogRequest(),
    ),
    serializer: skir.CatalogInvalidated.serializer,
    transformer: (_, response) => response,
  );

  Future<skir.PreparedCreation> prepareCreation(
    RealmEditorCatalogRoute route,
    skir.InitializationRequest request,
  ) async {
    final response = await ref.requestSkir(
      route.address.request("editor.creation.prepare"),
      skir.InitializationRequest.serializer.toBytes(request),
      skir.PrepareCreationResult.serializer,
    );
    return switch (response) {
      skir.PrepareCreationResult_preparedWrapper(:final value) => value,
      skir.PrepareCreationResult_catalogChangedWrapper(:final value) =>
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
