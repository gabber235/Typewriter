import "package:typewriter_panel/typewriter_panel.dart";

/// Derives the fields that several values can safely edit together.
///
/// Identical types remain intact. Record types retain only shared fields with
/// identical types, and conflicting defaults are removed. Other incompatible
/// shapes return diagnostics rather than inventing a projection.
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
        defaulted: candidates.every((field) => field.defaulted),
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
