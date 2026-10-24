import "package:typewriter_panel/typewriter_panel.dart";

/// Bounds how the transports split one payload, a request or a reply, into
/// frames.
///
/// A payload of at most [chunkBytes] travels as one plain message. A larger
/// one travels as frames of at most [chunkBytes]. A framed request flows in
/// credit windows of [windowFrames]: the receiver grants each next window, so
/// the panel never runs more than one window ahead of a slow receiver. Replies
/// to the panel stream every frame without credit, because granting a credit
/// is a NATS response and panel connections hold no response permission. A
/// payload above its direction's ceiling is never sent; the sender fails with
/// [TransferTooLarge]. Requests are single messages unless a route raises
/// [requestMaxBytes]; replies may be framed up to [replyMaxBytes]. The panel
/// waits [frameInactivity] for a credit and for the next frame of a reply. The
/// generated `transportLimits` carries the manifest defaults, and a route that
/// raises a ceiling carries its own.
final class TransportLimits {
  const TransportLimits({
    required this.chunkBytes,
    required this.windowFrames,
    required this.requestMaxBytes,
    required this.replyMaxBytes,
    required this.frameInactivity,
  }) : assert(chunkBytes > 0, "Transfer chunk size must be positive"),
       assert(windowFrames > 0, "A credit window holds at least one frame"),
       assert(
         requestMaxBytes >= chunkBytes && replyMaxBytes >= chunkBytes,
         "A direction carries at least one chunk",
       );

  /// The most bytes of an encoded payload that one message carries.
  final int chunkBytes;

  /// The most frames a sender sends before the receiver grants more.
  final int windowFrames;

  /// The largest encoded request a route carries.
  final int requestMaxBytes;

  /// The largest encoded reply a route carries.
  final int replyMaxBytes;

  /// How long a sender waits for a window's credit and a receiver waits for
  /// the next frame before it gives the payload up.
  final Duration frameInactivity;

  /// The most frames a payload of at most [maxBytes] splits into.
  int maxFrames(int maxBytes) => (maxBytes + chunkBytes - 1) ~/ chunkBytes;
}

/// A payload the transport could not deliver complete.
sealed class TransferFailure implements Exception {
  const TransferFailure();

  /// The failure a [PayloadHeaders.failure] value of [headers] names; unknown
  /// values are rejections.
  factory TransferFailure.named(String failure, NatsHeaders headers) {
    switch (failure) {
      case PayloadHeaders.tooLarge:
        final size = int.tryParse(headers.first(PayloadHeaders.size) ?? "");
        final limit = int.tryParse(headers.first(PayloadHeaders.limit) ?? "");
        return size == null || limit == null
            ? const TransferRejected("Too large frame lacks its size and limit")
            : TransferTooLarge(size: size, limit: limit);
      case PayloadHeaders.interrupted:
        return const TransferInterrupted();
      case PayloadHeaders.incomplete:
        return const TransferRejected(
          "The receiver missed a frame of the payload",
        );
      case PayloadHeaders.busy:
        return const TransferBusy();
      case PayloadHeaders.rejected:
        return const TransferRejected(
          "The receiver rejected a frame of the payload",
        );
      default:
        return const TransferRejected("Unknown transfer failure");
    }
  }

  /// Diagnostic description of the failure.
  String get message;

  @override
  String toString() => message;
}

/// The encoded payload of [size] bytes exceeded the [limit] its direction
/// carries, so no frame of it was sent.
final class TransferTooLarge extends TransferFailure {
  const TransferTooLarge({required this.size, required this.limit});

  final int size;
  final int limit;

  @override
  String get message =>
      "The payload is $size bytes, above the $limit byte transfer limit";
}

/// The sender stopped part way, so the payload can never complete.
final class TransferInterrupted extends TransferFailure {
  const TransferInterrupted();

  @override
  String get message => "The sender stopped before every frame was sent";
}

/// The receiver already holds its bound of assembling bytes and refused
/// another payload; the same payload may succeed later.
final class TransferBusy extends TransferFailure {
  const TransferBusy();

  @override
  String get message => "The receiver is assembling as many bytes as it holds";
}

/// A frame or answer broke the framing rules: malformed headers, changed
/// metadata or bytes, a failed size or digest check, a missing frame, or an
/// answer without the credit the sender waits for.
final class TransferRejected extends TransferFailure {
  const TransferRejected(this.message);

  @override
  final String message;
}

/// The caller stopped waiting for a reply before it completed.
final class TransferCancelled implements Exception {
  const TransferCancelled();
}

/// Header names and failure values of the payload framing wire format, shared
/// with the services and backend transports.
abstract final class PayloadHeaders {
  static const payload = "Typewriter-Payload";
  static const chunk = "Typewriter-Chunk";
  static const size = "Typewriter-Size";
  static const sha256 = "Typewriter-Sha256";
  static const failure = "Typewriter-Transfer-Failure";
  static const limit = "Typewriter-Limit";

  /// On the answer to a window's last frame: frames below this index may be
  /// sent.
  static const credit = "Typewriter-Credit";

  static const tooLarge = "too-large";
  static const interrupted = "interrupted";

  /// Answer to a window end whose earlier frames never arrived; NATS core may
  /// drop a message.
  static const incomplete = "incomplete";

  /// Answer to a payload that would exceed the receiver's bound of assembling
  /// bytes.
  static const busy = "busy";

  /// Answer to a window end whose payload broke the framing rules, so the
  /// receiver dropped it.
  static const rejected = "rejected";
}

/// Assembles the framed replies arriving at the panel, grouping frames by
/// payload id. Replies to the panel stream without credit, so the assembler
/// never answers a frame.
///
/// The failure header is checked before anything else, so too large and
/// interrupted payloads never decode as empty ones. A message without a
/// payload id is a complete payload. Frames may arrive in any order; identical
/// duplicates are accepted and changed ones rejected. Bounds against
/// [maxBytes], the complete size and the digest are verified before the bytes
/// are returned, so callers never decode partial payloads. Every rejection is
/// a [TransferFailure] and drops its assembly. The assembler retains frames
/// until their payload completes and is discarded with its request, whose
/// inactivity bound ends an abandoned assembly.
final class PayloadAssembler {
  PayloadAssembler(this.limits, {required this.maxBytes});

  final TransportLimits limits;

  /// The ceiling of the direction this assembler receives.
  final int maxBytes;

  final Map<String, _PayloadParts> _pending = {};

  /// Accepts one message and returns its complete payload bytes, or null
  /// while frames are missing.
  Uint8List? accept(NatsHeaders? headers, Uint8List payload) {
    final payloadId = headers?.first(PayloadHeaders.payload);
    if (headers?.first(PayloadHeaders.failure) case final failure?) {
      if (payloadId != null) _pending.remove(payloadId);
      throw TransferFailure.named(failure, headers!);
    }
    if (payloadId == null) return payload;
    try {
      final frame = _frame(headers!, payload);
      final parts = _pending.putIfAbsent(
        payloadId,
        () => _PayloadParts(frame.count, frame.size, frame.digest),
      );
      final bytes = parts.accept(frame);
      if (bytes != null) _pending.remove(payloadId);
      return bytes;
    } on TransferRejected {
      _pending.remove(payloadId);
      rethrow;
    }
  }

  _Frame _frame(NatsHeaders headers, Uint8List payload) {
    final chunk = _chunkPattern.firstMatch(
      headers.first(PayloadHeaders.chunk) ?? "",
    );
    final sizeText = headers.first(PayloadHeaders.size) ?? "";
    final size = _sizePattern.hasMatch(sizeText)
        ? int.tryParse(sizeText)
        : null;
    final digest = headers.first(PayloadHeaders.sha256) ?? "";
    if (chunk == null || size == null || !_sha256Pattern.hasMatch(digest)) {
      throw const TransferRejected("Frame metadata is malformed");
    }
    final index = int.parse(chunk.group(1)!);
    final count = int.parse(chunk.group(2)!);
    if (count < 1 || count > limits.maxFrames(maxBytes) || index >= count) {
      throw const TransferRejected("Frame position is out of bounds");
    }
    if (size > maxBytes) {
      throw const TransferRejected("Payload size is out of bounds");
    }
    if (payload.length > limits.chunkBytes) {
      throw const TransferRejected("Frame exceeds the chunk size");
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

/// The frames of one payload received so far, sharing the metadata of its
/// first frame.
final class _PayloadParts {
  _PayloadParts(this.count, this.size, this.digest)
    : _parts = List<Uint8List?>.filled(count, null);

  final int count;
  final int size;
  final String digest;
  final List<Uint8List?> _parts;
  var _received = 0;
  var _retained = 0;

  Uint8List? accept(_Frame frame) {
    if (frame.count != count || frame.size != size || frame.digest != digest) {
      throw const TransferRejected("Frame metadata changed during assembly");
    }
    final prior = _parts[frame.index];
    if (prior != null) {
      if (!const ListEquality<int>().equals(prior, frame.bytes)) {
        throw const TransferRejected("Frame changed during assembly");
      }
      return null;
    }
    _retained += frame.bytes.length;
    if (_retained > size) {
      throw const TransferRejected("Frames exceed their declared size");
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
      throw const TransferRejected("Payload size verification failed");
    }
    if (sha256.convert(bytes).toString() != digest) {
      throw const TransferRejected("Payload digest verification failed");
    }
    return bytes;
  }
}

final _chunkPattern = RegExp(r"^(\d{1,9})/(\d{1,9})$");
// Fifteen digits parse exactly on the web too and cover every admitted size;
// the services transport uses the same bound.
final _sizePattern = RegExp(r"^\d{1,15}$");
final _sha256Pattern = RegExp(r"^[0-9a-f]{64}$");
