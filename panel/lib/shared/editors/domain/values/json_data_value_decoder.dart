import "dart:convert";
import "dart:typed_data";

import "package:typewriter_panel/typewriter_panel.dart";

TypeResult<DataValue> decodeJsonDataValue(
  Object? source,
  TypeExpression type, {
  required TypeRegistry registry,
}) {
  final resolved = _resolve(type, registry);
  if (resolved case TypeFailure(:final diagnostics)) {
    return TypeResult.failure(diagnostics);
  }
  try {
    final value = _decode(source, resolved.valueOrNull!, registry);
    final diagnostics = value.validateAgainst(type, registry: registry);
    return diagnostics.isEmpty
        ? TypeResult.success(value)
        : TypeResult.failure(diagnostics);
  } on FormatException catch (error) {
    return TypeResult.failure([
      TypeDiagnostic(
        code: TypeDiagnosticCode.invalidValue,
        message: error.message,
      ),
    ]);
  }
}

TypeResult<TypeExpression> _resolve(
  TypeExpression type,
  TypeRegistry registry,
) {
  if (type case NamedType()) {
    final result = registry.resolve(type);
    if (result case TypeFailure(:final diagnostics)) {
      return TypeResult.failure(diagnostics);
    }
    return _resolve(result.valueOrNull!.representation, registry);
  }
  return TypeResult.success(type);
}

DataValue _decode(
  Object? source,
  TypeExpression type,
  TypeRegistry registry,
) => switch (type) {
  AnyType() => _infer(source),
  UnitType() when source == null => const UnitValue(),
  UnitType() => throw const FormatException("Expected a null value"),
  BooleanType() when source is bool => BooleanValue(source),
  BooleanType() => throw const FormatException("Expected a boolean value"),
  StringType() when source is String => StringValue(source),
  StringType() => throw const FormatException("Expected a string value"),
  BytesType() when source is String => BytesValue(
    Uint8List.fromList(base64Decode(source)),
  ),
  BytesType() => throw const FormatException("Expected base64 encoded bytes"),
  IntegerType() when source is int => IntegerValue(BigInt.from(source)),
  IntegerType() when source is String => IntegerValue(BigInt.parse(source)),
  IntegerType() => throw const FormatException("Expected an integer value"),
  FloatType() when source is num => FloatValue(source.toDouble()),
  FloatType() => throw const FormatException("Expected a numeric value"),
  DecimalType() when source is num || source is String => DecimalValue(
    source.toString(),
  ),
  DecimalType() => throw const FormatException("Expected a decimal value"),
  TimestampType() when source is String => TimestampValue(
    DateTime.parse(source),
  ),
  TimestampType() => throw const FormatException("Expected a timestamp value"),
  DurationType() when source is int => DurationValue(
    Duration(microseconds: source),
  ),
  DurationType() => throw const FormatException(
    "Expected a duration in microseconds",
  ),
  EnumType(:final valueType) => _decode(source, valueType, registry),
  ListType(:final element) when source is List<Object?> => ListValue(
    source.map((item) => _decodeResolved(item, element, registry)).toList(),
  ),
  ListType() => throw const FormatException("Expected a list value"),
  MapType(:final key, :final value) when source is Map<String, Object?> =>
    MapValue([
      for (final entry in source.entries)
        DataMapEntry(
          key: _decodeResolved(entry.key, key, registry),
          value: _decodeResolved(entry.value, value, registry),
        ),
    ]),
  MapType() => throw const FormatException("Expected an object value"),
  RecordType(:final fields, :final closed)
      when source is Map<String, Object?> =>
    _decodeRecord(source, fields, closed, registry),
  RecordType() => throw const FormatException("Expected an object value"),
  NamedType() => _decodeResolved(source, type, registry),
  ParameterType(:final name) => throw FormatException(
    "Cannot decode unresolved parameter $name",
  ),
};

DataValue _decodeResolved(
  Object? source,
  TypeExpression type,
  TypeRegistry registry,
) {
  final resolved = _resolve(type, registry);
  if (resolved case TypeFailure(:final diagnostics)) {
    throw FormatException(diagnostics.map((item) => item.message).join("; "));
  }
  return _decode(source, resolved.valueOrNull!, registry);
}

RecordValue _decodeRecord(
  Map<String, Object?> source,
  Map<String, TypeField> fields,
  bool closed,
  TypeRegistry registry,
) {
  if (closed) {
    final unknown = source.keys.where((key) => !fields.containsKey(key));
    if (unknown.isNotEmpty) {
      throw FormatException("Unknown field ${unknown.first}");
    }
  }
  final decoded = <String, DataValue>{};
  for (final entry in fields.entries) {
    if (source.containsKey(entry.key)) {
      decoded[entry.key] = _decodeResolved(
        source[entry.key],
        entry.value.type,
        registry,
      );
      continue;
    }
    final initial = entry.value.initialValue;
    if (initial == null) {
      throw FormatException("Missing field ${entry.key}");
    }
    decoded[entry.key] = initial;
  }
  return RecordValue(decoded);
}

DataValue _infer(Object? source) => switch (source) {
  null => const UnitValue(),
  final bool value => BooleanValue(value),
  final int value => IntegerValue(BigInt.from(value)),
  final double value => FloatValue(value),
  final String value => StringValue(value),
  final List<Object?> values => ListValue(values.map(_infer).toList()),
  final Map<String, Object?> values => RecordValue({
    for (final entry in values.entries) entry.key: _infer(entry.value),
  }),
  _ => throw FormatException("Unsupported JSON value ${source.runtimeType}"),
};
