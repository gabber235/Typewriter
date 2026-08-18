import "package:typewriter_panel/typewriter_panel.dart";

extension SafeTypeRefinement on TypeExpression {
  TypeResult<TypeExpression> safelyRefineWith(
    TypeExpression constraint,
    TypeRegistry registry,
  ) {
    final intersection = intersectTypes(this, constraint);
    if (intersection case TypeFailure(:final diagnostics)) {
      return TypeResult.failure(diagnostics);
    }
    final refined = intersection.valueOrNull!;
    if (refined.isStructurallyAssignableTo(this, registry)) {
      return TypeResult.success(refined);
    }
    return TypeResult.failure([
      const TypeDiagnostic(
        code: TypeDiagnosticCode.invalidConstraint,
        message: "Refinement is not assignable to its base type",
      ),
    ]);
  }
}
