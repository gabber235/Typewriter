import "dart:async";
import "dart:typed_data";

import "package:crypto/crypto.dart";

final RegExp _boundedTransferIdPattern = RegExp(r"^[A-Za-z0-9_-]{1,64}$");

String boundedTransferUpdateSubject(String base, String transferId) {
  if (!_boundedTransferIdPattern.hasMatch(transferId)) {
    throw ArgumentError.value(
      transferId,
      "transferId",
      "must be one safe subject segment",
    );
  }
  return "$base.$transferId";
}

final class BoundedTransferPart {
  BoundedTransferPart({
    required this.transferId,
    required this.index,
    required this.chunkCount,
    required this.encodedSize,
    required this.sha256,
    required List<int> payload,
  }) : payload = Uint8List.fromList(payload).asUnmodifiableView();

  final String transferId;
  final int index;
  final int chunkCount;
  final int encodedSize;
  final String sha256;
  final Uint8List payload;
}

sealed class BoundedTransferState {
  const BoundedTransferState();
}

final class BoundedTransferPending extends BoundedTransferState {
  const BoundedTransferPending();
}

final class BoundedTransferComplete extends BoundedTransferState {
  const BoundedTransferComplete(this.bytes);

  final Uint8List bytes;
}

final class BoundedTransferAssembler {
  BoundedTransferAssembler({
    this.maximumChunkBytes = defaultMaximumTransferChunkBytes,
    this.maximumChunks = defaultMaximumTransferChunks,
    this.onCleanupFailure,
  }) : maximumBytes = maximumChunkBytes * maximumChunks {
    if (maximumChunkBytes <= 0 || maximumChunks <= 0) {
      throw ArgumentError("Transfer limits must be positive");
    }
  }

  final int maximumChunkBytes;
  final int maximumChunks;
  final int maximumBytes;
  final void Function(Object error, StackTrace stackTrace)? onCleanupFailure;
  String? _transferId;
  int? _chunkCount;
  int? _encodedSize;
  String? _sha256;
  final Map<int, Uint8List> _chunks = {};
  var _retainedBytes = 0;
  var _finished = false;

  int get retainedBytes => _retainedBytes;

  String? get transferId => _transferId;

  Future<Uint8List> assemble(
    Stream<BoundedTransferPart> chunks, {
    Duration timeout = defaultBoundedTransferTimeout,
    Future<void>? cancelled,
  }) async {
    final iterator = StreamIterator(chunks);
    try {
      final assembly = _assemble(iterator).timeout(timeout);
      return await switch (cancelled) {
        null => assembly,
        final cancellation => Future.any([
          assembly,
          cancellation.then<Uint8List>(
            (_) => throw const BoundedTransferCancelled(),
          ),
        ]),
      };
    } finally {
      _finished = true;
      _release();
      unawaited(
        iterator.cancel().catchError((Object error, StackTrace stackTrace) {
          final report = onCleanupFailure ?? Zone.current.handleUncaughtError;
          report(error, stackTrace);
        }),
      );
    }
  }

  Future<Uint8List> _assemble(
    StreamIterator<BoundedTransferPart> iterator,
  ) async {
    while (await iterator.moveNext()) {
      final state = accept(iterator.current);
      if (state case BoundedTransferComplete(:final bytes)) {
        return bytes;
      }
    }
    throw const BoundedTransferRejected(
      "The transfer ended before every chunk arrived",
    );
  }

  BoundedTransferState accept(BoundedTransferPart part) {
    if (_finished) {
      throw const BoundedTransferRejected("The transfer is already finished");
    }
    try {
      _validateChunkShape(part);
      if (_transferId == null) {
        if (part.index != 0) {
          throw const BoundedTransferRejected(
            "The initial transfer chunk must have index zero",
          );
        }
        _transferId = part.transferId;
        _chunkCount = part.chunkCount;
        _encodedSize = part.encodedSize;
        _sha256 = part.sha256;
      } else {
        _validateSharedMetadata(part);
      }
      if (_chunks.containsKey(part.index)) {
        throw BoundedTransferRejected(
          "Transfer chunk ${part.index} was received twice",
        );
      }
      _retainedBytes += part.payload.length;
      if (_retainedBytes > _encodedSize! || _retainedBytes > maximumBytes) {
        throw const BoundedTransferRejected(
          "The transfer payload exceeds its advertised size",
        );
      }
      _chunks[part.index] = part.payload;
      if (_chunks.length != _chunkCount) {
        return const BoundedTransferPending();
      }
      final bytes = BytesBuilder(copy: false);
      for (var index = 0; index < _chunkCount!; index++) {
        final payload = _chunks[index];
        if (payload == null) {
          throw BoundedTransferRejected("Transfer chunk $index is absent");
        }
        bytes.add(payload);
      }
      final encoded = bytes.takeBytes();
      if (encoded.length != _encodedSize) {
        throw const BoundedTransferRejected(
          "The transfer encoded size is invalid",
        );
      }
      if (sha256.convert(encoded).toString() != _sha256) {
        throw const BoundedTransferRejected("The transfer digest is invalid");
      }
      _finished = true;
      _release();
      return BoundedTransferComplete(encoded.asUnmodifiableView());
    } on Object {
      _finished = true;
      _release();
      rethrow;
    }
  }

  void _release() {
    _chunks.clear();
    _retainedBytes = 0;
  }

  void _validateChunkShape(BoundedTransferPart part) {
    if (part.transferId.isEmpty ||
        part.chunkCount <= 0 ||
        part.index < 0 ||
        part.index >= part.chunkCount ||
        part.chunkCount > maximumChunks ||
        part.encodedSize < 0 ||
        part.encodedSize > maximumBytes ||
        !_sha256Pattern.hasMatch(part.sha256) ||
        part.payload.length > maximumChunkBytes ||
        (part.encodedSize == 0
            ? part.chunkCount != 1 || part.payload.isNotEmpty
            : part.payload.isEmpty)) {
      throw const BoundedTransferRejected(
        "The transfer chunk metadata is invalid",
      );
    }
  }

  void _validateSharedMetadata(BoundedTransferPart part) {
    if (part.transferId != _transferId ||
        part.chunkCount != _chunkCount ||
        part.encodedSize != _encodedSize ||
        part.sha256 != _sha256) {
      throw const BoundedTransferRejected(
        "The transfer chunk metadata does not match",
      );
    }
  }
}

sealed class BoundedTransferPoolState {
  const BoundedTransferPoolState();
}

final class BoundedTransferPoolPending extends BoundedTransferPoolState {
  const BoundedTransferPoolPending();
}

final class BoundedTransferPoolComplete extends BoundedTransferPoolState {
  const BoundedTransferPoolComplete(this.transferId, this.bytes);

  final String transferId;
  final Uint8List bytes;
}

final class BoundedTransferPool {
  BoundedTransferPool({
    this.maximumActiveTransfers = defaultMaximumActiveTransfers,
    this.maximumRetainedBytes = defaultMaximumTransferBytes,
    this.idleTimeout = defaultBoundedTransferTimeout,
    this.onExpired,
    BoundedTransferAssembler Function()? assemblerFactory,
  }) : _assemblerFactory = assemblerFactory ?? BoundedTransferAssembler.new {
    if (maximumActiveTransfers <= 0 ||
        maximumRetainedBytes <= 0 ||
        idleTimeout <= Duration.zero) {
      throw ArgumentError("Transfer pool limits must be positive");
    }
  }

  final int maximumActiveTransfers;
  final int maximumRetainedBytes;
  final Duration idleTimeout;
  final void Function(String transferId)? onExpired;
  final BoundedTransferAssembler Function() _assemblerFactory;
  final Map<String, _ActiveTransfer> _active = {};

  int get retainedBytes => _active.values.fold(
    0,
    (total, value) => total + value.assembler.retainedBytes,
  );

  BoundedTransferPoolState accept(BoundedTransferPart part) {
    final existing = _active[part.transferId];
    if (existing == null && _active.length >= maximumActiveTransfers) {
      throw const BoundedTransferRejected("Too many transfers are active");
    }
    final active = (existing ?? _start(part.transferId))
      ..refresh(idleTimeout, () => _expire(part.transferId));
    try {
      final state = active.assembler.accept(part);
      if (retainedBytes > maximumRetainedBytes) {
        throw const BoundedTransferRejected(
          "Active transfers exceed the retained byte limit",
        );
      }
      if (state case BoundedTransferComplete(:final bytes)) {
        _remove(part.transferId);
        return BoundedTransferPoolComplete(part.transferId, bytes);
      }
      return const BoundedTransferPoolPending();
    } on Object {
      _remove(part.transferId);
      rethrow;
    }
  }

  _ActiveTransfer _start(String transferId) {
    final active = _ActiveTransfer(_assemblerFactory());
    _active[transferId] = active;
    return active;
  }

  void _expire(String transferId) {
    if (_active.remove(transferId) case final active?) {
      active.cancel();
      onExpired?.call(transferId);
    }
  }

  void _remove(String transferId) => _active.remove(transferId)?.cancel();

  void clear() {
    for (final active in _active.values) {
      active.cancel();
    }
    _active.clear();
  }
}

final class _ActiveTransfer {
  _ActiveTransfer(this.assembler);

  final BoundedTransferAssembler assembler;
  Timer? _expiry;

  void refresh(Duration timeout, void Function() expire) {
    _expiry?.cancel();
    _expiry = Timer(timeout, expire);
  }

  void cancel() => _expiry?.cancel();
}

const defaultMaximumTransferChunkBytes = 512 * 1024;
const defaultMaximumTransferChunks = 64;
const defaultMaximumTransferBytes =
    defaultMaximumTransferChunks * defaultMaximumTransferChunkBytes;
const defaultMaximumActiveTransfers = 4;
const defaultBoundedTransferTimeout = Duration(seconds: 30);

final _sha256Pattern = RegExp(r"^[0-9a-f]{64}$");

final class BoundedTransferRejected implements Exception {
  const BoundedTransferRejected(this.message);

  final String message;

  @override
  String toString() => message;
}

final class BoundedTransferCancelled implements Exception {
  const BoundedTransferCancelled();
}
