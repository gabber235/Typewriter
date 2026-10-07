import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test(
    "authored draft retains resource identity from the canonical snapshot",
    () {
      final resource = skir.ResourceId(value: "resource:book");
      final record = skir.AuthoringRecord(
        configuration: skir.TypeSelection.unknown,
        fields: [
          skir.FieldValue(
            name: "title",
            value: skir.DataValue.wrapStringValue("Quest"),
          ),
        ],
      );
      final snapshot = skir.AuthoringState(
        generation: skir.CatalogGeneration(value: "catalog:1"),
        resources: [
          skir.AuthoringResource(
            id: resource,
            definition: skir.ResourceDefinitionId(value: "typewriter.book"),
            content: record,
          ),
        ],
        links: const [],
        findings: const [],
      );

      final draft = AuthoredDraft.fromState(snapshot);

      expect(draft.resources.keys, [resource]);
      expect(draft.resource(resource), record);
      expect(draft.prepare().catalog, snapshot.generation);
    },
  );
}
