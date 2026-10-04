import "dart:async";
import "dart:typed_data";

import "package:crypto/crypto.dart";
import "package:flutter_test/flutter_test.dart";
import "package:skir_client/skir_client.dart" show ByteString;
import "package:typewriter_panel/features/organizations/features/realms/application/catalog_transfer_assembler.dart";
import "package:typewriter_panel/infrastructure/messaging/bounded_transfer_assembler.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;

void main() {
  test("adopts a complete transfer only after every validated chunk", () {
    final fixture = _TransferFixture(_snapshot("catalog:2"), chunkCount: 3);
    final assembler = CatalogTransferAssembler();

    expect(assembler.accept(fixture.chunk(0)), isA<CatalogTransferPending>());
    expect(assembler.accept(fixture.chunk(2)), isA<CatalogTransferPending>());
    final completed = assembler.accept(fixture.chunk(1));

    expect(completed, isA<CatalogTransferComplete>());
    expect((completed as CatalogTransferComplete).snapshot, fixture.snapshot);
  });

  test("rejects chunks belonging to another scoped transfer", () {
    final fixture = _TransferFixture(_snapshot("catalog:2"), chunkCount: 2);
    final assembler = CatalogTransferAssembler()..accept(fixture.chunk(0));

    expect(
      () => assembler.accept(
        skir.CatalogTransferChunk(
          generation: fixture.generation,
          transfer: skir.BoundedTransferChunk(
            transferId: "another transfer",
            index: 1,
            chunkCount: 2,
            encodedSize: fixture.encoded.length,
            sha256: fixture.digest,
            payload: ByteString.copy([1]),
          ),
        ),
      ),
      throwsA(isA<CatalogTransferRejected>()),
    );
  });

  test("rejects duplicate indexes and changed shared metadata", () {
    final fixture = _TransferFixture(_snapshot("catalog:2"), chunkCount: 2);
    final duplicates = CatalogTransferAssembler()..accept(fixture.chunk(0));

    expect(
      () => duplicates.accept(fixture.chunk(0)),
      throwsA(isA<CatalogTransferRejected>()),
    );

    final changed = CatalogTransferAssembler()..accept(fixture.chunk(0));
    expect(
      () => changed.accept(
        fixture.chunk(1, sha256Value: List.filled(64, "0").join()),
      ),
      throwsA(isA<CatalogTransferRejected>()),
    );
  });

  test("rejects corrupted bytes from the transfer stream", () async {
    final fixture = _TransferFixture(_snapshot("catalog:2"), chunkCount: 2);
    final last = fixture.chunk(1);
    final corrupted = Uint8List.fromList(
      last.transfer.payload.asUnmodifiableList,
    );
    corrupted[0] ^= 1;

    await expectLater(
      CatalogTransferAssembler().assemble(
        Stream.fromIterable([
          fixture.chunk(0),
          fixture.chunk(1, payload: corrupted),
        ]),
      ),
      throwsA(
        isA<CatalogTransferRejected>().having(
          (error) => error.message,
          "message",
          contains("digest"),
        ),
      ),
    );
  });

  test("retains the active catalog when the final chunk never arrives", () async {
    final active = _snapshot("catalog:1");
    final fixture = _TransferFixture(_snapshot("catalog:2"), chunkCount: 2);
    final chunks = StreamController<skir.CatalogTransferChunk>();
    var adopted = active;
    chunks.add(fixture.chunk(0));

    try {
      adopted = await CatalogTransferAssembler().assemble(
        chunks.stream,
        timeout: const Duration(milliseconds: 10),
      );
    } on TimeoutException {
      // The active catalog remains unchanged until a complete transfer exists.
    }
    await chunks.close();

    expect(adopted, same(active));
  });

  test("cancellation releases an incomplete catalog transfer", () async {
    final fixture = _TransferFixture(_snapshot("catalog:2"), chunkCount: 2);
    final chunks = StreamController<skir.CatalogTransferChunk>();
    final cancelled = Completer<void>();
    var sourceCancelled = false;
    chunks.onCancel = () => sourceCancelled = true;
    final assembly = CatalogTransferAssembler().assemble(
      chunks.stream,
      cancelled: cancelled.future,
    );

    chunks.add(fixture.chunk(0));
    cancelled.complete();

    await expectLater(assembly, throwsA(isA<BoundedTransferCancelled>()));
    expect(sourceCancelled, isTrue);
    await chunks.close();
  });

  test(
    "assembles a multi megabyte generated catalog through the stream",
    () async {
      final snapshot = _largeSnapshot();
      final fixture = _TransferFixture(snapshot, chunkCount: 12);
      expect(fixture.encoded.length, greaterThan(4 * 1024 * 1024));

      final decoded = await CatalogTransferAssembler().assemble(
        Stream.fromIterable([
          fixture.chunk(0),
          for (var index = fixture.chunkCount - 1; index > 0; index--)
            fixture.chunk(index),
        ]),
      );

      expect(decoded.generation, snapshot.generation);
      expect(decoded.types.length, snapshot.types.length);
    },
  );

  test("bounds advertised and cumulative transfer sizes", () {
    final fixture = _TransferFixture(_snapshot("catalog:2"), chunkCount: 1);
    final chunk = fixture.chunk(0);
    final oversizedCount = skir.CatalogTransferChunk(
      generation: chunk.generation,
      transfer: skir.BoundedTransferChunk(
        transferId: chunk.transfer.transferId,
        index: 0,
        chunkCount: maximumCatalogTransferChunks + 1,
        encodedSize: chunk.transfer.encodedSize,
        sha256: chunk.transfer.sha256,
        payload: chunk.transfer.payload,
      ),
    );

    expect(
      () => CatalogTransferAssembler().accept(oversizedCount),
      throwsA(isA<CatalogTransferRejected>()),
    );

    final underreported = skir.CatalogTransferChunk(
      generation: chunk.generation,
      transfer: skir.BoundedTransferChunk(
        transferId: chunk.transfer.transferId,
        index: 0,
        chunkCount: 1,
        encodedSize: chunk.transfer.payload.length - 1,
        sha256: chunk.transfer.sha256,
        payload: chunk.transfer.payload,
      ),
    );
    expect(
      () => CatalogTransferAssembler().accept(underreported),
      throwsA(isA<CatalogTransferRejected>()),
    );
  });

  test("rejects a payload whose generation differs from transfer metadata", () {
    final fixture = _TransferFixture(
      _snapshot("catalog:2"),
      chunkCount: 1,
      transferGeneration: skir.CatalogGeneration(value: "catalog:3"),
    );

    expect(
      () => CatalogTransferAssembler().accept(fixture.chunk(0)),
      throwsA(
        isA<CatalogTransferRejected>().having(
          (error) => error.message,
          "message",
          contains("generation"),
        ),
      ),
    );
  });
}

skir.EditorCatalogWireSnapshot _snapshot(String generation) =>
    skir.EditorCatalogWireSnapshot(
      generation: skir.CatalogGeneration(value: generation),
      types: const [],
      relations: const [],
      resourceDefinitions: const [],
      presentations: const [],
      presentationMaterials: const [],
      configuration: const [],
      diagnostics: const [],
      initialization: const [],
      endpointBindings: const [],
      capabilities: const [],
      recommendations: const [],
      roleFallbacks: const [],
    );

skir.EditorCatalogWireSnapshot _largeSnapshot() {
  final types = [
    for (var typeIndex = 0; typeIndex < 5000; typeIndex++)
      _publishedType(typeIndex),
  ];
  return skir.EditorCatalogWireSnapshot(
    generation: skir.CatalogGeneration(value: "catalog:large"),
    types: types,
    relations: const [],
    resourceDefinitions: const [],
    presentations: const [],
    presentationMaterials: const [],
    configuration: const [],
    diagnostics: const [],
    initialization: const [],
    endpointBindings: const [],
    capabilities: const [],
    recommendations: const [],
    roleFallbacks: const [],
  );
}

skir.PublishedType _publishedType(int typeIndex) {
  final definition = skir.TypeDefinitionId(
    typeId: skir.TypeId.createQualified(
      namespace: "test.scale",
      name: "GeneratedType$typeIndex",
    ),
    revision: 1,
  );
  final fields = [
    for (var fieldIndex = 0; fieldIndex < 8; fieldIndex++)
      skir.FieldOwner(
        definition: definition,
        name: "generatedField$fieldIndex",
      ),
  ];
  return skir.PublishedType(
    display: null,
    definition: skir.TypeDefinition(
      id: definition,
      parameters: const [],
      representation: skir.RepresentationTemplate.createRecord(
        fields: [
          for (final field in fields)
            skir.FieldDeclaration(
              owner: field,
              type: skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
              overrides: const [],
              hasConstructorDefault: false,
            ),
        ],
        abstract_: false,
      ),
      parents: const [],
    ),
    status: skir.DeclarationStatus.ready,
    effectiveFields: [
      for (final field in fields)
        skir.EffectiveFieldTemplate(
          key: field.name,
          owner: field,
          type: skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
          rules: const [],
        ),
    ],
    ancestorTemplates: const [],
  );
}

final class _TransferFixture {
  _TransferFixture(
    this.snapshot, {
    required this.chunkCount,
    skir.CatalogGeneration? transferGeneration,
  }) : encoded = skir.EditorCatalogWireSnapshot.serializer.toBytes(snapshot),
       generation = transferGeneration ?? snapshot.generation {
    digest = sha256.convert(encoded).toString();
  }

  final skir.EditorCatalogWireSnapshot snapshot;
  final int chunkCount;
  final Uint8List encoded;
  final skir.CatalogGeneration generation;
  late final String digest;

  skir.CatalogTransferChunk chunk(
    int index, {
    String transferId = "transfer",
    String? sha256Value,
    Uint8List? payload,
  }) {
    final start = encoded.length * index ~/ chunkCount;
    final end = encoded.length * (index + 1) ~/ chunkCount;
    return skir.CatalogTransferChunk(
      generation: generation,
      transfer: skir.BoundedTransferChunk(
        transferId: transferId,
        index: index,
        chunkCount: chunkCount,
        encodedSize: encoded.length,
        sha256: sha256Value ?? digest,
        payload: ByteString.copy(payload ?? encoded.sublist(start, end)),
      ),
    );
  }
}
