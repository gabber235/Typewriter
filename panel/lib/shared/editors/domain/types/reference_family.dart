import "package:typewriter_panel/typewriter_panel.dart";

/// Physical resource table derived from one nominal reference target.
enum ReferenceFamily { book, page, tag, element }

extension ReferenceFamilyTable on ReferenceFamily {
  String get table => switch (this) {
    ReferenceFamily.book => "book",
    ReferenceFamily.page => "page",
    ReferenceFamily.tag => "tag",
    ReferenceFamily.element => "element",
  };
}

extension ReferenceFamilyResolution on TypeRegistry {
  /// Resolves one target through its complete ancestry.
  TypeResult<ReferenceFamily> referenceFamily(ResolvedTypeRef target) {
    final resolved = resolveExact(target);
    if (resolved case TypeFailure(:final diagnostics)) {
      return TypeResult.failure(diagnostics);
    }
    final closure = {target._declaration, ...resolved.valueOrNull!.ancestors};
    if (!closure.contains(referenceResourceTypes.referenceable)) {
      return _failure(
        "Reference target '$target' does not inherit Referenceable",
      );
    }
    final families = <ReferenceFamily>{
      if (closure.contains(referenceResourceTypes.book)) ReferenceFamily.book,
      if (closure.contains(referenceResourceTypes.page) ||
          closure.contains(referenceResourceTypes.pageKind))
        ReferenceFamily.page,
      if (closure.contains(referenceResourceTypes.tag)) ReferenceFamily.tag,
      if (closure.contains(referenceResourceTypes.element))
        ReferenceFamily.element,
    };
    if (families.length != 1) {
      return _failure(
        "Reference target '$target' must resolve to exactly one resource family",
      );
    }
    return TypeResult.success(families.single);
  }

  TypeFailure<ReferenceFamily> _failure(String message) => TypeFailure([
    TypeDiagnostic(
      code: TypeDiagnosticCode.invalidConstraint,
      message: message,
    ),
  ]);
}

extension on ResolvedTypeRef {
  ResolvedTypeRef get _declaration => withArguments(const []);
}

final referenceResourceTypes = ReferenceResourceTypes();

final class ReferenceResourceTypes {
  ReferenceResourceTypes();

  final referenceable = const ResolvedTypeRef(
    id: TypeId.qualified(
      namespace: "com.typewritermc.types",
      name: "Referenceable",
    ),
    revision: 1,
  );
  final book = const ResolvedTypeRef(
    id: TypeId.qualified(namespace: "com.typewritermc.library", name: "Book"),
    revision: 1,
  );
  final page = const ResolvedTypeRef(
    id: TypeId.qualified(namespace: "com.typewritermc.library", name: "Page"),
    revision: 1,
  );
  final pageKind = const ResolvedTypeRef(
    id: TypeId.qualified(
      namespace: "com.typewritermc.library",
      name: "PageKind",
    ),
    revision: 1,
  );
  final tag = const ResolvedTypeRef(
    id: TypeId.qualified(namespace: "com.typewritermc.library", name: "Tag"),
    revision: 1,
  );
  final element = const ResolvedTypeRef(
    id: TypeId.qualified(
      namespace: "com.typewritermc.elements",
      name: "Element",
    ),
    revision: 1,
  );

  List<TypeDefinition> get definitions => [
    TypeDefinition(id: referenceable, kind: NominalTypeKind.openAbstract),
    for (final type in [book, page, tag])
      TypeDefinition(
        id: type,
        kind: NominalTypeKind.concrete,
        parents: [referenceable],
        representation: const UnitType(),
      ),
    for (final type in [pageKind, element])
      TypeDefinition(
        id: type,
        kind: NominalTypeKind.openAbstract,
        parents: [referenceable],
        representation: const UnitType(),
      ),
  ];
}
