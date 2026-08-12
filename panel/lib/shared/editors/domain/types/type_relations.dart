import "package:typewriter_panel/typewriter_panel.dart";

extension TypeExpressionAssignability on TypeExpression {
  bool isStructurallyAssignableTo(
    TypeExpression target,
    TypeRegistry registry,
  ) {
    final source = this;
    if (target is AnyType) return true;
    if (typeExpressionsEqual(source, target)) return true;
    if (source is NamedType && target is NamedType) {
      return source._isReferenceAssignableTo(target, registry);
    }
    if (source is NamedType) {
      final resolved = registry.resolve(source).valueOrNull;
      return resolved != null &&
          resolved.representation.isStructurallyAssignableTo(target, registry);
    }
    if (target is NamedType) return false;

    if (source is StringType && target is StringType) {
      return _rangeContained(
            source.minimumLength,
            source.maximumLength,
            target.minimumLength,
            target.maximumLength,
          ) &&
          target.patterns.every(source.patterns.contains);
    }
    if (source is BytesType && target is BytesType) {
      return _rangeContained(
        source.minimumLength,
        source.maximumLength,
        target.minimumLength,
        target.maximumLength,
      );
    }
    if (source is IntegerType && target is IntegerType) {
      return source.width.minimum >= target.width.minimum &&
          source.width.maximum <= target.width.maximum &&
          (target.minimum == null ||
              (source.minimum ?? source.width.minimum) >= target.minimum!) &&
          (target.maximum == null ||
              (source.maximum ?? source.width.maximum) <= target.maximum!);
    }
    if (source is FloatType && target is FloatType) {
      return (source.width == target.width ||
              target.width == FloatWidth.float64) &&
          (target.minimum == null ||
              (source.minimum ?? double.negativeInfinity) >= target.minimum!) &&
          (target.maximum == null ||
              (source.maximum ?? double.infinity) <= target.maximum!);
    }
    if (source is DecimalType && target is DecimalType) {
      return source._decimalRangeContainedBy(target) &&
          (target.scale == null ||
              source.scale != null && source.scale! <= target.scale!);
    }
    if (source is TimestampType && target is TimestampType) {
      return _comparableRangeContained(
        source.minimum,
        source.maximum,
        target.minimum,
        target.maximum,
      );
    }
    if (source is DurationType && target is DurationType) {
      return _comparableRangeContained(
        source.minimum,
        source.maximum,
        target.minimum,
        target.maximum,
      );
    }
    if (source is EnumType && target is EnumType) {
      return source.valueType.isStructurallyAssignableTo(
            target.valueType,
            registry,
          ) &&
          source.values.every(target.values.contains);
    }
    if (source is ListType && target is ListType) {
      return typeExpressionsEqual(source.element, target.element) &&
          _rangeContained(
            source.minimumLength,
            source.maximumLength,
            target.minimumLength,
            target.maximumLength,
          ) &&
          (!target.unique || source.unique);
    }
    if (source is MapType && target is MapType) {
      return typeExpressionsEqual(source.key, target.key) &&
          typeExpressionsEqual(source.value, target.value) &&
          _rangeContained(
            source.minimumLength,
            source.maximumLength,
            target.minimumLength,
            target.maximumLength,
          );
    }
    if (source is RecordType && target is RecordType) {
      return source._isRecordAssignableTo(target, registry);
    }
    return false;
  }
}

extension on NamedType {
  bool _isReferenceAssignableTo(NamedType target, TypeRegistry registry) {
    final sourceType = registry.resolve(this).valueOrNull;
    if (sourceType == null) return false;
    final sameDeclaration =
        reference.id == target.reference.id &&
        reference.revision == target.reference.revision;
    if (!sameDeclaration && !sourceType.ancestors.contains(target.reference)) {
      return false;
    }
    if (!sameDeclaration) return true;
    final definition = registry.definition(reference);
    if (definition == null ||
        reference.arguments.length != target.reference.arguments.length) {
      return false;
    }
    for (final entry in definition.parameters.indexed) {
      final sourceArgument = reference.arguments[entry.$1];
      final targetArgument = target.reference.arguments[entry.$1];
      final valid = switch (entry.$2.variance) {
        TypeVariance.invariant => typeExpressionsEqual(
          sourceArgument,
          targetArgument,
        ),
        TypeVariance.covariant => sourceArgument.isStructurallyAssignableTo(
          targetArgument,
          registry,
        ),
        TypeVariance.contravariant => targetArgument.isStructurallyAssignableTo(
          sourceArgument,
          registry,
        ),
      };
      if (!valid) return false;
    }
    return true;
  }
}

extension on RecordType {
  bool _isRecordAssignableTo(RecordType target, TypeRegistry registry) {
    for (final targetField in target.fields.values) {
      final sourceField = fields[targetField.name];
      if (sourceField == null) return false;
      if (!sourceField.type.isStructurallyAssignableTo(
        targetField.type,
        registry,
      )) {
        return false;
      }
    }
    return true;
  }
}

bool _rangeContained(
  int? sourceMinimum,
  int? sourceMaximum,
  int? targetMinimum,
  int? targetMaximum,
) =>
    (targetMinimum == null ||
        (sourceMinimum != null && sourceMinimum >= targetMinimum)) &&
    (targetMaximum == null ||
        (sourceMaximum != null && sourceMaximum <= targetMaximum));

extension on DecimalType {
  bool _decimalRangeContainedBy(DecimalType target) =>
      (target.minimum == null ||
          minimum != null &&
              compareDecimalStrings(minimum!, target.minimum!) >= 0) &&
      (target.maximum == null ||
          maximum != null &&
              compareDecimalStrings(maximum!, target.maximum!) <= 0);
}

bool _comparableRangeContained<T extends Comparable<T>>(
  T? sourceMinimum,
  T? sourceMaximum,
  T? targetMinimum,
  T? targetMaximum,
) =>
    (targetMinimum == null ||
        sourceMinimum != null && sourceMinimum.compareTo(targetMinimum) >= 0) &&
    (targetMaximum == null ||
        sourceMaximum != null && sourceMaximum.compareTo(targetMaximum) <= 0);

extension TypeExpressionProjection on Iterable<TypeExpression> {
  TypeResult<TypeExpression> commonEditableProjection() {
    final values = toList();
    if (values.isEmpty) {
      return TypeResult.failure([
        const TypeDiagnostic(
          code: TypeDiagnosticCode.invalidConstraint,
          message: "At least one type is required",
        ),
      ]);
    }
    if (values.every((value) => typeExpressionsEqual(value, values.first))) {
      return TypeResult.success(values.first);
    }
    if (values.every((value) => value is RecordType)) {
      return values.cast<RecordType>()._commonRecord();
    }
    return TypeResult.failure([
      const TypeDiagnostic(
        code: TypeDiagnosticCode.invalidConstraint,
        message: "Types have no common editable projection",
      ),
    ]);
  }
}

extension on Iterable<RecordType> {
  TypeResult<TypeExpression> _commonRecord() {
    final records = toList();
    final names = records
        .map((record) => record.fields.keys.toSet())
        .reduce((left, right) => left.intersection(right));
    final fields = <String, TypeField>{};
    for (final name in names) {
      final candidates = records.map((record) => record.fields[name]!).toList();
      if (!candidates.every(
        (field) => typeExpressionsEqual(field.type, candidates.first.type),
      )) {
        continue;
      }
      fields[name] = TypeField(
        name: name,
        type: candidates.first.type,
        initialValue:
            candidates.map((field) => field.initialValue).toSet().length == 1
            ? candidates.first.initialValue
            : null,
      );
    }
    if (fields.isEmpty) {
      return TypeResult.failure([
        const TypeDiagnostic(
          code: TypeDiagnosticCode.invalidConstraint,
          message: "Records have no common editable fields",
        ),
      ]);
    }
    return TypeResult.success(RecordType(fields: fields));
  }
}
