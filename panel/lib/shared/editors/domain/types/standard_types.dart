import "package:typewriter_panel/typewriter_panel.dart";

/// Canonical references for types supplied by the panel and kernel catalog.
///
/// These references are shared by authoring, value validation, and presentation
/// resolution. Construct applications through this owner rather than copying
/// identifiers, so revisions and generic argument placement stay consistent.
final standardTypeRefs = StandardTypeReferences();

const standardColorPresentationId = PresentationId(
  namespace: "typewriter",
  name: "color",
);
const standardColorAlphaPresentationId = PresentationId(
  namespace: "typewriter",
  name: "color.alpha",
);
const standardIconifyPresentationId = PresentationId(
  namespace: "typewriter",
  name: "iconifyIcon",
);
const standardSvgIconPresentationId = PresentationId(
  namespace: "typewriter",
  name: "svgIcon",
);

/// Creates references to the built in nominal types used by the editor model.
final class StandardTypeReferences {
  StandardTypeReferences();

  final option = ResolvedTypeRef(id: const TypeId.option(), revision: 1);
  final some = ResolvedTypeRef(id: const TypeId.some(), revision: 1);
  final none = ResolvedTypeRef(id: const TypeId.none(), revision: 1);

  final color = ResolvedTypeRef(
    id: const QualifiedTypeId(namespace: "kernel/v1", name: "Color"),
    revision: 1,
  );
  final icon = ResolvedTypeRef(
    id: const QualifiedTypeId(namespace: "panel/v1", name: "Icon"),
    revision: 1,
  );
  final iconifyIcon = ResolvedTypeRef(
    id: const QualifiedTypeId(namespace: "panel/v1", name: "IconifyIcon"),
    revision: 1,
  );
  final svgIcon = ResolvedTypeRef(
    id: const QualifiedTypeId(namespace: "panel/v1", name: "SvgIcon"),
    revision: 1,
  );

  /// Applies the option type constructor to [type].
  ResolvedTypeRef optionOf(TypeExpression type) => option.withArguments([type]);

  /// Applies the successful option constructor to [type].
  ResolvedTypeRef someOf(TypeExpression type) => some.withArguments([type]);

  /// Applies the empty option constructor to [type].
  ResolvedTypeRef noneOf(TypeExpression type) => none.withArguments([type]);
}

/// Adds the panel's standard definitions before catalog supplied definitions.
///
/// [TypeRegistry] uses this assembled catalog for resolution. The input
/// definitions remain the caller's extension point; standard definitions are
/// always available to their representations and presentations.
TypeCatalog bootstrapTypeCatalog(Iterable<TypeDefinition> definitions) =>
    TypeCatalog([..._standardDefinitions, ...definitions]);

final _standardDefinitions = <TypeDefinition>[
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
    representation: RecordType(
      fields: const {
        "value": TypeField(name: "value", type: ParameterType("T")),
      },
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
    defaultPresentationId: standardColorPresentationId,
  ),
  TypeDefinition(
    id: standardTypeRefs.icon,
    kind: NominalTypeKind.sealedAbstract,
  ),
  TypeDefinition(
    id: standardTypeRefs.iconifyIcon,
    kind: NominalTypeKind.concrete,
    parents: [standardTypeRefs.icon],
    representation: const StringType(
      minimumLength: 3,
      patterns: [r"^[a-z0-9\-]+:[a-z0-9\-]+$"],
    ),
    defaultPresentationId: standardIconifyPresentationId,
  ),
  TypeDefinition(
    id: standardTypeRefs.svgIcon,
    kind: NominalTypeKind.concrete,
    parents: [standardTypeRefs.icon],
    representation: const StringType(minimumLength: 1),
    defaultPresentationId: standardSvgIconPresentationId,
  ),
];
