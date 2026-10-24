import "package:typewriter_panel/typewriter_panel.dart";

/// Bounds how the transports split one reply into frames on the requester's
/// reply inbox.
///
/// A reply of at most [chunkBytes] travels as one plain message. A larger
/// reply travels as frames of at most [chunkBytes] each, and a reply above
/// [maxEncodedSize] is never sent: the requester receives [TransferTooLarge].
/// The generated `transportLimits` carries the values of the transport route
/// manifest.
final class TransportLimits {
  const TransportLimits({required this.chunkBytes, required this.maxChunks})
    : assert(chunkBytes > 0, "Transfer chunk size must be positive"),
      assert(maxChunks > 0, "Transfer chunk count must be positive");

  /// The most bytes of an encoded reply that one frame carries.
  final int chunkBytes;

  /// The most frames one reply may have.
  final int maxChunks;

  /// The largest encoded reply a transport carries.
  int get maxEncodedSize => chunkBytes * maxChunks;
}

/// Time a request waits for the remaining frames once the first frame of its
/// reply arrived.
const replyAssemblyBudget = Duration(seconds: 30);

/// A reply the transport could not deliver complete.
sealed class TransferFailure implements Exception {
  const TransferFailure();

  /// Diagnostic description of the failure.
  String get message;

  @override
  String toString() => message;
}

/// The responder's encoded reply of [size] bytes exceeded the [limit] the
/// transport carries.
final class TransferTooLarge extends TransferFailure {
  const TransferTooLarge({required this.size, required this.limit});

  final int size;
  final int limit;

  @override
  String get message =>
      "The reply is $size bytes, above the $limit byte transfer limit";
}

/// The responder stopped publishing frames part way, so the reply can never
/// complete.
final class TransferInterrupted extends TransferFailure {
  const TransferInterrupted();

  @override
  String get message =>
      "The responder stopped before every reply frame was published";
}

/// A frame broke the framing rules: malformed headers, changed metadata or
/// bytes, or a failed size or digest check.
final class TransferRejected extends TransferFailure {
  const TransferRejected(this.message);

  @override
  final String message;
}

/// The caller stopped waiting for a reply before it completed.
final class TransferCancelled implements Exception {
  const TransferCancelled();
}

/// Header names and failure values of the reply framing wire format, shared
/// with the services and backend transports.
abstract final class ReplyHeaders {
  static const reply = "Typewriter-Reply";
  static const chunk = "Typewriter-Chunk";
  static const size = "Typewriter-Size";
  static const sha256 = "Typewriter-Sha256";
  static const failure = "Typewriter-Transfer-Failure";
  static const limit = "Typewriter-Limit";
  static const tooLarge = "too-large";
  static const interrupted = "interrupted";
}

/// Assembles the replies arriving for one request, grouping frames by reply
/// id.
///
/// The failure header is checked before anything else, so too large and
/// interrupted replies never decode as empty replies. A message without a
/// reply id is a complete reply. Frames may arrive in any order; identical
/// duplicates are accepted and changed ones rejected. Bounds, the complete
/// size and the digest are verified before the bytes are returned, so callers
/// never decode partial replies. Every rejection is a [TransferFailure]. The
/// assembler retains frames until their reply completes and is discarded with
/// its request.
final class ReplyAssembler {
  ReplyAssembler(this.limits);

  final TransportLimits limits;
  final Map<String, _ReplyParts> _pending = {};

  /// Accepts one message and returns its complete reply bytes, or null while
  /// frames are missing.
  Uint8List? accept(NatsHeaders? headers, Uint8List payload) {
    final replyId = headers?.first(ReplyHeaders.reply);
    if (headers?.first(ReplyHeaders.failure) case final failure?) {
      if (replyId != null) _pending.remove(replyId);
      throw _failure(failure, headers!);
    }
    if (replyId == null) return payload;
    try {
      final frame = _frame(headers!, payload);
      final parts = _pending.putIfAbsent(
        replyId,
        () => _ReplyParts(frame.count, frame.size, frame.digest),
      );
      final bytes = parts.accept(frame);
      if (bytes != null) _pending.remove(replyId);
      return bytes;
    } on TransferRejected {
      _pending.remove(replyId);
      rethrow;
    }
  }

  TransferFailure _failure(String failure, NatsHeaders headers) {
    switch (failure) {
      case ReplyHeaders.tooLarge:
        final size = int.tryParse(headers.first(ReplyHeaders.size) ?? "");
        final limit = int.tryParse(headers.first(ReplyHeaders.limit) ?? "");
        return size == null || limit == null
            ? const TransferRejected(
                "Too large reply frame lacks its size and limit",
              )
            : TransferTooLarge(size: size, limit: limit);
      case ReplyHeaders.interrupted:
        return const TransferInterrupted();
      default:
        return const TransferRejected("Unknown reply transfer failure");
    }
  }

  _Frame _frame(NatsHeaders headers, Uint8List payload) {
    final chunk = _chunkPattern.firstMatch(
      headers.first(ReplyHeaders.chunk) ?? "",
    );
    final sizeText = headers.first(ReplyHeaders.size) ?? "";
    final size = _sizePattern.hasMatch(sizeText)
        ? int.tryParse(sizeText)
        : null;
    final digest = headers.first(ReplyHeaders.sha256) ?? "";
    if (chunk == null || size == null || !_sha256Pattern.hasMatch(digest)) {
      throw const TransferRejected("Reply frame metadata is malformed");
    }
    final index = int.parse(chunk.group(1)!);
    final count = int.parse(chunk.group(2)!);
    if (count < 1 || count > limits.maxChunks || index >= count) {
      throw const TransferRejected("Reply frame position is out of bounds");
    }
    if (size > limits.maxEncodedSize) {
      throw const TransferRejected("Reply size is out of bounds");
    }
    if (payload.length > limits.chunkBytes) {
      throw const TransferRejected("Reply frame exceeds the chunk size");
    }
    return _Frame(index, count, size, digest, Uint8List.fromList(payload));
  }
}

final class _Frame {
  const _Frame(this.index, this.count, this.size, this.digest, this.bytes);

  final int index;
  final int count;
  final int size;
  final String digest;
  final Uint8List bytes;
}

/// The frames of one reply received so far, sharing the metadata of its first
/// frame.
final class _ReplyParts {
  _ReplyParts(this.count, this.size, this.digest)
    : _parts = List<Uint8List?>.filled(count, null);

  final int count;
  final int size;
  final String digest;
  final List<Uint8List?> _parts;
  var _received = 0;
  var _retained = 0;

  Uint8List? accept(_Frame frame) {
    if (frame.count != count || frame.size != size || frame.digest != digest) {
      throw const TransferRejected(
        "Reply frame metadata changed during assembly",
      );
    }
    final prior = _parts[frame.index];
    if (prior != null) {
      if (!const ListEquality<int>().equals(prior, frame.bytes)) {
        throw const TransferRejected("Reply frame changed during assembly");
      }
      return null;
    }
    _retained += frame.bytes.length;
    if (_retained > size) {
      throw const TransferRejected("Reply frames exceed their declared size");
    }
    _parts[frame.index] = frame.bytes;
    _received++;
    if (_received < count) return null;
    final builder = BytesBuilder(copy: false);
    for (final part in _parts) {
      builder.add(part!);
    }
    final bytes = builder.takeBytes();
    if (bytes.length != size) {
      throw const TransferRejected("Reply size verification failed");
    }
    if (sha256.convert(bytes).toString() != digest) {
      throw const TransferRejected("Reply digest verification failed");
    }
    return bytes;
  }
}

final _chunkPattern = RegExp(r"^(\d{1,9})/(\d{1,9})$");
// Fifteen digits parse exactly on the web too and cover every admitted size;
// the services transport uses the same bound.
final _sizePattern = RegExp(r"^\d{1,15}$");
final _sha256Pattern = RegExp(r"^[0-9a-f]{64}$");
