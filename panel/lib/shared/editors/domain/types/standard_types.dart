import "package:typewriter_panel/typewriter_panel.dart";

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
  final ref = ResolvedTypeRef(
    id: const QualifiedTypeId(namespace: "typewriter/v1", name: "Ref"),
    revision: 1,
  );

  ResolvedTypeRef optionOf(TypeExpression type) => option.withArguments([type]);

  ResolvedTypeRef someOf(TypeExpression type) => some.withArguments([type]);

  ResolvedTypeRef noneOf(TypeExpression type) => none.withArguments([type]);

  ResolvedTypeRef refTo(TypeExpression type) => ref.withArguments([type]);
}

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
    representation: const StringType(minimumLength: 1),
    defaultPresentationId: standardIconifyPresentationId,
  ),
  TypeDefinition(
    id: standardTypeRefs.svgIcon,
    kind: NominalTypeKind.concrete,
    parents: [standardTypeRefs.icon],
    representation: const StringType(minimumLength: 1),
    defaultPresentationId: standardSvgIconPresentationId,
  ),
  TypeDefinition(
    id: standardTypeRefs.ref,
    kind: NominalTypeKind.concrete,
    parameters: const [
      TypeParameter(name: "T", variance: TypeVariance.covariant),
    ],
    representation: const StringType(minimumLength: 1),
  ),
];
