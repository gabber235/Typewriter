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
      Map<String, skir.TypeTemplate> fields, {
      List<skir.NamedTypeTemplate> parents = const [],
    }) => skir.PublishedType(
      searchKey: null,
      placementField: fields.containsKey("placement")
          ? editorRootPath.field("placement")
          : null,
      display: defaultTypeDisplay(""),
      definition: skir.TypeDefinition(
        id: id,
        parameters: const [],
        parents: parents,
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
      ancestorTemplates: parents,
    );
    final refined = skir.TypeDefinitionId(
      typeId: skir.TypeId.createQualified(
        namespace: "test",
        name: "TintedGraphPlacement",
      ),
      revision: 1,
    );
    final parent = skir.NamedTypeTemplate(
      definition: graphPlacementTypeRef,
      arguments: const [],
    );
    final snapshot = skir.EditorCatalog.defaultInstance.toMutable()
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
        published(
          refined,
          {
            for (final key in ["x", "y", "width", "height"]) key: integer,
            "tint": skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
          },
          parents: [parent],
        ),
      ];
    final catalog = CheckedEditorCatalog(snapshot.toFrozen());
    final configuration = catalog.beginSelection(root);
    final existing = skir.ResourceId(value: "tag:existing");
    final created = skir.ResourceId(value: "tag:created");
    final placement = GraphPlacement(x: 0, y: 0, width: 3, height: 2);
    final draft =
        AuthoringEdit(
          generation: catalog.snapshot.generation,
          catalog: catalog,
          resources: [
            for (final id in [existing, created])
              skir.AuthoringResource(
                id: id,
                content: skir.AuthoringRecord(
                  configuration: configuration,
                  fields: [
                    skir.FieldValue(
                      name: "placement",
                      value: id == existing
                          ? placement.toAuthoredValue()
                          : skir.DataValue.createNamed(
                              actualType: skir.NamedTypeUse(
                                definition: refined,
                                arguments: const [],
                              ),
                              payload: skir.DataValue.createRecord(
                                fields: [
                                  ...placement
                                      .toAuthoredValue()
                                      .authoredRecord!
                                      .fields,
                                  skir.FieldValue(
                                    name: "tint",
                                    value: skir.DataValue.wrapStringValue(
                                      "blue",
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
          ],
          links: const [],
        )..placeCreatedResource(
          ResourceCreationRequest(
            id: created,
            type: root,
            configuration: configuration,
          ),
        );
    final before = draft.resource(existing)!.graphRect(catalog)!;
    final after = draft.resource(created)!.graphRect(catalog)!;
    expect(before, placement.gridRect);
    expect(after.overlaps(before, gap: 1), isFalse);
    expect(after.width, placement.width);
    expect(after.height, placement.height);
    final createdPlacement = draft
        .resource(created)!
        .authoredField("placement")!;
    expect(createdPlacement.authoredActualType!.definition, refined);
    expect(createdPlacement.authoredField("tint")!.authoredString, "blue");
    final count = draft.operationCount;
    expect(() => draft.resizeGraphPlacement(created, 0, 4), throwsStateError);
    expect(draft.operationCount, count);
    expect(draft.resource(created)!.graphRect(catalog), after);
    final unfinished = skir.DataValue.createNamed(
      actualType: skir.NamedTypeUse(
        definition: graphPlacementTypeRef,
        arguments: const [],
      ),
      payload: skir.DataValue.createRecord(
        fields: [
          skir.FieldValue(name: "x", value: skir.DataValue.unfilled),
          for (final key in ["y", "width", "height"]) _integerField(key, 1),
        ],
      ),
    ).readPlacement(catalog);
    expect(unfinished, PlacementReading.unfinished(editorRootPath.field("x")));
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
        definition: graphPlacementTypeRef,
        arguments: const [],
      ),
      payload: graphValue,
    ).readPlacement(CheckedEditorCatalog(skir.EditorCatalog.defaultInstance));

    expect(placement, isA<ReadyPlacement>());
    expect(
      (placement as ReadyPlacement).placement,
      GraphPlacement(x: 1, y: 2, width: 3, height: 4),
    );
  });

  test("placement decoding rejects an unknown type with a familiar shape", () {
    final unknown = skir.TypeDefinitionId(
      typeId: skir.TypeId.createDeclared(
        value: "b3af85bf5a024f2b8806fb3d5c4f15ec",
      ),
      revision: 1,
    );

    expect(
      skir.DataValue.createNamed(
        actualType: skir.NamedTypeUse(definition: unknown, arguments: const []),
        payload: graphValue,
      ).readPlacement(CheckedEditorCatalog(skir.EditorCatalog.defaultInstance)),
      isA<UnavailablePlacement>(),
    );
  });
}

skir.FieldValue _integerField(String name, int value) => skir.FieldValue(
  name: name,
  value: skir.DataValue.wrapInteger(value.toString()),
);
