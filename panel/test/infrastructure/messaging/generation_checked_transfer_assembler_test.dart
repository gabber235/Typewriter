import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("adopts the generation of the first chunk", () async {
    final value = await _assembler().assemble(
      Stream.fromIterable(_chunks("g1:payload")),
    );

    expect(value, "g1:payload");
  });

  test("rejects chunks from another generation", () async {
    final chunks = _chunks("g1:payload");
    await expectLater(
      _assembler().assemble(
        Stream.fromIterable([chunks.first, chunks.last.withGeneration("g2")]),
      ),
      throwsA(
        isA<BoundedTransferRejected>().having(
          (error) => error.message,
          "message",
          "The value generation changed between chunks",
        ),
      ),
    );
  });

  test("rejects a first chunk that differs from the expected generation", () {
    expect(
      () =>
          _assembler(expectedGeneration: "g2")
              .accept(_chunks("g1:payload").first),
      throwsA(isA<BoundedTransferRejected>()),
    );
  });

  test("rejects chunks from another transfer than expected", () {
    expect(
      () =>
          _assembler(expectedTransferId: "other")
              .accept(_chunks("g1:payload").first),
      throwsA(
        isA<BoundedTransferRejected>().having(
          (error) => error.message,
          "message",
          "The value transfer identity changed",
        ),
      ),
    );
  });

  test("rejects a decoded value whose generation differs", () {
    final assembler = _assembler();
    final chunks = _chunks("g2:payload", generation: "g1");

    expect(
      assembler.accept(chunks.first),
      isA<GenerationCheckedTransferPending<String>>(),
    );
    expect(
      () => assembler.accept(chunks.last),
      throwsA(
        isA<BoundedTransferRejected>().having(
          (error) => error.message,
          "message",
          "The decoded value generation differs from its transfer",
        ),
      ),
    );
  });

  test("reports decoding failures as rejected transfers", () {
    final assembler = _assembler(decode: (_) => throw const FormatException());
    final chunks = _chunks("g1:payload");
    assembler.accept(chunks.first);

    expect(
      () => assembler.accept(chunks.last),
      throwsA(
        isA<BoundedTransferRejected>().having(
          (error) => error.message,
          "message",
          startsWith("The value transfer payload cannot be decoded"),
        ),
      ),
    );
  });
}

GenerationCheckedTransferAssembler<_Chunk, String, String> _assembler({
  String? expectedGeneration,
  String? expectedTransferId,
  String Function(Uint8List bytes)? decode,
}) => GenerationCheckedTransferAssembler(
  subject: "value",
  chunkGeneration: (chunk) => chunk.generation,
  chunkTransfer: (chunk) => chunk.transfer,
  decode: decode ?? utf8.decode,
  decodedGeneration: (value) => value.split(":").first,
  expectedGeneration: expectedGeneration,
  expectedTransferId: expectedTransferId,
);

List<_Chunk> _chunks(String value, {String? generation}) {
  final bytes = utf8.encode(value);
  final split = bytes.length ~/ 2;
  return [
    for (var index = 0; index < 2; index++)
      _Chunk(
        generation ?? value.split(":").first,
        skir.BoundedTransferChunk(
          transferId: "transfer",
          index: index,
          chunkCount: 2,
          encodedSize: bytes.length,
          sha256: sha256.convert(bytes).toString(),
          payload: skir.ByteString.copy(
            index == 0 ? bytes.sublist(0, split) : bytes.sublist(split),
          ),
        ),
      ),
  ];
}

final class _Chunk {
  const _Chunk(this.generation, this.transfer);

  final String generation;
  final skir.BoundedTransferChunk transfer;

  _Chunk withGeneration(String generation) => _Chunk(generation, transfer);
}
