import "dart:typed_data";

import "package:typewriter_panel/infrastructure/messaging/bounded_transfer_assembler.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;

final class AuthoringChangedTransferAssembler {
  AuthoringChangedTransferAssembler({
    void Function(String transferId)? onExpired,
  }) {
    _pool = BoundedTransferPool(
      onExpired: (transferId) {
        _metadata.remove(transferId);
        onExpired?.call(transferId);
      },
    );
  }

  late final BoundedTransferPool _pool;
  final Map<String, _AuthoringChangedMetadata> _metadata = {};

  skir.AuthoringChanged? accept(skir.AuthoringChangedTransferResult result) {
    return switch (result) {
      skir.AuthoringChangedTransferResult_chunkWrapper(:final value) =>
        _acceptChunk(value),
      skir.AuthoringChangedTransferResult_unavailableWrapper(:final value) =>
        throw AuthoringChangedTransferUnavailable(value),
      skir.AuthoringChangedTransferResult_unknown() =>
        throw const BoundedTransferRejected(
          "The authored change transfer result is unknown",
        ),
    };
  }

  skir.AuthoringChanged? _acceptChunk(
    skir.AuthoringChangedTransferChunk chunk,
  ) {
    final transfer = chunk.transfer;
    final metadata = _AuthoringChangedMetadata.fromChunk(chunk);
    final existing = _metadata[transfer.transferId];
    if (existing == null) {
      _metadata[transfer.transferId] = metadata;
    } else if (existing != metadata) {
      _metadata.remove(transfer.transferId);
      throw const BoundedTransferRejected(
        "The authored change identity changed between chunks",
      );
    }
    try {
      return switch (_pool.accept(_part(transfer))) {
        BoundedTransferPoolPending() => null,
        BoundedTransferPoolComplete(:final transferId, :final bytes) =>
          _decodeAndValidate(bytes, _metadata.remove(transferId)!),
      };
    } on Object {
      _metadata.remove(transfer.transferId);
      rethrow;
    }
  }

  skir.AuthoringChanged _decodeAndValidate(
    Uint8List encoded,
    _AuthoringChangedMetadata metadata,
  ) {
    try {
      final value = skir.AuthoringChanged.serializer.fromBytes(encoded);
      if (!metadata.matches(value)) {
        throw const BoundedTransferRejected(
          "The decoded authored change identity differs from its transfer",
        );
      }
      return value;
    } on BoundedTransferRejected {
      rethrow;
    } on Object catch (error) {
      throw BoundedTransferRejected(
        "The authored change transfer payload cannot be decoded: $error",
      );
    }
  }

  void clear() {
    _metadata.clear();
    _pool.clear();
  }
}

final class AuthoringChangedTransferUnavailable implements Exception {
  const AuthoringChangedTransferUnavailable(this.value);

  final skir.AuthoringTransferUnavailable value;
}

final class _AuthoringChangedMetadata {
  const _AuthoringChangedMetadata(
    this.generation,
    this.previousSnapshot,
    this.snapshot,
    this.previousFindings,
    this.findingsToken,
  );

  factory _AuthoringChangedMetadata.fromChunk(
    skir.AuthoringChangedTransferChunk chunk,
  ) => _AuthoringChangedMetadata(
    chunk.generation,
    chunk.previousSnapshot,
    chunk.snapshot,
    chunk.previousFindings,
    chunk.findingsToken,
  );

  final skir.CatalogGeneration generation;
  final skir.SnapshotId previousSnapshot;
  final skir.SnapshotId snapshot;
  final skir.FindingsToken previousFindings;
  final skir.FindingsToken findingsToken;

  bool matches(skir.AuthoringChanged value) =>
      value.generation == generation &&
      value.previousSnapshot == previousSnapshot &&
      value.snapshot == snapshot &&
      value.previousFindings == previousFindings &&
      value.findingsToken == findingsToken;

  @override
  bool operator ==(Object other) =>
      other is _AuthoringChangedMetadata &&
      other.generation == generation &&
      other.previousSnapshot == previousSnapshot &&
      other.snapshot == snapshot &&
      other.previousFindings == previousFindings &&
      other.findingsToken == findingsToken;

  @override
  int get hashCode => Object.hash(
    generation,
    previousSnapshot,
    snapshot,
    previousFindings,
    findingsToken,
  );
}

BoundedTransferPart _part(skir.BoundedTransferChunk transfer) =>
    BoundedTransferPart(
      transferId: transfer.transferId,
      index: transfer.index,
      chunkCount: transfer.chunkCount,
      encodedSize: transfer.encodedSize,
      sha256: transfer.sha256,
      payload: transfer.payload.asUnmodifiableList,
    );
