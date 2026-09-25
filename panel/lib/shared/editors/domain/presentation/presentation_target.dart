import "package:typewriter_panel/typewriter_panel.dart";

extension TypeExpressionPresentationInference on TypeExpression {
  Map<String, TypeExpression>? inferPresentationSubstitutions(
    TypeExpression exact,
  ) {
    final substitutions = <String, TypeExpression>{};
    return _unifyWith(exact, substitutions) ? substitutions : null;
  }
}

/// Uses the same nominal and structural rules for catalog selection and
/// invocation binding. Keeping both decisions here prevents a field from
/// selecting a presentation that the invocation cannot bind.
Map<String, TypeExpression>? inferPresentationInputSubstitutions(
  TypeExpression expected,
  TypeExpression actual,
  TypeRegistry registry,
) {
  var inferred = expected.inferPresentationSubstitutions(actual);
  inferred ??= inferNominalOrAncestorPresentationSubstitutions(
    expected.bindingNominal(registry),
    actual.bindingNominal(registry),
    registry,
  );
  if (inferred == null && expected is! NamedType) {
    final representation = actual.bindingRepresentation(registry);
    inferred = expected.inferPresentationSubstitutions(representation);
    if (inferred == null &&
        representation.isStructurallyAssignableTo(expected, registry)) {
      inferred = {};
    }
  }
  return inferred;
}

/// Infers a presentation's type arguments from the actual type or one of its ancestors.
Map<String, TypeExpression>? inferNominalOrAncestorPresentationSubstitutions(
  TypeExpression expected,
  TypeExpression actual,
  TypeRegistry registry,
) {
  final exact = expected.inferPresentationSubstitutions(actual);
  if (exact != null || expected is! NamedType || actual is! NamedType) {
    return exact;
  }

  final resolved = registry.resolveExact(actual.reference).valueOrNull;
  if (resolved == null) return null;
  Map<String, TypeExpression>? inferred;
  for (final ancestor in resolved.ancestors) {
    final candidate = expected.inferPresentationSubstitutions(
      NamedType(ancestor),
    );
    if (candidate == null) continue;
    if (inferred != null && !_sameSubstitutions(inferred, candidate)) {
      return null;
    }
    inferred = candidate;
  }
  return inferred;
}

bool _sameSubstitutions(
  Map<String, TypeExpression> left,
  Map<String, TypeExpression> right,
) =>
    left.length == right.length &&
    left.entries.every((entry) {
      final value = right[entry.key];
      return value != null && typeExpressionsEqual(entry.value, value);
    });

extension on TypeExpression {
  bool _unifyWith(
    TypeExpression exact,
    Map<String, TypeExpression> substitutions,
  ) {
    final target = this;
    if (target case ParameterType(:final name)) {
      final existing = substitutions[name];
      if (existing == null) {
        substitutions[name] = exact;
        return true;
      }
      return typeExpressionsEqual(existing, exact);
    }
    return switch ((target, exact)) {
      (NamedType(reference: final left), NamedType(reference: final right)) =>
        left.id == right.id &&
            left.revision == right.revision &&
            left.arguments._unifyWith(right.arguments, substitutions),
      (ListType(element: final left), ListType(element: final right)) =>
        left._unifyWith(right, substitutions),
      (
        MapType(key: final leftKey, value: final leftValue),
        MapType(key: final rightKey, value: final rightValue),
      ) =>
        leftKey._unifyWith(rightKey, substitutions) &&
            leftValue._unifyWith(rightValue, substitutions),
      (RecordType(fields: final left), RecordType(fields: final right)) =>
        left._unifyWith(right, substitutions),
      _ => typeExpressionsEqual(target, exact),
    };
  }
}

extension on List<TypeExpression> {
  bool _unifyWith(
    List<TypeExpression> exact,
    Map<String, TypeExpression> substitutions,
  ) =>
      length == exact.length &&
      indexed.every(
        (entry) => entry.$2._unifyWith(exact[entry.$1], substitutions),
      );
}

extension on Map<String, TypeField> {
  bool _unifyWith(
    Map<String, TypeField> exact,
    Map<String, TypeExpression> substitutions,
  ) {
    if (length != exact.length) return false;
    for (final entry in entries) {
      final field = exact[entry.key];
      if (field == null ||
          !entry.value.type._unifyWith(field.type, substitutions)) {
        return false;
      }
    }
    return true;
  }
}
