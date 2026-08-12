import "dart:typed_data";

import "package:typewriter_panel/typewriter_panel.dart";

extension TypeExpressionInitialValue on TypeExpression {
  TypeResult<DataValue> createInitialValue({TypeRegistry? registry}) {
    final value = _createInitialValue(registry);
    if (value case TypeFailure()) return value;
    final diagnostics = value.valueOrNull!.validateAgainst(
      this,
      registry: registry,
    );
    return diagnostics.isEmpty ? value : TypeResult.failure(diagnostics);
  }
}

extension on TypeExpression {
  TypeResult<DataValue> _createInitialValue(TypeRegistry? registry) {
    final type = this;
    if (type is AnyType || type is ParameterType) {
      return _failure("The type must be resolved before creating a value");
    }
    if (type is UnitType) return const TypeResult.success(UnitValue());
    if (type is BooleanType) {
      return const TypeResult.success(BooleanValue(false));
    }
    if (type is StringType) {
      return TypeResult.success(
        StringValue(List.filled(type.minimumLength ?? 0, " ").join()),
      );
    }
    if (type is BytesType) {
      return TypeResult.success(BytesValue(Uint8List(type.minimumLength ?? 0)));
    }
    if (type is IntegerType) {
      final minimum = type.minimum ?? type.width.minimum;
      final maximum = type.maximum ?? type.width.maximum;
      final value = BigInt.zero < minimum
          ? minimum
          : BigInt.zero > maximum
          ? maximum
          : BigInt.zero;
      return TypeResult.success(IntegerValue(value));
    }
    if (type is FloatType) {
      final minimum = type.minimum ?? double.negativeInfinity;
      final maximum = type.maximum ?? double.infinity;
      final value = 0.0.clamp(minimum, maximum);
      return TypeResult.success(FloatValue(value));
    }
    if (type is DecimalType) return TypeResult.success(DecimalValue("0"));
    if (type is TimestampType) {
      return TypeResult.success(
        TimestampValue(type.minimum ?? DateTime.fromMillisecondsSinceEpoch(0)),
      );
    }
    if (type is DurationType) {
      return TypeResult.success(DurationValue(type.minimum ?? Duration.zero));
    }
    if (type is EnumType) {
      if (type.values.isEmpty) return _failure("An enum requires a value");
      return TypeResult.success(type.values.first);
    }
    if (type is ListType) return type._createListValue(registry);
    if (type is MapType) return type._createMapValue();
    if (type is RecordType) return type._createRecordValue(registry);
    if (type is NamedType) {
      if (registry == null) {
        return _failure("A registry is required to create a named value");
      }
      final resolved = registry.resolve(type);
      if (resolved case TypeFailure(:final diagnostics)) {
        return TypeResult.failure(diagnostics);
      }
      final resolvedType = resolved.valueOrNull!;
      if (!resolvedType.isConcrete) {
        return type.reference._createAbstractValue(registry);
      }
      return resolvedType.representation._createInitialValue(registry);
    }
    return _failure("The type does not have an initializer");
  }
}

extension on ListType {
  TypeResult<DataValue> _createListValue(TypeRegistry? registry) {
    final values = <DataValue>[];
    for (var index = 0; index < (minimumLength ?? 0); index++) {
      final value = element._createInitialValue(registry);
      if (value case TypeFailure()) return value;
      values.add(value.valueOrNull!);
    }
    return TypeResult.success(ListValue(values));
  }
}

extension on MapType {
  TypeResult<DataValue> _createMapValue() {
    if ((minimumLength ?? 0) > 0) {
      return _failure("A nonempty map requires an explicit initializer");
    }
    return TypeResult.success(MapValue(const []));
  }
}

extension on RecordType {
  TypeResult<DataValue> _createRecordValue(TypeRegistry? registry) {
    final values = <String, DataValue>{};
    for (final field in fields.values) {
      if (field.initialValue case final initial?) {
        values[field.name] = initial;
        continue;
      }
      final value = field.type._createInitialValue(registry);
      if (value case TypeFailure()) return value;
      values[field.name] = value.valueOrNull!;
    }
    return TypeResult.success(RecordValue(values));
  }
}

extension on ResolvedTypeRef {
  TypeResult<DataValue> _createAbstractValue(TypeRegistry registry) {
    if (id != const TypeId.option()) {
      return _failure(
        "An abstract type requires an explicit concrete initializer",
      );
    }
    final concrete = standardTypeRefs.noneOf(arguments.single);
    final resolved = registry.resolveExact(concrete);
    if (resolved case TypeFailure(:final diagnostics)) {
      return TypeResult.failure(diagnostics);
    }
    return TypeResult.success(
      PolymorphicValue(concreteType: concrete, value: const UnitValue()),
    );
  }
}

TypeFailure<DataValue> _failure(String message) => TypeFailure([
  TypeDiagnostic(code: TypeDiagnosticCode.invalidConstraint, message: message),
]);
