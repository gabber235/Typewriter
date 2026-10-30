import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Builds a catalog wire snapshot whose sections are empty unless supplied.
///
/// The generation defaults to the one of the empty default snapshot.
skir.EditorCatalog testCatalogSnapshot({
  skir.CatalogGeneration? generation,
  List<skir.PublishedType> types = const [],
  List<skir.RelationContract> relations = const [],
  skir.TypeDefinitionId? realmRoot,
  List<skir.PresentationDescriptor> presentations = const [],
  List<skir.PresentationMaterial> presentationMaterials = const [],
  List<skir.ConfigurationRecipe> configuration = const [],
}) => skir.EditorCatalog(
  resourceDisplays: const [],
  resourceOperations: const [],
  generation: generation ?? skir.EditorCatalog.defaultInstance.generation,
  types: types,
  relations: relations,
  realmRoot: realmRoot ?? skir.TypeDefinitionId.defaultInstance,
  presentations: presentations,
  presentationMaterials: presentationMaterials,
  configuration: configuration,
  diagnostics: const [],
  endpointBindings: const [],
  capabilities: const [],
  recommendations: const [],
  roleFallbacks: const [],
);

/// Checks a [testCatalogSnapshot] built from the same sections.
CheckedEditorCatalog testCheckedCatalog({
  skir.CatalogGeneration? generation,
  List<skir.PublishedType> types = const [],
  List<skir.RelationContract> relations = const [],
  skir.TypeDefinitionId? realmRoot,
  List<skir.PresentationDescriptor> presentations = const [],
  List<skir.PresentationMaterial> presentationMaterials = const [],
  List<skir.ConfigurationRecipe> configuration = const [],
}) => CheckedEditorCatalog(
  testCatalogSnapshot(
    generation: generation,
    types: types,
    relations: relations,
    realmRoot: realmRoot,
    presentations: presentations,
    presentationMaterials: presentationMaterials,
    configuration: configuration,
  ),
);

/// A type [id] in [status], ready by default, shaped by [representation],
/// whose effective fields are
/// [fields], declared by [fieldOwner] when it inherits them and by itself
/// otherwise, and which refines [parents]. Search finds it by [searchKey]
/// when given; [display] replaces the default display.
skir.PublishedType testPublishedType(
  skir.TypeDefinitionId id,
  skir.RepresentationTemplate representation, {
  Map<String, skir.TypeTemplate> fields = const {},
  List<skir.NamedTypeTemplate> parents = const [],
  List<skir.TypeParameter> parameters = const [],
  skir.ValuePath? placementField,
  String? searchKey,
  skir.TypeDisplay? display,
  skir.TypeDefinitionId? fieldOwner,
  skir.DeclarationStatus status = skir.DeclarationStatus.ready,
}) => skir.PublishedType(
  searchKey: searchKey,
  placementField: placementField,
  display: display ?? defaultTypeDisplay(""),
  definition: skir.TypeDefinition(
    id: id,
    parameters: parameters,
    representation: representation,
    parents: parents,
  ),
  status: status,
  effectiveFields: [
    for (final field in fields.entries)
      skir.EffectiveFieldTemplate(
        key: field.key,
        owner: skir.FieldOwner(definition: fieldOwner ?? id, name: field.key),
        type: field.value,
        rules: const [],
      ),
  ],
  ancestorTemplates: parents,
);

/// [definition] published as ready, with the fields its record
/// representation declares and [display] or the default display.
skir.PublishedType testPublishedDefinition(
  skir.TypeDefinition definition, {
  skir.TypeDisplay? display,
}) => skir.PublishedType(
  searchKey: null,
  placementField: null,
  definition: definition,
  status: skir.DeclarationStatus.ready,
  effectiveFields: [
    if (definition.representation
        case skir.RepresentationTemplate_recordWrapper(:final value))
      for (final field in value.fields)
        skir.EffectiveFieldTemplate(
          key: field.owner.name,
          owner: field.owner,
          type: field.type,
          rules: const [],
        ),
  ],
  ancestorTemplates: definition.parents,
  display: display ?? defaultTypeDisplay(""),
);

/// A ready record type [id] with type [parameters] that declares [fields]
/// and refines [parents]; concrete unless [abstract].
skir.PublishedType testPublishedRecord(
  skir.TypeDefinitionId id,
  Map<String, skir.TypeTemplate> fields, {
  List<skir.NamedTypeTemplate> parents = const [],
  List<skir.TypeParameter> parameters = const [],
  bool abstract = false,
  skir.ValuePath? placementField,
  String? searchKey,
  skir.TypeDisplay? display,
}) => testPublishedType(
  id,
  skir.RepresentationTemplate.createRecord(
    abstract_: abstract,
    fields: [
      for (final field in fields.entries)
        skir.FieldDeclaration(
          owner: skir.FieldOwner(definition: id, name: field.key),
          type: field.value,
          overrides: const [],
          hasConstructorDefault: false,
        ),
    ],
  ),
  fields: fields,
  parents: parents,
  parameters: parameters,
  placementField: placementField,
  searchKey: searchKey,
  display: display,
);

/// The id of the type [name] in the [namespace] tests declare their types in.
skir.TypeDefinitionId testTypeId(String name, {String namespace = "test"}) =>
    skir.TypeDefinitionId(
      typeId: skir.TypeId.createQualified(namespace: namespace, name: name),
      revision: 1,
    );

/// The ownership relation [id]: one [owner] owns many [member]s, deleting
/// them with it.
skir.RelationContract testOwnershipRelation(
  String id, {
  required skir.TypeDefinitionId owner,
  required skir.TypeDefinitionId member,
}) => skir.RelationContract(
  id: skir.RelationId(value: id),
  first: skir.EndpointDefinition(
    id: skir.EndpointId(value: "$id:first"),
    slot: skir.EndpointSlot.first,
    resource: skir.NamedTypeTemplate(definition: owner, arguments: const []),
    cardinality: skir.EndpointCardinality.one,
    onDelete: skir.RelationDeletePolicy.cascade,
  ),
  second: skir.EndpointDefinition(
    id: skir.EndpointId(value: "$id:second"),
    slot: skir.EndpointSlot.second,
    resource: skir.NamedTypeTemplate(definition: member, arguments: const []),
    cardinality: skir.EndpointCardinality.many,
    onDelete: skir.RelationDeletePolicy.clear,
  ),
  families: [skir.resourceOwnershipFamily],
);
