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

/// A saved document holding the one untyped record [resource], whose fields
/// hold [texts], typed by a [receivedCheckedEditorCatalog] of [generation]
/// that declares nothing, so only edits by location apply to it.
AuthoringDocument textRecordDocument(
  skir.ResourceId resource,
  Map<String, String> texts, {
  skir.CatalogGeneration? generation,
}) => AuthoringDocument(
  catalog: receivedCheckedEditorCatalog(generation: generation),
  entries: {
    resource: skir.AuthoringResource(
      id: resource,
      content: skir.AuthoringRecord(
        configuration: skir.TypeSelection.unknown,
        fields: [
          for (final MapEntry(:key, :value) in texts.entries)
            skir.FieldValue(
              name: key,
              value: skir.DataValue.wrapStringValue(value),
            ),
        ],
      ),
    ),
  },
  links: const [],
);
