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
    final value = _decode(source, resolved.valueOrNull!, registry, r"$");
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
  String path,
) => switch (type) {
  AnyType() => _infer(source, path),
  UnitType() when source == null => const UnitValue(),
  UnitType() => throw _invalidJsonValue(path, "null", source),
  BooleanType() when source is bool => BooleanValue(source),
  BooleanType() => throw _invalidJsonValue(path, "a boolean", source),
  StringType() when source is String => StringValue(source),
  StringType() => throw _invalidJsonValue(path, "a string", source),
  BytesType() when source is String => _decodeBytes(source, path),
  BytesType() => throw _invalidJsonValue(
    path,
    "a base64 encoded string",
    source,
  ),
  IntegerType() when source is int => IntegerValue(BigInt.from(source)),
  IntegerType() when source is String => _decodeInteger(source, path),
  IntegerType() => throw _invalidJsonValue(path, "an integer", source),
  FloatType() when source is num => FloatValue(source.toDouble()),
  FloatType() => throw _invalidJsonValue(path, "a number", source),
  DecimalType() when source is num || source is String => DecimalValue(
    source.toString(),
  ),
  DecimalType() => throw _invalidJsonValue(path, "a decimal", source),
  TimestampType() when source is String => _decodeTimestamp(source, path),
  TimestampType() => throw _invalidJsonValue(
    path,
    "an ISO 8601 timestamp string",
    source,
  ),
  DurationType() when source is int => DurationValue(
    Duration(microseconds: source),
  ),
  DurationType() => throw _invalidJsonValue(
    path,
    "a duration in integer microseconds",
    source,
  ),
  EnumType(:final valueType) => _decode(source, valueType, registry, path),
  ListType(:final element) when source is List<Object?> => ListValue([
    for (final (index, item) in source.indexed)
      _decodeResolved(item, element, registry, "$path[$index]"),
  ]),
  ListType() => throw _invalidJsonValue(path, "a list", source),
  MapType(:final key, :final value) when source is Map<String, Object?> =>
    MapValue([
      for (final entry in source.entries)
        DataMapEntry(
          key: _decodeResolved(
            entry.key,
            key,
            registry,
            "$path.keys[${jsonEncode(entry.key)}]",
          ),
          value: _decodeResolved(
            entry.value,
            value,
            registry,
            _jsonPropertyPath(path, entry.key),
          ),
        ),
    ]),
  MapType() => throw _invalidJsonValue(
    path,
    "an object with string keys",
    source,
  ),
  RecordType(:final fields, :final closed)
      when source is Map<String, Object?> =>
    _decodeRecord(source, fields, closed, registry, path),
  RecordType() => throw _invalidJsonValue(
    path,
    "an object with string keys",
    source,
  ),
  NamedType() => _decodeResolved(source, type, registry, path),
  ParameterType(:final name) => throw FormatException(
    "Expected a resolved type at $path, got unresolved parameter $name",
  ),
};

BytesValue _decodeBytes(String source, String path) {
  try {
    return BytesValue(Uint8List.fromList(base64Decode(source)));
  } on FormatException {
    throw _invalidJsonValue(path, "a valid base64 encoded string", source);
  }
}

IntegerValue _decodeInteger(String source, String path) {
  try {
    return IntegerValue(BigInt.parse(source));
  } on FormatException {
    throw _invalidJsonValue(path, "a decimal integer string", source);
  }
}

TimestampValue _decodeTimestamp(String source, String path) {
  try {
    return TimestampValue(DateTime.parse(source));
  } on FormatException {
    throw _invalidJsonValue(path, "an ISO 8601 timestamp string", source);
  }
}

DataValue _decodeResolved(
  Object? source,
  TypeExpression type,
  TypeRegistry registry,
  String path,
) {
  final resolved = _resolve(type, registry);
  if (resolved case TypeFailure(:final diagnostics)) {
    throw FormatException(
      "Expected a resolvable type at $path, got "
      "${diagnostics.map((item) => item.message).join("; ")}",
    );
  }
  return _decode(source, resolved.valueOrNull!, registry, path);
}

RecordValue _decodeRecord(
  Map<String, Object?> source,
  Map<String, TypeField> fields,
  bool closed,
  TypeRegistry registry,
  String path,
) {
  if (closed) {
    final unknown = source.keys.where((key) => !fields.containsKey(key));
    if (unknown.isNotEmpty) {
      final key = unknown.first;
      throw FormatException(
        "Expected a declared record field at ${_jsonPropertyPath(path, key)}, "
        "got an unknown field",
      );
    }
  }
  final decoded = <String, DataValue>{};
  for (final entry in fields.entries) {
    if (source.containsKey(entry.key)) {
      decoded[entry.key] = _decodeResolved(
        source[entry.key],
        entry.value.type,
        registry,
        _jsonPropertyPath(path, entry.key),
      );
      continue;
    }
    final initial = entry.value.initialValue;
    if (initial == null) {
      throw FormatException(
        "Expected a required record field at "
        "${_jsonPropertyPath(path, entry.key)}, got missing",
      );
    }
    decoded[entry.key] = initial;
  }
  return RecordValue(decoded);
}

DataValue _infer(Object? source, String path) => switch (source) {
  null => const UnitValue(),
  final bool value => BooleanValue(value),
  final int value => IntegerValue(BigInt.from(value)),
  final double value => FloatValue(value),
  final String value => StringValue(value),
  final List<Object?> values => ListValue([
    for (final (index, value) in values.indexed) _infer(value, "$path[$index]"),
  ]),
  final Map<String, Object?> values => RecordValue({
    for (final entry in values.entries)
      entry.key: _infer(entry.value, _jsonPropertyPath(path, entry.key)),
  }),
  _ => throw _invalidJsonValue(path, "a JSON value", source),
};

FormatException _invalidJsonValue(
  String path,
  String expected,
  Object? actual,
) => FormatException(
  "Expected $expected at $path, got ${_jsonValueShape(actual)}",
);

String _jsonPropertyPath(String path, String key) {
  if (RegExp(r"^[A-Za-z_][A-Za-z0-9_]*$").hasMatch(key)) {
    return "$path.$key";
  }
  return "$path[${jsonEncode(key)}]";
}

String _jsonValueShape(Object? value) => switch (value) {
  null => "null",
  String() => "a string",
  bool() => "a boolean",
  int() => "an integer",
  double() => "a number",
  List<Object?>() => "a list",
  Map<Object?, Object?>() => "an object",
  _ => "${value.runtimeType}",
};
