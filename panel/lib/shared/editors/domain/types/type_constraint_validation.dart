import "dart:collection";

import "package:typewriter_panel/typewriter_panel.dart";

part "type_constraint_validation_rules.dart";

extension TypeExpressionConstraintValidation on TypeExpression {
  List<TypeDiagnostic> validateConstraints(
    Set<String> allowedParameters, {
    DataPath path = DataPath.root,
  }) => _validateConstraintTree(allowedParameters, path, HashSet.identity());

  List<TypeDiagnostic> _validateConstraintTree(
    Set<String> parameters,
    DataPath path,
    Set<TypeExpression> active,
  ) {
    if (!active.add(this)) {
      return [_invalid("Type constraints contain structural recursion", path)];
    }
    final diagnostics = switch (this) {
      StringType() => (this as StringType).validateOwnConstraints(path),
      BytesType() => _lengthBounds(
        (this as BytesType).minimumLength,
        (this as BytesType).maximumLength,
        "Byte length",
        path,
      ),
      IntegerType() => (this as IntegerType).validateOwnConstraints(path),
      FloatType() => (this as FloatType).validateOwnConstraints(path),
      DecimalType() => (this as DecimalType).validateOwnConstraints(path),
      TimestampType() => _comparableBounds(
        (this as TimestampType).minimum,
        (this as TimestampType).maximum,
        "Timestamp",
        path,
      ),
      DurationType() => (this as DurationType).validateOwnConstraints(path),
      EnumType() => [
        ...(this as EnumType).valueType._validateConstraintTree(
          parameters,
          path,
          active,
        ),
        ...(this as EnumType).validateOwnConstraints(path),
      ],
      ListType() => [
        ..._lengthBounds(
          (this as ListType).minimumLength,
          (this as ListType).maximumLength,
          "List length",
          path,
        ),
        ...(this as ListType).element._validateConstraintTree(
          parameters,
          path,
          active,
        ),
      ],
      MapType() => [
        ..._lengthBounds(
          (this as MapType).minimumLength,
          (this as MapType).maximumLength,
          "Map length",
          path,
        ),
        ...(this as MapType).key._validateConstraintTree(
          parameters,
          path,
          active,
        ),
        ...(this as MapType).value._validateConstraintTree(
          parameters,
          path,
          active,
        ),
      ],
      RecordType() => (this as RecordType)._validateFields(
        parameters,
        path,
        active,
      ),
      NamedType() => [
        for (final argument in (this as NamedType).reference.arguments)
          ...argument._validateConstraintTree(parameters, path, active),
      ],
      ParameterType() =>
        parameters.contains((this as ParameterType).name)
            ? const <TypeDiagnostic>[]
            : [
                _invalid(
                  "Type parameter '${(this as ParameterType).name}' is not declared",
                  path,
                ),
              ],
      AnyType() || UnitType() || BooleanType() => const <TypeDiagnostic>[],
    };
    active.remove(this);
    return diagnostics;
  }

  bool get containsParameter => switch (this) {
    ParameterType() => true,
    ListType(:final element) => element.containsParameter,
    MapType(:final key, :final value) =>
      key.containsParameter || value.containsParameter,
    RecordType(:final fields) => fields.values.any(
      (field) => field.type.containsParameter,
    ),
    NamedType(:final reference) => reference.arguments.any(
      (argument) => argument.containsParameter,
    ),
    EnumType(:final valueType) => valueType.containsParameter,
    _ => false,
  };

  bool get requiresRegistry => switch (this) {
    NamedType() => true,
    ListType(:final element) => element.requiresRegistry,
    MapType(:final key, :final value) =>
      key.requiresRegistry || value.requiresRegistry,
    RecordType(:final fields) => fields.values.any(
      (field) => field.type.requiresRegistry,
    ),
    EnumType(:final valueType) => valueType.requiresRegistry,
    _ => false,
  };

  Set<String> get parameterUses => switch (this) {
    ParameterType(:final name) => {name},
    ListType(:final element) => element.parameterUses,
    MapType(:final key, :final value) => {
      ...key.parameterUses,
      ...value.parameterUses,
    },
    RecordType(:final fields) => {
      for (final field in fields.values) ...field.type.parameterUses,
    },
    EnumType(:final valueType) => valueType.parameterUses,
    NamedType(:final reference) => {
      for (final argument in reference.arguments) ...argument.parameterUses,
    },
    _ => const {},
  };

  List<TypeDiagnostic> validateResolvedEnums(
    TypeRegistry registry, {
    DataPath path = DataPath.root,
  }) => switch (this) {
    EnumType(:final valueType, :final values) => [
      for (final value in values)
        ...value.validateAgainst(valueType, path: path, registry: registry),
      ...valueType.validateResolvedEnums(registry, path: path),
    ],
    ListType(:final element) => element.validateResolvedEnums(
      registry,
      path: path,
    ),
    MapType(:final key, :final value) => [
      ...key.validateResolvedEnums(registry, path: path),
      ...value.validateResolvedEnums(registry, path: path),
    ],
    RecordType(:final fields) => [
      for (final field in fields.values)
        ...field.type.validateResolvedEnums(
          registry,
          path: path.field(field.name),
        ),
    ],
    NamedType(:final reference) => [
      for (final argument in reference.arguments)
        ...argument.validateResolvedEnums(registry, path: path),
    ],
    _ => const [],
  };
}

extension StringTypeConstraintValidation on StringType {
  List<TypeDiagnostic> validateOwnConstraints(DataPath path) => [
    ..._lengthBounds(minimumLength, maximumLength, "String length", path),
    for (final pattern in patterns) ...pattern._validatePattern("String", path),
  ];
}

extension IntegerTypeConstraintValidation on IntegerType {
  List<TypeDiagnostic> validateOwnConstraints(DataPath path) => [
    if (minimum case final value?
        when value < width.minimum || value > width.maximum)
      _invalid("Integer minimum exceeds its width", path),
    if (maximum case final value?
        when value < width.minimum || value > width.maximum)
      _invalid("Integer maximum exceeds its width", path),
    if (minimum != null && maximum != null && minimum! > maximum!)
      _invalid("Integer bounds are contradictory", path),
  ];
}

extension FloatTypeConstraintValidation on FloatType {
  List<TypeDiagnostic> validateOwnConstraints(DataPath path) {
    const float32Maximum = 3.4028234663852886e38;
    return [
      if (minimum case final value? when !value.isFinite)
        _invalid("Float minimum must be finite", path),
      if (maximum case final value? when !value.isFinite)
        _invalid("Float maximum must be finite", path),
      if (width == FloatWidth.float32 &&
          minimum != null &&
          minimum!.abs() > float32Maximum)
        _invalid("Float minimum exceeds its width", path),
      if (width == FloatWidth.float32 &&
          maximum != null &&
          maximum!.abs() > float32Maximum)
        _invalid("Float maximum exceeds its width", path),
      if (minimum != null && maximum != null && minimum! > maximum!)
        _invalid("Float bounds are contradictory", path),
    ];
  }
}

extension DecimalTypeConstraintValidation on DecimalType {
  List<TypeDiagnostic> validateOwnConstraints(DataPath path) {
    final minimumValid = minimum == null || decimalPattern.hasMatch(minimum!);
    final maximumValid = maximum == null || decimalPattern.hasMatch(maximum!);
    return [
      if (scale != null && scale! < 0)
        _invalid("Decimal scale must not be negative", path),
      if (!minimumValid) _invalid("Decimal minimum is malformed", path),
      if (!maximumValid) _invalid("Decimal maximum is malformed", path),
      if (minimumValid &&
          maximumValid &&
          minimum != null &&
          maximum != null &&
          compareDecimalStrings(minimum!, maximum!) > 0)
        _invalid("Decimal bounds are contradictory", path),
      if (scale != null &&
          minimum != null &&
          minimumValid &&
          minimum!.decimalScale > scale!)
        _invalid("Decimal minimum exceeds its scale", path),
      if (scale != null &&
          maximum != null &&
          maximumValid &&
          maximum!.decimalScale > scale!)
        _invalid("Decimal maximum exceeds its scale", path),
    ];
  }
}
