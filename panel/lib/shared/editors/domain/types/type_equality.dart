import "package:collection/collection.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Compares type expressions by their semantic structure rather than object
/// identity.
///
/// Record field order is ignored, while ordered constraints such as string
/// patterns and enum values retain their order. Named expressions compare only
/// their resolved references, not the declaration they may resolve to later.
bool typeExpressionsEqual(TypeExpression left, TypeExpression right) {
  if (identical(left, right)) return true;
  if (left.runtimeType != right.runtimeType) return false;
  if (left is AnyType || left is UnitType || left is BooleanType) return true;
  if (left is StringType && right is StringType) {
    return left.minimumLength == right.minimumLength &&
        left.maximumLength == right.maximumLength &&
        const ListEquality<String>().equals(left.patterns, right.patterns);
  }
  if (left is BytesType && right is BytesType) {
    return left.minimumLength == right.minimumLength &&
        left.maximumLength == right.maximumLength;
  }
  if (left is IntegerType && right is IntegerType) {
    return left.width == right.width &&
        left.minimum == right.minimum &&
        left.maximum == right.maximum;
  }

  if (left is FloatType && right is FloatType) {
    return left.width == right.width &&
        left.minimum == right.minimum &&
        left.maximum == right.maximum;
  }

  if (left is DecimalType && right is DecimalType) {
    return left.minimum == right.minimum &&
        left.maximum == right.maximum &&
        left.scale == right.scale;
  }

  if (left is TimestampType && right is TimestampType) {
    return left.minimum == right.minimum && left.maximum == right.maximum;
  }

  if (left is DurationType && right is DurationType) {
    return left.minimum == right.minimum && left.maximum == right.maximum;
  }

  if (left is EnumType && right is EnumType) {
    return typeExpressionsEqual(left.valueType, right.valueType) &&
        const ListEquality<DataValue>().equals(left.values, right.values);
  }

  if (left is ListType && right is ListType) {
    return typeExpressionsEqual(left.element, right.element) &&
        left.minimumLength == right.minimumLength &&
        left.maximumLength == right.maximumLength &&
        left.unique == right.unique;
  }

  if (left is MapType && right is MapType) {
    return typeExpressionsEqual(left.key, right.key) &&
        typeExpressionsEqual(left.value, right.value) &&
        left.minimumLength == right.minimumLength &&
        left.maximumLength == right.maximumLength;
  }

  if (left is RecordType && right is RecordType) {
    return left.closed == right.closed &&
        const SetEquality<String>().equals(
          left.fields.keys.toSet(),
          right.fields.keys.toSet(),
        ) &&
        left.fields.entries.every((entry) {
          final other = right.fields[entry.key];
          return other != null && typeFieldsEqual(entry.value, other);
        });
  }

  if (left is NamedType && right is NamedType) {
    return left.reference == right.reference;
  }

  if (left is ReferenceType && right is ReferenceType) {
    return left.target == right.target;
  }

  if (left is ParameterType && right is ParameterType) {
    return left.name == right.name;
  }

  return false;
}

bool typeFieldsEqual(TypeField left, TypeField right) =>
    left.name == right.name &&
    left.initialValue == right.initialValue &&
    left.defaulted == right.defaulted &&
    typeExpressionsEqual(left.type, right.type);

/// A hash for use with caches and change detection alongside
/// [typeExpressionsEqual]. It follows the same structural rules, including
/// order independent record fields.
extension TypeExpressionStructuralHash on TypeExpression {
  int get structuralHash => switch (this) {
    AnyType() || UnitType() || BooleanType() => runtimeType.hashCode,
    StringType(:final minimumLength, :final maximumLength, :final patterns) =>
      Object.hash(
        runtimeType,
        minimumLength,
        maximumLength,
        Object.hashAll(patterns),
      ),
    BytesType(:final minimumLength, :final maximumLength) => Object.hash(
      runtimeType,
      minimumLength,
      maximumLength,
    ),
    IntegerType(:final width, :final minimum, :final maximum) => Object.hash(
      runtimeType,
      width,
      minimum,
      maximum,
    ),
    FloatType(:final width, :final minimum, :final maximum) => Object.hash(
      runtimeType,
      width,
      minimum,
      maximum,
    ),
    DecimalType(:final minimum, :final maximum, :final scale) => Object.hash(
      runtimeType,
      minimum,
      maximum,
      scale,
    ),
    TimestampType(:final minimum, :final maximum) => Object.hash(
      runtimeType,
      minimum,
      maximum,
    ),
    DurationType(:final minimum, :final maximum) => Object.hash(
      runtimeType,
      minimum,
      maximum,
    ),
    EnumType(:final valueType, :final values) => Object.hash(
      runtimeType,
      valueType.structuralHash,
      Object.hashAll(values),
    ),
    ListType(
      :final element,
      :final minimumLength,
      :final maximumLength,
      :final unique,
    ) =>
      Object.hash(
        runtimeType,
        element.structuralHash,
        minimumLength,
        maximumLength,
        unique,
      ),
    MapType(
      :final key,
      :final value,
      :final minimumLength,
      :final maximumLength,
    ) =>
      Object.hash(
        runtimeType,
        key.structuralHash,
        value.structuralHash,
        minimumLength,
        maximumLength,
      ),
    RecordType(:final fields, :final closed) => Object.hash(
      runtimeType,
      closed,
      Object.hashAllUnordered(
        fields.entries.map(
          (entry) => Object.hash(entry.key, entry.value.structuralHash),
        ),
      ),
    ),
    NamedType(:final reference) => Object.hash(runtimeType, reference),
    ReferenceType(:final target) => Object.hash(runtimeType, target),
    ParameterType(:final name) => Object.hash(runtimeType, name),
  };
}

/// Structural hash for a record field, including its optional initializer.
extension TypeFieldStructuralHash on TypeField {
  int get structuralHash =>
      Object.hash(name, initialValue, defaulted, type.structuralHash);
}
