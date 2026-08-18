import "package:typewriter_panel/typewriter_panel.dart";

extension ConversionRuleEvaluation on ConversionRule {
  ConversionResult evaluate(DataValue input) {
    return switch (this) {
      InputConversionRule() => ConversionResult.success(input),
      InheritanceUpcastRule() => ConversionResult.success(input),
      ValidatedDowncastRule() => _failure(
        "Validated downcast requires target validation",
      ),
      ScalarConversionRule() => (this as ScalarConversionRule).convert(input),
      FieldConversionRule() => (this as FieldConversionRule).convert(input),
      RecordConversionRule() => (this as RecordConversionRule).convert(input),
      ListConversionRule() => (this as ListConversionRule).convert(input),
      PolymorphicConversionRule() =>
        (this as PolymorphicConversionRule).convert(input),
      ComposedConversionRule(:final rules) => rules.convert(input),
      RealmConversionRule() => _unavailable(),
      RecordProjectionConversionRule() ||
      RecordConstructionConversionRule() ||
      CollectionMappingConversionRule() ||
      PolymorphicMatchingConversionRule() ||
      ConversionCompositionIdsRule() => _failure(
        "Referenced conversion rules require a conversion graph",
      ),
    };
  }
}

ConversionUnavailable _unavailable() => ConversionUnavailable([
  TypeDiagnostic(
    code: TypeDiagnosticCode.conversionFailed,
    message: "Realm conversion execution is unavailable",
  ),
]);

extension on ScalarConversionRule {
  ConversionResult convert(DataValue input) {
    try {
      final value = switch ((conversion, input)) {
        (ScalarConversion.integerToFloat, IntegerValue(:final value)) =>
          FloatValue(value.toDouble()),
        (ScalarConversion.integerToDecimal, IntegerValue(:final value)) =>
          DecimalValue(value.toString()),
        (ScalarConversion.floatToInteger, FloatValue(:final value)) =>
          IntegerValue(BigInt.from(value)),
        (ScalarConversion.floatToDecimal, FloatValue(:final value)) =>
          DecimalValue(value.toString()),
        (ScalarConversion.decimalToInteger, DecimalValue(:final value)) =>
          IntegerValue(BigInt.parse(value)),
        (ScalarConversion.decimalToFloat, DecimalValue(:final value)) =>
          FloatValue(double.parse(value)),
        _ => null,
      };
      if (value != null) return ConversionResult.success(value);
    } on FormatException {
      return _failure("Scalar conversion could not parse its input");
    }
    return _failure("Scalar conversion does not accept ${input.runtimeType}");
  }
}

extension on FieldConversionRule {
  ConversionResult convert(DataValue input) {
    if (input is! RecordValue) {
      return _failure("Field conversion requires a record");
    }
    final value = input.fields[name];
    if (value == null) return _failure("Field '$name' is absent");
    return rule.evaluate(value);
  }
}

extension on RecordConversionRule {
  ConversionResult convert(DataValue input) {
    final values = <String, DataValue>{};
    for (final entry in fields.entries) {
      final result = entry.value.evaluate(input);
      if (result case ConversionFailure()) return result;
      if (result case ConversionUnavailable()) return result;
      values[entry.key] = (result as ConversionSuccess).value;
    }
    return ConversionResult.success(RecordValue(values));
  }
}

extension on ListConversionRule {
  ConversionResult convert(DataValue input) {
    if (input is! ListValue) return _failure("List conversion requires a list");
    final values = <DataValue>[];
    for (final value in input.values) {
      final result = element.evaluate(value);
      if (result case ConversionFailure()) return result;
      if (result case ConversionUnavailable()) return result;
      values.add((result as ConversionSuccess).value);
    }
    return ConversionResult.success(ListValue(values));
  }
}

extension on PolymorphicConversionRule {
  ConversionResult convert(DataValue input) {
    if (input is! PolymorphicValue) {
      return _failure("Polymorphic conversion requires a tagged value");
    }
    ConversionPolymorphicCase? selected;
    for (final candidate in cases) {
      if (candidate.sourceType == input.concreteType) {
        selected = candidate;
        break;
      }
    }
    if (selected == null) {
      return _failure("Concrete type '${input.concreteType}' is not mapped");
    }
    final result = selected.rule.evaluate(input.value);
    if (result case ConversionSuccess(:final value)) {
      return ConversionResult.success(
        PolymorphicValue(concreteType: selected.targetType, value: value),
      );
    }
    return result;
  }
}

extension on List<ConversionRule> {
  ConversionResult convert(DataValue input) {
    var current = input;
    for (final rule in this) {
      final result = rule.evaluate(current);
      if (result case ConversionFailure()) return result;
      if (result case ConversionUnavailable()) return result;
      current = (result as ConversionSuccess).value;
    }
    return ConversionResult.success(current);
  }
}

ConversionFailure _failure(String message) => ConversionFailure([
  TypeDiagnostic(code: TypeDiagnosticCode.conversionFailed, message: message),
]);
