import "package:typewriter_panel/typewriter_panel.dart";

/// Stable nominal identities used when requesting core resource type closure.
final class ReferenceResourceTypes {
  const ReferenceResourceTypes();

  ResolvedTypeRef get referenceable => const ResolvedTypeRef(
    id: TypeId.qualified(
      namespace: "com.typewritermc.types",
      name: "Referenceable",
    ),
    revision: 1,
  );
  ResolvedTypeRef get book => const ResolvedTypeRef(
    id: TypeId.qualified(namespace: "com.typewritermc.library", name: "Book"),
    revision: 1,
  );
  ResolvedTypeRef get page => const ResolvedTypeRef(
    id: TypeId.qualified(namespace: "com.typewritermc.library", name: "Page"),
    revision: 1,
  );
  ResolvedTypeRef get pageKind => const ResolvedTypeRef(
    id: TypeId.qualified(
      namespace: "com.typewritermc.library",
      name: "PageKind",
    ),
    revision: 1,
  );
  ResolvedTypeRef get tag => const ResolvedTypeRef(
    id: TypeId.qualified(namespace: "com.typewritermc.library", name: "Tag"),
    revision: 1,
  );
  ResolvedTypeRef get element => const ResolvedTypeRef(
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

const referenceResourceTypes = ReferenceResourceTypes();
