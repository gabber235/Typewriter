import "package:typewriter_panel/typewriter_panel.dart";

extension BindingReferenceMutation on BindingReference {
  TypedMutationResult replaceValue(
    TypeExpression type,
    DataValue value,
    ExpressionContext context,
    TypeRegistry? registry,
  ) {
    final diagnostics = value.validateAgainst(type, registry: registry);
    if (diagnostics.isNotEmpty) return MutationInvalid(diagnostics);
    final replaced = context.bindings.replace(this, value);
    if (replaced case TypeFailure(:final diagnostics)) {
      return MutationInvalid(diagnostics);
    }
    final snapshot = replaced.valueOrNull!.bindings[bindingId];
    if (snapshot == null) return invalidMutation("Updated binding is absent");
    return MutationSuccess(revision: snapshot.revision, value: snapshot.value);
  }
}

MutationInvalid invalidMutation(String message) => MutationInvalid([
  TypeDiagnostic(code: TypeDiagnosticCode.invalidValue, message: message),
]);

MutationUnavailable unavailableMutation(
  String message, {
  bool targetDeleted = false,
}) => MutationUnavailable([
  TypeDiagnostic(
    code: TypeDiagnosticCode.invalidValue,
    message: message,
    details: targetDeleted
        ? const [TypeDiagnosticDetail(key: "editor.target", value: "deleted")]
        : const [],
  ),
]);
