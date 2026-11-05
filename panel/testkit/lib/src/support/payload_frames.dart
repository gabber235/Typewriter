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
