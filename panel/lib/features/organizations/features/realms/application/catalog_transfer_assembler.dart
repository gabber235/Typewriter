import "dart:typed_data";

import "package:typewriter_panel/infrastructure/messaging/bounded_transfer_assembler.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;

sealed class CatalogTransferState {
  const CatalogTransferState();
}

final class CatalogTransferPending extends CatalogTransferState {
  const CatalogTransferPending();
}

final class CatalogTransferComplete extends CatalogTransferState {
  const CatalogTransferComplete(this.snapshot);

  final skir.EditorCatalogWireSnapshot snapshot;
}

final class CatalogTransferAssembler {
  final BoundedTransferAssembler _bytes = BoundedTransferAssembler();
  skir.CatalogGeneration? _generation;

  Future<skir.EditorCatalogWireSnapshot> assemble(
    Stream<skir.CatalogTransferChunk> chunks, {
    Duration timeout = catalogTransferTimeout,
    Future<void>? cancelled,
  }) async {
    try {
      final encoded = await _bytes.assemble(
        chunks.map(_part),
        timeout: timeout,
        cancelled: cancelled,
      );
      return _decodeAndValidate(encoded);
    } on BoundedTransferRejected catch (error) {
      throw CatalogTransferRejected(error.message);
    }
  }

  CatalogTransferState accept(skir.CatalogTransferChunk chunk) {
    try {
      return switch (_bytes.accept(_part(chunk))) {
        BoundedTransferPending() => const CatalogTransferPending(),
        BoundedTransferComplete(:final bytes) => CatalogTransferComplete(
          _decodeAndValidate(bytes),
        ),
      };
    } on BoundedTransferRejected catch (error) {
      throw CatalogTransferRejected(error.message);
    }
  }

  BoundedTransferPart _part(skir.CatalogTransferChunk chunk) {
    final generation = _generation;
    if (generation == null) {
      _generation = chunk.generation;
    } else if (generation != chunk.generation) {
      throw const CatalogTransferRejected(
        "The catalog transfer generation changed between chunks",
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

  skir.EditorCatalogWireSnapshot _decodeAndValidate(Uint8List encoded) {
    try {
      final snapshot = skir.EditorCatalogWireSnapshot.serializer.fromBytes(
        encoded,
      );
      if (snapshot.generation != _generation) {
        throw const CatalogTransferRejected(
          "The decoded catalog generation differs from its transfer",
        );
      }
      return snapshot;
    } on CatalogTransferRejected {
      rethrow;
    } on Object catch (error) {
      throw CatalogTransferRejected(
        "The catalog transfer payload cannot be decoded: $error",
      );
    }
  }
}

const maximumCatalogTransferChunkBytes = defaultMaximumTransferChunkBytes;
const maximumCatalogTransferChunks = defaultMaximumTransferChunks;
const maximumCatalogTransferBytes = defaultMaximumTransferBytes;
const catalogTransferTimeout = defaultBoundedTransferTimeout;

final class CatalogTransferRejected implements Exception {
  const CatalogTransferRejected(this.message);

  final String message;

  @override
  String toString() => message;
}
