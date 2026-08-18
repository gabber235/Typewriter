import "package:typewriter_panel/infrastructure/protocols/skir/editor_codec_support.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/editor_type_scalar_codec.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/editor_type_structure_codec.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as wire;
import "package:typewriter_panel/typewriter_panel.dart";

final class SkirTypeCodec {
  const SkirTypeCodec(this.registry);

  final TypeRegistry registry;

  TypeResult<wire.ResolvedTypeRef> encodeReference(ResolvedTypeRef reference) {
    final arguments = <wire.TypeExpression>[];
    final diagnostics = <TypeDiagnostic>[];
    for (final argument in reference.arguments) {
      final encoded = encodeExpression(argument);
      diagnostics.addAll(encoded.diagnostics);
      if (encoded.valueOrNull case final value?) arguments.add(value);
    }
    if (diagnostics.isNotEmpty) return TypeResult.failure(diagnostics);
    return TypeResult.success(
      wire.ResolvedTypeRef(
        typeId: _encodeTypeId(reference.id),
        revision: reference.revision,
        arguments: arguments,
      ),
    );
  }

  TypeResult<ResolvedTypeRef> decodeReference(wire.ResolvedTypeRef? value) {
    if (value == null) return invalidWire("Wire type reference is null");
    final id = _decodeTypeId(value.typeId);
    if (value.revision <= 0) {
      return invalidWire("Type revision must be positive");
    }
    final arguments = <TypeExpression>[];
    final diagnostics = <TypeDiagnostic>[...id.diagnostics];
    for (final argument in value.arguments) {
      final decoded = decodeExpression(argument);
      diagnostics.addAll(decoded.diagnostics);
      if (decoded.valueOrNull case final item?) arguments.add(item);
    }
    if (diagnostics.isNotEmpty) return TypeResult.failure(diagnostics);
    return TypeResult.success(
      ResolvedTypeRef(
        id: id.valueOrNull!,
        revision: value.revision,
        arguments: arguments,
      ),
    );
  }

  TypeResult<wire.TypeExpression> encodeExpression(TypeExpression value) =>
      switch (value) {
        AnyType() => invalidWire("Any type has no wire representation"),
        UnitType() => const TypeResult.success(wire.TypeExpression.unit),
        BooleanType() => const TypeResult.success(wire.TypeExpression.boolean),
        StringType() => SkirTypeScalarCodec.encodeString(value),
        BytesType() => TypeResult.success(
          wire.TypeExpression.createBytes(
            minimumLength: value.minimumLength,
            maximumLength: value.maximumLength,
            uniqueItems: false,
          ),
        ),
        IntegerType() => SkirTypeScalarCodec.encodeInteger(value),
        FloatType() => SkirTypeScalarCodec.encodeFloat(value),
        DecimalType() => SkirTypeScalarCodec.encodeDecimal(value),
        TimestampType() =>
          value.minimum == null && value.maximum == null
              ? const TypeResult.success(wire.TypeExpression.timestamp)
              : invalidWire("Timestamp bounds have no wire representation"),
        DurationType() =>
          value.minimum == null && value.maximum == null
              ? const TypeResult.success(wire.TypeExpression.duration)
              : invalidWire("Duration bounds have no wire representation"),
        EnumType() => _encodeEnum(value),
        ListType() => SkirTypeStructureCodec(this).encodeList(value),
        MapType() => SkirTypeStructureCodec(this).encodeMap(value),
        RecordType() => SkirTypeStructureCodec(this).encodeRecord(value),
        NamedType() => encodeReference(
          value.reference,
        ).mapValue(wire.TypeExpression.wrapNamed),
        ParameterType() => TypeResult.success(
          wire.TypeExpression.wrapParameter(value.name),
        ),
      };

  TypeResult<TypeExpression> decodeExpression(wire.TypeExpression? value) {
    if (value == null) return invalidWire("Wire type expression is null");
    return switch (value) {
      wire.TypeExpression_unknown() => invalidWire(
        "Unknown wire type expression",
      ),
      wire.TypeExpression.unit => const TypeResult.success(UnitType()),
      wire.TypeExpression.boolean => const TypeResult.success(BooleanType()),
      wire.TypeExpression.timestamp => const TypeResult.success(
        TimestampType(),
      ),
      wire.TypeExpression.duration => const TypeResult.success(DurationType()),
      wire.TypeExpression_stringWrapper(:final value) =>
        SkirTypeScalarCodec.decodeString(value),
      wire.TypeExpression_bytesWrapper(:final value) => TypeResult.success(
        BytesType(
          minimumLength: value.minimumLength,
          maximumLength: value.maximumLength,
        ),
      ),
      wire.TypeExpression_signedIntegerWrapper(:final value) =>
        SkirTypeScalarCodec.decodeInteger(value, true),
      wire.TypeExpression_unsignedIntegerWrapper(:final value) =>
        SkirTypeScalarCodec.decodeInteger(value, false),
      wire.TypeExpression_floatWrapper(:final value) =>
        SkirTypeScalarCodec.decodeFloat(value),
      wire.TypeExpression_decimalWrapper(:final value) =>
        SkirTypeScalarCodec.decodeDecimal(value),
      wire.TypeExpression_listWrapper(:final value) => SkirTypeStructureCodec(
        this,
      ).decodeList(value),
      wire.TypeExpression_mapWrapper(:final value) => SkirTypeStructureCodec(
        this,
      ).decodeMap(value),
      wire.TypeExpression_recordWrapper(:final value) => SkirTypeStructureCodec(
        this,
      ).decodeRecord(value),
      wire.TypeExpression_enumTypeWrapper(:final value) => _decodeEnum(value),
      wire.TypeExpression_parameterWrapper(:final value) =>
        value.isEmpty
            ? invalidWire("Type parameter name is empty")
            : TypeResult.success(ParameterType(value)),
      wire.TypeExpression_namedWrapper(:final value) => decodeReference(
        value,
      ).mapValue(NamedType.new),
    };
  }

  TypeResult<wire.TypeExpression> _encodeEnum(EnumType value) {
    if (value.values.isEmpty) return invalidWire("Enum has no values");
    final values = <wire.TypedValue>[];
    final diagnostics = <TypeDiagnostic>[];
    final valueCodec = SkirDataValueCodec(this);
    for (final item in value.values) {
      diagnostics.addAll(
        item.validateAgainst(value.valueType, registry: registry),
      );
      final encoded = valueCodec.encode(item);
      diagnostics.addAll(encoded.diagnostics);
      if (encoded.valueOrNull case final result?) values.add(result);
    }
    final valueType = encodeExpression(value.valueType);
    diagnostics.addAll(valueType.diagnostics);
    if (diagnostics.isNotEmpty) return TypeResult.failure(diagnostics);
    return TypeResult.success(
      wire.TypeExpression.createEnumType(
        valueType: valueType.valueOrNull!,
        canonicalValues: values,
      ),
    );
  }

  TypeResult<TypeExpression> _decodeEnum(wire.EnumType value) {
    if (value.canonicalValues.isEmpty) return invalidWire("Enum has no values");
    final values = <DataValue>[];
    final valueType = decodeExpression(value.valueType);
    final diagnostics = <TypeDiagnostic>[...valueType.diagnostics];
    final valueCodec = SkirDataValueCodec(this);
    for (final item in value.canonicalValues) {
      final decoded = valueCodec.decode(item);
      diagnostics.addAll(decoded.diagnostics);
      if (decoded.valueOrNull case final result?) {
        values.add(result);
        if (valueType.valueOrNull case final type?) {
          diagnostics.addAll(result.validateAgainst(type, registry: registry));
        }
      }
    }
    if (diagnostics.isNotEmpty) return TypeResult.failure(diagnostics);
    return TypeResult.success(
      EnumType(valueType: valueType.valueOrNull!, values: values),
    );
  }

  wire.TypeId _encodeTypeId(TypeId id) => switch (id) {
    OptionTypeId() => wire.TypeId.wrapBuiltin(wire.BuiltinTypeId.option),
    SomeTypeId() => wire.TypeId.wrapBuiltin(wire.BuiltinTypeId.some),
    NoneTypeId() => wire.TypeId.wrapBuiltin(wire.BuiltinTypeId.none),
    QualifiedTypeId(:final namespace, :final name) => wire.TypeId.createRealm(
      namespace: namespace,
      name: name,
    ),
  };

  TypeResult<TypeId> _decodeTypeId(wire.TypeId value) => switch (value) {
    wire.TypeId_builtinWrapper(:final value) => switch (value) {
      wire.BuiltinTypeId.option => const TypeResult.success(TypeId.option()),
      wire.BuiltinTypeId.some => const TypeResult.success(TypeId.some()),
      wire.BuiltinTypeId.none => const TypeResult.success(TypeId.none()),
      _ => invalidWire("Unknown builtin type id"),
    },
    wire.TypeId_realmWrapper(:final value) =>
      value.namespace.isEmpty || value.name.isEmpty
          ? invalidWire("Qualified type id is empty")
          : TypeResult.success(
              QualifiedTypeId(namespace: value.namespace, name: value.name),
            ),
    wire.TypeId_unknown() => invalidWire("Unknown type id"),
  };
}
