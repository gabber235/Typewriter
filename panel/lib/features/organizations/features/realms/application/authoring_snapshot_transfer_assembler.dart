import "dart:typed_data";

import "package:typewriter_panel/infrastructure/messaging/bounded_transfer_assembler.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;

final class AuthoringSnapshotTransferAssembler {
  final BoundedTransferAssembler _bytes = BoundedTransferAssembler();
  skir.CatalogGeneration? _generation;
  skir.SnapshotId? _snapshot;

  Future<skir.AuthoringSnapshot> assemble(
    Stream<skir.AuthoringSnapshotTransferChunk> chunks, {
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

  BoundedTransferPart _part(skir.AuthoringSnapshotTransferChunk chunk) {
    final generation = _generation;
    final snapshot = _snapshot;
    if (generation == null && snapshot == null) {
      _generation = chunk.generation;
      _snapshot = chunk.snapshot;
    } else if (generation != chunk.generation || snapshot != chunk.snapshot) {
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

  skir.AuthoringSnapshot _decodeAndValidate(Uint8List encoded) {
    try {
      final value = skir.AuthoringSnapshot.serializer.fromBytes(encoded);
      if (value.generation != _generation || value.snapshot != _snapshot) {
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

final class AuthoringSnapshotTransferUnavailable implements Exception {
  const AuthoringSnapshotTransferUnavailable(this.value);

  final skir.AuthoringTransferUnavailable value;

  @override
  String toString() =>
      "The authored snapshot is ${value.encodedSize} bytes, above the ${value.maxEncodedSize} byte transfer limit";
}
