import "package:typewriter_panel/infrastructure/protocols/skir/editor_codec_support.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/path.dart"
    as wire;
import "package:typewriter_panel/typewriter_panel.dart";

final class SkirDataPathCodec {
  const SkirDataPathCodec(this.valueCodec);

  final SkirDataValueCodec valueCodec;

  TypeResult<wire.DataPath> encode(DataPath path) {
    final segments = <wire.DataPathSegment>[];
    final diagnostics = <TypeDiagnostic>[];
    for (final segment in path.segments) {
      final result = _encodeSegment(segment);
      diagnostics.addAll(result.diagnostics);
      if (result.valueOrNull case final encoded?) segments.add(encoded);
    }
    if (diagnostics.isNotEmpty) return TypeResult.failure(diagnostics);
    return TypeResult.success(wire.DataPath(segments: segments));
  }

  TypeResult<DataPath> decode(wire.DataPath? path) {
    if (path == null) return invalidWire("Wire data path is null");
    final segments = <DataPathSegment>[];
    final diagnostics = <TypeDiagnostic>[];
    for (final segment in path.segments) {
      final result = _decodeSegment(segment);
      diagnostics.addAll(result.diagnostics);
      if (result.valueOrNull case final decoded?) segments.add(decoded);
    }
    if (diagnostics.isNotEmpty) return TypeResult.failure(diagnostics);
    return TypeResult.success(DataPath(segments));
  }

  TypeResult<wire.DataPathSegment> _encodeSegment(DataPathSegment segment) =>
      switch (segment) {
        FieldPathSegment(:final name) =>
          name.isEmpty
              ? invalidWire("Path field name is empty")
              : TypeResult.success(
                  wire.DataPathSegment.createField(fieldName: name),
                ),
        IndexPathSegment(:final index) =>
          index < 0
              ? invalidWire("Path index is negative")
              : TypeResult.success(
                  wire.DataPathSegment.createIndex(index: index),
                ),
        MapKeyPathSegment(:final key) =>
          valueCodec
              .encode(key)
              .mapValue(
                (encoded) => wire.DataPathSegment.createMapKey(key: encoded),
              ),
      };

  TypeResult<DataPathSegment> _decodeSegment(wire.DataPathSegment segment) =>
      switch (segment) {
        wire.DataPathSegment_unknown() => invalidWire(
          "Unknown wire data path segment",
        ),
        wire.DataPathSegment_fieldWrapper(:final value) =>
          value.fieldName.isEmpty
              ? invalidWire("Path field name is empty")
              : TypeResult.success(FieldPathSegment(value.fieldName)),
        wire.DataPathSegment_indexWrapper(:final value) =>
          value.index < 0
              ? invalidWire("Path index is negative")
              : TypeResult.success(IndexPathSegment(value.index)),
        wire.DataPathSegment_mapKeyWrapper(:final value) =>
          valueCodec.decode(value.key).mapValue(MapKeyPathSegment.new),
      };
}
