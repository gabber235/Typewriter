import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Builds a catalog wire snapshot whose sections are empty unless supplied.
///
/// The generation defaults to the one of the empty default snapshot.
skir.EditorCatalogWireSnapshot testCatalogSnapshot({
  skir.CatalogGeneration? generation,
  List<skir.PublishedType> types = const [],
  List<skir.RelationContract> relations = const [],
  List<skir.AuthoringResourceDefinition> resourceDefinitions = const [],
  List<skir.PresentationDescriptor> presentations = const [],
  List<skir.PresentationMaterial> presentationMaterials = const [],
}) => skir.EditorCatalogWireSnapshot(
  resourceDisplays: const [],
  resourceOperations: const [],
  resourceOperationContributions: const [],
  generation:
      generation ?? skir.EditorCatalogWireSnapshot.defaultInstance.generation,
  types: types,
  relations: relations,
  resourceDefinitions: resourceDefinitions,
  presentations: presentations,
  presentationMaterials: presentationMaterials,
  configuration: const [],
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
  List<skir.AuthoringResourceDefinition> resourceDefinitions = const [],
  List<skir.PresentationDescriptor> presentations = const [],
  List<skir.PresentationMaterial> presentationMaterials = const [],
}) => CheckedEditorCatalog(
  testCatalogSnapshot(
    generation: generation,
    types: types,
    relations: relations,
    resourceDefinitions: resourceDefinitions,
    presentations: presentations,
    presentationMaterials: presentationMaterials,
  ),
);
