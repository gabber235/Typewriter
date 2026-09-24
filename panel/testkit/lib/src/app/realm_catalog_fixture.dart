import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;

/// Supplies exact-generation catalog reads in authoring session tests.
RealmEditorCatalogCache fixedRealmCatalogCache({
  required RealmEditorCatalogSnapshot snapshot,
  required skir.RecordId organizationId,
  required skir.RecordId realmId,
}) => RealmEditorCatalogCache(
  source: _FixedRealmCatalogSource(snapshot),
  route: RealmEditorCatalogRoute(
    organizationId: organizationId,
    realmId: realmId,
  ),
);

final class _FixedRealmCatalogSource implements RealmEditorCatalogSource {
  const _FixedRealmCatalogSource(this.snapshot);

  final RealmEditorCatalogSnapshot snapshot;

  @override
  Future<RealmEditorCatalogFetchResult> fetch(
    RealmEditorCatalogRoute route,
    RealmEditorCatalogRequest request, {
    CatalogGeneration? expectedGeneration,
  }) async =>
      expectedGeneration != null && expectedGeneration != snapshot.generation
      ? RealmEditorCatalogGenerationMismatch(snapshot.generation)
      : RealmEditorCatalogFetched(snapshot);

  @override
  Stream<RealmEditorCatalogWatchEvent> watchInvalidations(
    RealmEditorCatalogRoute route,
  ) => const Stream.empty();

  @override
  Future<RealmTypedValueInitializationResult> initialize(
    RealmEditorCatalogRoute route, {
    required CatalogGeneration generation,
    required ResolvedTypeRef root,
    required DataValue? supplied,
    required TypeRegistry registry,
  }) =>
      Future.error(UnsupportedError("Initialization is outside this fixture"));
}

const realmFixtureGeneration = CatalogGeneration("fixture");

const _colorPresentationId = PresentationId(
  namespace: "typewritermc:realm",
  name: "color.editor",
);
const _iconifyPresentationId = PresentationId(
  namespace: "typewritermc:realm",
  name: "icon.iconify.editor",
);
const _svgPresentationId = PresentationId(
  namespace: "typewritermc:realm",
  name: "icon.svg.editor",
);

/// Builds the type closure a panel test would receive from Realm.
///
/// Supplied definitions replace matching Realm declarations. Stories can add
/// scenario types without recreating standard types or their ownership.
TypeCatalog receivedRealmCatalog([
  Iterable<TypeDefinition> definitions = const [],
]) {
  final supplied = definitions.toList(growable: false);
  final suppliedIds = supplied.map((definition) => definition.id).toSet();
  return panelPresentationTypeCatalog([
    for (final definition in _realmDefinitions)
      if (!suppliedIds.contains(definition.id)) definition,
    ...supplied,
  ]);
}

/// Builds one internally consistent Realm catalog fixture.
///
/// The factory owns standard type and presentation dependencies. Callers own
/// only capability specific declarations such as resource kinds, page types,
/// collection projections, and feature presentations.
RealmEditorCatalogSnapshot receivedRealmEditorCatalog({
  Iterable<TypeDefinition> definitions = const [],
  CatalogGeneration generation = realmFixtureGeneration,
  Map<PresentationId, PresentationDefinition> presentations = const {},
  Map<CapabilityId, CapabilityDefinition> capabilities = const {},
  Map<String, RealmElementCatalogEntry> elements = const {},
  RealmPageCatalog pageCatalog = const RealmPageCatalog(),
  Map<ResourceDefinitionId, RealmResourceDefinition> resourceDefinitions =
      const {},
  Map<String, RealmRelationDefinition> relations = const {},
  Map<PresentationCollectionSourceId, RealmCollectionProjectionDefinition>
      collectionProjections =
      const {},
}) => RealmEditorCatalogSnapshot(
  catalog: receivedRealmCatalog(definitions),
  generation: generation,
  presentations: {..._realmPresentations, ...presentations},
  capabilities: capabilities,
  elements: elements,
  pageCatalog: pageCatalog,
  resourceDefinitions: resourceDefinitions,
  relations: relations,
  collectionProjections: collectionProjections,
);

final _realmDefinitions = <TypeDefinition>[
  TypeDefinition(
    id: standardTypeRefs.color,
    kind: NominalTypeKind.concrete,
    representation: const IntegerType(width: IntegerWidth.unsigned32),
    rolePresentations: {PresentationRole.editor: _colorPresentationId},
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
    rolePresentations: {PresentationRole.editor: _iconifyPresentationId},
  ),
  TypeDefinition(
    id: standardTypeRefs.svgIcon,
    kind: NominalTypeKind.concrete,
    declarationOwner: "com.typewritermc.types",
    parents: [standardTypeRefs.icon],
    representation: const RecordType(
      fields: {"source": TypeField(name: "source", type: StringType())},
    ),
    rolePresentations: {PresentationRole.editor: _svgPresentationId},
  ),
];

final _realmPresentations = <PresentationId, PresentationDefinition>{
  _colorPresentationId: _defaultInputPresentation(
    _colorPresentationId,
    NamedType(standardTypeRefs.color),
    (control) => ColorInputElement(control: control),
  ),
  _iconifyPresentationId: _defaultInputPresentation(
    _iconifyPresentationId,
    NamedType(standardTypeRefs.iconifyIcon),
    (control) => TextInputElement(
      control: control.copyWith(
        binding: control.binding.at(DataPath.root.field("value")),
      ),
      multiline: false,
    ),
  ),
  _svgPresentationId: _defaultInputPresentation(
    _svgPresentationId,
    NamedType(standardTypeRefs.svgIcon),
    (control) => TextInputElement(
      control: control.copyWith(
        binding: control.binding.at(DataPath.root.field("source")),
      ),
      multiline: true,
    ),
  ),
};

PresentationDefinition _defaultInputPresentation(
  PresentationId id,
  TypeExpression type,
  PresentationElement Function(BoundControl control) element,
) {
  const binding = BindingReference(bindingId: BindingId(0));
  return PresentationDefinition(
    id: id,
    inputs: [
      PresentationInputParameter(
        id: binding.bindingId,
        name: "value",
        type: type,
        access: PresentationInputAccess.edit,
      ),
    ],
    primaryInput: binding.bindingId,
    root: PresentationNode(
      id: "${id.name}.root",
      element: element(BoundControl(binding: binding)),
    ),
  );
}
