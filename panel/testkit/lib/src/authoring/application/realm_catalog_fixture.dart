import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

final realmFixtureGeneration = skir.CatalogGeneration(value: "fixture");

skir.EditorCatalog receivedEditorCatalog({
  skir.CatalogGeneration? generation,
}) => skir.EditorCatalog(
  resourceDisplays: const [],
  resourceOperations: const [],
  generation: generation ?? realmFixtureGeneration,
  types: const [],
  relations: const [],
  realmRoot: skir.TypeDefinitionId.defaultInstance,
  presentations: const [],
  presentationMaterials: const [],
  configuration: const [],
  diagnostics: const [],

  endpointBindings: const [],
  capabilities: const [],
  recommendations: const [],
  roleFallbacks: const [],
);

CheckedEditorCatalog receivedCheckedEditorCatalog({
  skir.CatalogGeneration? generation,
}) => CheckedEditorCatalog(receivedEditorCatalog(generation: generation));
