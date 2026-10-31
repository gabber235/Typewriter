import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Builds a catalog wire snapshot whose sections are empty unless supplied.
///
/// The generation defaults to the one of the empty default snapshot.
skir.EditorCatalog testCatalogSnapshot({
  skir.CatalogGeneration? generation,
  Iterable<skir.PublishedType> types = const [],
  Iterable<skir.RelationContract> relations = const [],
  skir.TypeDefinitionId? realmRoot,
  Iterable<skir.ResourceDisplayFormulas> resourceDisplays = const [],
  Iterable<skir.ResourceOperationDefinition> resourceOperations = const [],
  Iterable<skir.PresentationDescriptor> presentations = const [],
  Iterable<skir.PresentationMaterial> presentationMaterials = const [],
  Iterable<skir.ConfigurationRecipe> configuration = const [],
  Iterable<skir.DeclarationDiagnostic> diagnostics = const [],
  Iterable<skir.EndpointBindingTemplate> endpointBindings = const [],
  Iterable<skir.CapabilityDefinition> capabilities = const [],
  Iterable<skir.TypeRecommendation> recommendations = const [],
  Iterable<skir.RoleFallback> roleFallbacks = const [],
}) {
  final catalog = skir.EditorCatalog.mutable()
    ..types = types
    ..relations = relations
    ..resourceDisplays = resourceDisplays
    ..resourceOperations = resourceOperations
    ..presentations = presentations
    ..presentationMaterials = presentationMaterials
    ..configuration = configuration
    ..diagnostics = diagnostics
    ..endpointBindings = endpointBindings
    ..capabilities = capabilities
    ..recommendations = recommendations
    ..roleFallbacks = roleFallbacks;
  if (generation != null) catalog.generation = generation;
  if (realmRoot != null) catalog.realmRoot = realmRoot;
  return catalog.toFrozen();
}

/// Checks a [testCatalogSnapshot] built from the same sections.
CheckedEditorCatalog testCheckedCatalog({
  skir.CatalogGeneration? generation,
  List<skir.PublishedType> types = const [],
  List<skir.RelationContract> relations = const [],
  skir.TypeDefinitionId? realmRoot,
  List<skir.PresentationDescriptor> presentations = const [],
  List<skir.PresentationMaterial> presentationMaterials = const [],
  List<skir.ConfigurationRecipe> configuration = const [],
  List<skir.EndpointBindingTemplate> endpointBindings = const [],
}) => CheckedEditorCatalog(
  testCatalogSnapshot(
    generation: generation,
    types: types,
    relations: relations,
    realmRoot: realmRoot,
    presentations: presentations,
    presentationMaterials: presentationMaterials,
    configuration: configuration,
    endpointBindings: endpointBindings,
  ),
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

/// The published type [id] of [representation], unknown by default, with
/// [parameters] and [parents].
///
/// Its ancestors are [ancestors], or else its [parents]; its effective fields
/// are [fields]. It is ready unless [status] says otherwise and shows
/// [display], the default display unless given, with no search key or
/// placement field unless given.
skir.PublishedType publishedType(
  skir.TypeDefinitionId id, {
  skir.RepresentationTemplate representation =
      skir.RepresentationTemplate.unknown,
  Iterable<skir.TypeParameter> parameters = const [],
  Iterable<skir.NamedTypeTemplate> parents = const [],
  Iterable<skir.NamedTypeTemplate>? ancestors,
  Iterable<skir.EffectiveFieldTemplate> fields = const [],
  skir.DeclarationStatus status = skir.DeclarationStatus.ready,
  skir.TypeDisplay? display,
  String? searchKey,
  skir.ValuePath? placementField,
}) => skir.PublishedType(
  definition: skir.TypeDefinition(
    id: id,
    parameters: parameters,
    representation: representation,
    parents: parents,
  ),
  status: status,
  effectiveFields: fields,
  ancestorTemplates: ancestors ?? parents,
  display: display ?? defaultTypeDisplay(""),
  searchKey: searchKey,
  placementField: placementField,
);

/// A host over the single [binding], with an empty root and catalog and a
/// small evaluation budget; the caller disposes it.
BoundPresentationHost singleBindingHost(BoundPresentationBinding binding) =>
    BoundPresentationHost(
      catalog: testCheckedCatalog(),
      root: () => skir.PresentationNode.defaultInstance,
      bindings: [binding],
      budget: skir.EvaluationBudget(maxSteps: 256, maxCollectionItems: 32),
    );

/// The type [id] whose only parent, and so only ancestor, is the type
/// [base] without arguments.
skir.PublishedType subtypeOf(
  skir.TypeDefinitionId id,
  skir.TypeDefinitionId base,
) {
  final parent = skir.NamedTypeTemplate(definition: base, arguments: const []);
  return publishedType(id, parents: [parent], ancestors: [parent]);
}
