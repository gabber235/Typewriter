import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "generation_checked_transfer_assembler.freezed.dart";

@freezed
sealed class GenerationCheckedTransferState<T>
    with _$GenerationCheckedTransferState<T> {
  const factory GenerationCheckedTransferState.pending() =
      GenerationCheckedTransferPending<T>;
  const factory GenerationCheckedTransferState.complete(T value) =
      GenerationCheckedTransferComplete<T>;
}

/// Reassembles one bounded transfer whose chunks and decoded value share a
/// generation.
///
/// The first chunk fixes the generation unless [expectedGeneration] is
/// supplied. Every chunk and the decoded value must carry that generation.
/// When [expectedTransferId] is supplied, chunks must also belong to it.
/// Byte bounds, ordering, size, and digest checks are delegated to
/// [BoundedTransferAssembler]. Every rejection is a [BoundedTransferRejected].
final class GenerationCheckedTransferAssembler<Chunk, Generation, Value> {
  GenerationCheckedTransferAssembler({
    required this.subject,
    required this.chunkGeneration,
    required this.chunkTransfer,
    required this.decode,
    required this.decodedGeneration,
    Generation? expectedGeneration,
    this.expectedTransferId,
  }) : _generation = expectedGeneration;

  /// Names the transferred value in rejection messages.
  final String subject;
  final Generation Function(Chunk chunk) chunkGeneration;
  final skir.BoundedTransferChunk Function(Chunk chunk) chunkTransfer;
  final Value Function(Uint8List bytes) decode;
  final Generation Function(Value value) decodedGeneration;
  final String? expectedTransferId;

  final BoundedTransferAssembler _bytes = BoundedTransferAssembler();
  Generation? _generation;

  /// Consumes chunks until complete, cancelled, timed out, or rejected.
  Future<Value> assemble(
    Stream<Chunk> chunks, {
    Duration timeout = defaultBoundedTransferTimeout,
    Future<void>? cancelled,
  }) async {
    final encoded = await _bytes.assemble(
      chunks.map(_part),
      timeout: timeout,
      cancelled: cancelled,
    );
    return _decodeAndValidate(encoded);
  }

  /// Accepts one chunk, ending the transfer on completion or rejection.
  GenerationCheckedTransferState<Value> accept(Chunk chunk) =>
      switch (_bytes.accept(_part(chunk))) {
        BoundedTransferPending() => const GenerationCheckedTransferPending(),
        BoundedTransferComplete(:final bytes) =>
          GenerationCheckedTransferComplete(_decodeAndValidate(bytes)),
      };

  BoundedTransferPart _part(Chunk chunk) {
    final generation = _generation;
    final actual = chunkGeneration(chunk);
    if (generation == null) {
      _generation = actual;
    } else if (generation != actual) {
      throw BoundedTransferRejected(
        "The $subject generation changed between chunks",
      );
    }
    final transfer = chunkTransfer(chunk);
    if (expectedTransferId case final expected?
        when transfer.transferId != expected) {
      throw BoundedTransferRejected("The $subject transfer identity changed");
    }
    return BoundedTransferPart(
      transferId: transfer.transferId,
      index: transfer.index,
      chunkCount: transfer.chunkCount,
      encodedSize: transfer.encodedSize,
      sha256: transfer.sha256,
      payload: transfer.payload.asUnmodifiableList,
    );
  }

  Value _decodeAndValidate(Uint8List encoded) {
    try {
      final value = decode(encoded);
      if (decodedGeneration(value) != _generation) {
        throw BoundedTransferRejected(
          "The decoded $subject generation differs from its transfer",
        );
      }
      return value;
    } on BoundedTransferRejected {
      rethrow;
    } on Object catch (error) {
      throw BoundedTransferRejected(
        "The $subject transfer payload cannot be decoded: $error",
      );
    }
  }
}
