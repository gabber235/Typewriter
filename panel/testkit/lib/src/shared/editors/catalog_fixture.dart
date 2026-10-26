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

/// A ready type [id] shaped by [representation], whose effective fields are
/// [fields] and which refines [parents].
skir.PublishedType testPublishedType(
  skir.TypeDefinitionId id,
  skir.RepresentationTemplate representation, {
  Map<String, skir.TypeTemplate> fields = const {},
  List<skir.NamedTypeTemplate> parents = const [],
  skir.ValuePath? placementField,
}) => skir.PublishedType(
  searchKey: null,
  placementField: placementField,
  display: defaultTypeDisplay(""),
  definition: skir.TypeDefinition(
    id: id,
    parameters: const [],
    representation: representation,
    parents: parents,
  ),
  status: skir.DeclarationStatus.ready,
  effectiveFields: [
    for (final field in fields.entries)
      skir.EffectiveFieldTemplate(
        key: field.key,
        owner: skir.FieldOwner(definition: id, name: field.key),
        type: field.value,
        rules: const [],
      ),
  ],
  ancestorTemplates: parents,
);

/// A ready concrete record type [id] that declares [fields] and refines
/// [parents].
skir.PublishedType testPublishedRecord(
  skir.TypeDefinitionId id,
  Map<String, skir.TypeTemplate> fields, {
  List<skir.NamedTypeTemplate> parents = const [],
  skir.ValuePath? placementField,
}) => testPublishedType(
  id,
  skir.RepresentationTemplate.createRecord(
    abstract_: false,
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
  placementField: placementField,
);
