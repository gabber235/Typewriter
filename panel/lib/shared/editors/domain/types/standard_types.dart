import "package:typewriter_panel/typewriter_panel.dart";

/// Canonical references for types supplied by the panel and kernel catalog.
///
/// These references are shared by authoring, value validation, and presentation
/// resolution. Construct applications through this owner rather than copying
/// identifiers, so revisions and generic argument placement stay consistent.
final standardTypeRefs = StandardTypeReferences();

/// Builds the complete standard type closure for panel owned presentations.
///
/// Realm catalogs remain authoritative and must deliver their own closure.
/// This constructor exists for presentation models authored and owned by the
/// panel itself, where no Realm catalog participates.
TypeCatalog panelPresentationTypeCatalog([
  Iterable<TypeDefinition> definitions = const [],
]) {
  final supplied = definitions.toList(growable: false);
  final suppliedIds = supplied.map((definition) => definition.id).toSet();
  return TypeCatalog([
    for (final definition in panelPresentationTypeDefinitions)
      if (!suppliedIds.contains(definition.id)) definition,
    ...supplied,
  ]);
}

final panelPresentationTypeDefinitions = <TypeDefinition>[
  TypeDefinition(
    id: standardTypeRefs.option,
    kind: NominalTypeKind.sealedAbstract,
    parameters: const [
      TypeParameter(name: "T", variance: TypeVariance.covariant),
    ],
  ),
  TypeDefinition(
    id: standardTypeRefs.some,
    kind: NominalTypeKind.concrete,
    parameters: const [TypeParameter(name: "T")],
    parents: [standardTypeRefs.optionOf(const ParameterType("T"))],
    representation: const RecordType(
      fields: {"value": TypeField(name: "value", type: ParameterType("T"))},
    ),
  ),
  TypeDefinition(
    id: standardTypeRefs.none,
    kind: NominalTypeKind.concrete,
    parameters: const [
      TypeParameter(name: "T", variance: TypeVariance.covariant),
    ],
    parents: [standardTypeRefs.optionOf(const ParameterType("T"))],
    representation: const UnitType(),
  ),
  TypeDefinition(
    id: standardTypeRefs.color,
    kind: NominalTypeKind.concrete,
    representation: const IntegerType(width: IntegerWidth.unsigned32),
  ),
  TypeDefinition(
    id: standardTypeRefs.icon,
    kind: NominalTypeKind.sealedAbstract,
    declarationOwner: "com.typewritermc.types",
  ),
  TypeDefinition(
    id: standardTypeRefs.iconifyIcon,
    kind: NominalTypeKind.concrete,
    declarationOwner: "com.typewritermc.types",
    parents: [standardTypeRefs.icon],
    representation: const RecordType(
      fields: {"value": TypeField(name: "value", type: StringType())},
    ),
  ),
  TypeDefinition(
    id: standardTypeRefs.svgIcon,
    kind: NominalTypeKind.concrete,
    declarationOwner: "com.typewritermc.types",
    parents: [standardTypeRefs.icon],
    representation: const RecordType(
      fields: {"source": TypeField(name: "source", type: StringType())},
    ),
  ),
];

/// Creates references to the built in nominal types used by the editor model.
final class StandardTypeReferences {
  StandardTypeReferences();

  final option = ResolvedTypeRef(id: const TypeId.option(), revision: 1);
  final some = ResolvedTypeRef(id: const TypeId.some(), revision: 1);
  final none = ResolvedTypeRef(id: const TypeId.none(), revision: 1);

  final color = ResolvedTypeRef(
    id: TypeId.declared("c15fe94d13fb4317924a0ad2072defe4"),
    revision: 1,
  );
  final icon = ResolvedTypeRef(
    id: TypeId.declared("6fffa4398c0b4611bbf3517e047e6a52"),
    revision: 1,
  );
  final iconifyIcon = ResolvedTypeRef(
    id: TypeId.declared("3845952a4d714e23ad55f07051669930"),
    revision: 1,
  );
  final svgIcon = ResolvedTypeRef(
    id: TypeId.declared("67ed1a5b0e534c05b8d233ef9783971b"),
    revision: 1,
  );

  /// Applies the option type constructor to [type].
  ResolvedTypeRef optionOf(TypeExpression type) => option.withArguments([type]);

  /// Applies the successful option constructor to [type].
  ResolvedTypeRef someOf(TypeExpression type) => some.withArguments([type]);

  /// Applies the empty option constructor to [type].
  ResolvedTypeRef noneOf(TypeExpression type) => none.withArguments([type]);
}
