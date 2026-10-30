import "package:typewriter_panel/typewriter_panel.dart";

/// The frames the panel's framer sends for [bytes] in chunks of
/// [chunkBytes], each with the headers a sender publishes.
List<({NatsHeaders headers, Uint8List payload})> payloadFrames(
  Uint8List bytes, {
  int chunkBytes = 4,
}) {
  final framed = FramedPayload(bytes, chunkBytes, const {});
  return [
    for (var index = 0; index < framed.count; index++)
      (headers: framed.headers(index), payload: framed.bytes(index)),
  ];
}

/// The headers of a payload a sender gave up on with [failure], naming the
/// payload's [size] and the receiver's [limit] when known.
NatsHeaders payloadFailure(String failure, {int? size, int? limit}) =>
    NatsHeaders(
      entries: [
        const MapEntry(PayloadHeaders.payload, "payload"),
        MapEntry(PayloadHeaders.failure, failure),
        if (size != null) MapEntry(PayloadHeaders.size, "$size"),
        if (limit != null) MapEntry(PayloadHeaders.limit, "$limit"),
      ],
    );

/// [length] bytes in a pattern that [seed] shifts, so two bodies of the same
/// length differ.
Uint8List patternedBytes(int length, {int seed = 0}) => Uint8List.fromList([
  for (var i = 0; i < length; i++) (i * 31 + seed) & 0xff,
]);

/// Feeding frames to a payload assembler the way a subscription delivers
/// them.
extension AssemblingFrames on PayloadAssembler {
  /// Accepts [frames] in order and returns the first complete payload, or
  /// null when none completed.
  Uint8List? assemble(
    Iterable<({NatsHeaders? headers, Uint8List payload})> frames,
  ) {
    for (final frame in frames) {
      final complete = accept(frame.headers, frame.payload);
      if (complete != null) return complete;
    }
    return null;
  }
}
