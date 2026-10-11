import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

final class AuthoringStateTransferAssembler {
  final BoundedTransferAssembler _bytes = BoundedTransferAssembler();
  skir.CatalogGeneration? _generation;

  Future<skir.AuthoringState> assemble(
    Stream<skir.AuthoringStateTransferChunk> chunks, {
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

  BoundedTransferPart _part(skir.AuthoringStateTransferChunk chunk) {
    final generation = _generation;
    if (generation == null) {
      _generation = chunk.generation;
    } else if (generation != chunk.generation) {
      throw const BoundedTransferRejected(
        "The authored snapshot identity changed between chunks",
      );
    }
    final transfer = chunk.transfer;
    return BoundedTransferPart(
      transferId: transfer.transferId,
      index: transfer.index,
      chunkCount: transfer.chunkCount,
      encodedSize: transfer.encodedSize,
      sha256: transfer.sha256,
      payload: transfer.payload.asUnmodifiableList,
    );
  }

  skir.AuthoringState _decodeAndValidate(Uint8List encoded) {
    try {
      final value = skir.AuthoringState.serializer.fromBytes(encoded);
      if (value.generation != _generation) {
        throw const BoundedTransferRejected(
          "The decoded authored snapshot identity differs from its transfer",
        );
      }
      return value;
    } on BoundedTransferRejected {
      rethrow;
    } on Object catch (error) {
      throw BoundedTransferRejected(
        "The authored snapshot transfer payload cannot be decoded: $error",
      );
    }
  }
}

final class AuthoringStateTransferUnavailable implements Exception {
  const AuthoringStateTransferUnavailable(this.value);

  final skir.AuthoringTransferUnavailable value;

  @override
  String toString() =>
      "The authored snapshot is ${value.encodedSize} bytes, above the ${value.maxEncodedSize} byte transfer limit";
}
