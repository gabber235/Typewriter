import "package:typewriter_panel/infrastructure/protocols/skir/editor_codec_support.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as wire;
import "package:typewriter_panel/typewriter_panel.dart";

final class SkirTypeStructureCodec {
  const SkirTypeStructureCodec(this.codec);

  final SkirTypeCodec codec;

  TypeResult<wire.TypeExpression> encodeList(ListType value) => codec
      .encodeExpression(value.element)
      .mapValue(
        (element) => wire.TypeExpression.createList(
          element: element,
          constraints: _constraints(
            value.minimumLength,
            value.maximumLength,
            value.unique,
          ),
        ),
      );

  TypeResult<TypeExpression> decodeList(wire.ListType value) => codec
      .decodeExpression(value.element)
      .mapValue(
        (element) => ListType(
          element: element,
          minimumLength: value.constraints.minimumLength,
          maximumLength: value.constraints.maximumLength,
          unique: value.constraints.uniqueItems,
        ),
      );

  TypeResult<wire.TypeExpression> encodeMap(MapType value) => combineResults(
    codec.encodeExpression(value.key),
    codec.encodeExpression(value.value),
    (key, item) => wire.TypeExpression.createMap(
      key: key,
      value: item,
      constraints: _constraints(
        value.minimumLength,
        value.maximumLength,
        false,
      ),
    ),
  );

  TypeResult<TypeExpression> decodeMap(wire.MapType value) => combineResults(
    codec.decodeExpression(value.key),
    codec.decodeExpression(value.value),
    (key, item) => MapType(
      key: key,
      value: item,
      minimumLength: value.constraints.minimumLength,
      maximumLength: value.constraints.maximumLength,
    ),
  );

  TypeResult<wire.TypeExpression> encodeRecord(RecordType value) {
    final fields = <wire.RecordField>[];
    final diagnostics = <TypeDiagnostic>[];
    for (final field in value.fields.values) {
      final result = codec.encodeExpression(field.type);
      diagnostics.addAll(result.diagnostics);
      final fieldType = result.valueOrNull;
      if (fieldType == null) continue;
      final initial = field.initialValue == null
          ? const TypeResult<wire.TypedValue?>.success(null)
          : SkirDataValueCodec(
              codec,
            ).encode(field.initialValue!).mapValue((value) => value);
      diagnostics.addAll(initial.diagnostics);
      fields.add(
        wire.RecordField(
          name: field.name,
          valueType: fieldType,
          initializer: initial.valueOrNull,
        ),
      );
    }
    if (diagnostics.isNotEmpty) return TypeResult.failure(diagnostics);
    return TypeResult.success(
      wire.TypeExpression.createRecord(fields: fields, closed: value.closed),
    );
  }

  TypeResult<TypeExpression> decodeRecord(wire.RecordType value) {
    final fields = <String, TypeField>{};
    final diagnostics = <TypeDiagnostic>[];
    for (final field in value.fields) {
      if (field.name.isEmpty) {
        diagnostics.add(wireDiagnostic("Record field name is empty"));
        continue;
      }
      if (fields.containsKey(field.name)) {
        diagnostics.add(
          wireDiagnostic("Duplicate record field '${field.name}'"),
        );
        continue;
      }
      final result = codec.decodeExpression(field.valueType);
      diagnostics.addAll(result.diagnostics);
      final fieldType = result.valueOrNull;
      if (fieldType == null) continue;
      final initial = field.initializer == null
          ? const TypeResult<DataValue?>.success(null)
          : SkirDataValueCodec(codec).decode(field.initializer);
      diagnostics.addAll(initial.diagnostics);
      fields[field.name] = TypeField(
        name: field.name,
        type: fieldType,
        initialValue: initial.valueOrNull,
      );
    }
    if (diagnostics.isNotEmpty) return TypeResult.failure(diagnostics);
    return TypeResult.success(RecordType(fields: fields, closed: value.closed));
  }

  wire.CollectionConstraints _constraints(
    int? minimum,
    int? maximum,
    bool unique,
  ) => wire.CollectionConstraints(
    minimumLength: minimum,
    maximumLength: maximum,
    uniqueItems: unique,
  );
}
