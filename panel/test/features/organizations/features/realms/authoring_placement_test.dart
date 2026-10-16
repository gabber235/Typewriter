import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("created graph resources avoid siblings and preserve dimensions", () {
    final root = skir.TypeDefinitionId(
      typeId: skir.TypeId.createQualified(
        namespace: "test",
        name: "GraphResource",
      ),
      revision: 1,
    );
    final integer = skir.TypeTemplate.wrapScalar(
      skir.ScalarKind.createInteger(width: skir.IntegerWidth.signedThirtyTwo),
    );
    skir.PublishedType published(
      skir.TypeDefinitionId id,
      Map<String, skir.TypeTemplate> fields,
    ) => skir.PublishedType(
      display: null,
      definition: skir.TypeDefinition(
        id: id,
        parameters: const [],
        parents: const [],
        representation: skir.RepresentationTemplate.createRecord(
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
      ancestorTemplates: const [],
    );
    final snapshot = skir.EditorCatalogWireSnapshot.defaultInstance.toMutable()
      ..types = [
        published(root, {
          "placement": skir.TypeTemplate.createNamed(
            definition: graphPlacementTypeRef,
            arguments: const [],
          ),
        }),
        published(graphPlacementTypeRef, {
          for (final key in ["x", "y", "width", "height"]) key: integer,
        }),
      ];
    final catalog = CheckedEditorCatalog(snapshot.toFrozen());
    final configuration = catalog.beginSelection(root);
    final existing = skir.ResourceId(value: "tag:existing");
    final created = skir.ResourceId(value: "tag:created");
    final definition = skir.ResourceDefinitionId(value: "test.tag");
    final placement = GraphPlacement(x: 0, y: 0, width: 3, height: 2);
    final draft =
        AuthoringEdit(
          generation: catalog.snapshot.generation,
          catalog: catalog,
          resources: [
            for (final id in [existing, created])
              skir.AuthoringResource(
                id: id,
                definition: definition,
                content: skir.AuthoringRecord(
                  configuration: configuration,
                  fields: [
                    skir.FieldValue(
                      name: "placement",
                      value: placement.toAuthoredValue(),
                    ),
                  ],
                ),
              ),
          ],
          links: const [],
        )..placeCreatedResource(
          ResourceCreationRequest(
            id: created,
            definition: definition,
            configuration: configuration,
          ),
        );
    final before = draft.resource(existing)!.graphGridRect!;
    final after = draft.resource(created)!.graphGridRect!;
    expect(before, placement.gridRect);
    expect(after.overlaps(before, gap: 1), isFalse);
    expect(after.width, placement.width);
    expect(after.height, placement.height);
  });

  final graphValue = skir.DataValue.createRecord(
    fields: [
      _integerField("x", 1),
      _integerField("y", 2),
      _integerField("width", 3),
      _integerField("height", 4),
    ],
  );

  test("placement variants are selected by declared type identity", () {
    final placement = skir.DataValue.createNamed(
      actualType: skir.NamedTypeUse(
        definition: placementTypeRefs.graph,
        arguments: const [],
      ),
      payload: graphValue,
    ).toPlacement();

    expect(placement, GraphPlacement(x: 1, y: 2, width: 3, height: 4));
  });

  test("placement decoding rejects an unknown type with a familiar shape", () {
    final unknown = skir.TypeDefinitionId(
      typeId: skir.TypeId.createDeclared(
        value: "b3af85bf5a024f2b8806fb3d5c4f15ec",
      ),
      revision: 1,
    );

    expect(
      () => skir.DataValue.createNamed(
        actualType: skir.NamedTypeUse(definition: unknown, arguments: const []),
        payload: graphValue,
      ).toPlacement(),
      throwsArgumentError,
    );
  });
}

skir.FieldValue _integerField(String name, int value) => skir.FieldValue(
  name: name,
  value: skir.DataValue.wrapInteger(value.toString()),
);
