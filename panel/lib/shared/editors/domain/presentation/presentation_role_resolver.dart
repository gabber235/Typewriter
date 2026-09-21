import "package:typewriter_panel/typewriter_panel.dart";

/// Resolves role associations independently through instantiated ancestry.
extension PresentationRoleResolution on TypeRegistry {
  /// Returns the unique association at the nearest ancestry distance.
  ///
  /// Equal distance declarations that point to distinct presentations are
  /// ambiguous. Repeated declarations of the same presentation remain one
  /// association. Generic parent arguments are retained by [resolveExact].
  TypeResult<PresentationId> resolvePresentationRole(
    ResolvedTypeRef actual,
    PresentationRole role,
  ) {
    var frontier = <ResolvedTypeRef>{actual};
    final visited = <ResolvedTypeRef>{};

    while (frontier.isNotEmpty) {
      final current = frontier.difference(visited);
      if (current.isEmpty) break;
      visited.addAll(current);

      final resolvedCurrent = <ResolvedType>[];
      for (final reference in current) {
        final resolved = resolveExact(reference);
        if (resolved case TypeFailure(:final diagnostics)) {
          return TypeResult.failure(diagnostics);
        }
        resolvedCurrent.add(resolved.valueOrNull!);
      }

      final matches = {
        for (final reference in current)
          ?definition(reference)?.rolePresentations[role],
      };
      if (matches.length == 1) return TypeResult.success(matches.single);
      if (matches.length > 1) {
        return _roleFailure(
          "Presentation role '${role.name}' is ambiguous for '$actual': "
          "${matches.map((id) => '${id.namespace}/${id.name}').join(', ')}",
          actual,
        );
      }

      final next = <ResolvedTypeRef>{
        for (final resolved in resolvedCurrent) ...resolved.directParents,
      };
      frontier = next;
    }

    return _roleFailure(
      "Presentation role '${role.name}' is unavailable for '$actual'",
      actual,
    );
  }
}

TypeFailure<PresentationId> _roleFailure(
  String message,
  ResolvedTypeRef type,
) => TypeFailure([
  TypeDiagnostic(
    code: TypeDiagnosticCode.invalidPresentation,
    message: message,
    type: type,
  ),
]);
