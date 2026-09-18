import "package:typewriter_panel/typewriter_panel.dart";

extension TypeExpressionInitialValue on TypeExpression {
  TypeResult<DataValue> createInitialValue({TypeRegistry? registry}) {
    if (registry == null) {
      return TypeResult.failure([
        const TypeDiagnostic(
          code: TypeDiagnosticCode.invalidConstraint,
          message: "A registry is required to materialize a value",
        ),
      ]);
    }
    return materializeReadyValue(this, registry);
  }
}
