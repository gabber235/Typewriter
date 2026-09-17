// Entry point for the editor protocol codecs.
//
// A single registry is shared by type, value, path, expression, action, and
// presentation codecs. That shared context is required because wire values
// contain references whose meaning comes from the catalog, not from transport
// decoding alone.
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/path.dart"
    as wire_path;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as wire_type;
import "package:typewriter_panel/typewriter_panel.dart";

export "package:typewriter_panel/infrastructure/protocols/skir/editor_action_codec.dart";
export "package:typewriter_panel/infrastructure/protocols/skir/editor_action_encoder.dart";
export "package:typewriter_panel/infrastructure/protocols/skir/editor_catalog_codec.dart";
export "package:typewriter_panel/infrastructure/protocols/skir/editor_catalog_definition_codec.dart";
export "package:typewriter_panel/infrastructure/protocols/skir/editor_conversion_codec.dart";
export "package:typewriter_panel/infrastructure/protocols/skir/editor_conversion_encoder.dart"
    show SkirConversionEncoder;
export "package:typewriter_panel/infrastructure/protocols/skir/editor_expression_codec.dart";
export "package:typewriter_panel/infrastructure/protocols/skir/editor_expression_encoder.dart";
export "package:typewriter_panel/infrastructure/protocols/skir/editor_path_codec.dart";
export "package:typewriter_panel/infrastructure/protocols/skir/editor_presentation_codec.dart";
export "package:typewriter_panel/infrastructure/protocols/skir/editor_presentation_encoder.dart";
export "package:typewriter_panel/infrastructure/protocols/skir/editor_realm_search_codec.dart";
export "package:typewriter_panel/infrastructure/protocols/skir/editor_type_codec.dart";
export "package:typewriter_panel/infrastructure/protocols/skir/editor_value_codec.dart";
export "package:typewriter_panel/infrastructure/protocols/skir/realm_search_query_codec.dart";

/// Coordinates codecs that decode and encode the editor's typed vocabulary.
final class SkirEditorCodec {
  factory SkirEditorCodec(TypeRegistry registry) {
    final typeCodec = SkirTypeCodec(registry);
    final valueCodec = SkirDataValueCodec(typeCodec);
    return SkirEditorCodec._(
      typeCodec,
      valueCodec,
      SkirDataPathCodec(valueCodec),
    );
  }

  const SkirEditorCodec._(this.typeCodec, this.valueCodec, this.pathCodec);

  final SkirTypeCodec typeCodec;
  final SkirDataValueCodec valueCodec;
  final SkirDataPathCodec pathCodec;

  /// Encodes a domain value while preserving its wire type tag.
  TypeResult<wire_type.TypedValue> encodeValue(DataValue value) =>
      valueCodec.encode(value);

  /// Decodes a wire value and reports malformed input as diagnostics.
  TypeResult<DataValue> decodeValue(wire_type.TypedValue? value) =>
      valueCodec.decode(value);

  /// Encodes a domain path used to locate nested editor data.
  TypeResult<wire_path.DataPath> encodePath(DataPath path) =>
      pathCodec.encode(path);

  /// Decodes a wire path, validating every segment and embedded map key.
  TypeResult<DataPath> decodePath(wire_path.DataPath? path) =>
      pathCodec.decode(path);

  /// Encodes a catalog resolved type reference.
  TypeResult<wire_type.ResolvedTypeRef> encodeType(ResolvedTypeRef type) =>
      typeCodec.encodeReference(type);

  /// Decodes a resolved type reference against this codec's catalog context.
  TypeResult<ResolvedTypeRef> decodeType(wire_type.ResolvedTypeRef? type) =>
      typeCodec.decodeReference(type);
}
