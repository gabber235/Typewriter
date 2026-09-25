part of "../../bound_value_renderer.dart";

/// Invokes a named presentation with caller supplied binding arguments.
///
/// Arguments are resolved in the caller, then projected into a fresh lexical
/// scope. The child can preserve edit access only when the caller granted it;
/// canonical destinations and owner references route changes back to the
/// caller's transaction. Recursive or unavailable definitions become a
/// diagnostic.
extension PresentationInvocationRendering on PresentationInvocationElement {
  Widget render(BuildContext context, PresentationRenderScope scope) {
    final resolution = scope.resolvePresentation(
      null,
      presentationId,
      PresentationInputAccess.read,
    );
    if (resolution case TypeFailure(:final diagnostics)) {
      return presentationDiagnostic(context, diagnostics);
    }
    final definition = resolution.valueOrNull;
    if (definition == null ||
        scope.activePresentations.contains(presentationId)) {
      return presentationDiagnostic(context, [
        const TypeDiagnostic(
          code: TypeDiagnosticCode.invalidPresentation,
          message: "Presentation is unavailable or recursively invoked",
        ),
      ]);
    }
    final bound = scope.bindPresentation(definition, arguments);
    if (bound case TypeFailure(:final diagnostics)) {
      return presentationDiagnostic(context, diagnostics);
    }
    return PresentationNodeRenderer(
      node: bound.valueOrNull!.$1,
      scope: bound.valueOrNull!.$2,
    );
  }
}

/// Binds and type checks the arguments for one presentation invocation.
///
/// This is the boundary between caller bindings and the presentation's input
/// bindings. It infers substitutions, enforces edit access, records canonical
/// destinations and owners, and marks the definition active for recursion
/// detection. The returned scope is immutable and inherits all other
/// capabilities from the caller.
extension PresentationInputScope on PresentationRenderScope {
  /// Arguments resolve in the caller before a fresh lexical scope is created.
  TypeResult<(PresentationNode, PresentationRenderScope)> bindPresentation(
    ResolvedPresentationDefinition definition,
    Map<BindingId, BindingReference> arguments,
  ) {
    final substitutions = <String, TypeExpression>{};
    final sources = <BindingId, BindingSource>{};
    final destinations = <BindingId, BindingReference>{};
    final owners = <BindingId, BindingReference?>{};
    if (definition.inputs.map((input) => input.id).toSet().length !=
            definition.inputs.length ||
        arguments.length != definition.inputs.length) {
      return _inputFailure("Presentation input count does not match");
    }
    for (final input in definition.inputs) {
      final argument = arguments[input.id];
      if (argument == null) {
        return _inputFailure("Missing presentation input: ${input.name}");
      }
      final resolved = inspect(argument);
      if (resolved case TypeFailure(:final diagnostics)) {
        return TypeResult.failure(diagnostics);
      }

      final value = resolved.valueOrNull!;

      final expected = input.type.substitute(substitutions);

      final actual = value.type;

      final inferred = inferPresentationInputSubstitutions(
        expected,
        actual,
        registry,
      );
      if (inferred == null) {
        return _inputFailure("Incompatible presentation input: ${input.name}");
      }

      substitutions.addAll(inferred);
      if (input.access == PresentationInputAccess.edit &&
          accessOf(argument) != PresentationInputAccess.edit) {
        return _inputFailure(
          "Presentation input requires editing: ${input.name}",
        );
      }
      final projected = expressions.bindings.project(
        argument,
        registry: registry,
      );
      if (projected case TypeFailure(:final diagnostics)) {
        return TypeResult.failure(diagnostics);
      }
      sources[input.id] = projected.valueOrNull!;

      destinations[input.id] = canonical(argument);
      owners[input.id] = ownerReference(argument);
    }

    return TypeResult.success((
      definition.root.substitute(substitutions),
      copyWith(
        expressions: expressions.copyWith(
          bindings: BindingEnvironment(sources),
        ),
        aliases: destinations,
        ownerBindings: owners,
        inputAccess: {
          for (final input in definition.inputs) input.id: input.access,
        },
        activePresentations: {...activePresentations, definition.id},
      ),
    ));
  }
}

TypeFailure<T> _inputFailure<T>(String message) => TypeFailure([
  TypeDiagnostic(
    code: TypeDiagnosticCode.invalidPresentation,
    message: message,
  ),
]);
