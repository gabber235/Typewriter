import "package:typewriter_panel/typewriter_panel.dart";

extension ResolvedTypeRefInference on ResolvedTypeRef {
  TypeResult<ResolvedTypeRef> inferFrom(
    TypeExpression evidence,
    TypeRegistry registry,
  ) {
    final definition = registry.definition(this);
    if (definition == null) {
      return _failure("Generic type is not present in the registry");
    }
    if (arguments.isNotEmpty) {
      return _failure("Generic inference requires an unapplied type reference");
    }
    final inferred = <String, TypeExpression>{};
    definition.representation._tryInfer(evidence, inferred, registry);
    for (final parent in definition.parents) {
      NamedType(parent)._tryInfer(evidence, inferred, registry);
    }
    definition._inferDependentBounds(evidence, inferred, registry);

    final inferredArguments = <TypeExpression>[];
    for (final parameter in definition.parameters) {
      final argument = inferred[parameter.name];
      if (argument == null) {
        return _failure("Type parameter '${parameter.name}' is not inferable");
      }
      inferredArguments.add(argument);
    }
    final reference = withArguments(inferredArguments);
    final resolved = registry.resolveExact(reference);
    if (resolved case TypeFailure(:final diagnostics)) {
      return TypeResult.failure(diagnostics);
    }
    return TypeResult.success(reference);
  }
}

extension on TypeDefinition {
  void _inferDependentBounds(
    TypeExpression evidence,
    Map<String, TypeExpression> inferred,
    TypeRegistry registry,
  ) {
    var changed = true;
    while (changed) {
      changed = false;
      for (final parameter in parameters) {
        if (inferred.containsKey(parameter.name)) continue;
        final before = inferred.length;
        final bound = parameter.bound.substitute(inferred);
        if (!bound._tryInfer(evidence, inferred, registry)) continue;
        inferred[parameter.name] = evidence;
        changed = changed || inferred.length > before;
      }
    }
  }
}

extension on TypeExpression {
  bool _tryInfer(
    TypeExpression evidence,
    Map<String, TypeExpression> inferred,
    TypeRegistry registry,
  ) {
    final candidate = Map<String, TypeExpression>.of(inferred);
    if (!_inferEvidence(evidence, candidate, registry)) return false;
    inferred
      ..clear()
      ..addAll(candidate);
    return true;
  }

  bool _inferEvidence(
    TypeExpression evidence,
    Map<String, TypeExpression> inferred,
    TypeRegistry registry,
  ) {
    final pattern = this;
    if (pattern case ParameterType(:final name)) {
      final existing = inferred[name];
      if (existing == null) {
        inferred[name] = evidence;
        return true;
      }
      return typeExpressionsEqual(existing, evidence);
    }
    if (pattern is ListType && evidence is ListType) {
      return pattern.element._inferEvidence(
        evidence.element,
        inferred,
        registry,
      );
    }
    if (pattern is MapType && evidence is MapType) {
      return pattern.key._inferEvidence(evidence.key, inferred, registry) &&
          pattern.value._inferEvidence(evidence.value, inferred, registry);
    }
    if (pattern is EnumType && evidence is EnumType) {
      return pattern.valueType._inferEvidence(
        evidence.valueType,
        inferred,
        registry,
      );
    }
    if (pattern is RecordType && evidence is RecordType) {
      for (final entry in pattern.fields.entries) {
        final actual = evidence.fields[entry.key];
        if (actual == null ||
            !entry.value.type._inferEvidence(actual.type, inferred, registry)) {
          return false;
        }
      }
      return true;
    }
    if (pattern is NamedType && evidence is NamedType) {
      return pattern.reference._inferNamed(
        evidence.reference,
        inferred,
        registry,
      );
    }
    return typeExpressionsEqual(pattern, evidence);
  }
}

extension on ResolvedTypeRef {
  bool _inferNamed(
    ResolvedTypeRef evidence,
    Map<String, TypeExpression> inferred,
    TypeRegistry registry,
  ) {
    final resolved = registry.resolveExact(evidence).valueOrNull;
    final candidates = [evidence, ...?resolved?.ancestors];
    for (final candidate in candidates) {
      if (id != candidate.id ||
          revision != candidate.revision ||
          arguments.length != candidate.arguments.length) {
        continue;
      }
      final local = Map<String, TypeExpression>.of(inferred);
      var matches = true;
      for (final entry in arguments.indexed) {
        if (!entry.$2._inferEvidence(
          candidate.arguments[entry.$1],
          local,
          registry,
        )) {
          matches = false;
          break;
        }
      }
      if (!matches) continue;
      inferred
        ..clear()
        ..addAll(local);
      return true;
    }
    return false;
  }
}

TypeFailure<ResolvedTypeRef> _failure(String message) => TypeFailure([
  TypeDiagnostic(code: TypeDiagnosticCode.genericBound, message: message),
]);
