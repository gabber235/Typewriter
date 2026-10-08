import "dart:typed_data";

import "package:crypto/crypto.dart";
import "package:flutter_test/flutter_test.dart";
import "package:skir_client/skir_client.dart" show ByteString;
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("current state chunks assemble without revision metadata", () async {
    final state = _state();
    final chunks = _chunks(state);
    final received = await AuthoringStateTransferAssembler().assemble(
      Stream.fromIterable(chunks),
    );
    expect(received, state);
  });
  test("chunks from different catalogs are rejected", () async {
    final chunks = _chunks(_state());
    final replacement = skir.AuthoringStateTransferChunk(
      generation: skir.CatalogGeneration(value: "other"),
      transfer: chunks.last.transfer,
    );
    await expectLater(
      AuthoringStateTransferAssembler().assemble(
        Stream.fromIterable([chunks.first, replacement]),
      ),
      throwsA(isA<BoundedTransferRejected>()),
    );
  });
  test("decoded catalog must match the transfer metadata", () async {
    final chunks = _chunks(
      _state(),
      generation: skir.CatalogGeneration(value: "other"),
    );
    await expectLater(
      AuthoringStateTransferAssembler().assemble(Stream.fromIterable(chunks)),
      throwsA(isA<BoundedTransferRejected>()),
    );
  });
  test("missing chunks do not expose partial current state", () async {
    await expectLater(
      AuthoringStateTransferAssembler().assemble(
        Stream.fromIterable(_chunks(_state()).take(1)),
      ),
      throwsA(isA<BoundedTransferRejected>()),
    );
  });
}

skir.AuthoringState _state() => skir.AuthoringState(
  generation: skir.CatalogGeneration(value: "catalog"),
  resources: [
    skir.AuthoringResource(
      id: skir.ResourceId(value: "book"),
      definition: skir.ResourceDefinitionId(value: "book"),
      content: skir.AuthoringRecord(
        configuration: skir.TypeSelection.unknown,
        fields: [
          skir.FieldValue(
            name: "title",
            value: skir.DataValue.wrapStringValue("Quest"),
          ),
        ],
      ),
    ),
  ],
  links: const [],
  findings: const [],
);
List<skir.AuthoringStateTransferChunk> _chunks(
  skir.AuthoringState state, {
  skir.CatalogGeneration? generation,
}) {
  final bytes = skir.AuthoringState.serializer.toBytes(state);
  final split = bytes.length ~/ 2;
  return [
    for (var index = 0; index < 2; index++)
      skir.AuthoringStateTransferChunk(
        generation: generation ?? state.generation,
        transfer: skir.BoundedTransferChunk(
          transferId: "current",
          index: index,
          chunkCount: 2,
          encodedSize: bytes.length,
          sha256: sha256.convert(bytes).toString(),
          payload: ByteString.copy(
            Uint8List.sublistView(
              bytes,
              index == 0 ? 0 : split,
              index == 0 ? split : bytes.length,
            ),
          ),
        ),
      ),
  ];
}
