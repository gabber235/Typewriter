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
export "package:typewriter_panel/infrastructure/protocols/skir/editor_type_codec.dart";
export "package:typewriter_panel/infrastructure/protocols/skir/editor_value_codec.dart";

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

  TypeResult<wire_type.TypedValue> encodeValue(DataValue value) =>
      valueCodec.encode(value);

  TypeResult<DataValue> decodeValue(wire_type.TypedValue? value) =>
      valueCodec.decode(value);

  TypeResult<wire_path.DataPath> encodePath(DataPath path) =>
      pathCodec.encode(path);

  TypeResult<DataPath> decodePath(wire_path.DataPath? path) =>
      pathCodec.decode(path);

  TypeResult<wire_type.ResolvedTypeRef> encodeType(ResolvedTypeRef type) =>
      typeCodec.encodeReference(type);

  TypeResult<ResolvedTypeRef> decodeType(wire_type.ResolvedTypeRef? type) =>
      typeCodec.decodeReference(type);
}
