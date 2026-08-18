import "package:collection/collection.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "type_special_value_validation.dart";

extension DataValueValidation on DataValue {
  List<TypeDiagnostic> validateAgainst(
    TypeExpression type, {
    DataPath path = DataPath.root,
    TypeRegistry? registry,
  }) {
    final value = this;
    if (type is AnyType) return const [];
    if (type is EnumType) {
      final diagnostics = validateAgainst(
        type.valueType,
        path: path,
        registry: registry,
      );
      if (diagnostics.isNotEmpty) return diagnostics;
      if (!type.values.contains(value)) {
        return [_invalid(path, "Value is not a member of the enum")];
      }
      return const [];
    }
    if (type is NamedType) {
      return _validateNamed(type, path, registry);
    }

    if (value is UnitValue && type is UnitType ||
        value is BooleanValue && type is BooleanType) {
      return const [];
    }
    if (value is StringValue && type is StringType) {
      return value._validateAgainst(type, path);
    }
    if (value is BytesValue && type is BytesType) {
      return _validateLength(
        value.value.length,
        type.minimumLength,
        type.maximumLength,
        path,
      );
    }
    if (value is IntegerValue && type is IntegerType) {
      return value._validateAgainst(type, path);
    }
    if (value is FloatValue && type is FloatType) {
      return value.validateFloatAgainst(type, path);
    }
    if (value is DecimalValue && type is DecimalType) {
      return value.validateDecimalAgainst(type, path);
    }
    if (value is TimestampValue && type is TimestampType) {
      return _validateComparable(value.value, type.minimum, type.maximum, path);
    }
    if (value is DurationValue && type is DurationType) {
      if (value.value.inMicroseconds.remainder(1000) != 0) {
        return [
          _invalid(path, "Duration must have exact millisecond precision"),
        ];
      }
      return _validateComparable(value.value, type.minimum, type.maximum, path);
    }
    if (value is ListValue && type is ListType) {
      return value._validateAgainst(type, path, registry);
    }
    if (value is MapValue && type is MapType) {
      return value._validateAgainst(type, path, registry);
    }
    if (value is RecordValue && type is RecordType) {
      return value._validateAgainst(type, path, registry);
    }
    return [
      _invalid(
        path,
        "${value.runtimeType} is not valid for ${type.runtimeType}",
      ),
    ];
  }
}

extension on StringValue {
  List<TypeDiagnostic> _validateAgainst(StringType type, DataPath path) => [
    ..._validateLength(
      value.runes.length,
      type.minimumLength,
      type.maximumLength,
      path,
    ),
    for (final pattern in type.patterns)
      if (!RegExp(pattern).hasMatch(value))
        _invalid(path, "String does not match '$pattern'"),
  ];
}

extension on IntegerValue {
  List<TypeDiagnostic> _validateAgainst(IntegerType type, DataPath path) {
    final value = this;
    final minimum = type.minimum ?? type.width.minimum;
    final maximum = type.maximum ?? type.width.maximum;
    if (value.value < minimum || value.value > maximum) {
      return [_invalid(path, "Integer must be between $minimum and $maximum")];
    }
    return const [];
  }
}

extension on ListValue {
  List<TypeDiagnostic> _validateAgainst(
    ListType type,
    DataPath path,
    TypeRegistry? registry,
  ) {
    final value = this;
    final diagnostics = _validateLength(
      value.values.length,
      type.minimumLength,
      type.maximumLength,
      path,
    );
    if (type.unique && value.values.toSet().length != value.values.length) {
      diagnostics.add(_invalid(path, "List values must be unique"));
    }
    for (final entry in value.values.indexed) {
      diagnostics.addAll(
        entry.$2.validateAgainst(
          type.element,
          path: path.index(entry.$1),
          registry: registry,
        ),
      );
    }
    return diagnostics;
  }
}

extension on MapValue {
  List<TypeDiagnostic> _validateAgainst(
    MapType type,
    DataPath path,
    TypeRegistry? registry,
  ) {
    final value = this;
    final diagnostics = _validateLength(
      value.entries.length,
      type.minimumLength,
      type.maximumLength,
      path,
    );
    final keys = <DataValue>{};
    for (final entry in value.entries) {
      if (!keys.add(entry.key)) {
        diagnostics.add(_invalid(path, "Map keys must be unique"));
      }
      diagnostics
        ..addAll(
          entry.key.validateAgainst(
            type.key,
            path: path.mapKey(entry.key),
            registry: registry,
          ),
        )
        ..addAll(
          entry.value.validateAgainst(
            type.value,
            path: path.mapKey(entry.key),
            registry: registry,
          ),
        );
    }
    return diagnostics;
  }
}

extension on RecordValue {
  List<TypeDiagnostic> _validateAgainst(
    RecordType type,
    DataPath path,
    TypeRegistry? registry,
  ) {
    final value = this;
    final diagnostics = <TypeDiagnostic>[];
    for (final field in type.fields.values) {
      final fieldValue = value.fields[field.name];
      if (fieldValue == null) {
        diagnostics.add(
          TypeDiagnostic(
            code: TypeDiagnosticCode.missingField,
            message: "Required field '${field.name}' is absent",
            path: path.field(field.name),
          ),
        );
        continue;
      }
      diagnostics.addAll(
        fieldValue.validateAgainst(
          field.type,
          path: path.field(field.name),
          registry: registry,
        ),
      );
    }
    if (!type.closed) return diagnostics;
    for (final name in value.fields.keys.whereNot(type.fields.containsKey)) {
      diagnostics.add(
        TypeDiagnostic(
          code: TypeDiagnosticCode.unknownField,
          message: "Field '$name' is not declared",
          path: path.field(name),
        ),
      );
    }
    return diagnostics;
  }
}

List<TypeDiagnostic> _validateLength(
  int length,
  int? minimum,
  int? maximum,
  DataPath path,
) {
  if (minimum != null && length < minimum) {
    return [_invalid(path, "Length must be at least $minimum")];
  }
  if (maximum != null && length > maximum) {
    return [_invalid(path, "Length must be at most $maximum")];
  }
  return [];
}

List<TypeDiagnostic> _validateComparable<T extends Comparable<T>>(
  T value,
  T? minimum,
  T? maximum,
  DataPath path,
) {
  if (minimum != null && value.compareTo(minimum) < 0) {
    return [_invalid(path, "Value is below its minimum")];
  }
  if (maximum != null && value.compareTo(maximum) > 0) {
    return [_invalid(path, "Value exceeds its maximum")];
  }
  return const [];
}

TypeDiagnostic _invalid(DataPath path, String message) => TypeDiagnostic(
  code: TypeDiagnosticCode.invalidValue,
  message: message,
  path: path,
);
