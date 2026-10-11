import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("checked catalog retains the complete received snapshot", () {
    final received = _catalog(
      generation: skir.CatalogGeneration(value: "catalog:7"),
    );
    final checked = CheckedEditorCatalog(received);

    expect(checked.snapshot, same(received));
    expect(checked.snapshot.generation.value, "catalog:7");
    expect(checked.snapshot.types, isEmpty);
    expect(checked.snapshot.diagnostics, isEmpty);
  });

  test("matching catalog and authored snapshot expose one draft", () {
    final generation = skir.CatalogGeneration(value: "catalog:7");
    final resource = skir.ResourceId(value: "book:1");
    final snapshot = skir.AuthoringState(
      generation: generation,
      resources: [
        skir.AuthoringResource(
          id: resource,
          definition: skir.ResourceDefinitionId(value: "typewriter.book"),
          content: skir.AuthoringRecord(
            configuration: skir.TypeSelection.unknown,
            fields: const [],
          ),
        ),
      ],
      links: const [],
      findings: const [],
    );
    final state = AuthoringSessionState(
      snapshot: snapshot,
      catalog: CheckedEditorCatalog(_catalog(generation: generation)),
    );

    expect(state.snapshot, snapshot);
    expect(state.confirmedDocument?.generation, snapshot.generation);
    expect(state.confirmedDocument?.resources.keys, contains(resource));
  });

  test("a catalog from another generation cannot form an authored draft", () {
    final snapshot = skir.AuthoringState(
      generation: skir.CatalogGeneration(value: "catalog:7"),
      resources: const [],
      links: const [],
      findings: const [],
    );
    final state = AuthoringSessionState(
      snapshot: snapshot,
      catalog: CheckedEditorCatalog(
        _catalog(generation: skir.CatalogGeneration(value: "catalog:8")),
      ),
    );

    expect(state.confirmedDocument, isNull);
  });
}

skir.EditorCatalogWireSnapshot _catalog({
  required skir.CatalogGeneration generation,
}) => skir.EditorCatalogWireSnapshot(
  generation: generation,
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
