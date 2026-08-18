import "package:typewriter_panel/typewriter_panel.dart";

final class TypeRegistry {
  TypeRegistry(TypeCatalog catalog)
    : this._(bootstrapTypeCatalog(catalog.definitions));

  TypeRegistry._(TypeCatalog catalog)
    : _definitions = {
        for (final definition in catalog.definitions) definition.id: definition,
      },
      _duplicates = _findDuplicates(catalog.definitions),
      _declarationDiagnostics = {
        for (final definition in catalog.definitions)
          definition.id: definition.validateDeclaration(),
      };

  final Map<ResolvedTypeRef, TypeDefinition> _definitions;
  final Set<ResolvedTypeRef> _duplicates;
  final Map<ResolvedTypeRef, List<TypeDiagnostic>> _declarationDiagnostics;
  final Map<ResolvedTypeRef, ResolvedType> _cache = {};

  TypeResult<ResolvedType> resolve(NamedType type) =>
      resolveExact(type.reference);

  TypeResult<ResolvedType> resolveExact(ResolvedTypeRef reference) {
    final declaration = reference._declarationRef;
    if (_duplicates.contains(declaration)) {
      return _failure(
        TypeDiagnosticCode.duplicateDefinition,
        "Type '$declaration' is defined more than once",
        declaration,
      );
    }
    final diagnostics = _declarationDiagnostics[declaration];
    if (diagnostics != null && diagnostics.isNotEmpty) {
      return TypeResult.failure(diagnostics);
    }
    return _resolve(reference, const []);
  }

  TypeResult<ResolvedType> _resolve(
    ResolvedTypeRef reference,
    List<ResolvedTypeRef> inheritanceStack,
  ) {
    final cached = _cache[reference];
    if (cached != null) return TypeResult.success(cached);
    final declaration = reference._declarationRef;
    if (_duplicates.contains(declaration)) {
      return _failure(
        TypeDiagnosticCode.duplicateDefinition,
        "Type '$declaration' is defined more than once",
        declaration,
      );
    }
    final declarationDiagnostics = _declarationDiagnostics[declaration];
    if (declarationDiagnostics != null && declarationDiagnostics.isNotEmpty) {
      return TypeResult.failure(declarationDiagnostics);
    }
    final definition = _definitions[declaration];
    if (definition == null) {
      return _failure(
        TypeDiagnosticCode.unknownType,
        "Type '$declaration' is not present in the catalog",
        declaration,
      );
    }
    if (reference.arguments.length != definition.parameters.length) {
      return _failure(
        TypeDiagnosticCode.genericArity,
        "Type '$declaration' expects ${definition.parameters.length} arguments but received ${reference.arguments.length}",
        declaration,
      );
    }
    if (inheritanceStack.contains(declaration)) {
      return _failure(
        TypeDiagnosticCode.inheritanceCycle,
        "Inheritance cycle includes '$declaration'",
        declaration,
      );
    }
    final varianceDiagnostics = definition.validateVarianceUse();
    if (varianceDiagnostics.isNotEmpty) {
      return TypeResult.failure(varianceDiagnostics);
    }
    final substitutions = <String, TypeExpression>{
      for (final entry in definition.parameters.indexed)
        entry.$2.name: reference.arguments[entry.$1],
    };
    final boundDiagnostics = _validateBounds(
      definition,
      reference,
      substitutions,
    );
    if (boundDiagnostics.isNotEmpty) {
      return TypeResult.failure(boundDiagnostics);
    }

    final declaredRepresentation = definition.representation.substitute(
      substitutions,
    );
    var effective = declaredRepresentation;
    final ancestors = <ResolvedTypeRef>{};
    final directParents = <ResolvedTypeRef>{};
    final nextStack = [...inheritanceStack, declaration];
    for (final parent in definition.parents) {
      final appliedParent = parent.substitute(substitutions);
      final resolvedParent = _resolve(appliedParent, nextStack);
      if (resolvedParent case TypeFailure(:final diagnostics)) {
        return TypeResult.failure(diagnostics);
      }
      final parentValue = resolvedParent.valueOrNull!;
      final ownership = _validateSealedOwnership(declaration, {
        appliedParent,
        ...parentValue.ancestors,
      });
      if (ownership.isNotEmpty) return TypeResult.failure(ownership);
      final weakening = _findWeakening(
        parentValue.representation,
        declaredRepresentation,
      );
      if (weakening.isNotEmpty) return TypeResult.failure(weakening);
      final merged = parentValue.representation.safelyRefineWith(
        effective,
        this,
      );
      if (merged case TypeFailure(:final diagnostics)) {
        return TypeResult.failure(
          diagnostics
              .map(
                (diagnostic) => TypeDiagnostic(
                  code: diagnostic.code,
                  message:
                      "Type '$declaration' conflicts with parent '${parent.id}': ${diagnostic.message}",
                  path: diagnostic.path,
                  type: declaration,
                ),
              )
              .toList(),
        );
      }
      effective = merged.valueOrNull!;
      directParents.add(appliedParent);
      ancestors
        ..add(appliedParent)
        ..addAll(parentValue.ancestors);
    }
    final resolvedDiagnostics = effective.validateResolvedEnums(this);
    if (resolvedDiagnostics.isNotEmpty) {
      return TypeResult.failure(resolvedDiagnostics);
    }
    final result = ResolvedType(
      reference: reference,
      kind: definition.kind,
      representation: effective,
      ancestors: ancestors,
      directParents: directParents,
    );
    _cache[reference] = result;
    return TypeResult.success(result);
  }

  List<TypeDiagnostic> _validateBounds(
    TypeDefinition definition,
    ResolvedTypeRef reference,
    Map<String, TypeExpression> substitutions,
  ) {
    final diagnostics = <TypeDiagnostic>[];
    for (final entry in definition.parameters.indexed) {
      final parameter = entry.$2;
      final bound = parameter.bound.substitute(substitutions);
      if (reference.arguments[entry.$1].isStructurallyAssignableTo(
        bound,
        this,
      )) {
        continue;
      }
      diagnostics.add(
        TypeDiagnostic(
          code: TypeDiagnosticCode.genericBound,
          message:
              "Argument for '${parameter.name}' does not satisfy its bound",
          type: definition.id,
        ),
      );
    }
    return diagnostics;
  }

  List<TypeDiagnostic> _validateSealedOwnership(
    ResolvedTypeRef child,
    Set<ResolvedTypeRef> ancestors,
  ) => [
    for (final ancestor in ancestors)
      if (_definitions[ancestor._declarationRef] case final definition?
          when definition.kind == NominalTypeKind.sealedAbstract &&
              definition.id.id._owner != child.id._owner)
        TypeDiagnostic(
          code: TypeDiagnosticCode.invalidConcreteType,
          message:
              "Type '$child' is outside the owner of sealed type '${definition.id}'",
          type: child,
        ),
  ];

  List<TypeDiagnostic> _findWeakening(
    TypeExpression parent,
    TypeExpression child,
  ) {
    if (child is AnyType) return const [];
    if (parent is RecordType && child is RecordType) {
      return [
        for (final entry in parent.fields.entries)
          if (child.fields[entry.key] case final childField?
              when !childField.type.isStructurallyAssignableTo(
                entry.value.type,
                this,
              ))
            TypeDiagnostic(
              code: TypeDiagnosticCode.conflictingInheritance,
              message: "Field '${entry.key}' weakens its inherited type",
              path: DataPath.root.field(entry.key),
            ),
      ];
    }
    if (parent.runtimeType == child.runtimeType &&
        !child.isStructurallyAssignableTo(parent, this)) {
      return [
        const TypeDiagnostic(
          code: TypeDiagnosticCode.conflictingInheritance,
          message: "The declared representation weakens its inherited type",
        ),
      ];
    }
    return const [];
  }

  TypeDefinition? definition(ResolvedTypeRef reference) =>
      _definitions[reference._declarationRef];

  static Set<ResolvedTypeRef> _findDuplicates(
    Iterable<TypeDefinition> definitions,
  ) {
    final seen = <ResolvedTypeRef>{};
    final duplicates = <ResolvedTypeRef>{};
    for (final definition in definitions) {
      if (!seen.add(definition.id)) duplicates.add(definition.id);
    }
    return duplicates;
  }

  TypeFailure<ResolvedType> _failure(
    TypeDiagnosticCode code,
    String message,
    ResolvedTypeRef type,
  ) => TypeFailure([TypeDiagnostic(code: code, message: message, type: type)]);
}

extension on TypeId {
  String get _owner => switch (this) {
    OptionTypeId() || SomeTypeId() || NoneTypeId() => "builtin",
    QualifiedTypeId(:final namespace) => namespace,
  };
}

extension on ResolvedTypeRef {
  ResolvedTypeRef get _declarationRef =>
      ResolvedTypeRef(id: id, revision: revision);
}
