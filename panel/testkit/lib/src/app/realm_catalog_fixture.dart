import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

const realmFixtureGeneration = CatalogGeneration("fixture");

skir.EditorCatalogWireSnapshot receivedEditorCatalogWireSnapshot({
  skir.CatalogGeneration? generation,
}) => skir.EditorCatalogWireSnapshot(
  generation:
      generation ?? skir.CatalogGeneration(value: realmFixtureGeneration.value),
  types: const [],
  relations: const [],
  resourceDefinitions: const [],
  presentations: const [],
  presentationMaterials: const [],
  configuration: const [],
  diagnostics: const [],
  initialization: const [],
  endpointBindings: const [],
  capabilities: const [],
  recommendations: const [],
  roleFallbacks: const [],
);

CheckedEditorCatalog receivedCheckedEditorCatalog({
  skir.CatalogGeneration? generation,
}) => CheckedEditorCatalog(
  receivedEditorCatalogWireSnapshot(generation: generation),
);
