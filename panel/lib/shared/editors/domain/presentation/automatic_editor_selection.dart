import "package:typewriter_panel/typewriter_panel.dart";

/// Resolves the contract for an automatically selected, single-value editor.
///
/// Editable fields use generated controls only when no role is declared.
/// An absent or incompatible declared editor is a catalog error at the field.
/// Read-only fields may fall back because an editor requiring write access
/// cannot be bound in that context.
TypeResult<PresentationDefinition?> selectAutomaticEditor({
  required TypeRegistry registry,
  required TypeExpression type,
  required Iterable<PresentationDefinition> presentations,
  required PresentationInputAccess access,
  List<PresentationRole> roles = const [PresentationRole.editor],
  PresentationId? requested,
}) {
  final ids = <PresentationId>[];
  if (requested != null) {
    ids.add(requested);
  } else if (type is NamedType) {
    for (final role in roles) {
      final association = registry.resolveOptionalPresentationRoleStatus(
        type.reference,
        role,
      );
      if (association case TypeFailure(:final diagnostics)) {
        return TypeResult.failure(diagnostics);
      }
      switch (association.valueOrNull) {
        case RolePresentationReady(:final id):
          ids.add(id);
        case RolePresentationRejected(:final message):
          if (access == PresentationInputAccess.edit) {
            return _invalidEditor(message, type);
          }
        case null:
          break;
      }
    }
  }

  for (final id in ids) {
    final definition = presentations.where((item) => item.id == id).firstOrNull;
    if (definition == null) {
      if (access == PresentationInputAccess.read && requested == null) {
        continue;
      }
      return _invalidEditor("Declared editor '$id' is unavailable", type);
    }
    if (access == PresentationInputAccess.read &&
        definition.inputs.length == 1 &&
        definition.inputs.single.access == PresentationInputAccess.edit) {
      continue;
    }
    if (definition.inputs.length != 1 || definition.primaryInput == null) {
      if (access == PresentationInputAccess.read && requested == null) {
        continue;
      }
      return _invalidEditor(
        "Editor '$id' must declare exactly one input",
        type,
      );
    }
    final expected = definition.inputs.single.type;
    if (inferPresentationInputSubstitutions(expected, type, registry) == null) {
      if (access == PresentationInputAccess.read && requested == null) {
        continue;
      }
      return _invalidEditor("Editor '$id' cannot bind to '$type'", type);
    }
    return TypeResult.success(definition);
  }
  return const TypeResult.success(null);
}

TypeFailure<PresentationDefinition?> _invalidEditor(
  String message,
  TypeExpression type,
) => TypeFailure([
  TypeDiagnostic(
    code: TypeDiagnosticCode.invalidPresentation,
    message: message,
    type: type is NamedType ? type.reference : null,
  ),
]);
