part of "type_constraint_validation.dart";

extension DurationTypeConstraintValidation on DurationType {
  List<TypeDiagnostic> validateOwnConstraints(DataPath path) => [
    ..._comparableBounds(minimum, maximum, "Duration", path),
    if (minimum?.inMicroseconds.remainder(1000) case final remainder?
        when remainder != 0)
      _invalid("Duration minimum must have exact millisecond precision", path),
    if (maximum?.inMicroseconds.remainder(1000) case final remainder?
        when remainder != 0)
      _invalid("Duration maximum must have exact millisecond precision", path),
  ];
}

extension EnumTypeConstraintValidation on EnumType {
  List<TypeDiagnostic> validateOwnConstraints(DataPath path) => [
    if (values.isEmpty) _invalid("Enum must declare at least one value", path),
    if (values.toSet().length != values.length)
      _invalid("Enum values must be unique", path),
    if (!valueType.containsParameter && !valueType.requiresRegistry)
      for (final value in values)
        ...value.validateAgainst(valueType, path: path),
  ];
}

extension RecordTypeConstraintValidation on RecordType {
  List<TypeDiagnostic> validateFieldConstraints(
    Set<String> allowedParameters, {
    DataPath path = DataPath.root,
  }) => _validateFields(allowedParameters, path, HashSet.identity());

  List<TypeDiagnostic> _validateFields(
    Set<String> parameters,
    DataPath path,
    Set<TypeExpression> active,
  ) {
    final diagnostics = <TypeDiagnostic>[];
    for (final entry in fields.entries) {
      final fieldPath = entry.key.isEmpty ? path : path.field(entry.key);
      if (entry.key.isEmpty) {
        diagnostics.add(_invalid("Record field name is empty", path));
      }
      if (entry.value.name != entry.key) {
        diagnostics.add(
          _invalid(
            "Record field metadata does not match '${entry.key}'",
            fieldPath,
          ),
        );
      }
      diagnostics.addAll(
        entry.value.type._validateConstraintTree(parameters, fieldPath, active),
      );
      if (entry.value.initialValue case final initial?
          when !entry.value.type.containsParameter) {
        diagnostics.addAll(
          initial.validateAgainst(entry.value.type, path: fieldPath),
        );
      }
    }
    return diagnostics;
  }
}

extension on String {
  List<TypeDiagnostic> _validatePattern(String label, DataPath path) {
    try {
      RegExp(this);
      return const [];
    } on FormatException {
      return [_invalid("$label pattern is malformed", path)];
    }
  }
}

List<TypeDiagnostic> _lengthBounds(
  int? minimum,
  int? maximum,
  String label,
  DataPath path,
) => [
  if (minimum != null && minimum < 0)
    _invalid("$label minimum must not be negative", path),
  if (maximum != null && maximum < 0)
    _invalid("$label maximum must not be negative", path),
  if (minimum != null && maximum != null && minimum > maximum)
    _invalid("$label bounds are contradictory", path),
];

List<TypeDiagnostic> _comparableBounds<T extends Comparable<T>>(
  T? minimum,
  T? maximum,
  String label,
  DataPath path,
) => minimum != null && maximum != null && minimum.compareTo(maximum) > 0
    ? [_invalid("$label bounds are contradictory", path)]
    : const [];

TypeDiagnostic _invalid(String message, DataPath path) => TypeDiagnostic(
  code: TypeDiagnosticCode.invalidConstraint,
  message: message,
  path: path,
);
